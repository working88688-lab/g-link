part of '../repo.dart';

mixin _Search on _BaseAppRepo implements SearchDomain {
  @override
  Future<UserSearchResult> searchUsers({
    required String q,
    String? cursor,
    int limit = 20,
  }) =>
      _searchService.searchUsers(q: q, cursor: cursor, limit: limit);

  @override
  Future<SearchHomeData> getSearchHome() => _searchService.getSearchHome();
}
