import 'package:analytics_sdk/entity/analytics_tab.dart';
import 'package:analytics_sdk/entity/navigation_event.dart';
import 'package:analytics_sdk/utils/logger.dart';
import 'package:analytics_sdk/widget/_tab_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// TabBar 的 analytics 包装。
///
/// 监听 TabController，在 Tab 切换完成时自动上报 [NavigationEvent]。
/// 不应直接使用；通过 [AnalyticsTabBarExtension.withAnalytics] 调用。
class AnalyticsTabBarWrapper extends StatefulWidget implements PreferredSizeWidget {
  final TabBar child;
  final List<AnalyticsTab> tabs;

  /// 仅供测试使用；null 时走 AnalyticsSdk.instance.track。
  @visibleForTesting
  final void Function(dynamic event)? onTrack;

  const AnalyticsTabBarWrapper({
    super.key,
    required this.child,
    required this.tabs,
    this.onTrack,
  });

  @override
  Size get preferredSize => child.preferredSize;

  @override
  State<AnalyticsTabBarWrapper> createState() => _AnalyticsTabBarWrapperState();
}

class _AnalyticsTabBarWrapperState extends State<AnalyticsTabBarWrapper> {
  TabController? _controller;
  int _lastTrackedIndex = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _attachController(_resolveController());
    } catch (e) {
      Logger.analyticsSdk('AnalyticsTabBarWrapper.didChangeDependencies 异常，已安全处理: $e');
    }
  }

  @override
  void didUpdateWidget(AnalyticsTabBarWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    try {
      final newController = _resolveController();
      if (newController != _controller) {
        _attachController(newController);
        _lastTrackedIndex = -1; // 新 controller 时重置，防止去重误判
      }
    } catch (e) {
      Logger.analyticsSdk('AnalyticsTabBarWrapper.didUpdateWidget 异常，已安全处理: $e');
    }
  }

  TabController? _resolveController() {
    return widget.child.controller ?? DefaultTabController.maybeOf(context);
  }

  void _attachController(TabController? controller) {
    if (controller == _controller) return;
    _controller?.removeListener(_onControllerChange);
    _controller = controller;
    _controller?.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    try {
      final ctrl = _controller;
      if (ctrl == null || ctrl.indexIsChanging) return;

      final index = ctrl.index;
      if (index == _lastTrackedIndex) return;
      _lastTrackedIndex = index;

      if (widget.tabs.isEmpty) return;

      final tab = resolveTab(widget.tabs, index);
      trackWith(widget.onTrack, NavigationEvent(
        navigationKey: tab.key,
        navigationName: resolveTabName(tab),
      ));
    } catch (e) {
      Logger.analyticsSdk('TabBarWrapper._onControllerChange 异常，已安全处理: $e');
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChange);
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
