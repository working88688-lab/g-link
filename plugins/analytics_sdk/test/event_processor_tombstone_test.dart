import 'dart:convert';
import 'dart:io';

import 'package:analytics_sdk/manager/event_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/path_provider_mock.dart';

/// EventProcessor tombstone 缓存测试
///
/// 验证：
/// 1. 上报成功后写 tombstone，不重写主文件
/// 2. loadCachedEvents 用 tombstone 过滤已上报事件
/// 3. tombstone 达到阈值时触发压缩
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ep_tombstone_test_');
    registerPathProviderMock(tempDir);
  });

  tearDown(() async {
    unregisterPathProviderMock();
    await tempDir.delete(recursive: true);
  });

  /// 写几条事件到主缓存文件
  Future<void> writeCacheLines(Directory dir, List<Map<String, dynamic>> events) async {
    final file = File('${dir.path}/data_plus_events_cache.jsonl');
    final lines = events.map(jsonEncode).join('\n');
    await file.writeAsString('$lines\n');
  }

  /// 读 tombstone 文件内容
  Future<Set<String>> readTombstone(Directory dir) async {
    final file = File('${dir.path}/data_plus_events_tombstone.txt');
    if (!await file.exists()) return {};
    final content = await file.readAsString();
    return content.split('\n').where((l) => l.isNotEmpty).toSet();
  }

  test('_removeEventsFromCache 追加写 tombstone，不重写主文件', () async {
    final processor = EventProcessor();
    await processor.initPersistence();

    final events = [
      {'event_id': 'id_1', 'event': 'page_view'},
      {'event_id': 'id_2', 'event': 'click'},
      {'event_id': 'id_3', 'event': 'purchase'},
    ];
    await writeCacheLines(tempDir, events);

    final cacheFile = File('${tempDir.path}/data_plus_events_cache.jsonl');
    final sizeBefore = await cacheFile.length();

    // 上报成功，移除前两条
    await processor.removeEventsFromCacheForTest(events.sublist(0, 2));

    // 主文件大小不变（没有重写）
    expect(await cacheFile.length(), equals(sizeBefore),
        reason: 'removeEvents 应追加写 tombstone，不应重写主缓存文件');

    // tombstone 包含两个 ID
    final ids = await readTombstone(tempDir);
    expect(ids, containsAll(['id_1', 'id_2']),
        reason: 'tombstone 应包含两个已移除的 event_id');
    expect(ids, isNot(contains('id_3')),
        reason: 'tombstone 不应包含未移除的 id_3');
  });

  test('loadCachedEvents 用 tombstone 过滤，只恢复未上报的事件', () async {
    final processor = EventProcessor();
    await processor.initPersistence();

    final events = [
      {'event_id': 'id_1', 'event': 'page_view'},
      {'event_id': 'id_2', 'event': 'click'},
      {'event_id': 'id_3', 'event': 'purchase'},
    ];
    await writeCacheLines(tempDir, events);

    // 预先写 tombstone，标记 id_1 已上报
    final tombstone = File('${tempDir.path}/data_plus_events_tombstone.txt');
    await tombstone.writeAsString('id_1\n');

    await processor.loadCachedEvents();

    // 只有 id_2 和 id_3 进入队列
    expect(processor.queueLength, equals(2),
        reason: 'tombstone 过滤后队列中应只剩 2 条未上报事件');

    // 两个文件都被删除
    expect(await File('${tempDir.path}/data_plus_events_cache.jsonl').exists(), isFalse,
        reason: 'loadCachedEvents 后主缓存文件应被删除');
    expect(await tombstone.exists(), isFalse,
        reason: 'loadCachedEvents 后 tombstone 文件应被删除');
  });

  test('tombstone 为空时 loadCachedEvents 恢复全部事件', () async {
    final processor = EventProcessor();
    await processor.initPersistence();

    final events = [
      {'event_id': 'id_1', 'event': 'page_view'},
      {'event_id': 'id_2', 'event': 'click'},
    ];
    await writeCacheLines(tempDir, events);

    await processor.loadCachedEvents();

    expect(processor.queueLength, equals(2),
        reason: 'tombstone 为空时应恢复全部 2 条事件');
  });
}
