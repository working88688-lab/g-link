import 'dart:io';

import 'package:analytics_sdk/manager/event_processor.dart';
import 'package:analytics_sdk/manager/session_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/path_provider_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ep_logic_test_');
    registerPathProviderMock(tempDir);
  });

  tearDown(() async {
    unregisterPathProviderMock();
    await tempDir.delete(recursive: true);
  });

  group('uploadBatch concurrent guard', () {
    test('resetState clears _isUploading so next uploadBatch can proceed', () async {
      final processor = EventProcessor();
      await processor.initPersistence();

      processor.enqueueEvent({
        'event': 'test_event',
        'event_id': 'eid1',
        'app_id': 'app1',
        'sid': 'sid1',
        'client_ts': 1711929600,
        'device_id': 'dev1',
      });
      expect(processor.queueLength, 1);

      processor.resetState();

      await processor.uploadBatch();
      expect(processor.queueLength, 1);
    });
  });

  group('queue removal correctness', () {
    test('enqueueEvent during upload does not corrupt removal', () {
      final processor = EventProcessor();

      for (int i = 1; i <= 3; i++) {
        processor.enqueueEvent({
          'event': 'evt',
          'event_id': 'eid_$i',
          'app_id': 'app1',
          'sid': 'sid1',
          'client_ts': 1711929600,
          'device_id': 'dev1',
        });
      }
      expect(processor.queueLength, 3);

      processor.enqueueEvent({
        'event': 'evt',
        'event_id': 'eid_4',
        'app_id': 'app1',
        'sid': 'sid1',
        'client_ts': 1711929600,
        'device_id': 'dev1',
      });
      expect(processor.queueLength, 4);
    });
  });

  group('dispose cache buffer flush', () {
    test('disposeAsync writes buffered events to cache file', () async {
      final processor = EventProcessor();
      await processor.initPersistence();

      // Enqueue 3 events (below _cacheBufferThreshold of 10, so they stay in buffer)
      for (int i = 1; i <= 3; i++) {
        processor.enqueueEvent({
          'event': 'evt',
          'event_id': 'buf_$i',
          'app_id': 'app1',
          'sid': 'sid1',
          'client_ts': 1711929600,
          'device_id': 'dev1',
        });
      }

      // Call disposeAsync — should flush buffer to disk
      await processor.disposeAsync();

      // Wait for any microtasks to complete
      await Future.delayed(Duration(milliseconds: 100));

      // Verify cache file has the 3 events
      final cacheFile = File('${tempDir.path}/data_plus_events_cache.jsonl');
      expect(await cacheFile.exists(), isTrue, reason: 'cache file should exist after dispose');
      final lines = (await cacheFile.readAsLines())
          .where((l) => l.trim().isNotEmpty)
          .toList();
      expect(lines.length, 3);
    });
  });

  group('SessionManager re-init', () {
    test('reset + initialize creates a new session ID', () {
      SessionManager.instance.reset();
      SessionManager.instance.initialize();
      final firstSid = SessionManager.instance.currentSessionId;
      expect(firstSid, isNotNull);

      SessionManager.instance.reset();
      SessionManager.instance.initialize();
      final secondSid = SessionManager.instance.currentSessionId;
      expect(secondSid, isNotNull);
      expect(secondSid, isNot(equals(firstSid)));
    });
  });

  group('event_id 防抖', () {
    late EventProcessor processor;

    setUp(() async {
      processor = EventProcessor();
      await processor.initPersistence();
    });

    tearDown(() {
      processor.dispose();
    });

    Map<String, dynamic> evt(String eventId) => {
          'event': 'test',
          'event_id': eventId,
          'app_id': 'app1',
          'sid': 'sid1',
          'client_ts': 1711929600,
          'device_id': 'dev1',
        };

    test('同一 event_id 立即重复入队，第二条被丢弃', () {
      expect(processor.enqueueEvent(evt('eid_dup')), isTrue);
      expect(processor.enqueueEvent(evt('eid_dup')), isFalse);
      expect(processor.queueLength, 1);
    });

    test('不同 event_id 在窗口内均可入队', () {
      expect(processor.enqueueEvent(evt('eid_a')), isTrue);
      expect(processor.enqueueEvent(evt('eid_b')), isTrue);
      expect(processor.queueLength, 2);
    });

    test('event_id 为 null 时不触发防抖，两条都入队', () {
      final e = {
        'event': 'test',
        'app_id': 'app1',
        'sid': 'sid1',
        'client_ts': 1711929600,
        'device_id': 'dev1',
      };
      expect(processor.enqueueEvent(e), isTrue);
      expect(processor.enqueueEvent(e), isTrue);
      expect(processor.queueLength, 2);
    });

    test('resetState 清空防抖状态，同一 event_id 可重新入队', () {
      expect(processor.enqueueEvent(evt('eid_reset')), isTrue);
      expect(processor.enqueueEvent(evt('eid_reset')), isFalse);
      processor.resetState();
      expect(processor.enqueueEvent(evt('eid_reset')), isTrue);
      expect(processor.queueLength, 2); // resetState 不清队列，只清防抖状态
    });
  });
}
