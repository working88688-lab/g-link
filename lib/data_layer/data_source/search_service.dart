import 'package:dio/dio.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/domain/model/search_models.dart';

/// 综合搜索 `/api/v1/search` + 音乐 `/api/v1/bgms/search`。
///
/// 全部 GET 走 `skipEncrypt: true`，与 v1 其它明文接口一致，避免响应被误解密。
class SearchService {
  const SearchService(this._dio);

  final Dio _dio;

  static final _plain = Options(extra: {'skipEncrypt': true});

  int _code(dynamic raw) {
    if (raw is! Map) return -1;
    return int.tryParse('${raw['code'] ?? raw['status'] ?? -1}') ?? -1;
  }

  Map<String, dynamic>? _dataMap(dynamic raw) {
    if (raw is! Map) return null;
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  Future<UserSearchResult> searchUsers({
    required String q,
    String? cursor,
    int limit = 20,
  }) async {
    final envelope = await _search(q: q, tab: 'user', cursor: cursor, limit: limit);
    final data = _dataMap(envelope);
    if (data == null || _code(envelope) != 0) {
      return const UserSearchResult(items: [], nextCursor: null, hasMore: false);
    }
    final list = (data['lists'] as List?) ?? const [];
    final items = list
        .map((e) => UserSearchItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return UserSearchResult(
      items: items,
      nextCursor: data['next_cursor'] as String?,
      hasMore: data['has_more'] == true,
    );
  }

  Future<PostSearchResult> searchPosts({
    required String q,
    String? cursor,
    int limit = 20,
  }) async {
    final envelope = await _search(q: q, tab: 'post', cursor: cursor, limit: limit);
    final data = _dataMap(envelope);
    if (data == null || _code(envelope) != 0) {
      return const PostSearchResult(items: [], nextCursor: null, hasMore: false);
    }
    final list = (data['lists'] as List?) ?? const [];
    final items = list
        .map((e) => PostSearchItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return PostSearchResult(
      items: items,
      nextCursor: data['next_cursor'] as String?,
      hasMore: data['has_more'] == true,
    );
  }

  /// 尝试 `tab=video`；若服务端未开放，返回空列表（不抛异常打断 UI）。
  Future<VideoSearchResult> searchVideos({
    required String q,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final envelope =
          await _search(q: q, tab: 'video', cursor: cursor, limit: limit);
      final data = _dataMap(envelope);
      if (data == null || _code(envelope) != 0) {
        return const VideoSearchResult(items: [], nextCursor: null, hasMore: false);
      }
      final list = (data['lists'] as List?) ?? const [];
      final items = list
          .map(
              (e) => VideoSearchItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return VideoSearchResult(
        items: items,
        nextCursor: data['next_cursor'] as String?,
        hasMore: data['has_more'] == true,
      );
    } catch (_) {
      return const VideoSearchResult(items: [], nextCursor: null, hasMore: false);
    }
  }

  Future<BgmSearchResult> searchMusic({
    required String q,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/v1/bgms/search',
        queryParameters: <String, dynamic>{
          'q': q,
          'limit': limit,
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        },
        options: _plain,
      );
      final raw = res.data;
      final data = _dataMap(raw);
      if (data == null || _code(raw) != 0) {
        return const BgmSearchResult(items: [], nextCursor: null, hasMore: false);
      }
      final list = (data['lists'] as List?) ?? const [];
      final items = list
          .map((e) => BgmSearchItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return BgmSearchResult(
        items: items,
        nextCursor: data['next_cursor'] as String?,
        hasMore: data['has_more'] == true,
      );
    } catch (_) {
      return const BgmSearchResult(items: [], nextCursor: null, hasMore: false);
    }
  }

  Future<SearchHomeData> getSearchHome() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/search/home',
      options: _plain,
    );
    final raw = res.data;
    final data = _dataMap(raw) ?? const <String, dynamic>{};
    final history = (data['history'] as List<dynamic>? ?? const [])
        .map((e) => '$e')
        .toList();
    final hot = (data['hot'] as List<dynamic>? ?? const [])
        .map((e) => SearchHotItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final recommendUsers =
        (data['recommend_users'] as List<dynamic>? ?? const [])
            .map((e) =>
                RecommendedUser.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
    return SearchHomeData(
      history: history,
      hot: hot,
      recommendUsers: recommendUsers,
    );
  }

  Future<Map<String, dynamic>> _search({
    required String q,
    required String tab,
    String? cursor,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/search',
      queryParameters: <String, dynamic>{
        'q': q,
        'tab': tab,
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
      options: _plain,
    );
    final body = res.data;
    if (body == null) return <String, dynamic>{'code': -1};
    return body;
  }
}
