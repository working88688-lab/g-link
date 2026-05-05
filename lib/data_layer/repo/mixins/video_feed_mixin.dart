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
}
