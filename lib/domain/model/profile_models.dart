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

  factory UserProfile.fromJson(Json json) {
    final stats = Json.from(json['stats'] ?? {});
    String displayOf(String key, int value) =>
        '${stats['${key}_display'] ?? value}';
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
    };
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
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      name: '${json['name'] ?? ''}',
      iconUrl: '${json['icon_url'] ?? ''}',
      category: '${json['category'] ?? ''}',
      isSelected: json['is_selected'] == true,
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
}

class UploadedImagePayload {
  const UploadedImagePayload({
    required this.objectKey,
    required this.downloadUrl,
  });

  final String objectKey;
  final String downloadUrl;
}
