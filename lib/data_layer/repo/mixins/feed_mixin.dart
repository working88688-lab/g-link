part of '../repo.dart';

mixin _Feed on _BaseAppRepo implements FeedDomain {
  @override
  AsyncResult<FeedPage<FeedPost>> getRecommendFeed({
    String? cursor,
    int limit = 20,
  }) =>
      _feedService
          .getRecommendFeed(cursor: cursor, limit: limit)
          .deserializeJsonBy(
              (json) => FeedPage.fromJson(Json.from(json), FeedPost.fromJson))
          .guard;

  @override
  AsyncResult<FeedPage<FeedPost>> getHotFeed({
    String? cursor,
    int limit = 20,
  }) =>
      _feedService
          .getHotFeed(cursor: cursor, limit: limit)
          .deserializeJsonBy(
              (json) => FeedPage.fromJson(Json.from(json), FeedPost.fromJson))
          .guard;

  @override
  AsyncResult<FeedPage<FeedPost>> getFollowFeed({
    String? cursor,
    int limit = 20,
  }) =>
      _feedService
          .getFollowFeed(cursor: cursor, limit: limit)
          .deserializeJsonBy(
              (json) => FeedPage.fromJson(Json.from(json), FeedPost.fromJson))
          .guard;

  @override
  AsyncResult<LikeResult> likePost({required int postId}) => _feedService
      .likePost(postId: postId)
      .deserializeJsonBy((json) => LikeResult.fromJson(Json.from(json)))
      .guard;

  @override
  AsyncResult<LikeResult> unlikePost({required int postId}) => _feedService
      .unlikePost(postId: postId)
      .deserializeJsonBy((json) => LikeResult.fromJson(Json.from(json)))
      .guard;

  @override
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
  }) async {
    try {
      if (images.isEmpty) {
        return Result(status: -1, msg: 'publishNeedImage');
      }
      final uploadDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final objectKeys = <String>[];
      for (final x in images) {
        final bytes = await x.readAsBytes();
        if (bytes.isEmpty) {
          return Result(status: -1, msg: 'publishEmptyImage');
        }
        final ext = _publishNormalizeImageExt(x);
        final presignRaw = await _feedService.presignUpload(
          fileExt: ext,
          fileSize: bytes.length,
          scene: 'post',
        );
        final presign = Json.from(presignRaw);
        if (presign.status != 0) {
          return Result(status: presign.status, msg: presign.msg);
        }
        final pdata = presign.data;
        if (pdata is! Map<String, dynamic>) {
          return Result(status: -1, msg: 'publishPresignInvalid');
        }
        final uploadUrl = pdata['upload_url'] as String?;
        final objectKey = pdata['object_key'] as String?;
        if (uploadUrl == null || objectKey == null || uploadUrl.isEmpty) {
          return Result(status: -1, msg: 'publishPresignInvalid');
        }
        final headerRaw = pdata['headers'];
        final reqHeaders = <String, dynamic>{
          Headers.contentLengthHeader: bytes.length,
        };
        if (headerRaw is Map) {
          headerRaw.forEach((k, v) => reqHeaders['$k'] = v);
        }
        reqHeaders.putIfAbsent(
          'Content-Type',
          () => _publishMimeForExt(ext),
        );
        await uploadDio.put<void>(
          uploadUrl,
          data: bytes,
          options: Options(
            headers: reqHeaders.map((k, v) => MapEntry(k, '$v')),
            validateStatus: (s) => s != null && s >= 200 && s < 400,
          ),
        );
        objectKeys.add(objectKey);
      }
      final maxIdx = objectKeys.length - 1;
      final cap = maxIdx < 8 ? maxIdx : 8;
      final cover = coverImageIndex.clamp(0, cap);
      final body = <String, dynamic>{
        'content': content,
        'images': objectKeys,
        'cover_image_index': cover,
        'visibility': visibility,
        'allow_comment': allowComment,
        if (location != null) 'location': location.toJson(),
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        if (mentionedUids != null && mentionedUids.isNotEmpty)
          'mentioned_uids': mentionedUids,
        if (draftId != null) 'draft_id': draftId,
      };
      return await _feedService
          .publishPost(body)
          .deserializeJsonBy(
            (json) => PublishPostResult.fromJson(Json.from(json)),
          )
          .guard;
    } catch (e, st) {
      CommonUtils.log(e);
      CommonUtils.log(st);
      return Result(msg: e.toString());
    }
  }
}

String _publishNormalizeImageExt(XFile file) {
  var name = file.name.toLowerCase();
  if (name.isEmpty) {
    final p = file.path.toLowerCase();
    final slash = p.lastIndexOf('/');
    name = slash >= 0 ? p.substring(slash + 1) : p;
  }
  final dot = name.lastIndexOf('.');
  final ext = dot >= 0 ? name.substring(dot + 1) : 'jpg';
  switch (ext) {
    case 'jpeg':
      return 'jpg';
    case 'jpg':
    case 'png':
    case 'webp':
      return ext;
    default:
      return 'jpg';
  }
}

String _publishMimeForExt(String ext) {
  switch (ext) {
    case 'jpg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    default:
      return 'image/jpeg';
  }
}
