import 'package:analytics_sdk/analytics_sdk.dart';
import 'package:analytics_sdk/entity/analytics_tab.dart';
import 'package:analytics_sdk/entity/app_page_view_event.dart';
import 'package:analytics_sdk/entity/navigation_event.dart';
import 'package:analytics_sdk/manager/page_name_manager.dart';
import 'package:analytics_sdk/observer/page_lifecycle_observer.dart';
import 'package:analytics_sdk/utils/logger.dart';
import 'package:analytics_sdk/widget/_tab_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// BottomNavigationBar 的 analytics 包装。
///
/// 使用 Listener + LayoutBuilder 方案：保持原始 child 完整进入 widget 树，
/// 通过指针位移计算 tab 索引，无需拷贝 BottomNavigationBar 的所有属性。
/// 这样 Flutter 升级新增属性时，SDK 不需要任何改动。
///
/// 不应直接使用；通过 [AnalyticsBottomNavExtension.withAnalytics] 调用。
class AnalyticsBottomNavWrapper extends StatefulWidget {
  final BottomNavigationBar child;
  final List<AnalyticsTab> tabs;

  // ignore: invalid_use_of_visible_for_testing_member
  /// 仅供测试使用；null 时走 AnalyticsSdk.instance.track。
  @visibleForTesting
  final void Function(dynamic event)? onTrack;

  const AnalyticsBottomNavWrapper({
    super.key,
    required this.child,
    required this.tabs,
    this.onTrack,
  });

  @override
  State<AnalyticsBottomNavWrapper> createState() =>
      _AnalyticsBottomNavWrapperState();
}

class _AnalyticsBottomNavWrapperState
    extends State<AnalyticsBottomNavWrapper> {
  /// 记录 pointer-down 位置，用于判断是否为 tap（而非拖拽）
  Offset? _tapDownPosition;

  /// 去重：记录最近一次上报的 tab 索引，防止快速连点重复上报
  int _lastTrackedIndex = -1;

  @override
  void didUpdateWidget(AnalyticsBottomNavWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 父组件以编程方式切换 currentIndex 时同步去重状态
    if (widget.child.currentIndex != oldWidget.child.currentIndex) {
      _lastTrackedIndex = widget.child.currentIndex;
    }
  }

  /// 纯计算：根据 tap 坐标解析 tab 索引。
  /// 返回 null 表示无效点击（越界、重复、当前已选中）。
  int? _indexFromTap(double tapX, double totalWidth, TextDirection textDirection) {
    final itemCount = widget.child.items.length;
    if (itemCount == 0 || totalWidth <= 0) return null;

    var index = (tapX / (totalWidth / itemCount))
        .floor()
        .clamp(0, itemCount - 1);

    // RTL 布局下 BottomNavigationBar items 从右到左排列，镜像索引
    if (textDirection == TextDirection.rtl) {
      index = itemCount - 1 - index;
    }

    if (index == _lastTrackedIndex || index == widget.child.currentIndex) {
      return null;
    }
    return index;
  }

  /// 根据横坐标、容器宽度和文字方向计算 tab 索引并上报埋点
  void _handleTapAt(double tapX, double totalWidth, TextDirection textDirection) {
    try {
      if (widget.tabs.isEmpty) return;

      final index = _indexFromTap(tapX, totalWidth, textDirection);
      if (index == null) return;
      _lastTrackedIndex = index;

      final tab = resolveTab(widget.tabs, index);
      final pageKey = tab.key;
      final pageName = resolveTabName(tab);

      final referrerKey = PageLifecycleObserver.currentPageKey;
      final referrerName = PageNameMapper.getPageName(referrerKey);
      PageLifecycleObserver.recordNavigation(pageKey);

      // 记录 tap 时刻；在下一帧渲染完成后测量实际耗时，与 PageLifecycleObserver 保持一致
      final tapTime = DateTime.now();
      final onTrackSnapshot = widget.onTrack;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final pageLoadTime = DateTime.now().difference(tapTime).inMilliseconds;
        try {
          trackWith(onTrackSnapshot, AppPageViewEvent(
            userType: AnalyticsSdk.userTypeProvider(),
            pageKey: pageKey,
            pageName: pageName,
            referrerPageKey: referrerKey,
            referrerPageName: referrerName,
            currentPageKey: pageKey,
            currentPageName: pageName,
            pageLoadTime: pageLoadTime,
          ));
          trackWith(onTrackSnapshot, NavigationEvent(
            navigationKey: pageKey,
            navigationName: pageName,
          ));
        } catch (e) {
          Logger.analyticsSdk('BottomNavWrapper.post-frame 上报异常，已安全处理: $e');
        }
      });
    } catch (e) {
      Logger.analyticsSdk('BottomNavWrapper._handleTapAt 异常，已安全处理: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textDirection = Directionality.of(context);
        return Listener(
          // 透传所有指针事件，不干扰 BottomNavigationBar 自身的手势识别
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            _tapDownPosition = event.localPosition;
          },
          onPointerUp: (event) {
            final down = _tapDownPosition;
            _tapDownPosition = null;
            if (down == null) return;
            // 位移 > 18px（与 Flutter kTouchSlop 对齐）视为拖拽，不触发 tab 埋点
            if ((event.localPosition - down).distance > 18) return;
            _handleTapAt(event.localPosition.dx, constraints.maxWidth, textDirection);
          },
          onPointerCancel: (_) {
            _tapDownPosition = null;
          },
          // 原始 child 完整保留，onTap 由 BottomNavigationBar 自身调用
          child: widget.child,
        );
      },
    );
  }
}
