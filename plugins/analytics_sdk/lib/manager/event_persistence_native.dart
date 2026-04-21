import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:analytics_sdk/config/sdk_config.dart';
import 'package:analytics_sdk/utils/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

/// Native 平台事件持久化：基于本地文件 + tombstone 机制。
class EventPersistenceImpl {
  String? _cacheFilePath;
  String? _tombstoneFilePath;
  final Lock _cacheLock = Lock();
  final List<Map<String, dynamic>> _cacheBuffer = [];
  static const int _cacheBufferThreshold = 10;
  static const Duration _cacheFlushInterval = Duration(seconds: 5);
  Timer? _cacheFlushTimer;

  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _cacheFilePath = '${dir.path}/${SdkConfig.cacheFileName}';
      _tombstoneFilePath = '${dir.path}/${SdkConfig.tombstoneFileName}';
    } catch (e) {
      Logger.analyticsSdk('持久化初始化失败: $e');
      _cacheFilePath = null;
      _tombstoneFilePath = null;
    }
  }

  void bufferEvent(Map<String, dynamic> event) {
    if (_cacheFilePath == null) return;
    _cacheBuffer.add(event);
    if (_cacheBuffer.length >= _cacheBufferThreshold) {
      flushBuffer();
    } else {
      _cacheFlushTimer ??= Timer(_cacheFlushInterval, () {
        _cacheFlushTimer = null;
        flushBuffer();
      });
    }
  }

  Future<List<Map<String, dynamic>>> loadEvents({
    required Queue<Map<String, dynamic>> queue,
    required int maxQueueSize,
    required int maxCacheLines,
    required bool Function(String) isEventTypeEnabled,
  }) async {
    if (_cacheFilePath == null) return const [];
    final file = File(_cacheFilePath!);
    if (!await file.exists()) return const [];

    final recovered = <Map<String, dynamic>>[];
    try {
      await _cacheLock.synchronized(() async {
        if (await file.length() > SdkConfig.maxCacheBytes) {
          await _trimCacheFileIfNeeded(file);
        }

        final tombstonedIds = await _loadTombstoneIds();
        final lines = await file.readAsLines();
        final linesToProcess = lines.length > maxCacheLines
            ? lines.sublist(lines.length - maxCacheLines)
            : lines;

        for (final line in linesToProcess) {
          if (line.trim().isEmpty) continue;
          try {
            final decoded = jsonDecode(line);
            if (decoded is Map<String, dynamic>) {
              final eventId = decoded['event_id'];
              if (tombstonedIds.isNotEmpty &&
                  eventId != null &&
                  tombstonedIds.contains(eventId)) {
                continue;
              }
              final eventType = decoded['event'] as String?;
              if (eventType != null && !isEventTypeEnabled(eventType)) {
                Logger.analyticsSdk('缓存恢复：事件类型 $eventType 未启用，跳过');
                continue;
              }
              recovered.add(decoded);
            }
          } catch (_) {
            continue;
          }
        }

        await file.delete();
        if (_tombstoneFilePath != null) {
          final tombstone = File(_tombstoneFilePath!);
          if (await tombstone.exists()) await tombstone.delete();
        }
      });
    } catch (e) {
      Logger.analyticsSdk('缓存加载失败: $e');
      try {
        await file.delete();
      } catch (_) {}
    }
    return recovered;
  }

  Future<void> removeEvents(List<Map<String, dynamic>> reportedEvents) async {
    if (_tombstoneFilePath == null || reportedEvents.isEmpty) return;

    final ids = reportedEvents
        .map((e) => e['event_id'])
        .whereType<String>()
        .where((id) => id.isNotEmpty && !id.contains('\n'))
        .toList();

    if (ids.isEmpty) return;

    try {
      await _cacheLock.synchronized(() async {
        try {
          final tombstone = File(_tombstoneFilePath!);
          await tombstone.writeAsString(
            '${ids.join('\n')}\n',
            mode: FileMode.append,
          );
          Logger.analyticsSdk('tombstone 追加 ${ids.length} 条 event_id');

          final tombstoneContent = await tombstone.readAsString();
          final tombstoneCount =
              tombstoneContent.split('\n').where((l) => l.isNotEmpty).length;
          if (tombstoneCount >= SdkConfig.tombstoneCompactionThreshold) {
            await _compactCache(tombstoneContent);
          }
        } catch (e) {
          Logger.analyticsSdk('tombstone 写入失败: $e');
        }
      });
    } catch (e) {
      Logger.analyticsSdk('缓存移除操作异常: $e');
    }
  }

  Future<void> clearCache() async {
    if (_cacheFilePath == null) return;
    try {
      await _cacheLock.synchronized(() async {
        try {
          final file = File(_cacheFilePath!);
          if (await file.exists()) await file.delete();
          if (_tombstoneFilePath != null) {
            final tombstone = File(_tombstoneFilePath!);
            if (await tombstone.exists()) await tombstone.delete();
          }
        } catch (e) {
          Logger.analyticsSdk('缓存清除失败: $e');
        }
      });
    } catch (e) {
      Logger.analyticsSdk('缓存清除操作异常: $e');
    }
  }

  void flushBuffer() {
    if (_cacheFilePath == null || _cacheBuffer.isEmpty) return;
    _cacheFlushTimer?.cancel();
    _cacheFlushTimer = null;
    final batch = List<Map<String, dynamic>>.from(_cacheBuffer);
    _cacheBuffer.clear();
    Future.microtask(() async {
      await _saveBatchToCache(batch);
    });
  }

  Future<void> flushBufferAsync() async {
    if (_cacheFilePath == null || _cacheBuffer.isEmpty) return;
    _cacheFlushTimer?.cancel();
    _cacheFlushTimer = null;
    final batch = List<Map<String, dynamic>>.from(_cacheBuffer);
    _cacheBuffer.clear();
    await _saveBatchToCache(batch);
  }

  // ==================== 私有方法 ====================

  Future<void> _trimCacheFileIfNeeded(File file) async {
    try {
      final len = await file.length();
      if (len <= SdkConfig.maxCacheBytes) return;
      final lines = await file.readAsLines();
      int total = 0;
      int startIndex = 0;
      for (int i = lines.length - 1; i >= 0; i--) {
        total += utf8.encode(lines[i]).length + 1;
        if (total > SdkConfig.maxCacheBytes) {
          startIndex = i + 1;
          break;
        }
      }
      if (startIndex <= 0) return;
      final kept = lines.sublist(startIndex);
      await file.writeAsString(kept.isEmpty ? '' : '${kept.join('\n')}\n');
      Logger.analyticsSdk(
          '缓存文件超过 ${SdkConfig.maxCacheBytes} 字节，已裁剪掉前 $startIndex 条');
    } catch (e) {
      Logger.analyticsSdk('缓存文件裁剪失败: $e');
    }
  }

  Future<void> _saveBatchToCache(List<Map<String, dynamic>> batch) async {
    if (_cacheFilePath == null || batch.isEmpty) return;
    try {
      await _cacheLock.synchronized(() async {
        try {
          final file = File(_cacheFilePath!);
          final lines = batch
              .map((item) {
                try {
                  return jsonEncode(item);
                } catch (e) {
                  Logger.analyticsSdk('单个事件编码失败，跳过: $e');
                  return null;
                }
              })
              .where((line) => line != null)
              .join('\n');
          if (lines.isNotEmpty) {
            await file.writeAsString('$lines\n', mode: FileMode.append);
            await _trimCacheFileIfNeeded(file);
          }
        } catch (e) {
          Logger.analyticsSdk('批量缓存写入失败: $e');
        }
      });
    } catch (e) {
      Logger.analyticsSdk('缓存保存异常: $e');
    }
  }

  Future<Set<String>> _loadTombstoneIds() async {
    if (_tombstoneFilePath == null) return {};
    try {
      final tombstone = File(_tombstoneFilePath!);
      if (!await tombstone.exists()) return {};
      final content = await tombstone.readAsString();
      return content.split('\n').where((l) => l.isNotEmpty).toSet();
    } catch (e) {
      Logger.analyticsSdk('tombstone 读取失败: $e');
      return {};
    }
  }

  Future<void> _compactCache(String tombstoneContent) async {
    if (_cacheFilePath == null || _tombstoneFilePath == null) return;
    try {
      final tombstonedIds =
          tombstoneContent.split('\n').where((l) => l.isNotEmpty).toSet();

      final cacheFile = File(_cacheFilePath!);
      if (!await cacheFile.exists()) {
        await File(_tombstoneFilePath!).delete();
        return;
      }

      final lines = await cacheFile.readAsLines();
      final kept = <String>[];
      int removed = 0;

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final decoded = jsonDecode(line);
          if (decoded is Map<String, dynamic>) {
            final id = decoded['event_id'];
            if (id != null && tombstonedIds.contains(id)) {
              removed++;
            } else {
              kept.add(line);
            }
          } else {
            kept.add(line);
          }
        } catch (_) {
          kept.add(line);
        }
      }

      if (kept.isEmpty) {
        await cacheFile.delete();
      } else {
        await cacheFile.writeAsString('${kept.join('\n')}\n');
      }
      try {
        await File(_tombstoneFilePath!).delete();
      } catch (e) {
        Logger.analyticsSdk('tombstone 删除失败（可忽略，下次压缩会重试）: $e');
      }

      Logger.analyticsSdk('缓存压缩完成：删除 $removed 条，保留 ${kept.length} 条');
    } catch (e) {
      Logger.analyticsSdk('缓存压缩失败: $e');
    }
  }
}
