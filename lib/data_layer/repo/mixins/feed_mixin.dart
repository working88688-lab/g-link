part of '../repo.dart';

mixin _Feed on _BaseAppRepo implements FeedDomain {
  @override
  AsyncResult<FeedPage<FeedPost>> getRecommendFeed({
    String? cursor,
    int limit = 20,
  }) =>
      _feedService
          .getRecommendFeed(cursor: cursor, limit: limit)
          .deserializeJsonBy(
              (json) => FeedPage.fromJson(Json.from(json), FeedPost.fromJson))
          .guard;

  @override
  AsyncResult<FeedPage<FeedPost>> getHotFeed({
    String? cursor,
    int limit = 20,
  }) =>
      _feedService
          .getHotFeed(cursor: cursor, limit: limit)
          .deserializeJsonBy(
              (json) => FeedPage.fromJson(Json.from(json), FeedPost.fromJson))
          .guard;

  @override
  AsyncResult<FeedPage<FeedPost>> getFollowFeed({
    String? cursor,
    int limit = 20,
  }) =>
      _feedService
          .getFollowFeed(cursor: cursor, limit: limit)
          .deserializeJsonBy(
              (json) => FeedPage.fromJson(Json.from(json), FeedPost.fromJson))
          .guard;

  @override
  AsyncResult<LikeResult> likePost({required int postId}) => _feedService
      .likePost(postId: postId)
      .deserializeJsonBy((json) => LikeResult.fromJson(Json.from(json)))
      .guard;

  @override
  AsyncResult<LikeResult> unlikePost({required int postId}) => _feedService
      .unlikePost(postId: postId)
      .deserializeJsonBy((json) => LikeResult.fromJson(Json.from(json)))
      .guard;
}
