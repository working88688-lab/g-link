import 'package:g_link/domain/model/profile_models.dart';

class UserSearchItem {
  const UserSearchItem({
    required this.uid,
    required this.username,
    required this.nickname,
    required this.avatarUrl,
    required this.followerCount,
    this.isFollowing = false,
  });

  final int uid;
  final String username;
  final String nickname;
  final String avatarUrl;
  final int followerCount;
  /// 服务端若返回则采用；否则客户端本地维护。
  final bool isFollowing;

  factory UserSearchItem.fromJson(Map<String, dynamic> json) => UserSearchItem(
        uid: int.tryParse('${json['uid'] ?? 0}') ?? 0,
        username: '${json['username'] ?? ''}',
        nickname: '${json['nickname'] ?? ''}',
        avatarUrl: '${json['avatar_url'] ?? ''}',
        followerCount: int.tryParse('${json['follower_count'] ?? 0}') ?? 0,
        isFollowing: json['is_following'] == true,
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

/// 帖子搜索项（tab=post）。作者字段后端可能逐步补全，故用可选字段兼容。
class PostSearchItem {
  const PostSearchItem({
    required this.id,
    required this.content,
    required this.images,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    required this.authorNickname,
    required this.authorUsername,
    required this.authorAvatarUrl,
  });

  final int id;
  final String content;
  final List<String> images;
  final int likeCount;
  final int commentCount;
  final String? createdAt;
  final String authorNickname;
  final String authorUsername;
  final String authorAvatarUrl;

  static List<String> _parseImages(dynamic raw) {
    if (raw is! List) return const [];
    final out = <String>[];
    for (final e in raw) {
      if (e is String && e.isNotEmpty) {
        out.add(e);
      } else if (e is Map && e['url'] != null) {
        out.add('${e['url']}');
      }
    }
    return out;
  }

  factory PostSearchItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? author;
    if (json['author'] is Map) {
      author = Map<String, dynamic>.from(json['author'] as Map);
    }
    return PostSearchItem(
      id: int.tryParse('${json['id'] ?? json['post_id'] ?? 0}') ?? 0,
      content: '${json['content'] ?? json['title'] ?? ''}',
      images: _parseImages(json['images']),
      likeCount: int.tryParse('${json['like_count'] ?? 0}') ?? 0,
      commentCount: int.tryParse('${json['comment_count'] ?? 0}') ?? 0,
      createdAt: json['created_at'] != null ? '${json['created_at']}' : null,
      authorNickname: author != null ? '${author['nickname'] ?? ''}' : '',
      authorUsername: author != null ? '${author['username'] ?? ''}' : '',
      authorAvatarUrl: author != null ? '${author['avatar_url'] ?? ''}' : '',
    );
  }
}

class PostSearchResult {
  const PostSearchResult({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<PostSearchItem> items;
  final String? nextCursor;
  final bool hasMore;
}

/// 短视频搜索项（tab=video，若后端未开放该 tab 则列表为空）。
class VideoSearchItem {
  const VideoSearchItem({
    required this.id,
    required this.coverUrl,
    required this.title,
    required this.durationSec,
  });

  final int id;
  final String coverUrl;
  final String title;
  final int durationSec;

  factory VideoSearchItem.fromJson(Map<String, dynamic> json) {
    final durMs = int.tryParse('${json['duration_ms'] ?? 0}') ?? 0;
    final durSecRaw = int.tryParse(
      '${json['duration_sec'] ?? json['duration'] ?? json['duration_seconds'] ?? 0}',
    ) ?? 0;
    var durationSec = durSecRaw;
    if (durationSec <= 0 && durMs > 0) {
      durationSec = (durMs / 1000).round();
    }

    String cover = '';
    if (json['cover_url'] != null) {
      cover = '${json['cover_url']}';
    } else if (json['thumbnail_url'] != null) {
      cover = '${json['thumbnail_url']}';
    } else if (json['poster_url'] != null) {
      cover = '${json['poster_url']}';
    }

    return VideoSearchItem(
      id: int.tryParse('${json['id'] ?? json['video_id'] ?? 0}') ?? 0,
      coverUrl: cover,
      title: '${json['title'] ?? json['caption'] ?? json['desc'] ?? ''}',
      durationSec: durationSec,
    );
  }
}

class VideoSearchResult {
  const VideoSearchResult({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<VideoSearchItem> items;
  final String? nextCursor;
  final bool hasMore;
}

/// BGM / 音乐搜索（`/api/v1/bgms/search`）。
class BgmSearchItem {
  const BgmSearchItem({
    required this.id,
    required this.name,
    required this.artist,
    required this.coverUrl,
    required this.audioUrl,
    required this.durationMs,
    required this.useCount,
  });

  final int id;
  final String name;
  final String artist;
  final String coverUrl;
  final String audioUrl;
  final int durationMs;
  final int useCount;

  factory BgmSearchItem.fromJson(Map<String, dynamic> json) => BgmSearchItem(
        id: int.tryParse('${json['id'] ?? 0}') ?? 0,
        name: '${json['name'] ?? ''}',
        artist: '${json['artist'] ?? ''}',
        coverUrl: '${json['cover_url'] ?? ''}',
        audioUrl: '${json['audio_url'] ?? ''}',
        durationMs: int.tryParse('${json['duration_ms'] ?? 0}') ?? 0,
        useCount: int.tryParse('${json['use_count'] ?? 0}') ?? 0,
      );
}

class BgmSearchResult {
  const BgmSearchResult({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<BgmSearchItem> items;
  final String? nextCursor;
  final bool hasMore;
}
