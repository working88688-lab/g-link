import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:analytics_sdk/utils/uuid_util.dart';

const _kFingerprintFileName = 'analytics_fingerprint.txt';

/// 原生平台设备指纹生成
///
/// **生成规则**
/// 1. 将非空因子用 `|` 拼接后做 SHA-256，取 64 位十六进制作为指纹。
///    因子：deviceId、device、deviceBrand、deviceModel、systemName、systemVersion。
/// 2. 若所有因子均为空（降级场景），则生成 UUID v4 并持久化至
///    `applicationDocumentsDirectory/analytics_fingerprint.txt`，
///    后续从文件读取保证稳定。
///
/// 任何异常均返回空字符串，不影响正常上报。
Future<String> generateOrLoadFingerprint({
  String deviceId = '',
  String device = '',
  String deviceBrand = '',
  String deviceModel = '',
  String systemName = '',
  String systemVersion = '',
  String userAgent = '',    // 原生端不使用，仅保持接口与 Web 端一致
}) async {
  try {
    final factors = [deviceId, device, deviceBrand, deviceModel, systemName, systemVersion]
        .where((f) => f.isNotEmpty)
        .toList();

    if (factors.isNotEmpty) {
      final digest = sha256.convert(utf8.encode(factors.join('|')));
      return digest.toString();
    }

    // 所有因子为空时降级为持久化 UUID v4
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_kFingerprintFileName');
    if (await file.exists()) {
      final existing = (await file.readAsString()).trim();
      if (existing.isNotEmpty) return existing;
    }
    final fp = generateUuidV4();
    await file.writeAsString(fp);
    return fp;
  } catch (_) {
    return '';
  }
}
