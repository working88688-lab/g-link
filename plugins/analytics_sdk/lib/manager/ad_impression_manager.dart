import 'package:analytics_sdk/config/sdk_config.dart';
import 'package:analytics_sdk/utils/logger.dart';

/// 广告展示去重管理器
///
/// 以页面为粒度做去重：同一页面访问内不重复上报同一广告，
/// 页面退出后去重状态随之清除，下次进入同一页面广告可重新上报。
/// 新 session 时调用 [clear] 清除所有页面记录。
class AdImpressionManager {
  static final AdImpressionManager instance = AdImpressionManager._internal();

  factory AdImpressionManager() => instance;

  AdImpressionManager._internal();

  /// 页面级广告去重表：pageKey → 已上报 adId 集合
  final Map<String, Set<String>> _reportedAdIdsByPage = {};

  /// 当前已存储的广告ID总数（跨所有页面）
  int get reportedCount =>
      _reportedAdIdsByPage.values.fold(0, (sum, s) => sum + s.length);

  /// 批量检查多个广告ID，返回在指定页面内尚未上报的列表（不修改状态）
  List<String> getUnreportedAdIds(String adIds, {required String pageKey}) {
    if (adIds.isEmpty) return [];

    final adIdList = adIds
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    if (adIdList.isEmpty) return [];

    final pageSet = _reportedAdIdsByPage[pageKey];
    if (pageSet == null || pageSet.isEmpty) return adIdList;

    return adIdList.where((id) => !pageSet.contains(id)).toList();
  }

  /// 在指定页面内批量标记广告ID为已上报
  void markAsReportedBatch(String adIds, {required String pageKey}) {
    if (adIds.isEmpty) return;

    final adIdList = adIds
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty);

    final pageSet = _reportedAdIdsByPage.putIfAbsent(pageKey, () => {});
    for (final id in adIdList) {
      if (reportedCount >= SdkConfig.maxAdImpressionCapacity) {
        Logger.adImpressionManager(
            '广告去重表已达上限（${SdkConfig.maxAdImpressionCapacity}），停止写入，跳过 id: $id',
            level: LogLevel.warn);
        break;
      }
      pageSet.add(id);
    }
  }

  /// 清除指定页面的广告去重记录（页面退出时调用，下次进入可重新上报）
  void clearPage(String pageKey) {
    if (_reportedAdIdsByPage.remove(pageKey) != null) {
      Logger.adImpressionManager('页面 "$pageKey" 广告去重记录已清除');
    }
  }

  /// 清除所有页面的广告去重记录（新 session 开始时调用）
  void clear() {
    _reportedAdIdsByPage.clear();
  }

  // ── 以下方法供测试使用 ──────────────────────────────

  /// 检查广告ID在指定页面内是否已上报（不修改状态）
  bool isReported(String adId, {required String pageKey}) {
    return _reportedAdIdsByPage[pageKey]?.contains(adId.trim()) ?? false;
  }

  /// [isReported] 的别名，用于断言
  bool contains(String adId, {required String pageKey}) =>
      isReported(adId, pageKey: pageKey);
}
