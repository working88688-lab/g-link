import 'package:analytics_sdk/const/event_type.dart';
import 'package:analytics_sdk/entity/analytics_utils.dart';
import 'package:analytics_sdk/enum/read_behavior_enum.dart';

/// 小说事件
class NovelEvent {
  final String event = EventType.novelEvent.event;
  late final String eventId;

  /// 小说 id
  final String novelId;

  /// 小说标题
  final String novelTitle;

  /// 分类ID
  final String novelTypeId;

  /// 分类名称
  final String novelTypeName;

  /// 标签KEY, 多个标签使用英文逗号分隔
  final String novelTagKey;

  /// 标签名称,多个标签使用英文逗号分隔
  final String novelTagName;

  /// 推荐引擎的trace_id，未接推荐引擎传空字符串
  final String recommendTraceId;

  /// 阅读进度百分比（0-100）
  final int readProgress;

  /// 当前阅读第几页(从1开始)
  final int pageNo;

  /// 行为标识：view(展示), page_next(下一页), page_prev(上一页), complete(读完) 等
  final ReadBehaviorEnum novelBehavior;

  /// 章节ID，没有章节上报空字符串，没有对接搜索推荐引擎的上报空字符串
  final String chapterId;

  /// 章节名称，没有章节上报空字符串，没有对接搜索推荐引擎的上报空字符串
  final String chapterName;

  /// 老司机媒体资源ID，如未使用老司机库资源可传空字符串
  final String mediaId;

  late final Map<String, dynamic> _commonFields;

  NovelEvent({
    required this.novelId,
    required this.novelTitle,
    required this.novelTypeId,
    required this.novelTypeName,
    required this.novelTagKey,
    required this.novelTagName,
    required this.readProgress,
    required this.pageNo,
    required this.novelBehavior,
    this.recommendTraceId = '',
    this.mediaId = '',
    this.chapterId = '',
    this.chapterName = '',
  }) {
    _commonFields = AnalyticsUtils.generateCommonFields(event);

    eventId = AnalyticsUtils.generateEventIdFromCommonFields(_commonFields, [
      novelId,
      novelTitle,
      novelTypeId,
      novelTypeName,
      novelTagKey,
      novelTagName,
      readProgress.toString(),
      pageNo.toString(),
      novelBehavior.key,
      novelBehavior.name,
      recommendTraceId,
      mediaId,
      chapterId,
      chapterName,
    ]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {
      'novel_id': novelId,
      'novel_title': novelTitle,
      'novel_type_id': novelTypeId,
      'novel_type_name': novelTypeName,
      'novel_tag_key': novelTagKey,
      'novel_tag_name': novelTagName,
      'recommend_trace_id': recommendTraceId,
      'read_progress': readProgress,
      'page_no': pageNo,
      'novel_behavior_key': novelBehavior.key,
      'novel_behavior_name': novelBehavior.name,
      'media_id': mediaId,
      'chapter_id': chapterId,
      'chapter_name': chapterName,
    };
    return {..._commonFields, 'event_id': eventId, "payload": payload};
  }

  factory NovelEvent.fromJson(Map<String, dynamic> json) {
    final behaviorKey  = json['novel_behavior_key']  as String? ?? '';
    final behaviorName = json['novel_behavior_name'] as String? ?? '';
    final behavior = ReadBehaviorEnum(
      behaviorKey.isNotEmpty  ? behaviorKey  : ReadBehaviorEnum.VIEW.key,
      behaviorName.isNotEmpty ? behaviorName : ReadBehaviorEnum.VIEW.name,
    );

    return NovelEvent(
      novelId: json['novel_id'] as String,
      novelTitle: json['novel_title'] as String,
      novelTypeId: json['novel_type_id'] as String,
      novelTypeName: json['novel_type_name'] as String,
      novelTagKey: json['novel_tag_key'] as String,
      novelTagName: json['novel_tag_name'] as String,
      readProgress: json['read_progress'] as int,
      pageNo: json['page_no'] as int,
      novelBehavior: behavior,
      recommendTraceId: json['recommend_trace_id'] as String? ?? '',
      mediaId: json['media_id'] as String? ?? '',
      chapterId: json['chapter_id'] as String? ?? '',
      chapterName: json['chapter_name'] as String? ?? '',
    );
  }
}
