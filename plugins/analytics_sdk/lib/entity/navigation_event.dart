import 'package:analytics_sdk/const/event_type.dart';
import 'package:analytics_sdk/entity/analytics_utils.dart';

/// 导航路径行为 （部分自动）
class NavigationEvent {
  final String event = EventType.navigation.event;
  late final String eventId;

  /// 导航标识：navigation_home(首页), navigation_discover(发现), navigation_user(我的)等
  final String navigationKey;

  /// 导航标识名称：首页导航, 发现导航, 我的导航
  final String navigationName;

  late final Map<String, dynamic> _commonFields;

  NavigationEvent({
    required this.navigationKey,
    required this.navigationName,
  }) {
    _commonFields = AnalyticsUtils.generateCommonFields(event);

    eventId = AnalyticsUtils.generateEventIdFromCommonFields(_commonFields, [
      navigationKey,
      navigationName,
    ]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {
      'navigation_key': navigationKey,
      'navigation_name': navigationName,
    };
    return {
      ..._commonFields,
      'event_id': eventId,
      "payload": payload
    };
  }

  factory NavigationEvent.fromJson(Map<String, dynamic> json) {
    return NavigationEvent(
      navigationKey: json['navigation_key'] as String,
      navigationName: json['navigation_name'] as String,
    );
  }
}
