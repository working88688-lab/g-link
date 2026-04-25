import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/domain/type_def.dart';

abstract class ReportDomain {
  AsyncResult getEncryptedConfig();

  Future<List<ReportTypeItem>> getReportTypes();

  Future<void> submitUserReport({
    required int uid,
    required int reasonType,
    String? reasonDetail,
    required List<String> evidenceUrls,
  });

  /// 上传举报证据图片，返回 download_url
  Future<String> uploadReportEvidence(String filePath);
}
