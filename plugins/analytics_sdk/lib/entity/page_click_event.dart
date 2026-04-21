import 'package:analytics_sdk/manager/page_name_manager.dart';
import 'package:analytics_sdk/const/event_type.dart';
import 'package:analytics_sdk/entity/analytics_utils.dart';

/// 应用页面点击日志 （自动）
class PageClickEvent {
  final String event = EventType.pageClick.event;
  late final String eventId;

  final String pageKey;

  /// 页面名称：首页, 我的, 视频页
  final String pageName;

  /// 点击位置坐标x轴
  final int clickPageX;

  /// 点击位置坐标y轴
  final int clickPageY;

  /// 点击位置横坐标百分比(0-100)
  final int clickXPercent;

  /// 点击位置纵坐标百分比(0-100)
  final int clickYPercent;

  /// 屏幕宽度（像素）
  final int screenWidth;

  /// 屏幕高度（像素）
  final int screenHeight;

  /// 推荐引擎的trace_id，有多个推荐列表时用英文逗号分隔，未接推荐引擎传空字符串
  final String recommendTraceId;

  late final Map<String, dynamic> _commonFields;

  PageClickEvent({
    required String pageKey,
    required this.pageName,
    required this.clickPageX,
    required this.clickPageY,
    required this.clickXPercent,
    required this.clickYPercent,
    required this.screenWidth,
    required this.screenHeight,
    this.recommendTraceId = '',
  }) : pageKey = PageNameMapper.normalizeKey(pageKey) {
    _commonFields = AnalyticsUtils.generateCommonFields(event);

    eventId = AnalyticsUtils.generateEventIdFromCommonFields(_commonFields, [
      pageKey,
      pageName,
      clickPageX.toString(),
      clickPageY.toString(),
      clickXPercent.toString(),
      clickYPercent.toString(),
      screenWidth.toString(),
      screenHeight.toString(),
      recommendTraceId,
    ]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {
      'page_key': pageKey,
      'page_name': pageName,
      'click_page_x': clickPageX,
      'click_page_y': clickPageY,
      'click_x_percent': clickXPercent,
      'click_y_percent': clickYPercent,
      'screen_width': screenWidth,
      'screen_height': screenHeight,
      'recommend_trace_id': recommendTraceId,
    };
    return {
      ..._commonFields,
      'event_id': eventId,
      "payload": payload
    };
  }

  factory PageClickEvent.fromJson(Map<String, dynamic> json) {
    return PageClickEvent(
      pageKey: json['page_key'] as String,
      pageName: json['page_name'] as String,
      clickPageX: json['click_page_x'] as int,
      clickPageY: json['click_page_y'] as int,
      clickXPercent: json['click_x_percent'] as int,
      clickYPercent: json['click_y_percent'] as int,
      screenWidth: json['screen_width'] as int,
      screenHeight: json['screen_height'] as int,
      recommendTraceId: json['recommend_trace_id'] as String? ?? '',
    );
  }
}
