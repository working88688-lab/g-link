import 'package:g_link/domain/type_def.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.nickname,
    required this.avatarUrl,
    required this.bio,
    required this.followingCount,
    required this.followerCount,
    required this.likeCount,
    required this.postCount,
    required this.videoCount,
  });

  final int uid;
  final String nickname;
  final String avatarUrl;
  final String bio;
  final int followingCount;
  final int followerCount;
  final int likeCount;
  final int postCount;
  final int videoCount;

  factory UserProfile.fromJson(Json json) {
    final stats = Json.from(json['stats'] ?? {});
    return UserProfile(
      uid: int.tryParse('${json['uid'] ?? 0}') ?? 0,
      nickname: '${json['nickname'] ?? ''}',
      avatarUrl: '${json['avatar_url'] ?? ''}',
      bio: '${json['bio'] ?? ''}',
      followingCount: int.tryParse('${stats['following_count'] ?? 0}') ?? 0,
      followerCount: int.tryParse('${stats['follower_count'] ?? 0}') ?? 0,
      likeCount: int.tryParse('${stats['like_count'] ?? 0}') ?? 0,
      postCount: int.tryParse('${stats['post_count'] ?? 0}') ?? 0,
      videoCount: int.tryParse('${stats['video_count'] ?? 0}') ?? 0,
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
    required this.category,
    required this.isSelected,
  });

  final int id;
  final String name;
  final String category;
  final bool isSelected;

  factory InterestTag.fromJson(Json json) {
    return InterestTag(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      name: '${json['name'] ?? ''}',
      category: '${json['category'] ?? ''}',
      isSelected: json['is_selected'] == true,
    );
  }
}
