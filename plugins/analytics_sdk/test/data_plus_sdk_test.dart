// test/data_plus_sdk_test.dart
//
// SDK 公共 API 崩溃安全测试：
//   验证接入方在任意调用顺序下都不会因 SDK 产生未捕获异常。
//
// 覆盖路径：
//   1. 静态写值 API — setUid / setChannel / setUserIdAndType / logoutUser
//   2. 静态读值 API — getParams / getDeviceCommonFields
//   3. track()       — null、无 toJson 对象、已序列化 Map
//   4. flush() / dispose() — 未 init() 时的安全降级
//   5. updateUserType      — 实例方法

import 'package:analytics_sdk/analytics_sdk.dart';
import 'package:analytics_sdk/enum/user_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ──────────────────────────────────────────────────────────────
  // 1. 静态写值 API
  // ──────────────────────────────────────────────────────────────
  group('静态写值 API 崩溃安全', () {
    test('setUid 正常值不抛异常', () {
      expect(() => AnalyticsSdk.setUid('user_123'), returnsNormally,
          reason: 'setUid 传正常 uid 不应抛异常');
    });

    test('setUid 空字符串不抛异常', () {
      expect(() => AnalyticsSdk.setUid(''), returnsNormally,
          reason: 'setUid 传空字符串（登出场景）不应抛异常');
    });

    test('setChannel 正常值不抛异常', () {
      expect(() => AnalyticsSdk.setChannel('app_store'), returnsNormally,
          reason: 'setChannel 传渠道标识不应抛异常');
    });

    test('setChannel 空字符串不抛异常', () {
      expect(() => AnalyticsSdk.setChannel(''), returnsNormally,
          reason: 'setChannel 传空字符串不应抛异常');
    });

    test('setUserIdAndType 正常调用不抛异常', () {
      expect(
        () => AnalyticsSdk.setUserIdAndType(
          userId: 'uid_abc',
          userTypeEnum: UserTypeEnum.normal,
        ),
        returnsNormally,
        reason: 'setUserIdAndType 正常调用不应抛异常',
      );
    });

    test('setUserIdAndType 不传 userTypeEnum 不抛异常', () {
      expect(
        () => AnalyticsSdk.setUserIdAndType(userId: 'uid_abc'),
        returnsNormally,
        reason: 'setUserIdAndType 省略 userTypeEnum 不应抛异常',
      );
    });

    test('setUserIdAndType 空 userId 不抛异常', () {
      expect(
        () => AnalyticsSdk.setUserIdAndType(userId: ''),
        returnsNormally,
        reason: 'setUserIdAndType 传空 userId（未登录状态）不应抛异常',
      );
    });

    test('logoutUser 不抛异常', () {
      expect(() => AnalyticsSdk.logoutUser(), returnsNormally,
          reason: 'logoutUser 不应抛异常');
    });
  });

  // ──────────────────────────────────────────────────────────────
  // 2. 静态读值 API
  // ──────────────────────────────────────────────────────────────
  group('静态读值 API 崩溃安全', () {
    test('getParams 未 init 时返回 Map 不抛异常', () {
      late Map<String, dynamic> result;
      expect(() {
        result = AnalyticsSdk.getParams();
      }, returnsNormally, reason: 'getParams() 在未 init 时不应抛异常');
      expect(result, isA<Map<String, dynamic>>(),
          reason: 'getParams() 应始终返回 Map，不返回 null');
    });

    test('getParams 按 keys 过滤不抛异常', () {
      late Map<String, dynamic> result;
      expect(() {
        result = AnalyticsSdk.getParams(['app_id', 'uid', 'sdk_version']);
      }, returnsNormally, reason: 'getParams(keys) 不应抛异常');
      expect(result, isA<Map<String, dynamic>>(),
          reason: 'getParams(keys) 应返回 Map');
    });

    test('getParams 传空 keys 返回全部参数不抛异常', () {
      late Map<String, dynamic> result;
      expect(() {
        result = AnalyticsSdk.getParams([]);
      }, returnsNormally, reason: 'getParams([]) 不应抛异常');
      expect(result, isA<Map<String, dynamic>>());
    });

    test('getDeviceCommonFields 未 init 时返回 Map 不抛异常', () {
      late Map<String, String> result;
      expect(() {
        result = AnalyticsSdk.getDeviceCommonFields();
      }, returnsNormally, reason: 'getDeviceCommonFields() 不应抛异常');
      expect(result, isA<Map<String, String>>(),
          reason: 'getDeviceCommonFields() 应始终返回 Map，不返回 null');
    });
  });

  // ──────────────────────────────────────────────────────────────
  // 3. track() 崩溃安全
  // ──────────────────────────────────────────────────────────────
  group('track() 崩溃安全', () {
    test('track(null) 不抛异常', () {
      expect(() => AnalyticsSdk.instance.track(null), returnsNormally,
          reason: 'track(null) SDK 内部有 null 守卫，不应抛异常');
    });

    test('track 无 toJson 的对象不抛异常', () {
      // 普通 Object 没有 toJson()，_serializeEvent 会 catch 并返回 null
      expect(() => AnalyticsSdk.instance.track(Object()), returnsNormally,
          reason: '传入无 toJson() 的对象，序列化失败时应安全丢弃，不抛异常');
    });

    test('track 缺少必填字段的 Map 不抛异常', () {
      // 校验不通过时 EventValidator 返回 null，事件被丢弃
      expect(
        () => AnalyticsSdk.instance.track({'foo': 'bar'}),
        returnsNormally,
        reason: '校验不通过的 Map 事件应被安全丢弃，不抛异常',
      );
    });
  });

  // ──────────────────────────────────────────────────────────────
  // 4. flush() / dispose() 未 init 时的安全降级
  // ──────────────────────────────────────────────────────────────
  group('flush() / dispose() 崩溃安全', () {
    test('flush() 未 init 时不抛异常', () async {
      // _reportUrl == null → uploadBatch 立即返回
      await expectLater(
        AnalyticsSdk.instance.flush(),
        completes,
        reason: 'flush() 在未 init 状态下不应抛异常',
      );
    });

    test('dispose() 未 init 时不抛异常', () async {
      await expectLater(
        AnalyticsSdk.instance.dispose(),
        completes,
        reason: 'dispose() 在未 init 状态下不应抛异常',
      );
    });

    test('dispose() 连续调用两次不抛异常', () async {
      await expectLater(AnalyticsSdk.instance.dispose(), completes);
      await expectLater(
        AnalyticsSdk.instance.dispose(),
        completes,
        reason: '连续调用 dispose() 两次不应抛异常',
      );
    });
  });

  // ──────────────────────────────────────────────────────────────
  // 5. updateUserType（实例方法）
  // ──────────────────────────────────────────────────────────────
  group('updateUserType 崩溃安全', () {
    test('updateUserType 正常值不抛异常', () {
      expect(
        () => AnalyticsSdk.instance.updateUserType('vip'),
        returnsNormally,
        reason: 'updateUserType 传正常值不应抛异常',
      );
    });

    test('updateUserType 空字符串不抛异常', () {
      expect(
        () => AnalyticsSdk.instance.updateUserType(''),
        returnsNormally,
        reason: 'updateUserType 传空字符串不应抛异常',
      );
    });
  });
}
