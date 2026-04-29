import 'package:dio/dio.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/domain/model/search_models.dart';

class SearchService {
  const SearchService(this._dio);

  final Dio _dio;

  Future<UserSearchResult> searchUsers({
    required String q,
    String? cursor,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'q': q,
      'tab': 'user',
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    };
    final res = await _dio.get('/api/v1/search', queryParameters: params);
    final data = res.data['data'] as Map<String, dynamic>;
    final items = (data['lists'] as List<dynamic>)
        .map((e) => UserSearchItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return UserSearchResult(
      items: items,
      nextCursor: data['next_cursor'] as String?,
      hasMore: (data['has_more'] as bool?) ?? false,
    );
  }

  Future<SearchHomeData> getSearchHome() async {
    final res = await _dio.get('/api/v1/search/home');
    final data = res.data['data'] as Map<String, dynamic>? ?? const {};
    final history = (data['history'] as List<dynamic>? ?? const [])
        .map((e) => '$e')
        .toList();
    final hot = (data['hot'] as List<dynamic>? ?? const [])
        .map((e) => SearchHotItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final recommendUsers = (data['recommend_users'] as List<dynamic>? ?? const [])
        .map((e) => RecommendedUser.fromJson(e as Map<String, dynamic>))
        .toList();
    return SearchHomeData(
      history: history,
      hot: hot,
      recommendUsers: recommendUsers,
    );
  }
}
