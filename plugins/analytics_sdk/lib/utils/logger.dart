import 'package:flutter/foundation.dart';

/// 日志级别枚举
enum LogLevel {
  debug,
  info,
  warn,
  error,
}

/// 日志工具类：统一管理 SDK 中的所有日志输出
class Logger {
  Logger._();

  /// 是否启用日志（默认：仅在 debug 模式下启用）
  static bool enabled = kDebugMode;

  /// 外部日志回调（可选）。
  /// 注册后，所有 SDK 日志在 debugPrint 的同时也会转发给此回调。
  /// 示例：在 example app 中将 SDK 内部日志显示到 UI 面板。
  static void Function(String message, LogLevel level)? onLog;

  /// 日志标签映射
  static const Map<String, String> _tags = {
    'AnalyticsSdk': '[AnalyticsSdk]',
    'DomainManager': '[DomainManager]',
    'EventTypeConfigManager': '[EventTypeConfigManager]',
    'GlobalClick': '[GlobalClick]',
    'AdImpressionManager': '[AdImpressionManager]',
    'PageLifecycleObserver': '[PageLifecycleObserver]',
    'InitConfigResult': '[InitConfigResult]',
  };

  /// 获取日志标签
  static String _getTag(String tag) {
    return _tags[tag] ?? '[$tag]';
  }

  /// 格式化日志消息
  static String _formatMessage(String tag, String message) {
    return '${_getTag(tag)} $message';
  }

  /// 输出调试日志
  static void debug(String tag, String message) {
    if (enabled) {
      final msg = _formatMessage(tag, message);
      debugPrint(msg);
      try { onLog?.call(msg, LogLevel.debug); } catch (_) {}
    }
  }

  /// 输出信息日志
  static void info(String tag, String message) {
    if (enabled) {
      final msg = _formatMessage(tag, message);
      debugPrint(msg);
      try { onLog?.call(msg, LogLevel.info); } catch (_) {}
    }
  }

  /// 输出警告日志
  static void warn(String tag, String message) {
    if (enabled) {
      final msg = _formatMessage(tag, '⚠️ $message');
      debugPrint(msg);
      try { onLog?.call(msg, LogLevel.warn); } catch (_) {}
    }
  }

  /// 输出错误日志
  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    if (enabled) {
      final errorInfo = error != null ? ', 错误: $error' : '';
      final stackInfo = stackTrace != null ? '\n堆栈: $stackTrace' : '';
      final msg = _formatMessage(tag, '❌ $message$errorInfo$stackInfo');
      debugPrint(msg);
      try { onLog?.call(msg, LogLevel.error); } catch (_) {}
    }
  }

  /// 输出日志（自动判断级别）
  static void log(String tag, String message, {LogLevel level = LogLevel.debug}) {
    switch (level) {
      case LogLevel.debug:
        debug(tag, message);
        break;
      case LogLevel.info:
        info(tag, message);
        break;
      case LogLevel.warn:
        warn(tag, message);
        break;
      case LogLevel.error:
        error(tag, message);
        break;
    }
  }

  /// 便捷方法：AnalyticsSdk 日志
  static void analyticsSdk(String message, {LogLevel level = LogLevel.debug}) {
    log('AnalyticsSdk', message, level: level);
  }

  /// 便捷方法：DomainManager 日志
  static void domainManager(String message, {LogLevel level = LogLevel.debug}) {
    log('DomainManager', message, level: level);
  }

  /// 便捷方法：EventTypeConfigManager 日志
  static void eventTypeConfigManager(String message, {LogLevel level = LogLevel.debug}) {
    log('EventTypeConfigManager', message, level: level);
  }

  /// 便捷方法：GlobalClick 日志
  static void globalClick(String message, {LogLevel level = LogLevel.debug}) {
    log('GlobalClick', message, level: level);
  }

  /// 便捷方法：AdImpressionManager 日志
  static void adImpressionManager(String message, {LogLevel level = LogLevel.debug}) {
    log('AdImpressionManager', message, level: level);
  }

  /// 便捷方法：PageLifecycleObserver 日志
  static void pageLifecycleObserver(String message, {LogLevel level = LogLevel.debug}) {
    log('PageLifecycleObserver', message, level: level);
  }

  /// 便捷方法：InitConfigResult 日志
  static void initConfigResult(String message, {LogLevel level = LogLevel.debug}) {
    log('InitConfigResult', message, level: level);
  }
}
