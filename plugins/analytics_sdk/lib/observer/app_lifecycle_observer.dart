import 'package:analytics_sdk/manager/session_manager.dart';
import 'package:analytics_sdk/utils/logger.dart';
import 'package:flutter/widgets.dart';

/// 应用生命周期观察者：监听应用前后台切换，用于会话管理
class AppLifecycleObserver with WidgetsBindingObserver {
  static final AppLifecycleObserver instance = AppLifecycleObserver._internal();

  factory AppLifecycleObserver() => instance;

  AppLifecycleObserver._internal();

  bool _isInitialized = false;

  /// 初始化观察者
  void initialize() {
    if (!_isInitialized) {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;
      Logger.analyticsSdk('应用生命周期观察者已初始化');
    }
  }

  /// 销毁观察者
  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
      Logger.analyticsSdk('应用生命周期观察者已销毁');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    try {
      switch (state) {
        case AppLifecycleState.resumed:
          // 应用从后台恢复前台
          SessionManager.instance.onAppForeground();
          Logger.analyticsSdk('应用恢复前台');
          break;
        case AppLifecycleState.paused:
          // Android 和 iOS 进入后台均走 paused（iOS 先经过 hidden 再到 paused）
          // 统一在此记录后台开始时间，避免在 hidden 重复记录
          SessionManager.instance.onAppBackground();
          Logger.analyticsSdk('应用进入后台');
          break;
        case AppLifecycleState.inactive:
          // inactive 是过渡状态（进后台和回前台都会经过），不记录后台时间
          Logger.analyticsSdk('应用进入 inactive 状态');
          break;
        case AppLifecycleState.detached:
          // 应用即将终止
          Logger.analyticsSdk('应用即将终止');
          break;
        case AppLifecycleState.hidden:
          // iOS/Android 过渡状态：进后台和回前台都会经过此状态。
          // 不在此记录后台时间——回前台时触发会把 _backgroundTime 重置为"刚才"，
          // 导致 SessionManager 计算后台时长永远为 0，30 分钟阈值失效。
          Logger.analyticsSdk('应用隐藏（hidden 过渡状态，不计入后台时间）');
          break;
      }
    } catch (e) {
      Logger.analyticsSdk('应用生命周期状态变化处理异常: $e');
    }
  }
}
