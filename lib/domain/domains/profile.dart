import 'dart:typed_data';

import 'package:g_link/domain/model/feed_models.dart';
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

  /// 用户帖子列表「富数据」版本——直接返 [FeedPost]，复用 home feed 的卡片渲染。
  /// 同样命中 `GET /api/v1/users/{uid}/posts`，但保留 `images / content / tags
  /// / counts / is_liked / created_at` 全字段，配合「最新帖子」全屏列表页使用。
  AsyncResult<FeedPage<FeedPost>> getUserPostsFeed({
    required int uid,
    String? cursor,
    int? limit,
    String? sort,
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

  AsyncResult<AppSettings> getMySettings();

  AsyncResult<AppSettings> updatePrivacySettings({
    String? whoCanFollow,
    String? whoCanMessage,
    String? whoCanMention,
    bool? showFollowingList,
    bool? showFollowerList,
    bool? showLikeCount,
  });

  AsyncResult<AppSettings> updateNotificationSettings({
    bool? notifyFollow,
    bool? notifyLike,
    bool? notifyComment,
    bool? notifyMention,
    bool? notifySystem,
    bool? pushEnabled,
  });

  AsyncResult<List<InterestTag>> getInterestTags();
  AsyncResult<List<FaqCategoryItem>> getFaqCategories();
  AsyncResult<List<String>> getBlockedKeywords();
  AsyncResult addBlockedKeyword({required String keyword});
  AsyncResult deleteBlockedKeyword({required String keyword});
  AsyncResult<List<NotificationUnreadCount>> getNotificationUnreadCount();
  AsyncResult<List<NotificationItem>> getNotifications({String? category});
  AsyncResult markNotificationRead({required int id});
  AsyncResult markAllNotificationsRead();
  AsyncResult updateMyInterestTags({required List<int> tagIds});

  AsyncResult<List<RecommendedUser>> getRecommendedUsers({int limit = 20});

  /// 关注指定用户。返回最新关系快照（含双向 is_following / 粉丝数）。
  AsyncResult<FollowResult> followUser({required int uid});

  /// 取消关注指定用户。幂等接口：未关注调用也返回成功。
  AsyncResult<FollowResult> unfollowUser({required int uid});

  /// 拉黑用户。重复拉黑幂等，拉黑自己返回业务错误码 -10630。
  AsyncResult blockUser({required int uid});

  /// 解除拉黑。目标不在黑名单时由后端返回错误。
  AsyncResult unblockUser({required int uid});

  /// 关注列表。游标分页，`cursor = 上一页最后一条 follow_id`，首页留空。
  AsyncResult<FollowedUsersPage> getUserFollowings({
    required int uid,
    String? cursor,
    int limit = 30,
  });

  /// 粉丝列表。游标分页同 followings。
  AsyncResult<FollowedUsersPage> getUserFollowers({
    required int uid,
    String? cursor,
    int limit = 30,
  });

  /// 互关列表，最多 20 条；不分页。
  AsyncResult<FollowedUsersPage> getUserMutualFollows({required int uid});

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
    required ImageUploadScene scene,
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
