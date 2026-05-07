import 'package:g_link/domain/type_def.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.username,
    required this.nickname,
    required this.avatarUrl,
    required this.coverUrl,
    required this.bio,
    required this.location,
    required this.professionTags,
    required this.isSelf,
    required this.followingCount,
    required this.followingCountDisplay,
    required this.followerCount,
    required this.followerCountDisplay,
    required this.likeCount,
    required this.likeCountDisplay,
    required this.postCount,
    required this.postCountDisplay,
    required this.videoCount,
    required this.videoCountDisplay,
    this.isFollowing = false,
    this.isFollowedBy = false,
    this.isFriend = false,
    this.isBlocked = false,
    this.isBlockedBy = false,
  });

  final int uid;
  final String username;
  final String nickname;
  final String avatarUrl;
  final String coverUrl;
  final String bio;
  final String location;
  final List<String> professionTags;
  final bool isSelf;
  final int followingCount;
  final String followingCountDisplay;
  final int followerCount;
  final String followerCountDisplay;
  final int likeCount;
  final String likeCountDisplay;
  final int postCount;
  final String postCountDisplay;
  final int videoCount;
  final String videoCountDisplay;

  /// 当前登录用户是否已关注该 profile。本人页不下发，恒 false。
  final bool isFollowing;

  /// 该 profile 是否已关注当前登录用户（用于判断「回关」状态）。
  final bool isFollowedBy;

  /// 互相关注。本人页不下发，恒 false。
  final bool isFriend;

  /// 我已经把对方拉黑了——拉黑后他人主页正文区会被替换成「对方已被你拉黑」。
  final bool isBlocked;

  /// 对方把我拉黑了——非本人接口才返回；本人页恒 false。
  final bool isBlockedBy;

  factory UserProfile.fromJson(Json json) {
    final stats = Json.from(json['stats'] ?? {});
    String displayOf(String key, int value) =>
        '${stats['${key}_display'] ?? value}';
    final relation = json['relation'] is Map
        ? Json.from(json['relation'] as Map)
        : const <String, dynamic>{};
    return UserProfile(
      uid: int.tryParse('${json['uid'] ?? 0}') ?? 0,
      username: '${json['username'] ?? ''}',
      nickname: '${json['nickname'] ?? ''}',
      avatarUrl: '${json['avatar_url'] ?? ''}',
      coverUrl: '${json['cover_url'] ?? ''}',
      bio: '${json['bio'] ?? ''}',
      location: '${json['location'] ?? ''}',
      professionTags:
          List<String>.from((json['profession_tags'] as List?) ?? const []),
      isSelf: json['is_self'] == true,
      followingCount: int.tryParse('${stats['following_count'] ?? 0}') ?? 0,
      followingCountDisplay: displayOf('following_count',
          int.tryParse('${stats['following_count'] ?? 0}') ?? 0),
      followerCount: int.tryParse('${stats['follower_count'] ?? 0}') ?? 0,
      followerCountDisplay: displayOf('follower_count',
          int.tryParse('${stats['follower_count'] ?? 0}') ?? 0),
      likeCount: int.tryParse('${stats['like_count'] ?? 0}') ?? 0,
      likeCountDisplay: displayOf(
          'like_count', int.tryParse('${stats['like_count'] ?? 0}') ?? 0),
      postCount: int.tryParse('${stats['post_count'] ?? 0}') ?? 0,
      postCountDisplay: displayOf(
          'post_count', int.tryParse('${stats['post_count'] ?? 0}') ?? 0),
      videoCount: int.tryParse('${stats['video_count'] ?? 0}') ?? 0,
      videoCountDisplay: displayOf(
          'video_count', int.tryParse('${stats['video_count'] ?? 0}') ?? 0),
      isFollowing: relation['is_following'] == true,
      isFollowedBy: relation['is_followed_by'] == true,
      isFriend: relation['is_friend'] == true,
      isBlocked: relation['is_blocked'] == true,
      isBlockedBy: relation['is_blocked_by'] == true,
    );
  }

  /// 序列化结构刻意贴近后端 `getMyProfile` 返回值，方便 [UserProfile.fromJson]
  /// 直接复用：本地缓存里存的是「上次后端响应」的镜像，下次冷启动直接 fromJson
  /// 复活，不需要单独维护一份 cache schema。
  Json toJson() {
    return <String, dynamic>{
      'uid': uid,
      'username': username,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'bio': bio,
      'location': location,
      'profession_tags': professionTags,
      'is_self': isSelf,
      'stats': <String, dynamic>{
        'following_count': followingCount,
        'following_count_display': followingCountDisplay,
        'follower_count': followerCount,
        'follower_count_display': followerCountDisplay,
        'like_count': likeCount,
        'like_count_display': likeCountDisplay,
        'post_count': postCount,
        'post_count_display': postCountDisplay,
        'video_count': videoCount,
        'video_count_display': videoCountDisplay,
      },
      // 缓存里只记自己的资料，relation 字段始终是默认值，写不写都行；写出去
      // 是为了 fromJson roundtrip 不丢字段——他人主页不进缓存，无需考虑。
      'relation': <String, dynamic>{
        'is_following': isFollowing,
        'is_followed_by': isFollowedBy,
        'is_friend': isFriend,
        'is_blocked': isBlocked,
        'is_blocked_by': isBlockedBy,
      },
    };
  }

  UserProfile copyWith({
    int? followerCount,
    String? followerCountDisplay,
    bool? isFollowing,
    bool? isFollowedBy,
    bool? isFriend,
    bool? isBlocked,
    bool? isBlockedBy,
  }) {
    return UserProfile(
      uid: uid,
      username: username,
      nickname: nickname,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
      bio: bio,
      location: location,
      professionTags: professionTags,
      isSelf: isSelf,
      followingCount: followingCount,
      followingCountDisplay: followingCountDisplay,
      followerCount: followerCount ?? this.followerCount,
      followerCountDisplay: followerCountDisplay ?? this.followerCountDisplay,
      likeCount: likeCount,
      likeCountDisplay: likeCountDisplay,
      postCount: postCount,
      postCountDisplay: postCountDisplay,
      videoCount: videoCount,
      videoCountDisplay: videoCountDisplay,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowedBy: isFollowedBy ?? this.isFollowedBy,
      isFriend: isFriend ?? this.isFriend,
      isBlocked: isBlocked ?? this.isBlocked,
      isBlockedBy: isBlockedBy ?? this.isBlockedBy,
    );
  }
}

class UserPostItem {
  const UserPostItem({
    required this.id,
    required this.coverUrl,
    required this.likeCount,
  });

  final int id;
  final String coverUrl;
  final int likeCount;

  factory UserPostItem.fromJson(Json json) {
    final images = (json['images'] as List?) ?? const [];
    final first = images.isNotEmpty ? Json.from(images.first) : const {};
    return UserPostItem(
      id: int.tryParse('${json['post_id'] ?? json['id'] ?? 0}') ?? 0,
      coverUrl: '${first['url'] ?? json['cover_url'] ?? ''}',
      likeCount: int.tryParse('${json['like_count'] ?? 0}') ?? 0,
    );
  }
}

class UserVideoItem {
  const UserVideoItem({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.playCount,
    required this.likeCount,
  });

  final int id;
  final String title;
  final String coverUrl;
  final int playCount;
  final int likeCount;

  factory UserVideoItem.fromJson(Json json) {
    return UserVideoItem(
      id: int.tryParse('${json['id'] ?? json['video_id'] ?? 0}') ?? 0,
      title: '${json['title'] ?? ''}',
      coverUrl: '${json['cover_url'] ?? ''}',
      playCount: int.tryParse('${json['play_count'] ?? 0}') ?? 0,
      likeCount: int.tryParse('${json['like_count'] ?? 0}') ?? 0,
    );
  }
}

class InterestTag {
  const InterestTag({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.category,
    required this.isSelected,
  });

  final int id;
  final String name;
  final String iconUrl;
  final String category;
  final bool isSelected;

  factory InterestTag.fromJson(Json json) {
    return InterestTag(
      id: int.tryParse('${json['id'] ?? json['tag_id'] ?? 0}') ?? 0,
      name: '${json['name'] ?? json['tag_name'] ?? json['title'] ?? ''}',
      iconUrl: '${json['icon_url'] ?? json['icon'] ?? ''}',
      category: '${json['category'] ?? ''}',
      isSelected: json['is_selected'] == true || json['selected'] == true,
    );
  }
}

class FaqItem {
  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
  });

  final int id;
  final String question;
  final String answer;

  factory FaqItem.fromJson(Json json) {
    return FaqItem(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      question: '${json['question'] ?? json['title'] ?? ''}',
      answer: '${json['answer'] ?? json['content'] ?? ''}',
    );
  }
}

class FaqCategoryItem {
  const FaqCategoryItem({
    required this.category,
    required this.items,
  });

  final String category;
  final List<FaqItem> items;

  factory FaqCategoryItem.fromJson(Json json) {
    return FaqCategoryItem(
      category: '${json['category'] ?? ''}',
      items: List<Json>.from((json['items'] ?? []) as List).map(FaqItem.fromJson).toList(),
    );
  }
}

class BlockedKeywordItem {
  const BlockedKeywordItem({required this.keyword});

  final String keyword;

  factory BlockedKeywordItem.fromJson(dynamic value) {
    return BlockedKeywordItem(keyword: '$value');
  }
}

class NotificationUnreadCount {
  const NotificationUnreadCount({required this.system});

  final int system;

  factory NotificationUnreadCount.fromJson(Json json) {
    final data = Json.from(json['data'] ?? json);
    return NotificationUnreadCount(
      system: int.tryParse('${data['system'] ?? data['system_count'] ?? data['unread_count'] ?? 0}') ?? 0,
    );
  }
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.category,
    required this.title,
    required this.desc,
    required this.time,
    this.unread = false,
    this.detailTitle,
    this.detailContent,
    this.detailTime,
  });

  final int id;
  final String category;
  final String title;
  final String desc;
  final String time;
  final bool unread;
  final String? detailTitle;
  final String? detailContent;
  final String? detailTime;

  factory NotificationItem.fromJson(Json json) {
    return NotificationItem(
      id: int.tryParse('${json['id'] ?? json['notification_id'] ?? 0}') ?? 0,
      category: '${json['category'] ?? json['type'] ?? ''}',
      title: '${json['title'] ?? json['name'] ?? ''}',
      desc: '${json['desc'] ?? json['content'] ?? json['message'] ?? ''}',
      time: '${json['time'] ?? json['created_at'] ?? ''}',
      unread: json['unread'] == true || json['is_read'] == false,
      detailTitle: '${json['detail_title'] ?? json['title'] ?? ''}',
      detailContent: '${json['detail_content'] ?? json['content'] ?? json['message'] ?? ''}',
      detailTime: '${json['detail_time'] ?? json['time'] ?? json['created_at'] ?? ''}',
    );
  }
}

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<NotificationItem> items;
  final String? nextCursor;
  final bool hasMore;

  factory NotificationPage.fromJson(Json json) {
    final list = (json['lists'] as List?) ?? const [];
    final nextCursorRaw = json['next_cursor'];
    return NotificationPage(
      items: list.map((e) => NotificationItem.fromJson(Json.from(e))).toList(),
      nextCursor: nextCursorRaw is String && nextCursorRaw.isNotEmpty ? nextCursorRaw : null,
      hasMore: json['has_more'] == true,
    );
  }
}

class RecommendedUser {
  const RecommendedUser({
    required this.uid,
    required this.username,
    required this.nickname,
    required this.avatarUrl,
    required this.bio,
    required this.isVerified,
    required this.followerCount,
    required this.isFollowing,
  });

  final int uid;
  final String username;
  final String nickname;
  final String avatarUrl;
  final String bio;
  final bool isVerified;
  final int followerCount;
  final bool isFollowing;

  factory RecommendedUser.fromJson(Json json) {
    return RecommendedUser(
      uid: int.tryParse('${json['uid'] ?? 0}') ?? 0,
      username: '${json['username'] ?? ''}',
      nickname: '${json['nickname'] ?? ''}',
      avatarUrl: '${json['avatar_url'] ?? ''}',
      bio: '${json['bio'] ?? ''}',
      isVerified: json['is_verified'] == true,
      followerCount: int.tryParse('${json['follower_count'] ?? 0}') ?? 0,
      isFollowing: json['is_following'] == true,
    );
  }
}

/// `GET /users/{uid}/followings` / `/followers` / `/mutual` 返回的列表项。
///
/// 三条接口字段大体一致——`mutual` 没有 `is_friend / followed_at`，
/// `followers` 与 `followings` 多一个 `followed_at` 时间戳。这里取并集表达。
class FollowedUser {
  const FollowedUser({
    required this.uid,
    required this.username,
    required this.nickname,
    required this.avatarUrl,
    required this.bio,
    required this.isVerified,
    required this.isFollowing,
    required this.isFriend,
    this.followedAt,
  });

  final int uid;
  final String username;
  final String nickname;
  final String avatarUrl;
  final String bio;
  final bool isVerified;

  /// 当前登录用户是否已关注该 user。
  /// - followings 列表恒为 true；
  /// - followers 列表为是否「回关」状态；
  /// - mutual 列表恒为 true。
  final bool isFollowing;

  /// 是否互相关注。`mutual` 接口没有该字段，取 `is_following && is_friend` 兜底。
  final bool isFriend;

  /// 关注时间，仅 followings/followers 返回。
  final String? followedAt;

  factory FollowedUser.fromJson(Json json) {
    return FollowedUser(
      uid: int.tryParse('${json['uid'] ?? 0}') ?? 0,
      username: '${json['username'] ?? ''}',
      nickname: '${json['nickname'] ?? ''}',
      avatarUrl: '${json['avatar_url'] ?? ''}',
      bio: json['bio']?.toString() ?? '',
      isVerified: json['is_verified'] == true,
      isFollowing: json['is_following'] == true,
      isFriend: json['is_friend'] == true,
      followedAt: json['followed_at']?.toString(),
    );
  }

  FollowedUser copyWith({
    bool? isFollowing,
    bool? isFriend,
  }) =>
      FollowedUser(
        uid: uid,
        username: username,
        nickname: nickname,
        avatarUrl: avatarUrl,
        bio: bio,
        isVerified: isVerified,
        isFollowing: isFollowing ?? this.isFollowing,
        isFriend: isFriend ?? this.isFriend,
        followedAt: followedAt,
      );
}

/// 关注 / 粉丝 列表的分页结果（mutual 没有分页字段，[hasMore] 永远 false）。
class FollowedUsersPage {
  const FollowedUsersPage({
    required this.lists,
    this.nextCursor,
    this.hasMore = false,
    this.total,
  });

  final List<FollowedUser> lists;
  final String? nextCursor;
  final bool hasMore;
  final int? total;

  factory FollowedUsersPage.fromJson(Json json) {
    final raw = json['lists'];
    final list = <FollowedUser>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) list.add(FollowedUser.fromJson(Json.from(e)));
      }
    }
    return FollowedUsersPage(
      lists: list,
      nextCursor: json['next_cursor']?.toString(),
      hasMore: json['has_more'] == true,
      total: int.tryParse('${json['total'] ?? json['count'] ?? ''}'),
    );
  }
}

class ReportTypeItem {
  const ReportTypeItem({required this.id, required this.name});

  final int id;
  final String name;

  factory ReportTypeItem.fromJson(Json json) {
    return ReportTypeItem(
      id: json['id'] as int,
      name: '${json['name'] ?? ''}',
    );
  }
}

class PrivacySettings {
  const PrivacySettings({
    required this.whoCanFollow,
    required this.whoCanMessage,
    required this.whoCanMention,
    required this.showFollowingList,
    required this.showFollowerList,
    required this.showLikeCount,
  });

  final String whoCanFollow;
  final String whoCanMessage;
  final String whoCanMention;
  final bool showFollowingList;
  final bool showFollowerList;
  final bool showLikeCount;

  factory PrivacySettings.fromJson(Json json) {
    return PrivacySettings(
      whoCanFollow: '${json['who_can_follow'] ?? ''}',
      whoCanMessage: '${json['who_can_message'] ?? ''}',
      whoCanMention: '${json['who_can_mention'] ?? ''}',
      showFollowingList: json['show_following_list'] == true,
      showFollowerList: json['show_follower_list'] == true,
      showLikeCount: json['show_like_count'] == true,
    );
  }

  PrivacySettings copyWith({
    String? whoCanFollow,
    String? whoCanMessage,
    String? whoCanMention,
    bool? showFollowingList,
    bool? showFollowerList,
    bool? showLikeCount,
  }) {
    return PrivacySettings(
      whoCanFollow: whoCanFollow ?? this.whoCanFollow,
      whoCanMessage: whoCanMessage ?? this.whoCanMessage,
      whoCanMention: whoCanMention ?? this.whoCanMention,
      showFollowingList: showFollowingList ?? this.showFollowingList,
      showFollowerList: showFollowerList ?? this.showFollowerList,
      showLikeCount: showLikeCount ?? this.showLikeCount,
    );
  }

  Json toJson() => <String, dynamic>{
        'who_can_follow': whoCanFollow,
        'who_can_message': whoCanMessage,
        'who_can_mention': whoCanMention,
        'show_following_list': showFollowingList,
        'show_follower_list': showFollowerList,
        'show_like_count': showLikeCount,
      };
}

class NotificationSettings {
  const NotificationSettings({
    required this.notifyFollow,
    required this.notifyLike,
    required this.notifyComment,
    required this.notifyMention,
    required this.notifySystem,
    required this.pushEnabled,
  });

  final bool notifyFollow;
  final bool notifyLike;
  final bool notifyComment;
  final bool notifyMention;
  final bool notifySystem;
  final bool pushEnabled;

  factory NotificationSettings.fromJson(Json json) => NotificationSettings(
        notifyFollow: json['notify_follow'] == true,
        notifyLike: json['notify_like'] == true,
        notifyComment: json['notify_comment'] == true,
        notifyMention: json['notify_mention'] == true,
        notifySystem: json['notify_system'] == true,
        pushEnabled: json['push_enabled'] == true,
      );

  NotificationSettings copyWith({
    bool? notifyFollow,
    bool? notifyLike,
    bool? notifyComment,
    bool? notifyMention,
    bool? notifySystem,
    bool? pushEnabled,
  }) {
    return NotificationSettings(
      notifyFollow: notifyFollow ?? this.notifyFollow,
      notifyLike: notifyLike ?? this.notifyLike,
      notifyComment: notifyComment ?? this.notifyComment,
      notifyMention: notifyMention ?? this.notifyMention,
      notifySystem: notifySystem ?? this.notifySystem,
      pushEnabled: pushEnabled ?? this.pushEnabled,
    );
  }
}

class ContentPrefSettings {
  const ContentPrefSettings({
    required this.safeMode,
    required this.autoPlayVideo,
    required this.preferredLang,
  });

  final bool safeMode;
  final bool autoPlayVideo;
  final String preferredLang;

  factory ContentPrefSettings.fromJson(Json json) => ContentPrefSettings(
        safeMode: json['safe_mode'] == true,
        autoPlayVideo: json['auto_play_video'] == true,
        preferredLang: '${json['preferred_lang'] ?? ''}',
      );
}

class GeneralSettings {
  const GeneralSettings({
    required this.darkMode,
    required this.locale,
    required this.notificationSound,
  });

  final String darkMode;
  final String locale;
  final bool notificationSound;

  factory GeneralSettings.fromJson(Json json) => GeneralSettings(
        darkMode: '${json['dark_mode'] ?? ''}',
        locale: '${json['locale'] ?? ''}',
        notificationSound: json['notification_sound'] == true,
      );
}

class AppSettings {
  const AppSettings({
    required this.privacy,
    required this.notification,
    required this.contentPref,
    required this.general,
  });

  final PrivacySettings privacy;
  final NotificationSettings notification;
  final ContentPrefSettings contentPref;
  final GeneralSettings general;

  factory AppSettings.fromJson(Json json) {
    final data = Json.from(json['data'] ?? json);
    return AppSettings(
      privacy: PrivacySettings.fromJson(Json.from(data['privacy'] ?? {})),
      notification: NotificationSettings.fromJson(Json.from(data['notification'] ?? {})),
      contentPref: ContentPrefSettings.fromJson(Json.from(data['content_pref'] ?? {})),
      general: GeneralSettings.fromJson(Json.from(data['general'] ?? {})),
    );
  }

  AppSettings copyWith({
    PrivacySettings? privacy,
    NotificationSettings? notification,
    ContentPrefSettings? contentPref,
    GeneralSettings? general,
  }) {
    return AppSettings(
      privacy: privacy ?? this.privacy,
      notification: notification ?? this.notification,
      contentPref: contentPref ?? this.contentPref,
      general: general ?? this.general,
    );
  }
}

enum ImageUploadScene {
  post,
  postCover,
  avatar,
  cover,
  videoCover,
  chat,
  message,
  reportEvidence,
  feedbackScreenshot,
}

extension ImageUploadSceneX on ImageUploadScene {
  String get value => switch (this) {
        ImageUploadScene.post => 'post',
        ImageUploadScene.postCover => 'post_cover',
        ImageUploadScene.avatar => 'avatar',
        ImageUploadScene.cover => 'cover',
        ImageUploadScene.videoCover => 'video_cover',
        ImageUploadScene.chat => 'chat',
        ImageUploadScene.message => 'message',
        ImageUploadScene.reportEvidence => 'report_evidence',
        ImageUploadScene.feedbackScreenshot => 'feedback_screenshot',
      };
}

class UploadedImagePayload {
  const UploadedImagePayload({
    required this.objectKey,
    required this.downloadUrl,
  });

  final String objectKey;
  final String downloadUrl;
}
