import 'package:g_link/domain/type_def.dart';

class VideoFeedAuthor {
  const VideoFeedAuthor({
    required this.uid,
    required this.username,
    required this.nickname,
    required this.avatarUrl,
    required this.isVerified,
  });

  final int uid;
  final String username;
  final String nickname;
  final String avatarUrl;
  final bool isVerified;

  factory VideoFeedAuthor.fromJson(Json json) {
    return VideoFeedAuthor(
      uid: int.tryParse('${json['uid'] ?? 0}') ?? 0,
      username: '${json['username'] ?? ''}',
      nickname: '${json['nickname'] ?? ''}',
      avatarUrl: '${json['avatar_url'] ?? ''}',
      isVerified: json['is_verified'] == true,
    );
  }
}

class VideoFeedStats {
  const VideoFeedStats({
    required this.playCount,
    required this.likeCount,
    required this.commentCount,
    required this.favoriteCount,
    required this.shareCount,
  });

  final int playCount;
  final int likeCount;
  final int commentCount;
  final int favoriteCount;
  final int shareCount;

  factory VideoFeedStats.fromJson(Json json) {
    return VideoFeedStats(
      playCount: int.tryParse('${json['play_count'] ?? 0}') ?? 0,
      likeCount: int.tryParse('${json['like_count'] ?? 0}') ?? 0,
      commentCount: int.tryParse('${json['comment_count'] ?? 0}') ?? 0,
      favoriteCount: int.tryParse('${json['favorite_count'] ?? 0}') ?? 0,
      shareCount: int.tryParse('${json['share_count'] ?? 0}') ?? 0,
    );
  }
}

class VideoFeedItem {
  const VideoFeedItem({
    required this.id,
    required this.author,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.videoUrl,
    required this.durationMs,
    required this.width,
    required this.height,
    required this.tags,
    required this.isLiked,
    required this.stats,
    required this.publishedAt,
  });

  final int id;
  final VideoFeedAuthor author;
  final String title;
  final String description;
  final String coverUrl;
  final String videoUrl;
  final int durationMs;
  final int width;
  final int height;
  final List<String> tags;
  final bool isLiked;
  final VideoFeedStats stats;
  final DateTime? publishedAt;

  factory VideoFeedItem.fromJson(Json json) {
    final tags = (json['tags'] as List?) ?? const [];
    final publishedAtRaw = json['published_at'];
    return VideoFeedItem(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      author: VideoFeedAuthor.fromJson(Json.from(json['author'] ?? {})),
      title: '${json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
      coverUrl: '${json['cover_url'] ?? ''}',
      videoUrl: '${json['video_url'] ?? ''}',
      durationMs: int.tryParse('${json['duration_ms'] ?? 0}') ?? 0,
      width: int.tryParse('${json['width'] ?? 0}') ?? 0,
      height: int.tryParse('${json['height'] ?? 0}') ?? 0,
      tags: tags.map((e) => '$e').toList(),
      isLiked: json['is_liked'] == true,
      stats: VideoFeedStats.fromJson(Json.from(json['stats'] ?? {})),
      publishedAt: publishedAtRaw is String
          ? DateTime.tryParse(publishedAtRaw)?.toLocal()
          : null,
    );
  }
}

class VideoFeedPage<T> {
  const VideoFeedPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<T> items;
  final String? nextCursor;
  final bool hasMore;

  factory VideoFeedPage.fromJson(Json json, T Function(Json) fromItem) {
    final list = (json['lists'] as List?) ?? const [];
    final nextCursorRaw = json['next_cursor'];
    return VideoFeedPage(
      items: list.map((e) => fromItem(Json.from(e))).toList(),
      nextCursor: nextCursorRaw is String && nextCursorRaw.isNotEmpty
          ? nextCursorRaw
          : null,
      hasMore: json['has_more'] == true,
    );
  }
}
