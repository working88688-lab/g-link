// lib/observer/page_lifecycle_observer.dart

import 'dart:async';

import 'package:analytics_sdk/config/sdk_config.dart';
import 'package:analytics_sdk/entity/app_page_view_event.dart';
import 'package:analytics_sdk/utils/logger.dart';
import 'package:analytics_sdk/entity/navigation_event.dart';
import 'package:analytics_sdk/manager/page_name_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class PageLifecycleObserver extends NavigatorObserver {
  final List<_PageInfo> _pageStack = [];

  /// 事件上报回调（由 AnalyticsSdk 在组合根注入，避免循环依赖）
  final void Function(dynamic event) _track;

  /// 用户类型提供者（由 AnalyticsSdk 在组合根注入）
  final String Function() _getUserType;

  /// 页面退出回调，传出退出页面的 pageKey（用于清除页面级广告去重状态）
  final void Function(String pageKey)? _onPageExit;

  /// 页面堆栈最大容量限制，防止内存无限增长
  static int get _maxPageStackSize => SdkConfig.maxPageStackSize;

  // 全局可访问的当前页面 key
  static String currentPageKey = 'main';

  /// 供非路由导航（如 BottomNavigationBar tab 切换）记录当前页面，
  /// 使后续路由跳转的 referrer 信息保持正确。
  static void recordNavigation(String pageKey) {
    currentPageKey = pageKey;
  }

  static String _stripLeadingSlash(String name) =>
      PageNameMapper.normalizeKey(name);

  // 跟踪活动的 Timer，防止内存泄漏
  final Map<Route, Timer> _activeTimers = <Route, Timer>{};

  PageLifecycleObserver({
    required void Function(dynamic event) track,
    required String Function() getUserType,
    void Function(String pageKey)? onPageExit,
  })  : _track = track,
        _getUserType = getUserType,
        _onPageExit = onPageExit;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    try {
      if (route is PageRoute && route.settings.name != null) {
        _handlePageEnter(route);
      }
    } catch (e) {
      Logger.pageLifecycleObserver(' didPush() 异常，已安全处理: $e');
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    try {
      if (_pageStack.isNotEmpty && _pageStack.last.route == route) {
        _handlePageExit(route);

        // 上报返回目标页的 NavigationEvent
        final toKey = _pageStack.isNotEmpty
            ? _pageStack.last.pageKey
            : _stripLeadingSlash(previousRoute?.settings.name ?? 'main');
        try {
          _track(NavigationEvent(
            navigationKey: toKey,
            navigationName: PageNameMapper.getPageName(toKey),
          ));
        } catch (e) {
          Logger.pageLifecycleObserver(' NavigationEvent(返回) 上报失败: $e');
        }
        currentPageKey = toKey;
      }
    } catch (e) {
      Logger.pageLifecycleObserver(' didPop() 异常，已安全处理: $e');
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    try {
      // pushAndRemoveUntil / removeRoute 走这里，需主动清理被移除路由
      final timer = _activeTimers.remove(route);
      timer?.cancel();
      final removed = _pageStack.where((info) => info.route == route).toList();
      _pageStack.removeWhere((info) => info.route == route);
      for (final info in removed) {
        try {
          _onPageExit?.call(info.pageKey);
        } catch (e) {
          Logger.pageLifecycleObserver('onPageExit 回调异常 (didRemove): $e');
        }
      }
    } catch (e) {
      Logger.pageLifecycleObserver(' didRemove() 异常，已安全处理: $e');
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    try {
      // 旧页面 hide
      if (oldRoute is PageRoute && _pageStack.isNotEmpty) {
        if (_pageStack.last.route == oldRoute) {
          _handlePageExit(oldRoute);
        }
      }
      // 新页面 show + 曝光
      if (newRoute is PageRoute && newRoute.settings.name != null) {
        _handlePageEnter(newRoute);
      }
    } catch (e) {
      Logger.pageLifecycleObserver(' didReplace() 异常，已安全处理: $e');
    }
  }

  /// 处理新页面进入：注册帧回调、上报 PageView/Navigation、入栈
  void _handlePageEnter(PageRoute route) {
    final pageKey = _stripLeadingSlash(route.settings.name!);
    final pageName = PageNameMapper.getPageName(pageKey);
    currentPageKey = pageKey;

    final referrerKey = _pageStack.isEmpty ? '' : _pageStack.last.pageKey;
    final referrerName = _pageStack.isEmpty ? '' : _pageStack.last.pageName;
    final enterTime = DateTime.now();

    bool callbackExecuted = false;
    Timer? loadTimer;

    void frameCallback(Duration timestamp) {
      if (callbackExecuted) return;
      // 页面可能在帧回调等待期间被 pop，检查是否仍在栈中
      final stillOnStack = _pageStack.any((info) => info.route == route);
      if (!stillOnStack) {
        callbackExecuted = true;
        loadTimer?.cancel();
        _activeTimers.remove(route);
        return;
      }
      callbackExecuted = true;

      final pageLoadTime = DateTime.now().difference(enterTime).inMilliseconds;
      loadTimer?.cancel();
      _activeTimers.remove(route);

      String userType;
      try {
        userType = _getUserType();
      } catch (e) {
        Logger.pageLifecycleObserver(' 获取用户类型失败，使用默认值: $e');
        userType = 'normal';
      }

      try {
        _track(AppPageViewEvent(
          userType: userType,
          pageKey: pageKey,
          pageName: pageName,
          referrerPageKey: referrerKey,
          referrerPageName: referrerName,
          currentPageKey: pageKey,
          currentPageName: pageName,
          pageLoadTime: pageLoadTime,
        ));
      } catch (e) {
        Logger.pageLifecycleObserver(' AppPageViewEvent 上报失败: $e');
      }

      try {
        _track(NavigationEvent(
          navigationKey: pageKey,
          navigationName: pageName,
        ));
      } catch (e) {
        Logger.pageLifecycleObserver(' NavigationEvent 上报失败: $e');
      }
    }

    // 超时保护：如果第一帧回调未在规定时间内执行，重新注册
    loadTimer = Timer(SdkConfig.pageLoadTimeout, () {
      if (!callbackExecuted && _pageStack.isNotEmpty && _pageStack.last.route == route) {
        SchedulerBinding.instance.addPostFrameCallback(frameCallback);
      }
    });
    _activeTimers[route] = loadTimer;
    SchedulerBinding.instance.addPostFrameCallback(frameCallback);

    // 页面堆栈容量检查
    if (_pageStack.length >= _maxPageStackSize) {
      final evicted = _pageStack.removeAt(0);
      final evictedTimer = _activeTimers.remove(evicted.route);
      evictedTimer?.cancel();
    }

    _pageStack.add(_PageInfo(
      pageKey: pageKey,
      pageName: pageName,
      enterTime: enterTime,
      route: route,
    ));
  }

  /// 释放所有待触发的 Timer，防止 SDK dispose 后继续触发幽灵上报
  void dispose() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
  }

  /// 处理页面退出：清理 Timer、出栈、触发页面退出回调
  void _handlePageExit(Route route) {
    if (_pageStack.isEmpty || _pageStack.last.route != route) return;

    final exitingPageKey = _pageStack.last.pageKey;
    _pageStack.removeLast();

    // 清理该路由的 Timer，防止内存泄漏
    final timer = _activeTimers.remove(route);
    timer?.cancel();

    try {
      _onPageExit?.call(exitingPageKey);
    } catch (e) {
      Logger.pageLifecycleObserver('onPageExit 回调异常: $e');
    }
  }
}

class _PageInfo {
  final String pageKey;
  final String pageName;
  final DateTime enterTime;
  final Route route;

  _PageInfo({
    required this.pageKey,
    required this.pageName,
    required this.enterTime,
    required this.route,
  });
}
