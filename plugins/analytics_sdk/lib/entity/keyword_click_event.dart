import 'package:analytics_sdk/const/event_type.dart';
import 'package:analytics_sdk/entity/analytics_utils.dart';
import 'package:analytics_sdk/enum/click_item_type_enum.dart';

/// 关键词搜索结果点击事件
class KeywordClickEvent {
  final String event = EventType.keywordClick.event;
  late final String eventId;

  /// 关联关键词
  final String keyword;

  /// 点击项目ID（视频ID/小说ID等）
  final String clickItemId;

  /// 点击项目类型，可用预定义常量或自定义：
  /// `ClickItemTypeEnum.video` / `ClickItemTypeEnum('manga', '漫画类')`
  final ClickItemTypeEnum clickItemType;

  /// 点击位置（搜索结果中的排序位置）
  final int clickPosition;

  /// 搜索引擎 trace ID，未接搜索引擎时传空字符串
  final String searchTraceId;

  late final Map<String, dynamic> _commonFields;

  KeywordClickEvent({
    required this.keyword,
    required this.clickItemId,
    required this.clickItemType,
    required this.clickPosition,
    this.searchTraceId = '',
  }) {
    _commonFields = AnalyticsUtils.generateCommonFields(event);

    eventId = AnalyticsUtils.generateEventIdFromCommonFields(_commonFields, [
      keyword,
      clickItemId,
      clickItemType.key,
      clickItemType.name,
      clickPosition.toString(),
      searchTraceId,
    ]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {
      'keyword': keyword,
      'click_item_id': clickItemId,
      'click_item_type_key': clickItemType.key,
      'click_item_type_name': clickItemType.name,
      'click_position': clickPosition,
      'search_trace_id': searchTraceId,
    };
    return {..._commonFields, 'event_id': eventId, "payload": payload};
  }

  factory KeywordClickEvent.fromJson(Map<String, dynamic> json) {
    return KeywordClickEvent(
      keyword: json['keyword'] as String,
      clickItemId: json['click_item_id'] as String,
      clickItemType: ClickItemTypeEnum(
        json['click_item_type_key'] as String,
        json['click_item_type_name'] as String,
      ),
      clickPosition: json['click_position'] as int,
      searchTraceId: json['search_trace_id'] as String? ?? '',
    );
  }
}
