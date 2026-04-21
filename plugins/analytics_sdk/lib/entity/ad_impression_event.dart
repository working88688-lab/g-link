import 'package:analytics_sdk/manager/page_name_manager.dart';
import 'package:analytics_sdk/const/event_type.dart';
import 'package:analytics_sdk/entity/analytics_utils.dart';

/// 广告展示日志 （手动）
/// 展示上报逻辑:
/// 1. 进入 APP → TabA
/// - 20 条曝光 → 上报 20 条(批量)
/// 2. 切换到TabB
/// - 20 条曝光 → 上报 20 条
/// 3. 返回TabA → 上滑加载 10 条
/// - 新 10 条渲染出来 → 上报 10 条
/// 4. 用户再次上下滑动TabA
/// - 所有广告已曝光，无需再上报

class AdImpressionEvent {
  final String event = EventType.adImpression.event;
  late final String eventId;

  final String pageKey;

  /// 页面名称：如 首页, 详情页, 播放页
  final String pageName;

  /// 广告位标识：如 home_banner_1等 对应广告导入数据的advertiseLocationCode
  final String adSlotKey;

  /// 广告位名称：如 首页顶部Banner，第3条信息流广告
  final String adSlotName;

  /// 广告ID, 多个广告ID英文逗号分隔 对应广告导入数据的advertiseCode
  final String adId;

  /// 素材ID（可选）多个素材ID英文逗号分隔,和广告ID一一对应,没有的填充空字符串
  final String creativeId;

  /// 广告类型字符串，如 banner, feed, interstitial, reward_video 等，由广告中心定义
  final String adType;

  late final Map<String, dynamic> _commonFields;

  AdImpressionEvent({
    required String pageKey,
    required this.pageName,
    required this.adSlotKey,
    required this.adSlotName,
    required this.adId,
    this.creativeId = '',
    this.adType = '',
  }) : pageKey = PageNameMapper.normalizeKey(pageKey) {
    _commonFields = AnalyticsUtils.generateCommonFields(event);

    eventId = AnalyticsUtils.generateEventIdFromCommonFields(_commonFields, [
      pageKey,
      pageName,
      adSlotKey,
      adSlotName,
      adId,
      adType,
      creativeId,
    ]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {
      'page_key': pageKey,
      'page_name': pageName,
      'ad_slot_key': adSlotKey,
      'ad_slot_name': adSlotName,
      'ad_id': adId,
      'ad_type': adType,
      'creative_id': creativeId,
    };
    return {..._commonFields, 'event_id': eventId, "payload": payload};
  }

  factory AdImpressionEvent.fromJson(Map<String, dynamic> json) {
    return AdImpressionEvent(
      pageKey: json['page_key'] as String,
      pageName: json['page_name'] as String,
      adSlotKey: json['ad_slot_key'] as String,
      adSlotName: json['ad_slot_name'] as String,
      adId: json['ad_id'] as String,
      creativeId: json['creative_id'] as String? ?? '',
      adType: json['ad_type'] as String? ?? '',
    );
  }
}
