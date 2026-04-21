// timing_observer.dart
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../report_page_map.dart';
import '../report_route_page_map.dart';

class ReportTimingObserver extends NavigatorObserver {
  ReportTimingObserver();

  /// 根据 route 映射到 PageInfo（你可以按自己需求改这个表）
  PageInfo _pageInfoForRoute(Route<dynamic> route) {
    var path;

    if (navigator != null) {
      try {
        final goRouter = GoRouter.of(navigator!.context);
        final matches = goRouter.routerDelegate.currentConfiguration.matches;
        String? pattern;
        if (matches.isNotEmpty) {
          final lastMatch = matches.last;
          final route = lastMatch.route; // 类型是 RouteBase

          if (route is GoRoute) {
            // GoRoute 才有 path
            pattern = route.path; // e.g. '/mineFillCode/:title'
          } else {
            // 可能是 ShellRoute 等
            pattern = null; // 或者做你自己的兜底处理
          }
        }
        path = pattern ?? '';
      } catch (_) {
        // 不是 go_router 或取值失败，继续用兜底方案
      }
    }
    // 最终兜底方案
    if (path.isEmpty) {
      path = '/';
    }

    return PageInfo.path(path);
    // return PageInfo(key: path, name: appPageMap[routePageMap[path]] ?? path);
  }

  /// 设置当前页面
  void _updateCurrent(Route<dynamic>? route) {
    if (route == null) return;
    final info = _pageInfoForRoute(route);
    RouteStore.currentRoute = route;
    RouteStore.currentPageKey = info.key;
    RouteStore.currentPageName = info.name;
  }

  /// 根据来源 Route 更新 referrer 信息
  void _updateReferrer(Route<dynamic>? fromRoute) {
    if (fromRoute == null) {
      RouteStore.referrerPageKey = null;
      RouteStore.referrerPageName = null;
      return;
    }
    final fromInfo = _pageInfoForRoute(fromRoute);
    RouteStore.referrerPageKey = fromInfo.key;
    RouteStore.referrerPageName = fromInfo.name;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // 新页面的 referrer = previousRoute
    _updateReferrer(previousRoute);
    _updateCurrent(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    // replace 时，newRoute 的 referrer = oldRoute
    if (newRoute != null) {
      _updateReferrer(oldRoute);
      _updateCurrent(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // 返回上一页时：上一页的 referrer = 被 pop 的这一页
    if (previousRoute != null) {
      _updateReferrer(route);
      _updateCurrent(previousRoute);
    }
  }
}

class PageInfo {
  final String key;
  final String path;
  final String name;

  const PageInfo({required this.key, required this.path, required this.name});

  factory PageInfo.path(String path) => PageInfo(
        key: routePageMap[path] ?? path,
        path: path,
        name: appPageMap[routePageMap[path]] ?? path,
      );
}

class RouteStore {
  /// 当前正在展示的 Route
  static Route<dynamic>? currentRoute;

  /// 当前页面 page_key（你埋点里的 page_key）
  static String? currentPageKey;

  /// 当前页面 page_name（你埋点里的 page_name）
  static String? currentPageName;

  /// referrer_page_key
  static String? referrerPageKey;

  /// referrer_page_name
  static String? referrerPageName;
}
