import 'package:cross_file/cross_file.dart';
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

  /// 发布图文：按接口文档 `POST /api/v1/upload/presign` 逐张直传后 `POST /api/v1/posts`。
  AsyncResult<PublishPostResult> publishImagePost({
    required String content,
    required List<XFile> images,
    int coverImageIndex = 0,
    List<String>? tags,
    List<int>? mentionedUids,
    int visibility = 0,
    int allowComment = 0,
    int? draftId,
    PublishLocationInput? location,
  });

  /// 发布短视频完整链路：
  /// `POST /videos/upload-presign` → PUT 直传 → `POST /videos/upload-done` →
  /// （可选）`POST /publish/video/cover-from-frame` 截帧 →
  /// 轮询 `GET /videos/{id}/transcode-status` 直至 2(完成) →
  /// `POST /videos/{id}/publish`。
  ///
  /// 任一步失败时 [Result.msg] 会带回 i18n key（见 `publishVideo*`）或后端原文。
  AsyncResult<PublishVideoResult> publishVideoPost({
    required XFile video,
    required String description,
    required int durationMs,
    required int width,
    required int height,
    String? title,
    List<String>? tags,
    int visibility = 0,
    int? bgmId,
    int coverFrameTimeMs = 0,
    PublishLocationInput? location,
    void Function(int sent, int total)? onUploadProgress,
  });

  /// 保存草稿：`POST /api/v1/drafts`。
  ///
  /// 服务端按现状落库（30 天自动清理），无需自管 id 映射；返回新建的 `draft_id`。
  /// `type` = `post` / `video`；`mediaData` / `settings` 是自由结构 JSON，
  /// 见 OpenAPI «保存草稿» 描述。
  AsyncResult<SaveDraftResult> saveDraft({
    required String type,
    String? title,
    String? content,
    Json? mediaData,
    Json? settings,
  });

  /// 草稿列表：`GET /api/v1/drafts`。
  ///
  /// `type` 为 `post` / `video` / `all`（默认 all）；游标分页按 id 倒序，
  /// 仅返回摘要（封面 + 前 50 字预览），详情走 `GET /drafts/{id}`。
  AsyncResult<List<DraftItem>> getDrafts({
    String? type,
    String? cursor,
    int limit = 20,
  });

  /// 删除草稿：`DELETE /api/v1/drafts/{id}`。
  ///
  /// 仅允许删除本人草稿，他人草稿返回 `DRAFT_NO_PERMISSION`，便于客户端区分
  /// 「不存在」与「无权限」。
  AsyncResult<void> deleteDraft({required int draftId});

  /// 发布页热门话题（话题模块 `GET /api/v1/topics/hot`）。
  AsyncResult<List<PublishTopicRow>> getHotTopics();

  /// 发布页话题搜索（话题模块 `GET /api/v1/topics/search`）。
  AsyncResult<List<PublishTopicRow>> searchTopics(String query);
}
