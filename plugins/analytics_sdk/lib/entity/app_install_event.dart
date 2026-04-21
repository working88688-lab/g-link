import 'package:analytics_sdk/const/event_type.dart';
import 'package:analytics_sdk/entity/analytics_utils.dart';

/// App 安装事件（客户端）
class AppInstallEvent {
  /// 事件类型（固定）
  final String event = EventType.appInstall.event;

  /// 去重 ID（动态计算）
  late final String eventId;

  /// 落地页点击生成唯一ID, 复制到剪切板, 打开APP后读取剪切板
  final String traceId;

  late final Map<String, dynamic> _commonFields;

  AppInstallEvent({
    required this.traceId,
  }) {
    _commonFields = AnalyticsUtils.generateCommonFields(event);

    eventId = AnalyticsUtils.generateEventIdFromCommonFields(_commonFields, [
      traceId,
    ]);
  }

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'trace_id': traceId,
    };
    return {..._commonFields, 'event_id': eventId, 'payload': payload};
  }

  factory AppInstallEvent.fromJson(Map<String, dynamic> json) {
    return AppInstallEvent(
      traceId: json['trace_id'] as String,
    );
  }
}

