part of '../repo.dart';

mixin _VideoFeed on _BaseAppRepo implements VideoFeedDomain {
  @override
  Future<VideoFeedPage<VideoFeedItem>> getVideoFeed({
    required String tab,
    String? cursor,
    int limit = 10,
  }) async {
    return await _videoFeedService.fetchVideoFeed(
      tab: tab,
      cursor: cursor,
      limit: limit,
    );
  }

  @override
  Future<VideoFeedItem> getVideoDetail(int videoId) async {
    return await _videoFeedService.fetchVideoDetail(videoId);
  }

  @override
  Future<VideoFeedLikeActionResult> likeVideo(int videoId) async {
    return await _videoFeedService.likeVideo(videoId);
  }

  @override
  Future<VideoFeedLikeActionResult> unlikeVideo(int videoId) async {
    return await _videoFeedService.unlikeVideo(videoId);
  }

  @override
  Future<VideoFeedFavoriteActionResult> favoriteVideo(int videoId) async {
    return await _videoFeedService.favoriteVideo(videoId);
  }

  @override
  Future<VideoFeedFavoriteActionResult> unfavoriteVideo(int videoId) async {
    return await _videoFeedService.unfavoriteVideo(videoId);
  }
}
