import 'package:analytics_sdk/const/event_type.dart';
import 'package:analytics_sdk/entity/analytics_utils.dart';
import 'package:analytics_sdk/manager/page_name_manager.dart';

/// 应用页面展示日志（自动）
class AppPageViewEvent {
  final String event = EventType.appPageView.event;
  late final String eventId;

  final String userType;

  /// 页面标识：home(首页), video_detail(视频详情), user_center(个人中心), discover(发现页)等
  final String pageKey;

  /// 页面名称：首页, 视频详情页, 个人中心, 发现页
  final String pageName;

  /// 来路页面标识：home(首页), detail(详情页), playback(播放页)
  final String referrerPageKey;

  /// 来路页面名称：首页, 详情页, 播放页
  final String referrerPageName;

  /// 当前页面标识：home(首页), detail(详情页), playback(播放页)
  final String currentPageKey;

  /// 当前页面名称：首页, 详情页, 播放页
  final String currentPageName;

  /// 页面加载耗时（毫秒）
  final int pageLoadTime;

  /// 推荐引擎的trace_id，有多个推荐列表时用英文逗号分隔，未接推荐引擎传空字符串
  final String recommendTraceId;

  late final Map<String, dynamic> _commonFields;

  AppPageViewEvent({
    required this.userType,
    required String pageKey,
    required this.pageName,
    required String referrerPageKey,
    required this.referrerPageName,
    required String currentPageKey,
    required this.currentPageName,
    required this.pageLoadTime,
    this.recommendTraceId = '',
  })  : pageKey = PageNameMapper.normalizeKey(pageKey),
        referrerPageKey = PageNameMapper.normalizeKey(referrerPageKey),
        currentPageKey = PageNameMapper.normalizeKey(currentPageKey) {
    _commonFields = AnalyticsUtils.generateCommonFields(event);

    eventId = AnalyticsUtils.generateEventIdFromCommonFields(_commonFields, [
      userType,
      pageKey,
      pageName,
      referrerPageKey,
      referrerPageName,
      currentPageKey,
      currentPageName,
      pageLoadTime.toString(),
      recommendTraceId,
    ]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {
      'user_type': userType,
      'page_key': pageKey,
      'page_name': pageName,
      'referrer_page_key': referrerPageKey,
      'referrer_page_name': referrerPageName,
      'current_page_key': currentPageKey,
      'current_page_name': currentPageName,
      'page_load_time': pageLoadTime,
      'recommend_trace_id': recommendTraceId,
    };
    return {
      ..._commonFields,
      'event_id': eventId,
      "payload": payload
    };
  }

  factory AppPageViewEvent.fromJson(Map<String, dynamic> json) {
    return AppPageViewEvent(
      userType: json['user_type'] as String,
      pageKey: json['page_key'] as String,
      pageName: json['page_name'] as String,
      referrerPageKey: json['referrer_page_key'] as String,
      referrerPageName: json['referrer_page_name'] as String,
      currentPageKey: json['current_page_key'] as String,
      currentPageName: json['current_page_name'] as String,
      pageLoadTime: json['page_load_time'] as int,
      recommendTraceId: json['recommend_trace_id'] as String? ?? '',
    );
  }
}
