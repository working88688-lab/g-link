import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:g_link/domain/domains/report.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/utils/common_utils.dart';

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

  /// 无 Bearer Header 的裸 Dio，用于直传 MinIO 预签名 URL
  final Dio _rawDio;

  Future<List<ReportTypeItem>> getReportTypes() async {
    final res = await _dio.get('/api/v1/reports/types');
    final types = res.data['data']['types'] as List<dynamic>;
    return types
        .map((e) => ReportTypeItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 上传单张图片（举报证据），返回 download_url
  Future<String> uploadReportEvidence(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final fileSize = bytes.length;
    final ext = filePath.split('.').last.toLowerCase();

    // 1. 获取预签名 URL
    final presignRes = await _dio.post(
      '/api/v1/upload/presign',
      data: {
        'file_ext': ext,
        'file_size': fileSize,
        'scene': 'report_evidence',
      },
    );
    final data = presignRes.data['data'] as Map<String, dynamic>;
    final uploadUrl = data['upload_url'] as String;
    final downloadUrl = data['download_url'] as String;

    // 2. PUT 直传
    await _rawDio.put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          Headers.contentLengthHeader: fileSize,
          'Content-Type': _mimeType(ext),
        },
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    return downloadUrl;
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

  Future<void> submitReport({
    required ReportTarget target,
    required int targetId,
    required int reasonType,
    String? reasonDetail,
    required List<String> evidenceUrls,
  }) async {
    final path = switch (target) {
      ReportTarget.user => '/api/v1/users/$targetId/report',
      ReportTarget.video => '/api/v1/videos/$targetId/report',
      ReportTarget.comment => '/api/v1/comments/$targetId/report',
      ReportTarget.post => '/api/v1/posts/$targetId/report',
    };
    await _dio.post(
      path,
      data: {
        'reason_type': reasonType,
        if (reasonDetail != null && reasonDetail.isNotEmpty)
          'reason_detail': reasonDetail,
        'evidence_urls': evidenceUrls,
      },
    );
  }
}
