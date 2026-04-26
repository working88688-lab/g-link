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
