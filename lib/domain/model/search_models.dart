import 'package:g_link/domain/model/profile_models.dart';

class UserSearchItem {
  const UserSearchItem({
    required this.uid,
    required this.username,
    required this.nickname,
    required this.avatarUrl,
    required this.followerCount,
  });

  final int uid;
  final String username;
  final String nickname;
  final String avatarUrl;
  final int followerCount;

  factory UserSearchItem.fromJson(Map<String, dynamic> json) => UserSearchItem(
        uid: (json['uid'] as int?) ?? 0,
        username: (json['username'] as String?) ?? '',
        nickname: (json['nickname'] as String?) ?? '',
        avatarUrl: (json['avatar_url'] as String?) ?? '',
        followerCount: (json['follower_count'] as int?) ?? 0,
      );
}

class UserSearchResult {
  const UserSearchResult({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<UserSearchItem> items;
  final String? nextCursor;
  final bool hasMore;
}

class SearchHotItem {
  const SearchHotItem({
    required this.rank,
    required this.keyword,
    required this.score,
  });

  final int rank;
  final String keyword;
  final int score;

  factory SearchHotItem.fromJson(Map<String, dynamic> json) => SearchHotItem(
        rank: (json['rank'] as int?) ?? 0,
        keyword: (json['keyword'] as String?) ?? '',
        score: (json['score'] as int?) ?? 0,
      );
}

class SearchHomeData {
  const SearchHomeData({
    required this.history,
    required this.hot,
    required this.recommendUsers,
  });

  final List<String> history;
  final List<SearchHotItem> hot;
  final List<RecommendedUser> recommendUsers;
}
