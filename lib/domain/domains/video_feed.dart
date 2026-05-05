import 'package:g_link/domain/model/video_feed_models.dart';
import 'package:g_link/domain/type_def.dart';

abstract class VideoFeedDomain {
  Future<VideoFeedPage<VideoFeedItem>> getVideoFeed({
    required String tab,
    String? cursor,
    int limit,
  });
}
