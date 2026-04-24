part of '../repo.dart';

mixin _Profile on _BaseAppRepo implements ProfileDomain {
  @override
  AsyncResult<UserProfile> getUserProfile({required int uid}) => _profileService
      .getUserProfile(uid: uid)
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
  AsyncResult<List<InterestTag>> getInterestTags() =>
      _profileService.getInterests().deserializeJsonBy((json) {
        final list = List<Json>.from((json['list'] ?? []) as List);
        return list.map(InterestTag.fromJson).toList();
      }).guard;
}
