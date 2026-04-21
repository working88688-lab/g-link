// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:crypto/crypto.dart';
import 'package:analytics_sdk/utils/uuid_util.dart';

const _kFingerprintKey = 'analytics_fp';

/// Web 平台设备指纹生成
///
/// **生成规则**
/// 1. 收集宿主 App 传入字段（device、deviceBrand、deviceModel、systemName、
///    systemVersion、userAgent）及浏览器环境信息（屏幕分辨率、语言、时区），
///    过滤空值后用 `|` 拼接，做 SHA-256 生成指纹。
/// 2. 若所有因子均为空，降级生成 UUID v4 并写入 localStorage，后续复用。
///
/// 任何异常均返回空字符串，不影响正常上报。
Future<String> generateOrLoadFingerprint({
  String deviceId = '',
  String device = '',
  String deviceBrand = '',
  String deviceModel = '',
  String systemName = '',
  String systemVersion = '',
  String userAgent = '',
}) async {
  try {
    final envFactors = _collectBrowserEnv();
    final factors = [
      device, deviceBrand, deviceModel,
      systemName, systemVersion,
      userAgent,
      ...envFactors,
    ].where((f) => f.isNotEmpty).toList();

    if (factors.isNotEmpty) {
      final digest = sha256.convert(utf8.encode(factors.join('|')));
      return digest.toString();
    }

    // 所有因子为空时降级为持久化 UUID v4
    final storage = html.window.localStorage;
    final existing = storage[_kFingerprintKey] ?? '';
    if (existing.isNotEmpty) return existing;

    final fp = generateUuidV4();
    storage[_kFingerprintKey] = fp;
    return fp;
  } catch (_) {
    return '';
  }
}

/// 收集浏览器环境因子：屏幕分辨率、语言、时区
List<String> _collectBrowserEnv() {
  final factors = <String>[];
  try {
    final screen = html.window.screen;
    if (screen != null) {
      final w = screen.width;
      final h = screen.height;
      if (w != null && h != null && w > 0 && h > 0) {
        factors.add('${w}x$h');
      }
    }
  } catch (_) {}
  try {
    final lang = html.window.navigator.language;
    if (lang.isNotEmpty) factors.add(lang);
  } catch (_) {}
  try {
    final tz = DateTime.now().timeZoneName;
    if (tz.isNotEmpty) factors.add(tz);
  } catch (_) {}
  return factors;
}
