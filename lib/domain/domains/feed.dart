import 'package:g_link/domain/model/feed_models.dart';
import 'package:g_link/domain/type_def.dart';

/// 首页 Feed 业务接口。返回 [Result] 包装，失败统一进 `msg` 字段。
abstract class FeedDomain {
  /// 推荐流。`cursor` 为空表示拉首屏。
  AsyncResult<FeedPage<FeedPost>> getRecommendFeed({
    String? cursor,
    int limit,
  });

  /// 热门流。
  AsyncResult<FeedPage<FeedPost>> getHotFeed({
    String? cursor,
    int limit,
  });

  /// 关注流。
  AsyncResult<FeedPage<FeedPost>> getFollowFeed({
    String? cursor,
    int limit,
  });

  /// 点赞帖子。
  AsyncResult<LikeResult> likePost({required int postId});

  /// 取消点赞。
  AsyncResult<LikeResult> unlikePost({required int postId});
}
