part of '../repo.dart';

mixin _Report on _BaseAppRepo implements ReportDomain {
  @override
  AsyncResult getEncryptedConfig() =>
      _reportService.getEncryptedConfig().deserialize().guard;

  @override
  Future<List<ReportTypeItem>> getReportTypes() =>
      _userReportService.getReportTypes();

  @override
  Future<void> submitReport({
    required ReportTarget target,
    required int targetId,
    required int reasonType,
    String? reasonDetail,
    required List<String> evidenceUrls,
  }) =>
      _userReportService.submitReport(
        target: target,
        targetId: targetId,
        reasonType: reasonType,
        reasonDetail: reasonDetail,
        evidenceUrls: evidenceUrls,
      );

  @override
  Future<String> uploadReportEvidence(String filePath) =>
      _userReportService.uploadReportEvidence(filePath);
}
