import 'dart:io';

import 'package:dio/dio.dart';
import 'package:g_link/domain/model/profile_models.dart';

class UserReportService {
  UserReportService(this._dio) : _rawDio = Dio();

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

  Future<void> submitUserReport({
    required int uid,
    required int reasonType,
    String? reasonDetail,
    required List<String> evidenceUrls,
  }) async {
    await _dio.post(
      '/api/v1/users/$uid/report',
      data: {
        'reason_type': reasonType,
        if (reasonDetail != null && reasonDetail.isNotEmpty)
          'reason_detail': reasonDetail,
        'evidence_urls': evidenceUrls,
      },
    );
  }
}
