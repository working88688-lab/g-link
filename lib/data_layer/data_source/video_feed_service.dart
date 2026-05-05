import 'package:g_link/domain/model/video_feed_models.dart';
import 'package:g_link/domain/type_def.dart';

import 'base_service.dart';

class VideoFeedService extends BaseService {
  VideoFeedService(super._dio);

  @override
  final service = 'v1';

  Future<VideoFeedPage<VideoFeedItem>> fetchVideoFeed({
    required String tab,
    String? cursor,
    int limit = 10,
  }) async {
    final params = <String, dynamic>{'tab': tab, 'limit': limit};
    if (cursor != null && cursor.isNotEmpty) params['cursor'] = cursor;

    final res = await get('/videos/feed', queryParameters: params, encrypted: false);
    final data = res['data'] as Map<String, dynamic>? ?? res;
    final items = (data['lists'] as List<dynamic>? ?? const [])
        .map((e) => VideoFeedItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return VideoFeedPage(
      items: items,
      nextCursor: data['next_cursor'] as String?,
      hasMore: (data['has_more'] as bool?) ?? false,
    );
  }
}
