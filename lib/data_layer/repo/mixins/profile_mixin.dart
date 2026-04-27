part of '../repo.dart';

mixin _Profile on _BaseAppRepo implements ProfileDomain {
  @override
  AsyncResult<UserProfile> getUserProfile({required int uid}) => _profileService
      .getUserProfile(uid: uid)
      .deserializeJsonBy((json) => UserProfile.fromJson(Json.from(json)))
      .guard;

  @override
  AsyncResult<UserProfile> getMyProfile() => _profileService
      .getMyProfile()
      .deserializeJsonBy((json) => UserProfile.fromJson(Json.from(json)))
      .guard;

  @override
  AsyncResult<List<UserVideoItem>> getUserVideos({
    required int uid,
    String? cursor,
    int? limit,
  }) =>
      _profileService
          .getUserVideos(uid: uid, cursor: cursor, limit: limit)
          .deserializeJsonBy((json) {
        final list = List<Json>.from((json['list'] ?? []) as List);
        return list.map(UserVideoItem.fromJson).toList();
      }).guard;

  @override
  AsyncResult<List<UserPostItem>> getUserPosts({
    required int uid,
    String? cursor,
    int? limit,
  }) =>
      _profileService
          .getUserPosts(uid: uid, cursor: cursor, limit: limit)
          .deserializeJsonBy((json) {
        final list = List<Json>.from((json['list'] ?? []) as List);
        return list.map(UserPostItem.fromJson).toList();
      }).guard;

  @override
  AsyncResult<List<UserPostItem>> getUserLikes({
    required int uid,
    String? cursor,
    int? limit,
  }) =>
      _profileService
          .getUserLikes(uid: uid, cursor: cursor, limit: limit)
          .deserializeJsonBy((json) {
        final list = List<Json>.from((json['list'] ?? []) as List);
        return list.map(UserPostItem.fromJson).toList();
      }).guard;

  @override
  AsyncResult<List<UserVideoItem>> getMyVideos({
    String? cursor,
    int? limit,
  }) =>
      _profileService
          .getMyVideos(cursor: cursor, limit: limit)
          .deserializeJsonBy((json) {
        final list = List<Json>.from((json['list'] ?? []) as List);
        return list.map(UserVideoItem.fromJson).toList();
      }).guard;

  @override
  AsyncResult<List<UserPostItem>> getMyPosts({
    String? cursor,
    int? limit,
  }) =>
      _profileService
          .getMyPosts(cursor: cursor, limit: limit)
          .deserializeJsonBy((json) {
        final list = List<Json>.from((json['list'] ?? []) as List);
        return list.map(UserPostItem.fromJson).toList();
      }).guard;

  @override
  AsyncResult<List<UserPostItem>> getMyLikes({
    String? cursor,
    int? limit,
  }) =>
      _profileService
          .getMyLikes(cursor: cursor, limit: limit)
          .deserializeJsonBy((json) {
        final list = List<Json>.from((json['list'] ?? []) as List);
        return list.map(UserPostItem.fromJson).toList();
      }).guard;

  @override
  AsyncResult<List<InterestTag>> getInterestTags() =>
      _profileService.getInterests().deserializeJsonBy((json) {
        final list = List<Json>.from((json['list'] ?? []) as List);
        return list.map(InterestTag.fromJson).toList();
      }).guard;

  @override
  AsyncResult<List<RecommendedUser>> getRecommendedUsers({int limit = 20}) =>
      _profileService
          .getRecommendedUsers(limit: limit)
          .deserializeJsonBy((json) {
        final list = List<Json>.from((json['lists'] ?? []) as List);
        return list.map(RecommendedUser.fromJson).toList();
      }).guard;
  AsyncResult submitOnboardingInterests({
    required List<int> tagIds,
  }) =>
      _profileService
          .submitOnboardingInterests(tagIds: tagIds)
          .deserialize()
          .guard;

  @override
  AsyncResult completeOnboarding() =>
      _profileService.completeOnboarding().deserialize().guard;
}
