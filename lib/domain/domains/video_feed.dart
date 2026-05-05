import 'package:g_link/domain/model/video_feed_models.dart';

abstract class VideoFeedDomain {
  Future<VideoFeedPage<VideoFeedItem>> getVideoFeed({
    required String tab,
    String? cursor,
    int limit,
  });

  Future<VideoFeedItem> getVideoDetail(int videoId);
  Future<VideoFeedLikeActionResult> likeVideo(int videoId);
  Future<VideoFeedLikeActionResult> unlikeVideo(int videoId);
  Future<VideoFeedFavoriteActionResult> favoriteVideo(int videoId);
  Future<VideoFeedFavoriteActionResult> unfavoriteVideo(int videoId);
}
