import 'dart:typed_data';

import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/domain/type_def.dart';

abstract class ProfileDomain {
  AsyncResult<UserProfile> getUserProfile({required int uid});
  AsyncResult<UserProfile> getMyProfile();

  AsyncResult<List<UserVideoItem>> getUserVideos({
    required int uid,
    String? cursor,
    int? limit,
  });
  AsyncResult<List<UserPostItem>> getUserPosts({
    required int uid,
    String? cursor,
    int? limit,
  });
  AsyncResult<List<UserPostItem>> getUserLikes({
    required int uid,
    String? cursor,
    int? limit,
  });
  AsyncResult<List<UserVideoItem>> getMyVideos({
    String? cursor,
    int? limit,
  });
  AsyncResult<List<UserPostItem>> getMyPosts({
    String? cursor,
    int? limit,
  });
  AsyncResult<List<UserPostItem>> getMyLikes({
    String? cursor,
    int? limit,
  });

  AsyncResult<List<InterestTag>> getInterestTags();

  AsyncResult<List<RecommendedUser>> getRecommendedUsers({int limit = 20});
  AsyncResult updateMyProfile({
    String? nickname,
    String? username,
    String? bio,
    String? location,
    String? avatarUrl,
    String? coverUrl,
  });
  AsyncResult<UploadedImagePayload> uploadImageByPresign({
    required Uint8List bytes,
    required String fileExt,
    required int fileSize,
    required String scene,
  });
  AsyncResult submitOnboardingInterests({
    required List<int> tagIds,
  });

  AsyncResult completeOnboarding();

  /// 读取上次缓存的"我的"个人资料；冷启动 MinePage 时优先用它先把 UI 填上，
  /// 避免用户每次进个人主页都看到一段 loading。
  Future<UserProfile?> readCachedMyProfile();

  /// 把网络拿到的最新资料写到本地，下次冷启动可以零等待复用。
  Future<void> cacheMyProfile(UserProfile profile);

  /// 退出登录或被踢下线时调用，避免下个账号看到上一个用户的缓存。
  Future<void> clearCachedMyProfile();
}
