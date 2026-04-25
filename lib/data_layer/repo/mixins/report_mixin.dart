part of '../repo.dart';

mixin _Report on _BaseAppRepo implements ReportDomain {
  @override
  AsyncResult getEncryptedConfig() =>
      _reportService.getEncryptedConfig().deserialize().guard;

  @override
  Future<List<ReportTypeItem>> getReportTypes() =>
      _userReportService.getReportTypes();

  @override
  Future<void> submitUserReport({
    required int uid,
    required int reasonType,
    String? reasonDetail,
    required List<String> evidenceUrls,
  }) =>
      _userReportService.submitUserReport(
        uid: uid,
        reasonType: reasonType,
        reasonDetail: reasonDetail,
        evidenceUrls: evidenceUrls,
      );

  @override
  Future<String> uploadReportEvidence(String filePath) =>
      _userReportService.uploadReportEvidence(filePath);
}
