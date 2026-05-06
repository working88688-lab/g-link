import 'package:g_link/domain/type_def.dart';

import 'base_service.dart';

/// 短视频发布相关接口（OpenAPI «发布» 分组）。
///
/// 五条接口：
/// - `POST /api/v1/publish/video/cover-from-frame` 视频封面截帧
/// - `POST /api/v1/videos/upload-presign` 视频上传预签名
/// - `POST /api/v1/videos/upload-done` 视频上传完成回调
/// - `GET  /api/v1/videos/{videoId}/transcode-status` 查询转码状态
/// - `POST /api/v1/videos/{videoId}/publish` 发布视频
///
/// 与 [FeedService] 一致跳过加密拦截器：服务端返回为明文 JSON。
class VideoPublishService extends BaseService {
  VideoPublishService(super._dio);

  @override
  final service = 'v1';

  /// `POST /api/v1/videos/upload-presign`
  ///
  /// 客户端拿到 `upload_url` 后直接 `PUT` 上传到 MinIO/OSS，预签名 1 小时有效，
  /// 文件大小上限 500MB；上传成功后调用 [notifyUploadDone] 通知后端。
  AsyncJson presignVideoUpload({
    required String fileExt,
    required int fileSize,
    String? contentType,
    int? durationMs,
    int? width,
    int? height,
  }) =>
      post(
        '/videos/upload-presign',
        data: {
          'file_ext': fileExt,
          'file_size': fileSize,
          if (contentType != null && contentType.isNotEmpty)
            'content_type': contentType,
          if (durationMs != null) 'duration_ms': durationMs,
          if (width != null) 'width': width,
          if (height != null) 'height': height,
        },
        encrypted: false,
      );

  /// `POST /api/v1/videos/upload-done`
  ///
  /// PUT 上传完成后调用；后端创建视频记录并触发转码，返回 `video_id`
  /// 供后续 [getTranscodeStatus] 与 [publishVideo] 使用。
  ///
  /// 服务端校验 `object_key / duration_ms / width / height / file_size` 均为必填，
  /// `file_hash / cover_url` 可选。
  AsyncJson notifyUploadDone({
    required String objectKey,
    required int durationMs,
    required int width,
    required int height,
    required int fileSize,
    String? fileHash,
    String? coverUrl,
  }) =>
      post(
        '/videos/upload-done',
        data: {
          'object_key': objectKey,
          'duration_ms': durationMs,
          'width': width,
          'height': height,
          'file_size': fileSize,
          if (fileHash != null && fileHash.isNotEmpty) 'file_hash': fileHash,
          if (coverUrl != null && coverUrl.isNotEmpty) 'cover_url': coverUrl,
        },
        encrypted: false,
      );

  /// `GET /api/v1/videos/{videoId}/transcode-status`
  ///
  /// `transcode_status`：0 排队 / 1 转码中 / 2 完成 / 3 失败。
  AsyncJson getTranscodeStatus({required int videoId}) => get(
        '/videos/$videoId/transcode-status',
        encrypted: false,
      );

  /// `POST /api/v1/videos/{videoId}/publish`
  ///
  /// `body` 字段见 OpenAPI «发布视频»：title / description / cover_object_key /
  /// tags / mentioned_uids / visibility / allow_comment / location / draft_id 等。
  AsyncJson publishVideo({
    required int videoId,
    required Json body,
  }) =>
      post(
        '/videos/$videoId/publish',
        data: body,
        encrypted: false,
      );

  /// `POST /api/v1/publish/video/cover-from-frame`
  ///
  /// 服务端异步从指定时间点截帧并上传对象存储；返回 `cover_url` / `cover_key`。
  /// 通常 3-10s 内就绪，发布时把 `cover_key` 作为 `cover_object_key` 传入。
  AsyncJson coverFromFrame({
    required String videoKey,
    required int frameTimeMs,
  }) =>
      post(
        '/publish/video/cover-from-frame',
        data: {
          'video_key': videoKey,
          'frame_time_ms': frameTimeMs,
        },
        encrypted: false,
      );
}
