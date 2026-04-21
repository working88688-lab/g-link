import 'package:analytics_sdk/manager/ad_impression_manager.dart';
import 'package:analytics_sdk/manager/session_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// AdImpressionManager 去重逻辑回归测试
///
/// 覆盖 Bug 修复：
/// - _getUnreportedAdIds 异常时（返回 null）应降级为"继续上报（不去重）"，
///   而非被当作"全部已上报"而丢弃事件。
///   修复点：analytics_sdk.dart track() 中的 null/empty 判断分离。
void main() {
  const page = 'test_page';

  setUp(() {
    AdImpressionManager.instance.clear();
    SessionManager.instance.reset();
  });

  tearDown(() {
    AdImpressionManager.instance.clear();
    SessionManager.instance.reset();
  });

  group('getUnreportedAdIds', () {
    test('所有 adId 未上报时，返回完整列表', () {
      final result =
          AdImpressionManager.instance.getUnreportedAdIds('ad1,ad2,ad3', pageKey: page);
      expect(result, ['ad1', 'ad2', 'ad3']);
    });

    test('所有 adId 已上报时，返回空列表', () {
      AdImpressionManager.instance.markAsReportedBatch('ad1,ad2,ad3', pageKey: page);
      final result =
          AdImpressionManager.instance.getUnreportedAdIds('ad1,ad2,ad3', pageKey: page);
      expect(result, isEmpty);
    });

    test('部分 adId 已上报时，只返回未上报的', () {
      AdImpressionManager.instance.markAsReportedBatch('ad1,ad3', pageKey: page);
      final result =
          AdImpressionManager.instance.getUnreportedAdIds('ad1,ad2,ad3', pageKey: page);
      expect(result, ['ad2']);
    });

    test('空字符串 adId 返回空列表', () {
      final result = AdImpressionManager.instance.getUnreportedAdIds('', pageKey: page);
      expect(result, isEmpty);
    });

    test('含空白项的 adId 被 trim 后正确处理', () {
      AdImpressionManager.instance.markAsReportedBatch('ad1', pageKey: page);
      final result =
          AdImpressionManager.instance.getUnreportedAdIds(' ad1 , ad2 ', pageKey: page);
      expect(result, ['ad2']);
    });
  });

  group('页面级去重：不同页面互不干扰', () {
    test('同一 adId 在不同页面各自独立去重', () {
      AdImpressionManager.instance.markAsReportedBatch('ad1', pageKey: 'page_a');
      // page_a 已上报
      expect(
        AdImpressionManager.instance.getUnreportedAdIds('ad1', pageKey: 'page_a'),
        isEmpty,
      );
      // page_b 未上报
      expect(
        AdImpressionManager.instance.getUnreportedAdIds('ad1', pageKey: 'page_b'),
        equals(['ad1']),
      );
    });

    test('clearPage 只清除指定页面的去重记录', () {
      AdImpressionManager.instance.markAsReportedBatch('ad1', pageKey: 'page_a');
      AdImpressionManager.instance.markAsReportedBatch('ad1', pageKey: 'page_b');

      AdImpressionManager.instance.clearPage('page_a');

      // page_a 已清除，可重新上报
      expect(
        AdImpressionManager.instance.getUnreportedAdIds('ad1', pageKey: 'page_a'),
        equals(['ad1']),
      );
      // page_b 不受影响，仍然已上报
      expect(
        AdImpressionManager.instance.getUnreportedAdIds('ad1', pageKey: 'page_b'),
        isEmpty,
      );
    });

    test('离开页面再返回后同一广告可重新上报', () {
      // 第一次进入 list_page，上报广告
      AdImpressionManager.instance.markAsReportedBatch('ad1,ad2,ad3', pageKey: 'list_page');
      expect(
        AdImpressionManager.instance.getUnreportedAdIds('ad1,ad2,ad3', pageKey: 'list_page'),
        isEmpty,
        reason: '同一次页面访问内不重复上报',
      );

      // 离开 list_page（模拟页面退出清除去重）
      AdImpressionManager.instance.clearPage('list_page');

      // 再次进入 list_page，广告可重新上报
      expect(
        AdImpressionManager.instance.getUnreportedAdIds('ad1,ad2,ad3', pageKey: 'list_page'),
        equals(['ad1', 'ad2', 'ad3']),
        reason: '页面退出后重新进入，广告可重新上报',
      );
    });
  });

  group('session 级去重：新 session 后同一 adId 可重新上报', () {
    test('标记后 clear() 使 adId 重新出现在未上报列表', () {
      AdImpressionManager.instance.markAsReportedBatch('adX', pageKey: page);
      expect(AdImpressionManager.instance.getUnreportedAdIds('adX', pageKey: page), isEmpty);

      // SessionManager._createNewSession() 内部调用 AdImpressionManager.instance.clear()
      SessionManager.instance.reset();
      SessionManager.instance.getSessionId();

      expect(
        AdImpressionManager.instance.getUnreportedAdIds('adX', pageKey: page),
        equals(['adX']),
        reason: '新 session 后 adX 应视为未上报',
      );
    });

    test('多 adId：新 session 后全部解除去重', () {
      AdImpressionManager.instance.markAsReportedBatch('ad1,ad2,ad3', pageKey: page);
      expect(
          AdImpressionManager.instance.getUnreportedAdIds('ad1,ad2,ad3', pageKey: page), isEmpty);

      SessionManager.instance.reset();
      SessionManager.instance.getSessionId();

      expect(
        AdImpressionManager.instance.getUnreportedAdIds('ad1,ad2,ad3', pageKey: page),
        equals(['ad1', 'ad2', 'ad3']),
      );
    });

    test('新 session 后重新标记，同 session 内再次去重', () {
      // Session 1：标记 ad1
      SessionManager.instance.getSessionId();
      AdImpressionManager.instance.markAsReportedBatch('ad1', pageKey: page);

      // Session 2：ad1 解除去重，重新标记
      SessionManager.instance.reset();
      SessionManager.instance.getSessionId();
      expect(AdImpressionManager.instance.getUnreportedAdIds('ad1', pageKey: page), equals(['ad1']));
      AdImpressionManager.instance.markAsReportedBatch('ad1', pageKey: page);

      // Session 2 内 ad1 再次被去重
      expect(
        AdImpressionManager.instance.getUnreportedAdIds('ad1', pageKey: page),
        isEmpty,
        reason: '同 session 2 内 ad1 已标记，不重复',
      );
    });
  });

  group('null 与 empty 语义区分（Bug 1 核心）', () {
    /// 在 analytics_sdk.dart track() 里：
    ///   null  = _getUnreportedAdIds 发生异常 → 降级：继续上报（不去重）
    ///   empty = 所有 adId 已上报 → 跳过整个事件
    ///
    /// 修复前：null || empty 统一 return（事件丢失）
    /// 修复后：只有 empty 才 return，null 降级继续上报
    ///
    /// 此处通过 AdImpressionManager.getUnreportedAdIds 验证：
    /// "全部已上报"场景返回 []（非 null），框架需区分处理。
    test('全部已上报时 getUnreportedAdIds 返回 [] 而非 null', () {
      AdImpressionManager.instance.markAsReportedBatch('ad1', pageKey: page);
      final result = AdImpressionManager.instance.getUnreportedAdIds('ad1', pageKey: page);
      // 必须是 empty list，不能是 null
      // analytics_sdk.dart 只应在结果为 empty（非 null）时跳过事件
      expect(result, isNotNull);
      expect(result, isEmpty);
    });
  });
}
