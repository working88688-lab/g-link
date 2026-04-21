// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web 端设备信息：device_brand / device_model / system_name / system_version
/// 按埋点规范均为空字符串，仅 device 固定为 'PC'，user_agent 从浏览器读取。
Future<void> initializeDeviceInfo() async {}

String getDeviceType() => 'PC';

String getSystemName() => '';

String getSystemVersion() => '';

String getDeviceBrand() => '';

String getDeviceModel() => '';

String getUserAgent() {
  try {
    return html.window.navigator.userAgent;
  } catch (_) {
    return '';
  }
}
