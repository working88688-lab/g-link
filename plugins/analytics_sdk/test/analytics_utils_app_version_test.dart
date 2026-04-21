import 'package:analytics_sdk/entity/analytics_utils.dart';
import 'package:analytics_sdk/utils/logger.dart';
import 'package:flutter_test/flutter_test.dart';

/// appVersion 格式校验测试。
///
/// `flutter test` 默认运行在 Debug 模式（kDebugMode=true），
/// 因此这里只能直接验证 Debug 分支行为。Release 分支的外部可观察效果
/// 与 Debug 分支最终一致：都让 `generateCommonFields()['app_version']`
/// 退回到 [AnalyticsUtils.kDefaultAppVersion]。
void main() {
  group('AnalyticsUtils appVersion 格式校验', () {
    setUp(() {
      AnalyticsUtils.reset();
    });

    tearDown(() {
      Logger.onLog = null;
      AnalyticsUtils.reset();
    });

    test('合法 x.y.z 正常写入', () {
      AnalyticsUtils.configure(appVersion: '2.5.1');
      expect(AnalyticsUtils.appVersion, equals('2.5.1'));
      expect(
        AnalyticsUtils.generateCommonFields('test')['app_version'],
        equals('2.5.1'),
      );
    });

    test('未传 appVersion：上报字段默认填 kDefaultAppVersion', () {
      AnalyticsUtils.configure(appId: 'app');
      expect(AnalyticsUtils.appVersion, isNull);
      expect(
        AnalyticsUtils.generateCommonFields('test')['app_version'],
        equals(AnalyticsUtils.kDefaultAppVersion),
      );
    });

    test('非法 appVersion：Debug 下保留原值，发出 error 日志，上报字段退回默认值', () {
      final logs = <MapEntry<String, LogLevel>>[];
      Logger.onLog = (msg, level) => logs.add(MapEntry(msg, level));

      AnalyticsUtils.configure(appVersion: 'abc');

      expect(AnalyticsUtils.appVersion, isNull,
          reason: 'Debug 下非法值不应写入 _appVersion');
      expect(
        AnalyticsUtils.generateCommonFields('test')['app_version'],
        equals(AnalyticsUtils.kDefaultAppVersion),
      );
      expect(
        logs.any((e) =>
            e.value == LogLevel.error && e.key.contains('appVersion 格式不正确')),
        isTrue,
        reason: 'Debug 下应发出 error 级日志',
      );
    });

    test('先合法后非法：Debug 下保留先前合法值不被污染', () {
      AnalyticsUtils.configure(appVersion: '3.2.1');
      AnalyticsUtils.configure(appVersion: 'not-a-version');
      expect(AnalyticsUtils.appVersion, equals('3.2.1'));
    });
  });
}
