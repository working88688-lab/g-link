import 'package:analytics_sdk/manager/ad_impression_manager.dart';
import 'package:analytics_sdk/manager/session_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// SessionManager 回归测试
///
/// 覆盖 Bug 修复：
/// - _shouldCreateNewSession 是查询方法，不应在非超时分支清空 _backgroundTime。
///   修复前：getSessionId() 在后台期间被调用时（如推送通知触发 track()），
///           非超时分支的 `_backgroundTime = null` 会提前清空后台时间，
///           导致后续 onAppForeground() 无法判断后台时长，旧会话被错误保留。
///   修复点：session_manager.dart _shouldCreateNewSession 中只在超时分支清空。
void main() {
  const page = 'test_page';

  setUp(() {
    SessionManager.instance.reset();
    AdImpressionManager.instance.clear();
  });

  tearDown(() {
    SessionManager.instance.reset();
    AdImpressionManager.instance.clear();
  });

  group('_shouldCreateNewSession 不应提前清空 _backgroundTime（Bug 2 核心）', () {
    test('onAppBackground 后 backgroundTime 非 null', () {
      SessionManager.instance.getSessionId(); // 确保已初始化
      SessionManager.instance.onAppBackground();
      expect(
        SessionManager.instance.backgroundTimeForTest,
        isNotNull,
        reason: 'onAppBackground() 应设置 _backgroundTime',
      );
    });

    test('后台期间调用 getSessionId() 不应清空 backgroundTime', () {
      SessionManager.instance.getSessionId(); // 初始化会话
      SessionManager.instance.onAppBackground();

      // 模拟后台期间有推送通知触发了 track() → getSessionId()
      // 后台时间极短（< 30 min），不应触发新会话，但也不应清空 _backgroundTime
      SessionManager.instance.getSessionId();

      expect(
        SessionManager.instance.backgroundTimeForTest,
        isNotNull,
        reason: '后台期间调用 getSessionId() 不应清空 _backgroundTime，'
            '否则后续 onAppForeground() 无法正确判断后台时长',
      );
    });

    test('onAppForeground 后 backgroundTime 被正确清空', () {
      SessionManager.instance.getSessionId();
      SessionManager.instance.onAppBackground();
      SessionManager.instance.onAppForeground();
      expect(
        SessionManager.instance.backgroundTimeForTest,
        isNull,
        reason: 'onAppForeground() 执行完毕后应清空 _backgroundTime',
      );
    });

    test('未调用 onAppBackground 时，getSessionId 不影响 backgroundTime（始终为 null）', () {
      SessionManager.instance.getSessionId();
      expect(SessionManager.instance.backgroundTimeForTest, isNull);
      SessionManager.instance.getSessionId();
      expect(SessionManager.instance.backgroundTimeForTest, isNull);
    });
  });

  group('新 session 时清空广告去重集（session 级去重）', () {
    test('新 session 创建后 AdImpressionManager 被清空', () {
      SessionManager.instance.getSessionId();
      AdImpressionManager.instance.markAsReportedBatch('ad1,ad2', pageKey: page);

      // 确认已标记
      expect(AdImpressionManager.instance.getUnreportedAdIds('ad1,ad2', pageKey: page), isEmpty);

      // 重置触发新 session
      SessionManager.instance.reset();
      SessionManager.instance.getSessionId();

      expect(
        AdImpressionManager.instance.getUnreportedAdIds('ad1,ad2', pageKey: page),
        equals(['ad1', 'ad2']),
        reason: '新 session 后同一 adId 应视为未上报',
      );
    });

    test('同一 session 内标记后不再返回未上报', () {
      SessionManager.instance.getSessionId();
      AdImpressionManager.instance.markAsReportedBatch('ad1', pageKey: page);

      // 没有新 session，ad1 应仍被去重
      expect(
        AdImpressionManager.instance.getUnreportedAdIds('ad1', pageKey: page),
        isEmpty,
        reason: '同 session 内 ad1 不应重复上报',
      );
    });

    test('连续建立多个 session，每次都清空去重集', () {
      const ids = 'ad1,ad2,ad3';

      // Session 1
      SessionManager.instance.getSessionId();
      AdImpressionManager.instance.markAsReportedBatch(ids, pageKey: page);
      expect(AdImpressionManager.instance.getUnreportedAdIds(ids, pageKey: page), isEmpty);

      // Session 2
      SessionManager.instance.reset();
      SessionManager.instance.getSessionId();
      expect(
        AdImpressionManager.instance.getUnreportedAdIds(ids, pageKey: page),
        equals(['ad1', 'ad2', 'ad3']),
        reason: 'Session 2 开始时去重集应已清空',
      );

      // Session 2 内再次标记
      AdImpressionManager.instance.markAsReportedBatch(ids, pageKey: page);
      expect(AdImpressionManager.instance.getUnreportedAdIds(ids, pageKey: page), isEmpty);

      // Session 3
      SessionManager.instance.reset();
      SessionManager.instance.getSessionId();
      expect(
        AdImpressionManager.instance.getUnreportedAdIds(ids, pageKey: page),
        equals(['ad1', 'ad2', 'ad3']),
        reason: 'Session 3 开始时去重集应再次清空',
      );
    });

    test('端到端：上报 → 同 session 去重 → 新 session → 再次可报', () {
      const adId = 'banner_001';

      // Step 1: 首次出现 → 未上报
      SessionManager.instance.getSessionId();
      expect(AdImpressionManager.instance.getUnreportedAdIds(adId, pageKey: page), [adId]);
      AdImpressionManager.instance.markAsReportedBatch(adId, pageKey: page);

      // Step 2: 同 session 内再次出现 → 去重
      expect(
        AdImpressionManager.instance.getUnreportedAdIds(adId, pageKey: page),
        isEmpty,
        reason: '同 session 内不重复上报',
      );

      // Step 3: 新 session
      SessionManager.instance.reset();
      SessionManager.instance.getSessionId();

      // Step 4: 新 session 内首次出现 → 可上报
      expect(
        AdImpressionManager.instance.getUnreportedAdIds(adId, pageKey: page),
        equals([adId]),
        reason: '新 session 内首次出现，应可上报',
      );

      // Step 5: 新 session 内标记后 → 再次去重
      AdImpressionManager.instance.markAsReportedBatch(adId, pageKey: page);
      expect(
        AdImpressionManager.instance.getUnreportedAdIds(adId, pageKey: page),
        isEmpty,
        reason: '新 session 内已标记，不重复上报',
      );
    });
  });

  group('会话基础行为', () {
    test('未初始化时 getSessionId 返回非空 ID', () {
      final id = SessionManager.instance.getSessionId();
      expect(id, isNotEmpty);
    });

    test('连续调用 getSessionId 返回相同 ID', () {
      final id1 = SessionManager.instance.getSessionId();
      final id2 = SessionManager.instance.getSessionId();
      expect(id1, equals(id2));
    });

    test('reset 后 getSessionId 创建新 ID', () {
      final id1 = SessionManager.instance.getSessionId();
      SessionManager.instance.reset();
      final id2 = SessionManager.instance.getSessionId();
      expect(id1, isNot(equals(id2)));
    });
  });
}
