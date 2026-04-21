import 'dart:ui';

import 'package:analytics_sdk/config/sdk_config.dart';
import 'package:analytics_sdk/entity/page_click_event.dart';
import 'package:analytics_sdk/utils/logger.dart';
import 'package:analytics_sdk/manager/page_name_manager.dart';
import 'package:analytics_sdk/observer/page_lifecycle_observer.dart';
import 'package:analytics_sdk/utils/widget_bridge.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class GlobalClickWrapper extends StatefulWidget {
  final Widget child;

  const GlobalClickWrapper({
    required this.child,
    super.key,
  });

  @override
  State<GlobalClickWrapper> createState() => _GlobalClickWrapperState();
}

class _GlobalClickWrapperState extends State<GlobalClickWrapper> {
  DateTime? _lastClickTime;
  Offset? _pointerDownPosition;
  bool _pointerScrolled = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (PointerDownEvent event) {
        _pointerDownPosition = event.position;
        _pointerScrolled = false;
      },
      onPointerMove: (PointerMoveEvent event) {
        if (!_pointerScrolled && _pointerDownPosition != null) {
          final dist = (event.position - _pointerDownPosition!).distance;
          if (dist > kTouchSlop) {
            _pointerScrolled = true;
          }
        }
      },
      onPointerUp: (PointerUpEvent event) {
        if (!_pointerScrolled) {
          _handleTap(event);
        }
        _pointerDownPosition = null;
        _pointerScrolled = false;
      },
      onPointerCancel: (_) {
        _pointerDownPosition = null;
        _pointerScrolled = false;
      },
      // 透传所有事件，不影响原有交互
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }

  void _handleTap(PointerUpEvent event) {
    try {
      // 点击节流：限制点击事件上报频率，避免高频点击造成性能问题
      final now = DateTime.now();
      if (_lastClickTime != null &&
          now.difference(_lastClickTime!) < SdkConfig.clickThrottleDuration) {
        return;
      }
      _lastClickTime = now;

      // 允许触摸（移动端）、鼠标（桌面/Web）、触控板（macOS）；过滤触控笔等其他设备。
      final kind = event.kind;
      if (kind != PointerDeviceKind.touch &&
          kind != PointerDeviceKind.mouse &&
          kind != PointerDeviceKind.trackpad) {
        return;
      }

      final pageKey = PageLifecycleObserver.currentPageKey;

      if (pageKey.isEmpty || pageKey == 'unknown_page') {
        return;
      }

      final pageName = PageNameMapper.getPageName(pageKey);

      // 保存事件位置信息，避免在异步回调中访问已失效的事件对象
      final clickPosition = event.position;

      // 异步获取 RenderBox，避免在 build 阶段调用 findRenderObject
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (!mounted) return;

          final renderObject = context.findRenderObject();
          if (renderObject == null || renderObject is! RenderBox) return;
          final renderBox = renderObject;

          final size = renderBox.size;

          final clickX = clickPosition.dx.round();
          final clickY = clickPosition.dy.round();
          final percentX = size.width > 0 ? (clickPosition.dx / size.width * 100).round() : 0;
          final percentY = size.height > 0 ? (clickPosition.dy / size.height * 100).round() : 0;

          Logger.globalClick(
              '上报点击成功 → $pageKey ($clickX,$clickY) [$percentX%,$percentY%]');

          WidgetBridge.track(PageClickEvent(
            pageKey: pageKey,
            pageName: pageName,
            clickPageX: clickX,
            clickPageY: clickY,
            clickXPercent: percentX,
            clickYPercent: percentY,
            screenWidth: size.width.round(),
            screenHeight: size.height.round(),
          ));
        } catch (e) {
          Logger.globalClick('点击事件处理异常，已安全处理: $e');
        }
      });
    } catch (e) {
      Logger.globalClick('_handleTap() 异常，已安全处理: $e');
    }
  }
}
