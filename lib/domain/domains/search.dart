import 'package:g_link/domain/model/search_models.dart';

abstract class SearchDomain {
  Future<UserSearchResult> searchUsers({
    required String q,
    String? cursor,
    int limit = 20,
  });

  Future<PostSearchResult> searchPosts({
    required String q,
    String? cursor,
    int limit = 20,
  });

  /// 依赖后端是否开放 `tab=video`；未开放时返回空列表。
  Future<VideoSearchResult> searchVideos({
    required String q,
    String? cursor,
    int limit = 20,
  });

  /// 音乐走 `/api/v1/bgms/search`（与综合搜索同源业务，独立 path）。
  Future<BgmSearchResult> searchMusic({
    required String q,
    String? cursor,
    int limit = 20,
  });

  Future<SearchHomeData> getSearchHome();
}
