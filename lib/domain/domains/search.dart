import 'package:g_link/domain/model/search_models.dart';

abstract class SearchDomain {
  Future<UserSearchResult> searchUsers({
    required String q,
    String? cursor,
    int limit = 20,
  });

  Future<SearchHomeData> getSearchHome();
}
