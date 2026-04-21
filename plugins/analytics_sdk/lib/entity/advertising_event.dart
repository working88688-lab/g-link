import 'package:analytics_sdk/const/event_type.dart';
import 'package:analytics_sdk/entity/analytics_utils.dart';

/// APP广告行为
class AdvertisingEvent {
  final String event = EventType.advertising.event;
  late final String eventId;

  ///事件类型：click(点击), close(关闭), show(展示)
  final String eventType;

  /// 广告标识：home_popup(首页弹窗), home_banner(首页Banner), video_reward(激励视频)等
  final String advertisingKey;

  /// 广告标识名称：首页弹窗, 首页Banner, 激励视频
  final String advertisingName;

  /// 广告ID
  final String advertisingId;

  late final Map<String, dynamic> _commonFields;

  AdvertisingEvent({
    required this.eventType,
    required this.advertisingKey,
    required this.advertisingName,
    required this.advertisingId,
  }) {
    _commonFields = AnalyticsUtils.generateCommonFields(event);

    eventId = AnalyticsUtils.generateEventIdFromCommonFields(_commonFields, [
      eventType,
      advertisingKey,
      advertisingName,
      advertisingId,
    ]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {
      'event_type': eventType,
      'advertising_key': advertisingKey,
      'advertising_name': advertisingName,
      'advertising_id': advertisingId,
    };
    return {..._commonFields, 'event_id': eventId, "payload": payload};
  }

  factory AdvertisingEvent.fromJson(Map<String, dynamic> json) {
    return AdvertisingEvent(
      eventType: json['event_type'] as String,
      advertisingKey: json['advertising_key'] as String,
      advertisingName: json['advertising_name'] as String,
      advertisingId: json['advertising_id'] as String,
    );
  }
}
