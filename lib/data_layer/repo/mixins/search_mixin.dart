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
  Future<PostSearchResult> searchPosts({
    required String q,
    String? cursor,
    int limit = 20,
  }) =>
      _searchService.searchPosts(q: q, cursor: cursor, limit: limit);

  @override
  Future<VideoSearchResult> searchVideos({
    required String q,
    String? cursor,
    int limit = 20,
  }) =>
      _searchService.searchVideos(q: q, cursor: cursor, limit: limit);

  @override
  Future<BgmSearchResult> searchMusic({
    required String q,
    String? cursor,
    int limit = 20,
  }) =>
      _searchService.searchMusic(q: q, cursor: cursor, limit: limit);

  @override
  Future<SearchHomeData> getSearchHome() => _searchService.getSearchHome();
}
