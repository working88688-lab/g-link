import 'device_fingerprint_native.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'device_fingerprint_web.dart';

/// 设备指纹工具类
///
/// SDK 内部自动调用，业务方无需手动传入。
///
/// **生成规则**
/// 1. 将非空设备因子（deviceId、device、deviceBrand、deviceModel、
///    systemName、systemVersion；Web 端额外加 userAgent、屏幕分辨率、
///    语言、时区）用 `|` 拼接后做 SHA-256，取 64 位十六进制作为指纹。
/// 2. 若所有因子均为空，降级为随机 UUID v4 并持久化至本地存储。
///
/// **平台差异**
/// - Native（Android/iOS/桌面）：降级 UUID 存于 `applicationDocumentsDirectory/analytics_fingerprint.txt`
/// - Web：降级 UUID 存于 `localStorage['analytics_fp']`
///
/// **失败兜底**：任何异常均返回空字符串，事件正常上报，仅 `device_fingerprint` 字段为空。
///
/// **注意**：`device_fingerprint` 不参与 `event_id` 的计算。
class DeviceFingerprintUtil {
  /// 指纹生成规则版本号。
  ///
  /// 每次生成规则（因子组合、哈希算法）发生变更时，此版本号必须同步递增，
  /// 以便服务端区分不同规则下生成的指纹，支持跨版本数据对比分析。
  ///
  /// 版本历史：
  /// - `1`（v0.2.0）：SHA-256(deviceId|device|deviceBrand|deviceModel|systemName|systemVersion)；
  ///                  Web 端额外加 userAgent、屏幕分辨率、语言、时区；
  ///                  因子全空时降级为 UUID v4 持久化。
  static const String kVersion = '1.0.0';

  static String? _cache;

  /// 获取设备指纹。
  ///
  /// 首次调用时根据传入的设备因子计算并内存缓存，后续直接返回缓存值。
  /// 若设备因子发生变化需重新计算，请先调用 [clearCache]。
  static Future<String> getFingerprint({
    String deviceId = '',
    String device = '',
    String deviceBrand = '',
    String deviceModel = '',
    String systemName = '',
    String systemVersion = '',
    String userAgent = '',
  }) async {
    if (_cache != null) return _cache!;
    _cache = await generateOrLoadFingerprint(
      deviceId: deviceId,
      device: device,
      deviceBrand: deviceBrand,
      deviceModel: deviceModel,
      systemName: systemName,
      systemVersion: systemVersion,
      userAgent: userAgent,
    );
    return _cache!;
  }

  /// 清除内存缓存（通常仅测试时使用，不会删除本地存储文件）
  static void clearCache() {
    _cache = null;
  }
}
