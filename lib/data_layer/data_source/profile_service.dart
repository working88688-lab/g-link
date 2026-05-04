import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/domain/type_def.dart';

import 'base_service.dart';

class ProfileService extends BaseService {
  ProfileService(super._dio) : _rawDio = _buildRawDio();

  @override
  final service = 'v1';
  final Dio _rawDio;

  static Dio _buildRawDio() {
    // S3/OSS 直传专用 dio：不要走业务 dio 的加密/鉴权拦截器；
    // 在 BaseOptions 上配齐三个超时（dio 5.x 的 Options.connectTimeout 不生效），
    // 并挂一个 LogInterceptor 方便排查 PUT 失败。
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(minutes: 2),
      receiveTimeout: const Duration(seconds: 30),
    ));
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: false,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => developer.log('$obj', name: 'upload-put'),
    ));
    return dio;
  }

  AsyncJson getUserProfile({required int uid}) =>
      get('/users/$uid', encrypted: false);
  AsyncJson getMyProfile() => get('/users/me', encrypted: false);
  AsyncJson updateMyProfile({
    String? nickname,
    String? username,
    String? bio,
    String? location,
    String? avatarUrl,
    String? coverUrl,
  }) =>
      patch(
        '/users/me',
        data: {
          if (nickname != null) 'nickname': nickname,
          if (username != null) 'username': username,
          if (bio != null) 'bio': bio,
          // 后端读字段叫 `location`，但写入字段叫 `location_city`（openapi.yaml
          // L1091 PATCH /api/v1/users/me 请求体里只接受这个 key），白名单外的
          // 字段会被静默丢掉，导致 updated_fields:[] 而 location 返回 null。
          if (location != null) 'location_city': location,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (coverUrl != null) 'cover_url': coverUrl,
        },
        encrypted: false,
      );

  AsyncJson getUserVideos({
    required int uid,
    String? cursor,
    int? limit,
  }) =>
      get(
        '/users/$uid/videos',
        queryParameters: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          if (limit != null) 'limit': limit,
        },
        encrypted: false,
      );
  AsyncJson getUserPosts({
    required int uid,
    String? cursor,
    int? limit,
  }) =>
      get(
        '/users/$uid/posts',
        queryParameters: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          if (limit != null) 'limit': limit,
        },
        encrypted: false,
      );
  AsyncJson getUserLikes({
    required int uid,
    String? cursor,
    int? limit,
  }) =>
      get(
        '/users/$uid/likes',
        queryParameters: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          if (limit != null) 'limit': limit,
        },
        encrypted: false,
      );
  AsyncJson getMyVideos({
    String? cursor,
    int? limit,
  }) =>
      get(
        '/users/me/videos',
        queryParameters: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          if (limit != null) 'limit': limit,
        },
        encrypted: false,
      );
  AsyncJson getMyPosts({
    String? cursor,
    int? limit,
  }) =>
      get(
        '/users/me/posts',
        queryParameters: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          if (limit != null) 'limit': limit,
        },
        encrypted: false,
      );
  AsyncJson getMyLikes({
    String? cursor,
    int? limit,
  }) =>
      get(
        '/users/me/likes',
        queryParameters: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          if (limit != null) 'limit': limit,
        },
        encrypted: false,
      );

  AsyncJson getMySettings() => get('/settings', encrypted: false);
  AsyncJson updatePrivacySettings({
    String? whoCanFollow,
    String? whoCanMessage,
    String? whoCanMention,
    bool? showFollowingList,
    bool? showFollowerList,
    bool? showLikeCount,
  }) =>
      patch(
        '/settings/privacy',
        data: {
          if (whoCanFollow != null) 'who_can_follow': whoCanFollow,
          if (whoCanMessage != null) 'who_can_message': whoCanMessage,
          if (whoCanMention != null) 'who_can_mention': whoCanMention,
          if (showFollowingList != null) 'show_following_list': showFollowingList,
          if (showFollowerList != null) 'show_follower_list': showFollowerList,
          if (showLikeCount != null) 'show_like_count': showLikeCount,
        },
        encrypted: false,
      );

  AsyncJson updateNotificationSettings({
    bool? notifyFollow,
    bool? notifyLike,
    bool? notifyComment,
    bool? notifyMention,
    bool? notifySystem,
    bool? pushEnabled,
  }) =>
      patch(
        '/settings/notification',
        data: {
          if (notifyFollow != null) 'notify_follow': notifyFollow,
          if (notifyLike != null) 'notify_like': notifyLike,
          if (notifyComment != null) 'notify_comment': notifyComment,
          if (notifyMention != null) 'notify_mention': notifyMention,
          if (notifySystem != null) 'notify_system': notifySystem,
          if (pushEnabled != null) 'push_enabled': pushEnabled,
        },
        encrypted: false,
      );

  AsyncJson getInterests() => get('/interest-tags', encrypted: false);
  AsyncJson updateMyInterestTags({required List<int> tagIds}) => put(
        '/interest-tags',
        data: {
          'tag_ids': tagIds,
        },
        jsonBody: true,
        encrypted: false,
      );

  AsyncJson getRecommendedUsers({int limit = 20}) => get(
        '/users/recommendations',
        queryParameters: {'limit': limit},
        encrypted: false,
      );

  AsyncJson followUser({required int uid}) => post(
        '/users/$uid/follow',
        data: const <String, dynamic>{},
        encrypted: false,
      );

  AsyncJson unfollowUser({required int uid}) => delete(
        '/users/$uid/follow',
        encrypted: false,
      );
  AsyncJson submitOnboardingInterests({
    required List<int> tagIds,
  }) =>
      post('/onboarding/interests',
          data: {
            'tag_ids': tagIds,
          },
          jsonBody: true,
          encrypted: false);

  AsyncJson completeOnboarding() =>
      post('/onboarding/complete', data: {}, jsonBody: true, encrypted: false);

  Future<UploadedImagePayload> uploadImageByPresign({
    required Uint8List bytes,
    required String fileExt,
    required int fileSize,
    required ImageUploadScene scene,
  }) async {
    final presignRes = await _requestPresignWithRetry(
      fileExt: fileExt,
      fileSize: fileSize,
      scene: scene.value,
    );
    final data = Json.from(presignRes['data'] ?? {});
    final uploadUrl = '${data['upload_url'] ?? ''}';
    final objectKey = '${data['object_key'] ?? ''}';
    final downloadUrl = '${data['download_url'] ?? ''}';
    final headerMap = Json.from(data['headers'] ?? {});
    if (uploadUrl.isEmpty || downloadUrl.isEmpty || objectKey.isEmpty) {
      throw Exception('upload presign response invalid');
    }
    // presign 仅返回一个临时签名 URL，必须把真实字节 PUT 到该 URL，
    // 才会在对象存储里产生对象；缺少这一步会导致 download_url 返回 403。
    //
    // 注意：后端偶发会把 bucket 名重复拼到 host 上（如
    // `glink-oss.glink-oss.s3.*.amazonaws.com`），且 SigV4 是基于这个错误的
    // host 签的，客户端无论改不改 URL 都通不过：
    //   - 不改：TLS Hostname mismatch（证书不覆盖二级 bucket 子域）；
    //   - 改成正确 host：SignatureDoesNotMatch（host 是签名输入之一）。
    // 所以这里只做静态校验、提前抛错，把问题打回后端。
    _assertUploadUrlHostValid(uploadUrl);
    final contentType =
        '${headerMap['Content-Type'] ?? headerMap['content-type'] ?? _mimeType(fileExt)}';
    final resp = await _putObjectWithRetry(
      uploadUrl: uploadUrl,
      bytes: bytes,
      contentType: contentType,
      extraHeaders: headerMap,
    );
    final statusCode = resp.statusCode ?? -1;
    if (statusCode < 200 || statusCode >= 400) {
      throw Exception('upload put failed: http $statusCode');
    }
    return UploadedImagePayload(
      objectKey: objectKey,
      downloadUrl: downloadUrl,
    );
  }

  Future<Json> _requestPresignWithRetry({
    required String fileExt,
    required int fileSize,
    required String scene,
  }) async {
    Exception? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await post(
          '/upload/presign',
          data: {
            'file_ext': fileExt,
            'file_size': fileSize,
            'scene': scene,
          },
          encrypted: false,
          options: Options(
            // presign 仅返回签名信息，弱网下适当放宽超时，避免 5s 默认值误伤。
            connectTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 25),
          ),
        );
      } on DioException catch (e) {
        final isTimeout = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout;
        if (!isTimeout) rethrow;
        lastError = Exception('presign timeout: ${e.message ?? ''}');
      } catch (e) {
        lastError = Exception('presign failed: $e');
      }
    }
    throw lastError ?? Exception('presign request failed');
  }

  Future<Response<dynamic>> _putObjectWithRetry({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
    required Map<String, dynamic> extraHeaders,
  }) async {
    DioException? lastTimeoutError;
    // 仅保留 presign headers 中的非 Content-Type 字段（如 x-amz-* 自定义头），
    // Content-Type 通过 Options.contentType 单一源设置，避免大小写冲突重复。
    final passthroughHeaders = <String, dynamic>{};
    extraHeaders.forEach((k, v) {
      if (k.toLowerCase() == 'content-type') return;
      passthroughHeaders[k] = v;
    });
    final headers = <String, dynamic>{
      ...passthroughHeaders,
      Headers.contentLengthHeader: bytes.length,
    };

    for (var attempt = 0; attempt < 2; attempt++) {
      developer.log(
        '[upload-put] start attempt=${attempt + 1} '
        'bytes=${bytes.length} ct=$contentType url=$uploadUrl',
        name: 'upload-put',
      );
      final stopwatch = Stopwatch()..start();
      try {
        final resp = await _rawDio.put(
          uploadUrl,
          data: Stream<List<int>>.fromIterable([bytes]),
          options: Options(
            contentType: contentType,
            headers: headers,
            validateStatus: (status) =>
                status != null && status >= 200 && status < 400,
            sendTimeout: const Duration(minutes: 2),
            receiveTimeout: const Duration(seconds: 30),
          ),
          onSendProgress: (sent, total) {
            if (total <= 0) return;
            final pct = (sent * 100 / total).floor();
            if (pct % 25 == 0) {
              developer.log('[upload-put] progress $pct% ($sent/$total)',
                  name: 'upload-put');
            }
          },
        );
        stopwatch.stop();
        developer.log(
          '[upload-put] done attempt=${attempt + 1} '
          'status=${resp.statusCode} elapsed=${stopwatch.elapsedMilliseconds}ms',
          name: 'upload-put',
        );
        return resp;
      } on DioException catch (e) {
        stopwatch.stop();
        developer.log(
          '[upload-put] DioException attempt=${attempt + 1} '
          'type=${e.type} status=${e.response?.statusCode} '
          'elapsed=${stopwatch.elapsedMilliseconds}ms '
          'msg=${e.message} body=${e.response?.data}',
          name: 'upload-put',
        );
        final isTimeout = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout;
        if (!isTimeout) rethrow;
        lastTimeoutError = e;
      }
    }
    throw Exception('upload put timeout: ${lastTimeoutError?.message ?? ''}');
  }

  String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  /// 校验 upload_url 的 host 是否合法。
  ///
  /// 已知后端 bug：会生成 `<bucket>.<bucket>.s3.<region>.amazonaws.com` 这种
  /// 重复 bucket 子域的 URL；该 URL 既无法过 TLS 校验，也无法被客户端纠正
  /// （SigV4 已基于错误 host 签名，改 host 必然 SignatureDoesNotMatch）。
  /// 这里直接拒绝，避免业务层再耗时跑一次注定失败的 PUT。
  void _assertUploadUrlHostValid(String url) {
    final uri = Uri.parse(url);
    final host = uri.host;
    final parts = host.split('.');
    if (parts.length >= 5 &&
        parts[0].isNotEmpty &&
        parts[0] == parts[1] &&
        (parts[2] == 's3' || parts[2].startsWith('s3-')) &&
        host.endsWith('amazonaws.com')) {
      developer.log(
        '[upload-put] presign 返回了非法 upload_url（bucket 子域重复）：$url；'
        '该 URL 已使用错误 host 完成 SigV4 签名，客户端无法修复，'
        '需要后端修正 /api/v1/upload/presign 的 URL 生成逻辑。',
        name: 'upload-put',
      );
      throw Exception(
        '上传 URL 不合法（bucket 子域重复），请联系后端修复 presign 接口。',
      );
    }
  }
}
