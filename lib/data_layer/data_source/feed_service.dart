import 'package:g_link/domain/type_def.dart';

import 'base_service.dart';

/// 首页 Feed 相关接口（推荐流 / 热门流 / 关注流 / 点赞）。
///
/// 全部走 `/api/v1/...`，并设置 `encrypted: false`：feed/like 接口
/// 后端返回是明文 JSON，跳过自动解密拦截器避免 `WRONG_FINAL_BLOCK_LENGTH` 误伤。
class FeedService extends BaseService {
  FeedService(super._dio);

  @override
  final service = 'v1';

  /// 推荐流（基于 Gorse 推荐引擎，降级到热度+时间排序）。
  /// 文档定义：cursor 是 offset 数字字符串，首页不传。
  AsyncJson getRecommendFeed({String? cursor, int limit = 20}) => get(
        '/feed/recommend',
        queryParameters: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          'limit': limit,
        },
        encrypted: false,
      );

  AsyncJson getHotFeed({String? cursor, int limit = 20}) => get(
        '/feed/hot',
        queryParameters: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          'limit': limit,
        },
        encrypted: false,
      );

  AsyncJson getFollowFeed({String? cursor, int limit = 20}) => get(
        '/feed/follow',
        queryParameters: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          'limit': limit,
        },
        encrypted: false,
      );

  AsyncJson likePost({required int postId}) => post(
        '/posts/$postId/like',
        data: const <String, dynamic>{},
        encrypted: false,
      );

  AsyncJson unlikePost({required int postId}) => delete(
        '/posts/$postId/like',
        encrypted: false,
      );

  /// 获取单张图片上传预签名（直传 MinIO/OSS），参见 `POST /api/v1/upload/presign`。
  AsyncJson presignUpload({
    required String fileExt,
    required int fileSize,
    required String scene,
  }) =>
      post(
        '/upload/presign',
        data: {
          'file_ext': fileExt,
          'file_size': fileSize,
          'scene': scene,
        },
        encrypted: false,
      );

  /// 发布帖子，参见 `POST /api/v1/posts`。
  AsyncJson publishPost(Json body) => post(
        '/posts',
        data: body,
        encrypted: false,
      );

  /// 保存草稿，参见 `POST /api/v1/drafts`。
  ///
  /// `type` 为必填（`post` / `video`），其它字段全部可选——服务端按现状落库，
  /// 客户端无需自行管理 id 映射，每次都建一条新记录即可。
  AsyncJson saveDraft(Json body) => post(
        '/drafts',
        data: body,
        encrypted: false,
      );

  /// 草稿列表，参见 `GET /api/v1/drafts`。
  ///
  /// `type`：`post` / `video` / `all`（默认 all）。游标分页按 id 倒序，
  /// 列表项只返摘要（封面 + 前 50 字预览）。
  AsyncJson getDrafts({
    String? type,
    String? cursor,
    int limit = 20,
  }) =>
      get(
        '/drafts',
        queryParameters: {
          if (type != null && type.isNotEmpty) 'type': type,
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          'limit': limit,
        },
        encrypted: false,
      );

  /// 删除草稿，参见 `DELETE /api/v1/drafts/{id}`。
  ///
  /// 仅允许删除本人草稿；他人草稿返回 `DRAFT_NO_PERMISSION` 而不是 404。
  AsyncJson deleteDraft({required int draftId}) => delete(
        '/drafts/$draftId',
        encrypted: false,
      );
}
