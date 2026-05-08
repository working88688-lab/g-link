import 'package:g_link/domain/type_def.dart';

class CommentUser {
  const CommentUser({
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

  factory CommentUser.fromJson(Json json) {
    return CommentUser(
      uid: int.tryParse('${json['uid'] ?? 0}') ?? 0,
      username: '${json['username'] ?? ''}',
      nickname: '${json['nickname'] ?? ''}',
      avatarUrl: '${json['avatar_url'] ?? ''}',
      isVerified: json['is_verified'] == true,
    );
  }
}

class CommentReplyTo {
  const CommentReplyTo({
    required this.uid,
    required this.username,
    required this.nickname,
  });

  final int uid;
  final String username;
  final String nickname;

  factory CommentReplyTo.fromJson(Json json) {
    return CommentReplyTo(
      uid: int.tryParse('${json['uid'] ?? 0}') ?? 0,
      username: '${json['username'] ?? ''}',
      nickname: '${json['nickname'] ?? ''}',
    );
  }
}

class CommentItemModel {
  const CommentItemModel({
    required this.id,
    required this.parentId,
    required this.rootId,
    required this.user,
    required this.content,
    required this.mediaUrl,
    required this.likeCount,
    required this.replyCount,
    required this.isAuthor,
    required this.isLiked,
    required this.ipLocation,
    required this.createdAt,
    this.replyTo,
    this.replies = const [],
  });

  final int id;
  final int parentId;
  final int rootId;
  final CommentUser user;
  final CommentReplyTo? replyTo;
  final String content;
  final String mediaUrl;
  final int likeCount;
  final int replyCount;
  final bool isAuthor;
  final bool isLiked;
  final String ipLocation;
  final DateTime? createdAt;
  final List<CommentItemModel> replies;

  factory CommentItemModel.fromJson(Json json) {
    final createdAtRaw = json['created_at'];
    return CommentItemModel(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      parentId: int.tryParse('${json['parent_id'] ?? 0}') ?? 0,
      rootId: int.tryParse('${json['root_id'] ?? 0}') ?? 0,
      user: CommentUser.fromJson(Json.from(json['user'] ?? {})),
      replyTo: json['reply_to'] is Map<String, dynamic>
          ? CommentReplyTo.fromJson(Json.from(json['reply_to']))
          : null,
      content: '${json['content'] ?? ''}',
      mediaUrl: '${json['media_url'] ?? ''}',
      likeCount: int.tryParse('${json['like_count'] ?? 0}') ?? 0,
      replyCount: int.tryParse('${json['reply_count'] ?? 0}') ?? 0,
      isAuthor: json['is_author'] == true,
      isLiked: json['is_liked'] == true,
      ipLocation: '${json['ip_location'] ?? ''}',
      createdAt: createdAtRaw is String
          ? DateTime.tryParse(createdAtRaw)?.toLocal()
          : null,
    );
  }

  CommentItemModel copyWith({
    int? likeCount,
    bool? isLiked,
    List<CommentItemModel>? replies,
  }) {
    return CommentItemModel(
      id: id,
      parentId: parentId,
      rootId: rootId,
      user: user,
      replyTo: replyTo,
      content: content,
      mediaUrl: mediaUrl,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount,
      isAuthor: isAuthor,
      isLiked: isLiked ?? this.isLiked,
      ipLocation: ipLocation,
      createdAt: createdAt,
      replies: replies ?? this.replies,
    );
  }
}

class CommentPage<T> {
  const CommentPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<T> items;
  final String? nextCursor;
  final bool hasMore;

  factory CommentPage.fromJson(Json json, T Function(Json) fromItem) {
    final list = (json['lists'] as List?) ?? const [];
    final nextCursorRaw = json['next_cursor'];
    return CommentPage(
      items: list.map((e) => fromItem(Json.from(e))).toList(),
      nextCursor: nextCursorRaw is String && nextCursorRaw.isNotEmpty
          ? nextCursorRaw
          : null,
      hasMore: json['has_more'] == true,
    );
  }
}

class CommentLikeActionResult {
  const CommentLikeActionResult({
    required this.liked,
    required this.likeCount,
  });

  final bool liked;
  final int likeCount;

  factory CommentLikeActionResult.fromJson(Json json) {
    return CommentLikeActionResult(
      liked: json['liked'] == true,
      likeCount: int.tryParse('${json['like_count'] ?? 0}') ?? 0,
    );
  }
}
