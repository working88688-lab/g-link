/// 内部桥接层：解除 widget 对 AnalyticsSdk 的直接依赖。
///
/// AnalyticsSdk.init() 调用 [register] 注册实现；
/// widget 层通过此类的静态方法访问 SDK 能力，
/// 无需 import analytics_sdk.dart，避免上行依赖。
class WidgetBridge {
  static void Function(dynamic event)? _track;
  static bool _enableDebugBanner = false;
  static List<Map<String, String>> Function()? _getDebugSteps;

  /// 由 AnalyticsSdk.init() 调用，注册 SDK 实现
  static void register({
    required void Function(dynamic event) track,
    required bool enableDebugBanner,
    required List<Map<String, String>> Function() getDebugSteps,
  }) {
    _track = track;
    _enableDebugBanner = enableDebugBanner;
    _getDebugSteps = getDebugSteps;
  }

  static void track(dynamic event) => _track?.call(event);

  static bool get enableDebugBanner => _enableDebugBanner;

  static List<Map<String, String>> getDebugSteps() =>
      _getDebugSteps?.call() ?? [];
}
