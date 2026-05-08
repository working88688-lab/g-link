import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:g_link/domain/domains/report.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/domain/type_def.dart';
import 'package:g_link/utils/common_utils.dart';

/// 举报：`GET /api/v1/reports/types`、`POST /api/v1/reports`、证据图走 `upload/presign`。
class UserReportService {
  UserReportService(this._dio) : _rawDio = Dio() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          CommonUtils.log('[cURL] ${_toCurl(options)}');
          handler.next(options);
        },
      ),
    );
    _rawDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          CommonUtils.log('[cURL] ${_toCurl(options)}');
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;

  /// 无 Bearer Header 的裸 Dio，用于直传 MinIO/OSS 预签名 URL
  final Dio _rawDio;

  /// v1 明文 JSON：必须带 `skipEncrypt`，否则 [AutoEncryptAndDecryptInterceptor]
  /// 会把 body 打成 `_ver=…&data=…&sign=…`，服务端拿不到 `file_ext` /
  /// `file_size` / `scene` 等字段（`Validation failed`）。
  static Options _plainJsonOptions({
    Duration? connectTimeout,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) =>
      Options(
        contentType: Headers.jsonContentType,
        extra: const {'skipEncrypt': true},
        connectTimeout: connectTimeout,
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
      );

  static int _responseCode(dynamic root) {
    if (root is! Map) return -1;
    return int.tryParse('${root['code'] ?? root['status'] ?? 0}') ?? 0;
  }

  Future<List<ReportTypeItem>> getReportTypes() async {
    final res = await _dio.get<dynamic>(
      '/api/v1/reports/types',
      options: _plainJsonOptions(),
    );
    return _parseReportTypes(res.data);
  }

  List<ReportTypeItem> _parseReportTypes(dynamic raw) {
    if (raw is! Map) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/v1/reports/types'),
        message: 'Invalid report types response',
      );
    }
    final code = _responseCode(raw);
    if (code != 0) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/v1/reports/types'),
        message: '${raw['message'] ?? raw['msg'] ?? 'load failed'}',
      );
    }
    final data = raw['data'];
    List<dynamic> types = const [];
    if (data is Map) {
      types = (data['types'] as List?) ??
          (data['lists'] as List?) ??
          const [];
    } else if (data is List) {
      types = data;
    }
    final out = <ReportTypeItem>[];
    for (final e in types) {
      if (e is Map) {
        out.add(ReportTypeItem.fromJson(Json.from(e)));
      }
    }
    return out;
  }

  /// 上传单张图片（举报证据），返回可提交给举报接口的 URL（`download_url` 或等价公开地址）。
  Future<String> uploadReportEvidence(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final fileSize = bytes.length;
    if (fileSize <= 0) {
      throw StateError('Empty image file');
    }
    var ext = filePath.split('.').last.toLowerCase();
    if (ext.isEmpty || ext.length > 5) ext = 'jpg';

    final presignRes = await _dio.post<dynamic>(
      '/api/v1/upload/presign',
      data: {
        'file_ext': ext,
        'file_size': fileSize,
        'scene': 'report_evidence',
      },
      options: _plainJsonOptions(
        connectTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 25),
      ),
    );
    final root = presignRes.data;
    if (root is! Map) {
      throw StateError('Invalid presign response');
    }
    final code = _responseCode(root);
    if (code != 0) {
      throw DioException(
        requestOptions: presignRes.requestOptions,
        message: '${root['message'] ?? root['msg'] ?? 'presign failed'}',
      );
    }
    final pdata = root['data'];
    if (pdata is! Map) {
      throw StateError('Invalid presign data');
    }
    final uploadUrl = pdata['upload_url']?.toString();
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw StateError('Missing upload_url');
    }
    final downloadUrl = pdata['download_url']?.toString();
    final objectKey = pdata['object_key']?.toString();

    final headerRaw = pdata['headers'];
    final reqHeaders = <String, dynamic>{
      Headers.contentLengthHeader: fileSize,
    };
    if (headerRaw is Map) {
      headerRaw.forEach((k, v) => reqHeaders['$k'] = v);
    }
    reqHeaders.putIfAbsent('Content-Type', () => _mimeType(ext));

    await _rawDio.put<void>(
      uploadUrl,
      data: bytes,
      options: Options(
        headers: reqHeaders.map((k, v) => MapEntry(k, '$v')),
        validateStatus: (s) => s != null && s >= 200 && s < 400,
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    if (downloadUrl != null && downloadUrl.isNotEmpty) {
      return downloadUrl;
    }
    if (objectKey != null && objectKey.isNotEmpty) {
      return objectKey;
    }
    throw StateError('Missing download_url / object_key after upload');
  }

  String _mimeType(String ext) {
    switch (ext) {
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

  String _toCurl(RequestOptions options) {
    final buffer = StringBuffer(
        "curl -X ${options.method.toUpperCase()} '${options.uri}'");
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
        final body = data is String ? data : jsonEncode(data);
        final escapedBody = body.replaceAll("'", r"'\''");
        buffer.write(" --data-raw '$escapedBody'");
      }
    }
    return buffer.toString();
  }

  static String _targetTypeString(ReportTarget target) => switch (target) {
        ReportTarget.user => 'user',
        ReportTarget.video => 'video',
        ReportTarget.comment => 'comment',
        ReportTarget.post => 'post',
      };

  /// 统一举报提交：`POST /api/v1/reports`（设计稿 / 产品约定入口）。
  Future<void> submitReport({
    required ReportTarget target,
    required int targetId,
    required int reasonType,
    String? reasonDetail,
    required List<String> evidenceUrls,
  }) async {
    final res = await _dio.post<dynamic>(
      '/api/v1/reports',
      data: {
        'target_type': _targetTypeString(target),
        'target_id': targetId,
        'reason_type': reasonType,
        if (reasonDetail != null && reasonDetail.isNotEmpty)
          'reason_detail': reasonDetail,
        'evidence_urls': evidenceUrls,
      },
      options: _plainJsonOptions(),
    );
    final root = res.data;
    if (root is Map) {
      final code = _responseCode(root);
      if (code != 0) {
        throw DioException(
          requestOptions: res.requestOptions,
          message: '${root['message'] ?? root['msg'] ?? 'submit failed'}',
        );
      }
    }
  }
}
