import 'package:analytics_sdk/manager/page_name_manager.dart';
import 'package:analytics_sdk/const/event_type.dart';
import 'package:analytics_sdk/entity/analytics_utils.dart';
import 'package:analytics_sdk/enum/recommend_content_type_enum.dart';

/// 推荐列表内容展示事件（服务端/客户端）
class RecommendListViewEvent {
  /// 事件类型（固定）
  final String event = EventType.recommendListView.event;

  /// 去重 ID（动态计算）
  late final String eventId;

  /// 页面标识：home(首页), video_detail(视频详情), user_center(个人中心), discover(发现页)等
  final String pageKey;

  /// 页面名称：首页, 视频详情页, 个人中心, 发现页
  final String pageName;

  /// 推荐列表的类型: video(视频),novel(小说),comic(漫画)
  final RecommendContentTypeEnum recommendContentType;

  /// 推荐引擎的trace_id
  final String recommendTraceId;

  /// 推荐引擎列表的video_id(视频),novel_id(小说),comic_id(漫画), 可视窗口有多个,使用英文逗号分隔
  final String recommendId;

  /// 推荐引擎的trace_info，未接推荐引擎传空字符串
  final String recommendTraceInfo;

  /// 客户端版本，三位数字点分隔，例如：1.0.1
  final String clientVersion;

  late final Map<String, dynamic> _commonFields;

  RecommendListViewEvent({
    required String pageKey,
    required this.pageName,
    required this.recommendContentType,
    required this.recommendId,
    this.recommendTraceId = '',
    this.recommendTraceInfo = '',
    this.clientVersion = '',
  }) : pageKey = PageNameMapper.normalizeKey(pageKey) {
    _commonFields = AnalyticsUtils.generateCommonFields(event);

    eventId = AnalyticsUtils.generateEventIdFromCommonFields(_commonFields, [
      pageKey,
      pageName,
      recommendContentType.label,
      recommendTraceId,
      recommendId,
      recommendTraceInfo,
      clientVersion,
    ]);
  }

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'event': event,
      'page_key': pageKey,
      'page_name': pageName,
      'recommend_content_type': recommendContentType.label,
      'recommend_trace_id': recommendTraceId,
      'recommend_id': recommendId,
      'recommend_trace_info': recommendTraceInfo,
      'client_version': clientVersion,
    };
    return {..._commonFields, 'event_id': eventId, 'payload': payload};
  }

  factory RecommendListViewEvent.fromJson(Map<String, dynamic> json) {
    final contentTypeStr = json['recommend_content_type'] as String? ?? '';
    final contentType = RecommendContentTypeEnum(
      contentTypeStr.isNotEmpty ? contentTypeStr : RecommendContentTypeEnum.VIDEO.label,
    );
    return RecommendListViewEvent(
      pageKey: json['page_key'] as String,
      pageName: json['page_name'] as String,
      recommendContentType: contentType,
      recommendTraceId: json['recommend_trace_id'] as String,
      recommendId: json['recommend_id'] as String,
      recommendTraceInfo: json['recommend_trace_info'] as String? ?? '',
      clientVersion: json['client_version'] as String? ?? '',
    );
  }
}
