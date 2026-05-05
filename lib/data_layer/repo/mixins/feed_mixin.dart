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

  @override
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
  }) async {
    try {
      if (durationMs <= 0 || width <= 0 || height <= 0) {
        return Result(status: -1, msg: 'publishVideoMetaInvalid');
      }
      final fileSize = await video.length();
      if (fileSize <= 0) {
        return Result(status: -1, msg: 'publishVideoEmptyFile');
      }
      // OpenAPI «视频上传预签名»：上限 500MB.
      const maxBytes = 500 * 1024 * 1024;
      if (fileSize > maxBytes) {
        return Result(status: -1, msg: 'publishVideoFileTooLarge');
      }
      final ext = _publishNormalizeVideoExt(video);

      // 1) presign：拿 upload_url + object_key（视频 key）。
      final presignRaw = await _videoPublishService.presignVideoUpload(
        fileExt: ext,
        fileSize: fileSize,
        contentType: _publishVideoMimeForExt(ext),
        durationMs: durationMs,
        width: width,
        height: height,
      );
      final presignJson = Json.from(presignRaw);
      if (presignJson.status != 0) {
        return Result(status: presignJson.status, msg: presignJson.msg);
      }
      final pdata = presignJson.data;
      if (pdata is! Map) {
        return Result(status: -1, msg: 'publishVideoPresignInvalid');
      }
      final presign = VideoUploadPresign.fromJson(Json.from(pdata));
      if (presign.uploadUrl.isEmpty || presign.objectKey.isEmpty) {
        return Result(status: -1, msg: 'publishVideoPresignInvalid');
      }
      if (presign.maxSize != null && fileSize > presign.maxSize!) {
        return Result(status: -1, msg: 'publishVideoFileTooLarge');
      }

      // 2) 直传到 S3/OSS。
      //
      // S3 presigned PUT 对请求很挑剔——重复 `Content-Length` 或 `Transfer-Encoding: chunked`
      // 会被网关以「Connection reset by peer」直接断开。
      // 这里参考 [R2UploaderUtil] 用 `Stream<List<int>>` + 显式 Content-Length + Options.contentType，
      // 不再传 `Uint8List`（避免 Dio 内部转码逻辑导致 chunked 编码）。
      final uploadDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(minutes: 30),
          receiveTimeout: const Duration(minutes: 30),
        ),
      );
      String? signedContentType;
      final extraHeaders = <String, dynamic>{};
      presign.headers?.forEach((k, v) {
        if (k.toLowerCase() == 'content-type') {
          if (v.isNotEmpty) signedContentType = v;
        } else if (k.toLowerCase() != 'content-length') {
          extraHeaders[k] = v;
        }
      });
      final contentType = signedContentType ?? _publishVideoMimeForExt(ext);
      final headers = <String, dynamic>{
        ...extraHeaders,
        Headers.contentLengthHeader: fileSize,
      };
      await uploadDio.put<void>(
        presign.uploadUrl,
        data: video.openRead(),
        onSendProgress: onUploadProgress,
        options: Options(
          contentType: contentType,
          headers: headers.map((k, v) => MapEntry(k, '$v')),
          validateStatus: (s) => s != null && s >= 200 && s < 400,
        ),
      );

      // 3) upload-done：换得 video_id。
      final doneRaw = await _videoPublishService.notifyUploadDone(
        objectKey: presign.objectKey,
        durationMs: durationMs,
        width: width,
        height: height,
        fileSize: fileSize,
      );
      final doneJson = Json.from(doneRaw);
      if (doneJson.status != 0) {
        return Result(status: doneJson.status, msg: doneJson.msg);
      }
      if (doneJson.data is! Map) {
        return Result(status: -1, msg: 'publishVideoDoneInvalid');
      }
      final done = VideoUploadDoneResult.fromJson(Json.from(doneJson.data));
      if (done.videoId <= 0) {
        return Result(status: -1, msg: 'publishVideoDoneInvalid');
      }

      // 4) cover-from-frame：仅在用户挑选了非 0 时间点时调用，
      //    并与下一步转码轮询并行——OpenAPI «查询转码状态» 也会返回 cover_url，
      //    可作为兜底，避免把封面接口放在关键路径上。
      Future<String?>? coverFuture;
      if (coverFrameTimeMs > 0) {
        coverFuture = _publishExtractCoverFromFrame(
          videoKey: presign.objectKey,
          durationMs: durationMs,
          frameTimeMs: coverFrameTimeMs,
        );
      }

      // 5) 自适应轮询转码状态：首次 600ms，按 1.5x 退避至 2s 上限，最长 5 分钟。
      //    短视频可在 ≤1s 内完成，旧版 2s 固定间隔会浪费首检等待时间。
      final pollDeadline = DateTime.now().add(const Duration(minutes: 5));
      var pollDelay = const Duration(milliseconds: 600);
      const pollDelayCap = Duration(seconds: 2);
      String? transcodeCoverUrl;
      while (true) {
        if (DateTime.now().isAfter(pollDeadline)) {
          return Result(status: -1, msg: 'publishVideoTranscodeTimeout');
        }
        try {
          final statusRaw = await _videoPublishService
              .getTranscodeStatus(videoId: done.videoId);
          final statusJson = Json.from(statusRaw);
          if (statusJson.status == 0 && statusJson.data is Map) {
            final status = VideoTranscodeStatusResult.fromJson(
              Json.from(statusJson.data),
            );
            if (status.isDone) {
              transcodeCoverUrl = status.coverUrl;
              break;
            }
            if (status.isFailed) {
              return Result(
                status: -1,
                msg: status.errorMessage?.isNotEmpty == true
                    ? status.errorMessage!
                    : 'publishVideoTranscodeFailed',
              );
            }
          }
        } catch (e, st) {
          CommonUtils.log(e);
          CommonUtils.log(st);
        }
        await Future<void>.delayed(pollDelay);
        final next = pollDelay * 1.5;
        pollDelay = next > pollDelayCap ? pollDelayCap : next;
      }

      // 6) 等待并行的截帧任务；最多再等 800ms 即转用转码生成的封面，
      //    保证发布请求不被截帧返回时延阻塞。
      String? coverUrl;
      if (coverFuture != null) {
        try {
          coverUrl = await coverFuture
              .timeout(const Duration(milliseconds: 800));
        } catch (_) {
          coverUrl = null;
        }
      }
      coverUrl ??= (transcodeCoverUrl?.isNotEmpty ?? false)
          ? transcodeCoverUrl
          : null;

      // 7) publish：严格对齐 OpenAPI «发布视频» 请求体。
      // 服务端白名单仅有 title / description / cover_url / tags / visibility /
      // bgm_id / location；其它字段（allow_comment / mentioned_uids / draft_id /
      // cover_object_key）会被忽略或导致 422，故不再下发。
      final body = <String, dynamic>{
        'description': description,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (coverUrl != null) 'cover_url': coverUrl,
        'visibility': visibility,
        if (location != null) 'location': location.toJson(),
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        if (bgmId != null) 'bgm_id': bgmId,
      };
      return await _videoPublishService
          .publishVideo(videoId: done.videoId, body: body)
          .deserializeJsonBy(
            (json) => PublishVideoResult.fromJson(Json.from(json)),
          )
          .guard;
    } catch (e, st) {
      CommonUtils.log(e);
      CommonUtils.log(st);
      return Result(msg: e.toString());
    }
  }

  @override
  AsyncResult<SaveDraftResult> saveDraft({
    required String type,
    String? title,
    String? content,
    Json? mediaData,
    Json? settings,
  }) async {
    try {
      final body = <String, dynamic>{
        'type': type,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (content != null && content.trim().isNotEmpty) 'content': content,
        if (mediaData != null && mediaData.isNotEmpty) 'media_data': mediaData,
        if (settings != null && settings.isNotEmpty) 'settings': settings,
      };
      return await _feedService
          .saveDraft(body)
          .deserializeJsonBy(
            (json) => SaveDraftResult.fromJson(Json.from(json)),
          )
          .guard;
    } catch (e, st) {
      CommonUtils.log(e);
      CommonUtils.log(st);
      return Result(msg: e.toString());
    }
  }

  @override
  AsyncResult<List<DraftItem>> getDrafts({
    String? type,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final raw = Json.from(await _feedService.getDrafts(
        type: type,
        cursor: cursor,
        limit: limit,
      ));
      if (raw.status != 0) {
        return Result(status: raw.status, msg: raw.msg);
      }
      final data = raw.data;
      List<dynamic> rows = const [];
      if (data is Map) {
        final lists = data['lists'];
        if (lists is List) rows = lists;
      } else if (data is List) {
        rows = data;
      }
      final items = <DraftItem>[];
      for (final e in rows) {
        if (e is Map) items.add(DraftItem.fromJson(Json.from(e)));
      }
      return Result(data: items, status: 0);
    } catch (e, st) {
      CommonUtils.log(e);
      CommonUtils.log(st);
      return Result(msg: e.toString());
    }
  }

  @override
  AsyncResult<void> deleteDraft({required int draftId}) async {
    try {
      final raw = Json.from(await _feedService.deleteDraft(draftId: draftId));
      if (raw.status != 0) {
        return Result(status: raw.status, msg: raw.msg);
      }
      return Result(status: 0);
    } catch (e, st) {
      CommonUtils.log(e);
      CommonUtils.log(st);
      return Result(msg: e.toString());
    }
  }

  /// 后台异步拉取 cover-from-frame 的 cover_url；任何失败都返回 `null`，
  /// 让转码自带封面兜底，不阻断发布主流程。
  Future<String?> _publishExtractCoverFromFrame({
    required String videoKey,
    required int durationMs,
    required int frameTimeMs,
  }) async {
    try {
      final upper = durationMs - 1 < 180000 ? durationMs - 1 : 180000;
      final maxFrameMs = upper > 0 ? upper : 0;
      final clamped = frameTimeMs.clamp(0, maxFrameMs);
      final coverRaw = await _videoPublishService.coverFromFrame(
        videoKey: videoKey,
        frameTimeMs: clamped,
      );
      final coverJson = Json.from(coverRaw);
      if (coverJson.status == 0 && coverJson.data is Map) {
        final cover = VideoCoverFromFrameResult.fromJson(
          Json.from(coverJson.data),
        );
        if (cover.coverUrl.isNotEmpty) return cover.coverUrl;
      }
    } catch (e, st) {
      CommonUtils.log(e);
      CommonUtils.log(st);
    }
    return null;
  }

  List<PublishTopicRow> _parseTopicsResponseData(dynamic data) {
    final List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      list = (data['lists'] as List?) ??
          (data['list'] as List?) ??
          (data['items'] as List?) ??
          (data['topics'] as List?) ??
          (data['data'] is List ? data['data'] as List : null) ??
          const [];
    } else {
      list = const [];
    }
    final out = <PublishTopicRow>[];
    for (final e in list) {
      if (e is! Map) continue;
      final row = PublishTopicRow.tryParse(Json.from(e));
      if (row != null) out.add(row);
    }
    return out;
  }

  @override
  AsyncResult<List<PublishTopicRow>> getHotTopics() async {
    try {
      final raw = Json.from(await _topicService.getHotTopics());
      if (raw.status != 0) {
        return Result(status: raw.status, msg: raw.msg);
      }
      return Result(
        data: _parseTopicsResponseData(raw.data),
        status: 0,
      );
    } catch (e, st) {
      CommonUtils.log(e);
      CommonUtils.log(st);
      return Result(msg: e.toString());
    }
  }

  @override
  AsyncResult<List<PublishTopicRow>> searchTopics(String query) async {
    try {
      final q = query.trim();
      if (q.isEmpty) {
        return Result(data: const [], status: 0);
      }
      final raw = Json.from(await _topicService.searchTopics(query: q));
      if (raw.status != 0) {
        return Result(status: raw.status, msg: raw.msg);
      }
      return Result(
        data: _parseTopicsResponseData(raw.data),
        status: 0,
      );
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

String _publishNormalizeVideoExt(XFile file) {
  var name = file.name.toLowerCase();
  if (name.isEmpty) {
    final p = file.path.toLowerCase();
    final slash = p.lastIndexOf('/');
    name = slash >= 0 ? p.substring(slash + 1) : p;
  }
  final dot = name.lastIndexOf('.');
  final ext = dot >= 0 ? name.substring(dot + 1) : 'mp4';
  switch (ext) {
    case 'mp4':
    case 'mov':
    case 'm4v':
    case 'webm':
      return ext;
    default:
      return 'mp4';
  }
}

String _publishVideoMimeForExt(String ext) {
  switch (ext) {
    case 'mov':
      return 'video/quicktime';
    case 'm4v':
      return 'video/x-m4v';
    case 'webm':
      return 'video/webm';
    case 'mp4':
    default:
      return 'video/mp4';
  }
}
