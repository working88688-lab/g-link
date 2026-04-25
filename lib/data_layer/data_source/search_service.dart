import 'package:dio/dio.dart';
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
}
