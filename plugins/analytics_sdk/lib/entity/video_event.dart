import 'package:analytics_sdk/const/event_type.dart';
import 'package:analytics_sdk/entity/analytics_utils.dart';
import 'package:analytics_sdk/enum/video_content_type_enum.dart';
import 'package:analytics_sdk/enum/video_event_enum.dart';

/// 视频事件 （手动）
class VideoEvent {
  final String event = EventType.videoEvent.event;
  late final String eventId;

  final String videoId;

  /// 视频标题
  final String videoTitle;

  /// 视频分类ID
  final String videoTypeId;

  /// 视频分类名称
  final String videoTypeName;

  /// 标签名称,多个标签使用英文逗号分隔
  final String videoTagName;

  /// 标签KEY, 多个标签使用英文逗号分隔
  final String videoTagKey;

  /// 视频总时长（秒）
  final int videoDuration;

  /// 本次播放时长（秒）
  final int playDuration;

  /// 播放进度百分比（0-100）
  final int playProgress;

  /// 视频行为标识：video_play(播放), video_pause(暂停), video_share(分享), video_complete(播放完成), video_forward(快进), video_rewind(快退)等
  final VideoEventEnum videoBehavior;

  /// 视频内容类型：video(长视频), short_video(短视频)
  final VideoContentTypeEnum? videoContentType;

  /// 推荐引擎的trace_id，未接推荐引擎传空字符串
  final String recommendTraceId;

  /// 老司机媒体资源ID，视频分析日志新加字段，可为空字符串
  final String mediaId;

  late final Map<String, dynamic> _commonFields;

  VideoEvent(
      {required this.videoId,
      required this.videoTitle,
      required this.videoTypeId,
      required this.videoTypeName,
      required this.videoTagKey,
      required this.videoTagName,
      required this.videoDuration,
      required this.playDuration,
      required this.playProgress,
      required this.videoBehavior,
      required this.videoContentType,
      this.recommendTraceId = '',
      this.mediaId = ''}) {
    _commonFields = AnalyticsUtils.generateCommonFields(event);

    eventId = AnalyticsUtils.generateEventIdFromCommonFields(_commonFields, [
      videoId,
      videoTitle,
      videoTypeId,
      videoTypeName,
      videoTagKey,
      videoTagName,
      videoDuration.toString(),
      playDuration.toString(),
      playProgress.toString(),
      videoBehavior.key,
      videoBehavior.name,
      videoContentType?.label ?? '',
      recommendTraceId,
    ]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {
      'video_id': videoId,
      'video_title': videoTitle,
      'video_type_id': videoTypeId,
      'video_type_name': videoTypeName,
      'video_tag_key': videoTagKey,
      'video_tag_name': videoTagName,
      'video_duration': videoDuration,
      'play_duration': playDuration,
      'play_progress': playProgress,
      'video_behavior_key': videoBehavior.key,
      'video_behavior_name': videoBehavior.name,
      'video_content_type': videoContentType?.label ?? '',
      'recommend_trace_id': recommendTraceId,
      'media_id': mediaId,
    };
    return {..._commonFields, 'event_id': eventId, "payload": payload};
  }

  factory VideoEvent.fromJson(Map<String, dynamic> json) {
    final behaviorKey  = json['video_behavior_key']  as String? ?? '';
    final behaviorName = json['video_behavior_name'] as String? ?? '';
    final behavior = VideoEventEnum(
      behaviorKey.isNotEmpty  ? behaviorKey  : VideoEventEnum.VIDEO_PLAY.key,
      behaviorName.isNotEmpty ? behaviorName : VideoEventEnum.VIDEO_PLAY.name,
    );

    final contentTypeStr = json['video_content_type'] as String? ?? '';
    final VideoContentTypeEnum? contentType =
        contentTypeStr.isNotEmpty ? VideoContentTypeEnum(contentTypeStr) : null;

    return VideoEvent(
      videoId: json['video_id'] as String,
      videoTitle: json['video_title'] as String,
      videoTypeId: json['video_type_id'] as String,
      videoTypeName: json['video_type_name'] as String,
      videoTagKey: json['video_tag_key'] as String,
      videoTagName: json['video_tag_name'] as String,
      videoDuration: json['video_duration'] as int,
      playDuration: json['play_duration'] as int,
      playProgress: json['play_progress'] as int,
      videoBehavior: behavior,
      videoContentType: contentType,
      recommendTraceId: json['recommend_trace_id'] as String? ?? '',
      mediaId: json['media_id'] as String? ?? '',
    );
  }
}
