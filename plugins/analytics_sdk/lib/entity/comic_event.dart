import 'package:analytics_sdk/const/event_type.dart';
import 'package:analytics_sdk/entity/analytics_utils.dart';
import 'package:analytics_sdk/enum/read_behavior_enum.dart';

/// 漫画事件
class ComicEvent {
  final String event = EventType.comicEvent.event;
  late final String eventId;

  /// 漫画 id
  final String comicId;

  /// 漫画标题
  final String comicTitle;

  /// 分类ID
  final String comicTypeId;

  /// 分类名称
  final String comicTypeName;

  /// 标签KEY, 多个标签使用英文逗号分隔
  final String comicTagKey;

  /// 标签名称,多个标签使用英文逗号分隔
  final String comicTagName;

  /// 推荐引擎的trace_id，未接推荐引擎传空字符串
  final String recommendTraceId;

  /// 阅读进度百分比（0-100）
  final int readProgress;

  /// 当前阅读第几页(从1开始)
  final int pageNo;

  /// 行为标识：view(展示), page_next(下一页), page_prev(上一页), complete(读完) 等
  final ReadBehaviorEnum comicBehavior;

  /// 章节ID，没有章节上报空字符串，没有对接搜索推荐引擎的上报空字符串
  final String chapterId;

  /// 章节名称，没有章节上报空字符串，没有对接搜索推荐引擎的上报空字符串
  final String chapterName;

  /// 老司机媒体资源ID，如未使用老司机库资源可传空字符串
  final String mediaId;

  late final Map<String, dynamic> _commonFields;

  ComicEvent({
    required this.comicId,
    required this.comicTitle,
    required this.comicTypeId,
    required this.comicTypeName,
    required this.comicTagKey,
    required this.comicTagName,
    required this.readProgress,
    required this.pageNo,
    required this.comicBehavior,
    this.recommendTraceId = '',
    this.mediaId = '',
    this.chapterId = '',
    this.chapterName = '',
  }) {
    _commonFields = AnalyticsUtils.generateCommonFields(event);

    eventId = AnalyticsUtils.generateEventIdFromCommonFields(_commonFields, [
      comicId,
      comicTitle,
      comicTypeId,
      comicTypeName,
      comicTagKey,
      comicTagName,
      readProgress.toString(),
      pageNo.toString(),
      comicBehavior.key,
      comicBehavior.name,
      recommendTraceId,
      mediaId,
      chapterId,
      chapterName,
    ]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {
      'comic_id': comicId,
      'comic_title': comicTitle,
      'comic_type_id': comicTypeId,
      'comic_type_name': comicTypeName,
      'comic_tag_key': comicTagKey,
      'comic_tag_name': comicTagName,
      'recommend_trace_id': recommendTraceId,
      'read_progress': readProgress,
      'page_no': pageNo,
      'comic_behavior_key': comicBehavior.key,
      'comic_behavior_name': comicBehavior.name,
      'media_id': mediaId,
      'chapter_id': chapterId,
      'chapter_name': chapterName,
    };
    return {..._commonFields, 'event_id': eventId, "payload": payload};
  }

  factory ComicEvent.fromJson(Map<String, dynamic> json) {
    final behaviorKey  = json['comic_behavior_key']  as String? ?? '';
    final behaviorName = json['comic_behavior_name'] as String? ?? '';
    final behavior = ReadBehaviorEnum(
      behaviorKey.isNotEmpty  ? behaviorKey  : ReadBehaviorEnum.VIEW.key,
      behaviorName.isNotEmpty ? behaviorName : ReadBehaviorEnum.VIEW.name,
    );

    return ComicEvent(
      comicId: json['comic_id'] as String,
      comicTitle: json['comic_title'] as String,
      comicTypeId: json['comic_type_id'] as String,
      comicTypeName: json['comic_type_name'] as String,
      comicTagKey: json['comic_tag_key'] as String,
      comicTagName: json['comic_tag_name'] as String,
      readProgress: json['read_progress'] as int,
      pageNo: json['page_no'] as int,
      comicBehavior: behavior,
      recommendTraceId: json['recommend_trace_id'] as String? ?? '',
      mediaId: json['media_id'] as String? ?? '',
      chapterId: json['chapter_id'] as String? ?? '',
      chapterName: json['chapter_name'] as String? ?? '',
    );
  }
}
