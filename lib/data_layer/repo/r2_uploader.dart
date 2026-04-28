import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:cross_file/cross_file.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:g_link/ui_layer/notifier/home_config_notifier.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:g_link/utils/common_utils.dart';

String _curlFromOptions(RequestOptions options) {
  final buffer =
      StringBuffer("curl -X ${options.method.toUpperCase()} '${options.uri}'");
  options.headers.forEach((key, value) {
    if (value == null) return;
    final escaped = value.toString().replaceAll("'", r"'\''");
    buffer.write(" -H '$key: $escaped'");
  });
  final data = options.data;
  if (data != null) {
    if (data is FormData) {
      for (final field in data.fields) {
        final v = field.value.replaceAll("'", r"'\''");
        buffer.write(" -F '${field.key}=$v'");
      }
    } else {
      final body = data is String ? data : data.toString();
      final escapedBody = body.replaceAll("'", r"'\''");
      buffer.write(" --data-raw '$escapedBody'");
    }
  }
  return buffer.toString();
}

class R2UploaderUtil {
  R2UploaderUtil({required BuildContext context, this.cancelToken})
      : r2URL = Provider.of<HomeConfigNotifier>(context, listen: false)
                .homeData
                .config
                .r2URL ??
            '',
        r2Key = Provider.of<HomeConfigNotifier>(context, listen: false)
                .homeData
                .config
                .r2Key ??
            '',
        r2CompleteURL = Provider.of<HomeConfigNotifier>(context, listen: false)
                .homeData
                .config
                .r2CompleteURL ??
            '';

  final CancelToken? cancelToken;
  final String r2URL;
  final String r2Key;
  final String r2CompleteURL;

  late final _r2Dio = Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          CommonUtils.log('[cURL] ${_curlFromOptions(options)}');
          handler.next(options);
        },
      ),
    );

  late final timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
  late final signature =
      md5.convert(utf8.encode('$timeStamp$r2Key')).toString();

  Future<Map<String, dynamic>> upload({
    required XFile xFile,
    ProgressCallback? progressCallback,
  }) async {
    const chunkSize = 5 * 1024 * 1024; // 5MB
    final fileSize = await xFile.length();

    final numberOfChunks = (fileSize / chunkSize).ceil();

    final multipartData = await _getMultipartData(numberOfChunks);
    if (multipartData['status'] != 'success') {
      return {'code': 0, 'message': 'r2scsb'.tr()};
    }

    final uploadUrl = multipartData['data']['uploadUrl'];
    final uploadName = multipartData['data']['UploadName'];
    final uploadId = multipartData['data']['uploadId'];
    final chunkUploadUrl = uploadUrl
        .replaceAll('{UploadName}', uploadName)
        .replaceAll('{uploadId}', uploadId);

    final List slices = multipartData['data']['slices'];

    final tasks = Queue<({String url, int i, int end, int start})>.from(
        List.generate(slices.length, (i) {
      final start = i * chunkSize;
      final end = min(start + chunkSize, fileSize);
      final url = chunkUploadUrl
          .replaceAll('{number}', slices[i]['number'].toString())
          .replaceAll('{signature}', slices[i]['signature']);
      return (start: start, end: end, url: url, i: i);
    }));

    final uploader = _R2Uploader(xFile, tasks, cancelToken: cancelToken,
        uploadedSizeChanged: (int uploadedSize) {
      progressCallback?.call(uploadedSize, fileSize);
    });

    try {
      final sliceTags = await uploader.exec(kIsWeb ? 5 : 15);
      final completeData =
          await _multipartComplete(uploadName, uploadId, sliceTags);
      if (completeData['status'] == 'success') {
        return {
          'code': 1,
          'message': completeData['data']['publicUrl'].toString()
        };
      }
      return {'code': 0, 'message': 'r2scsb'.tr()};
    } catch (e) {
      return {'code': -1, 'message': 'r2qxsc'.tr()};
    }
  }

  Future<Map> _getMultipartData(int numberOfChunks) async {
    try {
      final uploadResponse = await _r2Dio.post(
        r2URL,
        data: FormData.fromMap({
          'sign': signature,
          'timestamp': timeStamp,
          'total': numberOfChunks,
        }),
        options: Options(contentType: 'multipart/form-data'),
        cancelToken: cancelToken,
      );
      return uploadResponse.data;
    } catch (_) {
      return {};
    }
  }

  Future<Map> _multipartComplete(
      String name, String id, List<Map> sliceTags) async {
    try {
      final uploadResponse = await _r2Dio.post(
        r2CompleteURL,
        data: FormData.fromMap({
          'sign': signature,
          'timestamp': timeStamp,
          'upload_name': name,
          'upload_id': id,
          'slice_tag': jsonEncode(sliceTags),
        }),
        cancelToken: cancelToken,
        options: Options(contentType: 'multipart/form-data'),
      );
      return uploadResponse.data;
    } catch (e) {
      return {};
    }
  }
}

class _R2Uploader {
  _R2Uploader(
    this.xFile,
    this.tasks, {
    this.uploadedSizeChanged,
    this.cancelToken,
  }) : _tasksCount = tasks.length;
  final XFile xFile;
  final Queue<({String url, int i, int end, int start})> tasks;
  final ValueChanged<int>? uploadedSizeChanged;
  final CancelToken? cancelToken;
  final _completer = Completer<List<Map>>();
  final Dio _sliceDio = Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          CommonUtils.log('[cURL] ${_curlFromOptions(options)}');
          handler.next(options);
        },
      ),
    );

  bool _isRunning = false;

  final int _tasksCount;

  Future<List<Map>> exec(int maxConcurrent) async {
    if (!_isRunning) {
      _isRunning = true;
      for (int i = 0; i < maxConcurrent; i++) {
        _execRunner();
      }
    }
    return _completer.future;
  }

  final List<Map> _sliceTags = [];
  int _uploadedSize = 0;
  _execRunner() async {
    if (tasks.isEmpty) return;

    final task = tasks.removeFirst();
    final start = task.start;
    final end = task.end;
    final sliceSize = end - start;

    try {
      final Response response = await _sliceDio.put(
        task.url,
        data: xFile.openRead(start, end),
        cancelToken: cancelToken,
        options: Options(
          contentType: 'application/octet-stream',
          headers: {
            Headers.contentLengthHeader: sliceSize,
          },
        ),
      );

      if (response.statusCode == 200) {
        _sliceTags.add({
          'number': task.i + 1,
          'e_tag': response.headers['etag']![0].replaceAll('"', ''),
        });

        _uploadedSize += sliceSize;
        uploadedSizeChanged?.call(_uploadedSize);
        if (_sliceTags.length == _tasksCount) {
          _completer.complete(_sliceTags);
        } else {
          _execRunner();
        }
      } else {
        tasks.add(task);
        _execRunner();
      }
    } on DioException catch (e) {
      if (_completer.isCompleted) return;
      if (e.type == DioExceptionType.cancel) {
        _completer.completeError(e);
      } else {
        tasks.add(task);
        _execRunner();
      }
    } catch (e) {
      tasks.add(task);
      _execRunner();
    }
  }
}
