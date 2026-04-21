import 'device_info_native.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'device_info_web.dart';

/// 设备信息工具类：SDK 内部自动检测，业务方无需手动传入。
///
/// 使用前须在 SDK 初始化时调用一次 [initialize]，之后所有 getter 同步返回缓存值。
class DeviceInfoUtil {
  static bool _initialized = false;

  /// 异步初始化（调用 device_info_plus 获取品牌/型号并缓存）。
  /// 重复调用无副作用。
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await initializeDeviceInfo();
  }

  /// 设备类型：Android / iOS / PC
  static String get deviceType => getDeviceType();

  /// 操作系统名称：Android / iOS / macOS / Windows / Linux / Web
  static String get systemName => getSystemName();

  /// 操作系统版本号
  static String get systemVersion => getSystemVersion();

  /// 设备品牌（由 device_info_plus 自动获取）
  static String get deviceBrand => getDeviceBrand();

  /// 设备型号（由 device_info_plus 自动获取）
  static String get deviceModel => getDeviceModel();

  /// User-Agent（Web 端自动读取，Native 端返回空字符串）
  static String get userAgent => getUserAgent();
}
