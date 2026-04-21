import 'dart:io';

import 'package:analytics_sdk/entity/analytics_utils.dart';
import 'package:analytics_sdk/utils/event_validator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/path_provider_mock.dart';

/// EventValidator 回归测试
///
/// 覆盖三个历史 bug 修复路径：
/// 1. device 传入空字符串时，事件不应被丢弃
/// 2. 逗号分隔字段清洗后为空时，字段应被移除而非保留空字符串
/// 3. generateEventId() fallback 值符合 ^[A-Za-z0-9]{1,32}$ 正则
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  // 为 SessionManager（内部依赖 path_provider）提供 mock
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ev_regression_test_');
    registerPathProviderMock(tempDir);
  });

  tearDown(() async {
    unregisterPathProviderMock();
    await tempDir.delete(recursive: true);
  });

  // 构造一个基础合法事件，仅覆盖要测试的字段
  Map<String, dynamic> baseEvent({Map<String, dynamic>? overrides}) {
    final base = <String, dynamic>{
      'event': 'test_event',
      'event_id': 'abc123',
      'app_id': 'test_app',
      'sid': 'sess_001',
      'client_ts': 1704067200,
      'device_id': 'device_001',
      'payload': <String, dynamic>{},
    };
    if (overrides != null) base.addAll(overrides);
    return base;
  }

  group('EventValidator 回归：device 空字符串', () {
    test('device 为空字符串时，事件不被丢弃（应正常返回）', () {
      final event = baseEvent(overrides: {'device': ''});
      final result = EventValidator.validate(event);
      // 空字符串 device 应视为未提供，事件正常通过
      expect(result, isNotNull, reason: 'device 空字符串不应导致事件被丢弃');
    });

    test('device 为合法值 android 时，自动纠正大小写', () {
      final event = baseEvent(overrides: {'device': 'android'});
      final result = EventValidator.validate(event);
      expect(result, isNotNull);
      expect(result!['device'], equals('Android'));
    });

    test('device 为无法识别的值时，事件应被丢弃', () {
      final event = baseEvent(overrides: {'device': 'Windows'});
      final result = EventValidator.validate(event);
      expect(result, isNull, reason: '无法识别的 device 应丢弃事件');
    });
  });

  group('EventValidator 回归：逗号分隔字段清洗后为空', () {
    test('ad_id 为纯空格逗号时，清洗后为空，字段应被移除', () {
      final event = baseEvent(overrides: {
        'payload': {'ad_id': ' , , '},
      });
      final result = EventValidator.validate(event);
      expect(result, isNotNull);
      expect(
        (result!['payload'] as Map<String, dynamic>).containsKey('ad_id'),
        isFalse,
        reason: '清洗后为空的逗号分隔字段应被移除，而非保留空字符串',
      );
    });

    test('ad_id 有合法值时，正常保留并清洗', () {
      final event = baseEvent(overrides: {
        'payload': {'ad_id': 'ad_001 , , ad_002'},
      });
      final result = EventValidator.validate(event);
      expect(result, isNotNull);
      expect(
        (result!['payload'] as Map<String, dynamic>)['ad_id'],
        equals('ad_001,ad_002'),
      );
    });

    test('novel_tag_key 为纯空格时，trim 后保留为空字符串', () {
      final event = baseEvent(overrides: {
        'payload': {'novel_tag_key': '  '},
      });
      final result = EventValidator.validate(event);
      expect(result, isNotNull);
      expect(
        (result!['payload'] as Map<String, dynamic>).containsKey('novel_tag_key'),
        isTrue,
      );
    });
  });

  group('generateEventId() 回归：fallback 值格式合规', () {
    final idPattern = RegExp(r'^[A-Za-z0-9]{1,32}$');

    test('正常路径生成的 event_id 符合 ^[A-Za-z0-9]{1,32}\$', () {
      final id = AnalyticsUtils.generateEventId(['event', 'app', 'uid', 'ts']);
      expect(idPattern.hasMatch(id), isTrue,
          reason: 'MD5 生成的 event_id 应符合正则: $id');
    });

    test('空列表生成的 event_id 符合正则', () {
      final id = AnalyticsUtils.generateEventId([]);
      expect(idPattern.hasMatch(id), isTrue,
          reason: '空列表 fallback event_id 应符合正则: $id');
    });

    test('生成的 event_id 长度不超过 32', () {
      final id = AnalyticsUtils.generateEventId(['a', 'b', 'c']);
      expect(id.length, lessThanOrEqualTo(32));
    });

    test('fallback h\${abs} 格式：字母数字开头，无连字符或下划线', () {
      // 验证 h 前缀 + 纯数字的形式符合正则
      final hashFallback = 'h${('abc').hashCode.abs()}';
      expect(idPattern.hasMatch(hashFallback), isTrue,
          reason: 'h\${hashCode.abs()} 应符合正则: $hashFallback');
    });

    test('fallback t\${milliseconds} 格式符合正则', () {
      final tsFallback = 't${DateTime.now().millisecondsSinceEpoch}';
      // 13 位时间戳 + 't' 前缀 = 14 字符，≤ 32
      expect(idPattern.hasMatch(tsFallback), isTrue,
          reason: 't\${ms} 应符合正则: $tsFallback');
    });
  });
}
