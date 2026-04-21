import 'package:analytics_sdk/const/event_type.dart';
import 'package:analytics_sdk/entity/analytics_utils.dart';

/// 关键词搜索事件
class KeywordSearchEvent {
  final String event = EventType.keywordSearch.event;
  late final String eventId;

  /// 搜索关键词
  final String keyword;

  /// 搜索结果数量
  final int searchResultCount;

  /// 搜索引擎 trace ID，未接搜索引擎时传空字符串
  final String searchTraceId;

  /// 搜索引擎 search ID，未接搜索引擎时传空字符串
  final String searchId;

  late final Map<String, dynamic> _commonFields;

  KeywordSearchEvent({
    required this.keyword,
    required this.searchResultCount,
    this.searchTraceId = '',
    this.searchId = '',
  }) {
    _commonFields = AnalyticsUtils.generateCommonFields(event);

    eventId = AnalyticsUtils.generateEventIdFromCommonFields(_commonFields, [
      keyword,
      searchResultCount.toString(),
      searchTraceId,
      searchId,
    ]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> payload = {
      'keyword': keyword,
      'search_result_count': searchResultCount,
      'search_trace_id': searchTraceId,
      'search_id': searchId,
    };
    return {..._commonFields, 'event_id': eventId, "payload": payload};
  }

  factory KeywordSearchEvent.fromJson(Map<String, dynamic> json) {
    return KeywordSearchEvent(
      keyword: json['keyword'] as String,
      searchResultCount: json['search_result_count'] as int,
      searchTraceId: json['search_trace_id'] as String? ?? '',
      searchId: json['search_id'] as String? ?? '',
    );
  }
}
