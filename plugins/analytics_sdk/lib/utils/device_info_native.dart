import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

String? _cachedBrand;
String? _cachedModel;
String? _cachedVersion;

Future<void> initializeDeviceInfo() async {
  try {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      _cachedBrand = info.brand;
      _cachedModel = info.model;
      _cachedVersion = info.version.release;
    } else if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      _cachedBrand = 'Apple';
      _cachedModel = info.model;
    } else if (Platform.isMacOS) {
      final info = await plugin.macOsInfo;
      _cachedBrand = 'MAC';
      _cachedModel = info.model;
    } else if (Platform.isWindows) {
      final info = await plugin.windowsInfo;
      _cachedBrand = '';
      _cachedModel = info.productName;
    }
    // Linux：无通用品牌/型号，留空
  } catch (_) {}
}

String getDeviceType() {
  if (Platform.isAndroid) return 'Android';
  if (Platform.isIOS) return 'iOS';
  return 'PC';
}

String getSystemName() {
  if (Platform.isAndroid) return 'Android';
  if (Platform.isIOS) return 'iOS';
  if (Platform.isMacOS) return 'macOS';
  if (Platform.isWindows) return 'Windows';
  if (Platform.isLinux) return 'Linux';
  return '';
}

String getSystemVersion() {
  if (_cachedVersion != null) return _cachedVersion!;
  // 非 Android 平台：从 "macOS 14.5.0" / "Windows 11 ..." 等字符串中提取版本号
  final match = RegExp(r'[\d]+(?:\.[\d]+)*').firstMatch(Platform.operatingSystemVersion);
  return match?.group(0) ?? Platform.operatingSystemVersion;
}

String getDeviceBrand() => _cachedBrand ?? '';

String getDeviceModel() => _cachedModel ?? '';

String getUserAgent() => '';
