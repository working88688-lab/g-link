import 'package:flutter/material.dart';

import '../event_tracking.dart';
import 'report_timing_observer.dart';

class ReportGestureDetector extends StatelessWidget {
  const ReportGestureDetector({
    super.key,
    this.behavior,
    this.child,
    this.onTap,
    this.onLongPress,
    this.onVerticalDragDown,
    this.onVerticalDragUpdate,
    this.onHorizontalDragDown,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragStart,
    this.onHorizontalDragEnd,
  });
  final Widget? child;
  final Function()? onTap;
  final GestureLongPressCallback? onLongPress;
  final Function(DragDownDetails)? onVerticalDragDown;
  final Function(DragUpdateDetails)? onVerticalDragUpdate;

  final Function(DragDownDetails)? onHorizontalDragDown;
  final Function(DragUpdateDetails)? onHorizontalDragUpdate;

  final GestureDragStartCallback? onHorizontalDragStart;
  final GestureDragEndCallback? onHorizontalDragEnd;
  final HitTestBehavior? behavior;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onVerticalDragDown: onVerticalDragDown,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onHorizontalDragDown: onHorizontalDragDown,
      onHorizontalDragUpdate: onHorizontalDragUpdate,
      onHorizontalDragStart: onHorizontalDragStart,
      onHorizontalDragEnd: onHorizontalDragEnd,
      behavior: behavior,
      child: child,
      onTapDown: (details) {
        // 全局坐标
        final dx = details.globalPosition.dx.toInt();
        final dy = details.globalPosition.dy.toInt();
        // 屏幕大小
        final size = MediaQuery.of(context).size;
        // 百分比
        final px = (dx / size.width * 100).round();
        final py = (dy / size.height * 100).round();

        // onTap?.call();
        postXYReport(context, size, dx, dy, px, py);
      },
    );
  }

  void postXYReport(
      BuildContext context, Size size, int dx, int dy, int px, int py) {
    EventTracking().reportSingle({
      "event": "page_click",
      "page_key": RouteStore.currentPageKey,
      "page_name": RouteStore.currentPageName,
      "click_page_x": dx,
      "click_page_y": dy,
      "click_x_percent": px,
      "click_y_percent": py,
      "screen_width": size.width,
      "screen_height": size.height,
    });
  }
}
