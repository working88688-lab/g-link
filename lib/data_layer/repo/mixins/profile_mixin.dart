part of '../repo.dart';

mixin _Profile on _BaseAppRepo implements ProfileDomain {
  @override
  AsyncResult<UserProfile> getUserProfile({required int uid}) =>
      _profileService.getUserProfile(uid: uid).deserializeJsonBy((json) => UserProfile.fromJson(Json.from(json))).guard;

  @override
  AsyncResult<UserProfile> getMyProfile() =>
      _profileService.getMyProfile().deserializeJsonBy((json) => UserProfile.fromJson(Json.from(json))).guard;

  @override
  AsyncResult<List<UserVideoItem>> getUserVideos({
    required int uid,
    String? cursor,
    int? limit,
  }) =>
      _profileService.getUserVideos(uid: uid, cursor: cursor, limit: limit).deserializeJsonBy((json) {
        final list = List<Json>.from((json['list'] ?? []) as List);
        return list.map(UserVideoItem.fromJson).toList();
      }).guard;

  @override
  AsyncResult<List<UserPostItem>> getUserPosts({
    required int uid,
    String? cursor,
    int? limit,
  }) =>
      _profileService.getUserPosts(uid: uid, cursor: cursor, limit: limit).deserializeJsonBy((json) {
        final list = List<Json>.from((json['list'] ?? []) as List);
        return list.map(UserPostItem.fromJson).toList();
      }).guard;

  @override
  AsyncResult<List<UserPostItem>> getUserLikes({
    required int uid,
    String? cursor,
    int? limit,
  }) =>
      _profileService.getUserLikes(uid: uid, cursor: cursor, limit: limit).deserializeJsonBy((json) {
        final list = List<Json>.from((json['list'] ?? []) as List);
        return list.map(UserPostItem.fromJson).toList();
      }).guard;

  @override
  AsyncResult<List<UserVideoItem>> getMyVideos({
    String? cursor,
    int? limit,
  }) =>
      _profileService.getMyVideos(cursor: cursor, limit: limit).deserializeJsonBy((json) {
        final list = List<Json>.from((json['list'] ?? []) as List);
        return list.map(UserVideoItem.fromJson).toList();
      }).guard;

  @override
  AsyncResult<List<UserPostItem>> getMyPosts({
    String? cursor,
    int? limit,
  }) =>
      _profileService.getMyPosts(cursor: cursor, limit: limit).deserializeJsonBy((json) {
        final list = List<Json>.from((json['list'] ?? []) as List);
        return list.map(UserPostItem.fromJson).toList();
      }).guard;

  @override
  AsyncResult<List<UserPostItem>> getMyLikes({
    String? cursor,
    int? limit,
  }) =>
      _profileService.getMyLikes(cursor: cursor, limit: limit).deserializeJsonBy((json) {
        final list = List<Json>.from((json['list'] ?? []) as List);
        return list.map(UserPostItem.fromJson).toList();
      }).guard;

  @override
  AsyncResult<AppSettings> getMySettings() =>
      _profileService.getMySettings().deserializeJsonBy((json) => AppSettings.fromJson(Json.from(json))).guard;

  @override
  AsyncResult<AppSettings> updatePrivacySettings({
    String? whoCanFollow,
    String? whoCanMessage,
    String? whoCanMention,
    bool? showFollowingList,
    bool? showFollowerList,
    bool? showLikeCount,
  }) =>
      _profileService
          .updatePrivacySettings(
            whoCanFollow: whoCanFollow,
            whoCanMessage: whoCanMessage,
            whoCanMention: whoCanMention,
            showFollowingList: showFollowingList,
            showFollowerList: showFollowerList,
            showLikeCount: showLikeCount,
          )
          .deserializeJsonBy((json) => AppSettings.fromJson(Json.from(json)))
          .guard;

  @override
  AsyncResult<AppSettings> updateNotificationSettings({
    bool? notifyFollow,
    bool? notifyLike,
    bool? notifyComment,
    bool? notifyMention,
    bool? notifySystem,
    bool? pushEnabled,
  }) =>
      _profileService
          .updateNotificationSettings(
            notifyFollow: notifyFollow,
            notifyLike: notifyLike,
            notifyComment: notifyComment,
            notifyMention: notifyMention,
            notifySystem: notifySystem,
            pushEnabled: pushEnabled,
          )
          .deserializeJsonBy((json) => AppSettings.fromJson(Json.from(json)))
          .guard;

  @override
  AsyncResult<List<InterestTag>> getInterestTags() => _profileService.getInterests().deserializeJsonBy((json) {
        final list = List<Json>.from((json['list'] ?? []) as List);
        return list.map(InterestTag.fromJson).toList();
      }).guard;

  @override
  AsyncResult<List<RecommendedUser>> getRecommendedUsers({int limit = 20}) =>
      _profileService.getRecommendedUsers(limit: limit).deserializeJsonBy((json) {
        final list = List<Json>.from((json['lists'] ?? []) as List);
        return list.map(RecommendedUser.fromJson).toList();
      }).guard;

  @override
  AsyncResult<FollowResult> followUser({required int uid}) =>
      _profileService.followUser(uid: uid).deserializeJsonBy((json) => FollowResult.fromJson(Json.from(json))).guard;

  @override
  AsyncResult<FollowResult> unfollowUser({required int uid}) =>
      _profileService.unfollowUser(uid: uid).deserializeJsonBy((json) => FollowResult.fromJson(Json.from(json))).guard;

  @override
  AsyncResult updateMyProfile({
    String? nickname,
    String? username,
    String? bio,
    String? location,
    String? avatarUrl,
    String? coverUrl,
  }) =>
      _profileService
          .updateMyProfile(
            nickname: nickname,
            username: username,
            bio: bio,
            location: location,
            avatarUrl: avatarUrl,
            coverUrl: coverUrl,
          )
          .deserialize()
          .guard;

  @override
  AsyncResult<UploadedImagePayload> uploadImageByPresign({
    required Uint8List bytes,
    required String fileExt,
    required int fileSize,
    required ImageUploadScene scene,
  }) async {
    try {
      final url = await _profileService.uploadImageByPresign(
        bytes: bytes,
        fileExt: fileExt,
        fileSize: fileSize,
        scene: scene,
      );
      return Result<UploadedImagePayload>(status: 0, msg: 'success', data: url);
    } catch (err) {
      return Result<UploadedImagePayload>(status: -1, msg: err.toString());
    }
  }

  @override
  AsyncResult submitOnboardingInterests({
    required List<int> tagIds,
  }) =>
      _profileService.submitOnboardingInterests(tagIds: tagIds).deserialize().guard;

  @override
  AsyncResult completeOnboarding() => _profileService.completeOnboarding().deserialize().guard;

  @override
  Future<UserProfile?> readCachedMyProfile() async {
    final json = await _cacheManager.readMyProfile();
    if (json == null) return null;
    try {
      return UserProfile.fromJson(json);
    } catch (_) {
      // 缓存结构损坏直接当作没缓存，避免持续抛出影响首屏。
      return null;
    }
  }

  @override
  Future<void> cacheMyProfile(UserProfile profile) => _cacheManager.upsertMyProfile(profile.toJson());

  @override
  Future<void> clearCachedMyProfile() => _cacheManager.deleteMyProfile();
}
