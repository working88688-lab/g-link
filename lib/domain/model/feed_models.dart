import 'package:g_link/domain/type_def.dart';

/// 首页 feed 帖子作者卡片信息（推荐流/热门流/关注流共用）。
///
/// 注意：后端 `/feed/recommend` 等接口的 author 节点**只携带展示字段**，
/// 不返回 `is_following`，关注关系需要客户端自行维护（看 [HomeFeedNotifier]）。
class FeedAuthor {
  const FeedAuthor({
    required this.uid,
    required this.nickname,
    required this.avatarUrl,
    required this.isVerified,
    this.isFollowing,
  });

  final int uid;
  final String nickname;
  final String avatarUrl;
  final bool isVerified;

  /// 服务器是否在 feed 里带了关注关系；无字段时为 null（由客户端覆盖表补全）。
  final bool? isFollowing;

  factory FeedAuthor.fromJson(Json json) {
    final bool? following;
    if (json.containsKey('is_following')) {
      following = json['is_following'] == true;
    } else {
      following = null;
    }
    return FeedAuthor(
      uid: int.tryParse('${json['uid'] ?? 0}') ?? 0,
      nickname: '${json['nickname'] ?? ''}',
      avatarUrl: '${json['avatar_url'] ?? ''}',
      isVerified: json['is_verified'] == true,
      isFollowing: following,
    );
  }
}

/// 帖子图片节点。后端会返回 url 与原始宽高，便于客户端按比例占位避免
/// 加载抖动；宽高缺失时按 1:1 兜底。
class FeedImage {
  const FeedImage({
    required this.url,
    required this.width,
    required this.height,
  });

  final String url;
  final int width;
  final int height;

  double get aspectRatio {
    if (width <= 0 || height <= 0) return 1;
    return width / height;
  }

  factory FeedImage.fromJson(Json json) {
    return FeedImage(
      url: '${json['url'] ?? ''}',
      width: int.tryParse('${json['width'] ?? 0}') ?? 0,
      height: int.tryParse('${json['height'] ?? 0}') ?? 0,
    );
  }
}

/// 单条帖子。字段命名贴合后端响应，方便定位问题。
class FeedPost {
  const FeedPost({
    required this.postId,
    required this.type,
    required this.author,
    required this.content,
    required this.images,
    required this.tags,
    required this.location,
    required this.visibility,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.viewCount,
    required this.isLiked,
    required this.createdAt,
  });

  final int postId;
  final String type;
  final FeedAuthor author;
  final String content;
  final List<FeedImage> images;
  final List<String> tags;
  final String location;
  final String visibility;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int viewCount;
  final bool isLiked;
  final DateTime? createdAt;

  factory FeedPost.fromJson(Json json) {
    final imgList = (json['images'] as List?) ?? const [];
    final tagList = (json['tags'] as List?) ?? const [];
    final createdAtRaw = json['created_at'];
    return FeedPost(
      postId: int.tryParse('${json['post_id'] ?? json['id'] ?? 0}') ?? 0,
      type: '${json['type'] ?? 'post'}',
      author: FeedAuthor.fromJson(Json.from(json['author'] ?? {})),
      content: '${json['content'] ?? ''}',
      images: imgList.map((e) => FeedImage.fromJson(Json.from(e))).toList(),
      tags: tagList.map((e) => '$e').toList(),
      location: '${json['location'] ?? ''}',
      visibility: '${json['visibility'] ?? 'public'}',
      likeCount: int.tryParse('${json['like_count'] ?? 0}') ?? 0,
      commentCount: int.tryParse('${json['comment_count'] ?? 0}') ?? 0,
      shareCount: int.tryParse('${json['share_count'] ?? 0}') ?? 0,
      viewCount: int.tryParse('${json['view_count'] ?? 0}') ?? 0,
      isLiked: json['is_liked'] == true,
      createdAt: createdAtRaw is String
          ? DateTime.tryParse(createdAtRaw)?.toLocal()
          : null,
    );
  }

  FeedPost copyWith({
    bool? isLiked,
    int? likeCount,
  }) {
    return FeedPost(
      postId: postId,
      type: type,
      author: author,
      content: content,
      images: images,
      tags: tags,
      location: location,
      visibility: visibility,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount,
      shareCount: shareCount,
      viewCount: viewCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
    );
  }
}

/// 游标分页结果包装：列表 + 下一页游标 + 是否还有更多。
/// 与文档 `4. 分页` 一致：cursor 是 string，next_cursor 为 null 表示到底。
class FeedPage<T> {
  const FeedPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<T> items;
  final String? nextCursor;
  final bool hasMore;

  factory FeedPage.fromJson(
    Json json,
    T Function(Json) fromItem,
  ) {
    final list = (json['lists'] as List?) ?? const [];
    final nextCursorRaw = json['next_cursor'];
    final hasMore = json['has_more'] == true;
    return FeedPage(
      items: list.map((e) => fromItem(Json.from(e))).toList(),
      nextCursor: nextCursorRaw is String && nextCursorRaw.isNotEmpty
          ? nextCursorRaw
          : null,
      hasMore: hasMore,
    );
  }
}

/// 点赞/取消点赞响应：成功后返回最新点赞状态 + 当前点赞总数。
class LikeResult {
  const LikeResult({required this.liked, required this.likeCount});

  final bool liked;
  final int likeCount;

  factory LikeResult.fromJson(Json json) {
    return LikeResult(
      liked: json['liked'] == true,
      likeCount: int.tryParse('${json['like_count'] ?? 0}') ?? 0,
    );
  }
}

/// 发布帖子 `location` 字段（OpenAPI `POST /api/v1/posts`）。
class PublishLocationInput {
  const PublishLocationInput({
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
  });

  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;

  Json toJson() => {
        'name': name,
        if (address != null && address!.trim().isNotEmpty) 'address': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}

/// 发布页话题推荐 / 搜索（话题模块：`GET /api/v1/topics/hot`、`GET /api/v1/topics/search`）。
class PublishTopicRow {
  const PublishTopicRow({
    required this.tag,
    required this.statLabel,
  });

  /// 话题词，不含 `#`。
  final String tag;

  /// 右侧统计文案（如 `5.8亿次播放`）；接口未给时可为空。
  final String statLabel;

  /// 列表左侧展示用，带 `#`。
  String get lineTitle => tag.startsWith('#') ? tag : '#$tag';

  static PublishTopicRow? tryParse(Json m) {
    final raw = m['name'] ??
        m['title'] ??
        m['topic'] ??
        m['keyword'] ??
        m['tag'];
    if (raw == null) return null;
    var tag = '$raw'.trim();
    if (tag.isEmpty) return null;
    if (tag.startsWith('#')) tag = tag.substring(1);
    if (tag.length > 30) tag = tag.substring(0, 30);
    final stat = _topicStatFromJson(m);
    return PublishTopicRow(tag: tag, statLabel: stat);
  }
}

String _topicStatFromJson(Json m) {
  final pre = m['play_count_display'] ??
      m['view_display'] ??
      m['hot_display'] ??
      m['stat_text'];
  if (pre != null && '$pre'.trim().isNotEmpty) {
    return '$pre';
  }
  final v = m['play_count'] ??
      m['view_count'] ??
      m['hot'] ??
      m['views'];
  var stat = formatTopicPlayCount(v);
  if (stat.isEmpty) {
    final cc = int.tryParse('${m['content_count'] ?? ''}');
    if (cc != null && cc > 0) {
      stat = '$cc条内容';
    }
  }
  return stat;
}

/// 将接口数值格式化为中文「次播放」文案（与设计稿类似）。
String formatTopicPlayCount(dynamic v) {
  if (v == null) return '';
  if (v is String) {
    final t = v.trim();
    if (t.isEmpty) return '';
    return t.contains('播放') ? t : '$t次播放';
  }
  final n = v is int
      ? v.toDouble()
      : (v is double ? v : double.tryParse('$v'));
  if (n == null || n <= 0) return '';
  if (n >= 1e8) {
    final s = (n / 1e8).toStringAsFixed(n >= 1e9 ? 1 : 1);
    return '${_trimTrivialZero(s)}亿次播放';
  }
  if (n >= 1e4) {
    final s = (n / 1e4).toStringAsFixed(1);
    return '${_trimTrivialZero(s)}w次播放';
  }
  return '${n.toInt()}次播放';
}

String _trimTrivialZero(String s) {
  if (s.endsWith('.0')) return s.substring(0, s.length - 2);
  return s;
}

/// 发布帖子接口 `POST /api/v1/posts` 成功后的 `data` 摘要。
class PublishPostResult {
  const PublishPostResult({
    required this.postId,
    this.shareUrl,
  });

  final int postId;
  final String? shareUrl;

  factory PublishPostResult.fromJson(Json json) {
    return PublishPostResult(
      postId: int.tryParse('${json['post_id'] ?? 0}') ?? 0,
      shareUrl: json['share_url'] != null ? '${json['share_url']}' : null,
    );
  }
}

/// 关注/取消关注响应：包含双向关系快照，便于一次同步多个 UI 状态。
class FollowResult {
  const FollowResult({
    required this.uid,
    required this.isFollowing,
    required this.isFollowedBy,
    required this.isFriend,
    required this.followerCount,
    required this.followerCountDisplay,
  });

  final int uid;
  final bool isFollowing;
  final bool isFollowedBy;
  final bool isFriend;
  final int followerCount;
  final String followerCountDisplay;

  factory FollowResult.fromJson(Json json) {
    return FollowResult(
      uid: int.tryParse('${json['uid'] ?? 0}') ?? 0,
      isFollowing: json['is_following'] == true,
      isFollowedBy: json['is_followed_by'] == true,
      isFriend: json['is_friend'] == true,
      followerCount: int.tryParse('${json['follower_count'] ?? 0}') ?? 0,
      followerCountDisplay: '${json['follower_count_display'] ?? ''}',
    );
  }
}
