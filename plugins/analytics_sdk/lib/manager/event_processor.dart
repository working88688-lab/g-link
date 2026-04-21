import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:analytics_sdk/manager/event_persistence.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

import 'package:analytics_sdk/config/sdk_config.dart';
import 'package:analytics_sdk/manager/event_type_config_manager.dart';
import 'package:analytics_sdk/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';

/// 事件处理与上报管理器
///
/// 负责：
/// - 维护事件队列
/// - 本地持久化（缓存文件）
/// - 批量上报 & 指数退避重试
/// - 定时上报定时器
///
/// 对外由 `AnalyticsSdk` 持有并调用，不直接暴露给业务方。
class EventProcessor {
  String? _reportUrl;
  final Queue<Map<String, dynamic>> _eventQueue = Queue<Map<String, dynamic>>();

  Timer? _uploadTimer;

  final EventPersistenceImpl _persistence = EventPersistenceImpl();

  int _backoffLevel = 0;
  Timer? _retryTimer;

  /// JSON 过大时折半缩小批次；成功后重置为 null（恢复用 maxBatchSize）
  int? _overrideBatchSize;

  http.Client? _httpClient;

  http.Client get _client => _httpClient ??= http.Client();

  /// 上报锁，防止并发上报
  bool _isUploading = false;
  final Lock _uploadLock = Lock();

  /// event_id 防抖：记录最近见到该 id 的时间，窗口内重复则丢弃
  final Map<String, DateTime> _recentEventIds = {};

  /// 防抖窗口：1000ms 秒级时间戳粒度 + 100ms 时钟抖动容差。
  /// event_id 的哈希因子包含秒级 client_ts，同秒内同事件会产生同一 id；
  /// 额外 100ms 用于覆盖调用链路上的微小时间偏移，避免临界点误判。
  static const _dedupWindow = Duration(milliseconds: 1100);

  /// 测试包用：最近一次上报结果
  bool? lastUploadSuccess;
  String? lastUploadError;
  DateTime? lastUploadTime;

  /// 是否已配置可用的上报 URL
  bool get hasValidReportUrl =>
      _reportUrl != null && _reportUrl!.isNotEmpty == true;

  /// 测试包用：队列中待上报事件数
  int get queueLength => _eventQueue.length;

  /// 测试包用：当前上报地址（脱敏）
  String? get debugReportUrl => _reportUrl;

  /// 更新上报 URL（域名管理器回调时调用）
  void updateReportUrl(String? reportUrl) {
    _reportUrl = reportUrl;
  }

  /// 启动定时上报定时器
  void startAutoUploadTimer() {
    _uploadTimer?.cancel();
    _uploadTimer = Timer.periodic(SdkConfig.uploadInterval, (_) {
      try {
        uploadBatch().catchError((e) {
          Logger.analyticsSdk('定时上报 Future 异常: $e');
        });
      } catch (e) {
        Logger.analyticsSdk('定时上报异常: $e');
      }
    });
  }

  /// 停止定时上报定时器
  void stopAutoUploadTimer() {
    _uploadTimer?.cancel();
    _uploadTimer = null;
  }

  /// 重置退避和上报状态（SDK 重新初始化时调用）
  void resetState() {
    _backoffLevel = 0;
    _overrideBatchSize = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    lastUploadSuccess = null;
    lastUploadError = null;
    lastUploadTime = null;
    _isUploading = false;
    _recentEventIds.clear();
  }

  /// 事件入队：
  /// - 负责队列容量检查
  /// - 触发必要的上报
  /// - 写入本地缓存
  ///
  /// 返回值：
  /// - `true`：事件成功进入队列
  /// - `false`：因队列已满等原因被丢弃
  bool enqueueEvent(Map<String, dynamic> json) {
    // 队列容量检查，防止内存无限增长
    if (_eventQueue.length >= SdkConfig.maxQueueSize) {
      Logger.analyticsSdk('警告：事件队列已满（${_eventQueue.length}），尝试立即上报');
      // 尝试立即上报以释放队列空间（不 await）
      try {
        uploadBatch().catchError((e) {
          Logger.analyticsSdk('立即上报 Future 异常: $e');
        });
      } catch (e) {
        Logger.analyticsSdk('立即上报异常: $e');
      }
      // 队列已满时直接丢弃新事件
      return false;
    }

    // event_id 防抖：1100ms 窗口内同一 id 只保留第一条
    final eventId = json['event_id'] as String?;
    if (eventId != null) {
      final now = DateTime.now();
      _recentEventIds.removeWhere((_, t) => now.difference(t) > _dedupWindow);
      final lastSeen = _recentEventIds[eventId];
      if (lastSeen != null && now.difference(lastSeen) <= _dedupWindow) {
        Logger.analyticsSdk('event_id 防抖，已丢弃: $eventId');
        return false;
      }
      _recentEventIds[eventId] = now;
    }

    _eventQueue.add(json);
    _persistence.bufferEvent(json);
    _flushIfNeeded();
    return true;
  }

  /// 当队列长度达到阈值时触发上报
  void _flushIfNeeded() {
    if (_eventQueue.length >= SdkConfig.autoUploadThreshold) {
      uploadBatch().catchError((e) {
        Logger.analyticsSdk('阈值触发上报 Future 异常: $e');
      });
    }
  }

  /// 强制立即上报
  /// 该方法永远不会抛出异常
  Future<void> flush() async {
    try {
      await uploadBatch();
    } catch (e) {
      Logger.analyticsSdk('flush() 发生异常，已安全处理: $e');
    }
  }

  /// 批量上报队列中的事件
  Future<void> uploadBatch() async {
    if (_eventQueue.isEmpty || _reportUrl == null) return;

    return _uploadLock.synchronized(() async {
      if (_eventQueue.isEmpty || _reportUrl == null || _isUploading) return;

      _isUploading = true;
      // 限制单次上报的批次大小，避免请求过大导致超时或内存问题
      // _overrideBatchSize 在 JSON 过大时折半缩小，上报成功后重置
      final maxBatch = _overrideBatchSize ?? SdkConfig.maxBatchSize;
      final batchSize =
          _eventQueue.length > maxBatch ? maxBatch : _eventQueue.length;

      // 安全检查：确保批次大小有效
      if (batchSize <= 0) {
        Logger.analyticsSdk('批次大小无效: $batchSize');
        _isUploading = false;
        return;
      }

      // 取出批次但不从队列移除，上报成功后再移除（at-least-once 语义）
      final batch = List<Map<String, dynamic>>.from(
        _eventQueue.take(batchSize),
      );

      try {
        // 安全检查：确保批次不为空
        if (batch.isEmpty) {
          Logger.analyticsSdk('批次为空，跳过上报');
          return;
        }

        // 在后台线程执行 JSON 编码，避免阻塞主线程
        final batchJson = await _encodeBatchAsync(batch);

        // 检查编码结果
        if (batchJson == '[]' || batchJson.isEmpty) {
          Logger.analyticsSdk('JSON 编码失败或结果为空');
          _scheduleRetry();
          return;
        }

        // 检查 JSON 大小，避免请求过大
        final jsonSize = utf8.encode(batchJson).length;
        if (jsonSize > SdkConfig.maxJsonSize) {
          Logger.analyticsSdk(
              '警告：JSON 大小过大 (${(jsonSize / 1024 / 1024).toStringAsFixed(2)}MB)，缩小批次重试');
          if (batchSize > 1) {
            // 折半批次后重试，避免同一批次反复触发 JSON 过大
            _overrideBatchSize = (batchSize / 2).ceil();
            _isUploading = false;
            Future.microtask(() {
              uploadBatch().catchError((e) {
                Logger.analyticsSdk('缩小批次后重试上报 Future 异常: $e');
              });
            });
          } else {
            // 单条事件过大，移除该事件避免阻塞队列
            if (_eventQueue.isNotEmpty) {
              _eventQueue.removeFirst();
            }
            Logger.analyticsSdk(
                '警告：单条事件过大 (${(jsonSize / 1024).toStringAsFixed(2)}KB)，已丢弃');
          }
          return;
        } else {
          Logger.analyticsSdk(
              '上报中：${batch.length} 条事件，JSON大小: ${(jsonSize / 1024).toStringAsFixed(2)}KB');
        }

        try {
          // 解析 URL，添加错误处理
          Uri uri;
          try {
            uri = Uri.parse(_reportUrl!);
            if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
              throw const FormatException('无效的 URL scheme');
            }
          } catch (e) {
            Logger.analyticsSdk('URL 解析失败: $_reportUrl, 错误: $e');
            _scheduleRetry();
            return;
          }

          // 复用 http.Client，利用连接池
          final response = await _client
              .post(
                uri,
                headers: {
                  'Content-Type': 'application/json; charset=utf-8',
                },
                body: batchJson,
              )
              .timeout(SdkConfig.connectionTimeout +
                  SdkConfig.writeTimeout +
                  SdkConfig.readTimeout);
          final statusCode = response.statusCode;
          if (statusCode == 200) {
            // 上报成功，按 event_id 从队列中移除已上报的事件
            final reportedIds =
                batch.map((e) => e['event_id']).whereType<String>().toSet();
            if (reportedIds.isNotEmpty) {
              _eventQueue
                  .removeWhere((e) => reportedIds.contains(e['event_id']));
            } else {
              // event_id 全缺失时回退到按数量移除（兜底）
              for (int i = 0; i < batchSize && _eventQueue.isNotEmpty; i++) {
                _eventQueue.removeFirst();
              }
            }
            lastUploadSuccess = true;
            lastUploadError = null;
            lastUploadTime = DateTime.now();
            _overrideBatchSize = null; // 上报成功，恢复正常批次大小
            _resetBackoff();
            await _persistence.removeEvents(batch);
            Logger.analyticsSdk(
                '上报成功: ${batch.length} 条事件，状态码: $statusCode，已从缓存中移除对应事件');
          } else {
            lastUploadSuccess = false;
            lastUploadError = 'HTTP $statusCode';
            lastUploadTime = DateTime.now();
            _scheduleRetry();
            if (statusCode >= 400 && statusCode < 500) {
              Logger.analyticsSdk('上报失败: 客户端错误，状态码: $statusCode（可能是数据格式问题）');
            } else if (statusCode >= 500) {
              Logger.analyticsSdk('上报失败: 服务器错误，状态码: $statusCode（服务器问题，将重试）');
            } else {
              Logger.analyticsSdk('上报失败: 未知状态码 $statusCode');
            }
          }
        } catch (e) {
          lastUploadSuccess = false;
          lastUploadError = e is TimeoutException
              ? '请求超时'
              : e is http.ClientException
                  ? '网络连接失败'
                  : e.toString().length > 30
                      ? '${e.toString().substring(0, 30)}...'
                      : e.toString();
          lastUploadTime = DateTime.now();
          _scheduleRetry();
          if (e is TimeoutException) {
            Logger.analyticsSdk('上报异常: 请求超时 - ${e.message ?? "未知超时"}',
                level: LogLevel.error);
          } else if (e is http.ClientException) {
            Logger.analyticsSdk('上报异常: 网络连接失败 - ${e.message}',
                level: LogLevel.error);
          } else {
            final errorMessage = e.toString();
            Logger.analyticsSdk('上报异常: $errorMessage', level: LogLevel.error);
          }
        }
      } finally {
        _isUploading = false;
      }
    });
  }

  /// JSON 编码的静态方法，用于 compute isolate
  static String _encodeBatchJson(List<Map<String, dynamic>> batch) {
    return jsonEncode(batch);
  }

  /// 在后台 isolate 中异步执行 JSON 编码，避免阻塞主线程
  Future<String> _encodeBatchAsync(List<Map<String, dynamic>> batch) async {
    try {
      if (batch.isEmpty) {
        return '[]';
      }
      if (batch.length <= SdkConfig.isolateEncodingThreshold) {
        return jsonEncode(batch);
      }
      try {
        return await compute(_encodeBatchJson, batch);
      } catch (e) {
        Logger.analyticsSdk('compute 失败，回退到主线程编码: $e');
        return jsonEncode(batch);
      }
    } catch (e) {
      Logger.analyticsSdk('JSON 编码失败: $e');
      return '[]';
    }
  }

  /// 安排指数退避重试（事件仍在队列中，无需重新入队）
  void _scheduleRetry() {
    _backoffLevel = (_backoffLevel + 1).clamp(0, SdkConfig.maxBackoffLevel);
    _retryTimer?.cancel();
    final delay = _nextDelay();
    _retryTimer = Timer(delay, () {
      try {
        Logger.analyticsSdk('指数退避重试 (延迟 ${delay.inSeconds}s)');
        uploadBatch();
      } catch (e) {
        Logger.analyticsSdk('重试上报异常: $e');
      }
    });
  }

  /// 计算下次延迟时间（指数退避 + 上限）
  Duration _nextDelay() {
    final exponential = SdkConfig.baseRetryDelay * pow(2, _backoffLevel);
    return exponential > SdkConfig.maxRetryDelay
        ? SdkConfig.maxRetryDelay
        : exponential;
  }

  /// 上报成功时重置退避状态
  void _resetBackoff() {
    if (_backoffLevel > 0) {
      _backoffLevel = 0;
      _retryTimer?.cancel();
      _retryTimer = null;
      Logger.analyticsSdk('上报成功，退避机制已重置');
    }
  }

  Future<void> initPersistence() async {
    try {
      await _persistence.init();
    } catch (e) {
      Logger.analyticsSdk('持久化初始化失败: $e');
    }
  }

  Future<void> loadCachedEvents() async {
    try {
      final recovered = await _persistence.loadEvents(
        queue: _eventQueue,
        maxQueueSize: SdkConfig.maxQueueSize,
        maxCacheLines: SdkConfig.maxCacheLines,
        isEventTypeEnabled: EventTypeConfigManager.instance.isEventTypeEnabled,
      );

      if (recovered.isNotEmpty) {
        final availableSpace = SdkConfig.maxQueueSize - _eventQueue.length;
        if (availableSpace > 0) {
          final eventsToRecover = recovered.length > availableSpace
              ? recovered.sublist(0, availableSpace)
              : recovered;
          _eventQueue.addAll(eventsToRecover);
          Logger.analyticsSdk('从缓存恢复 ${eventsToRecover.length} 条事件');
        } else {
          Logger.analyticsSdk('警告：队列已满，无法恢复缓存事件');
        }
      }

      _flushIfNeeded();
    } catch (e) {
      Logger.analyticsSdk('缓存加载失败: $e');
    }
  }

  Future<void> clearCache() async {
    await _persistence.clearCache();
  }

  /// 释放资源（定时器、HttpClient、缓存 buffer 等）
  void dispose() {
    try {
      stopAutoUploadTimer();
      _retryTimer?.cancel();
      _retryTimer = null;
      _isUploading = false;
      _persistence.flushBuffer();
      _httpClient?.close();
      _httpClient = null;
    } catch (e) {
      Logger.analyticsSdk('EventProcessor.dispose 异常: $e');
    }
  }

  /// 测试专用入口：触发 tombstone 写入以供单元测试验证缓存移除行为
  @visibleForTesting
  Future<void> removeEventsFromCacheForTest(
          List<Map<String, dynamic>> events) =>
      _persistence.removeEvents(events);

  /// 异步释放资源（先 await 缓存刷写，再释放其他资源）
  ///
  /// 推荐在 SDK dispose 时使用此方法替代 [dispose]，确保缓存 buffer 写入磁盘。
  Future<void> disposeAsync() async {
    try {
      stopAutoUploadTimer();
      _retryTimer?.cancel();
      _retryTimer = null;
      _isUploading = false;
      await _persistence.flushBufferAsync();
      _httpClient?.close();
      _httpClient = null;
    } catch (e) {
      Logger.analyticsSdk('EventProcessor.disposeAsync 异常: $e');
    }
  }
}
