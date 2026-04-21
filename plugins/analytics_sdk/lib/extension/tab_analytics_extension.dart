// lib/extension/tab_analytics_extension.dart
import 'package:analytics_sdk/entity/analytics_tab.dart';
import 'package:analytics_sdk/widget/analytics_bottom_nav_wrapper.dart';
import 'package:analytics_sdk/widget/analytics_tab_bar_wrapper.dart';
import 'package:flutter/material.dart';

/// 为 [BottomNavigationBar] 提供 analytics 自动埋点能力。
///
/// 示例：
/// ```dart
/// BottomNavigationBar(
///   currentIndex: _index,
///   onTap: (i) => setState(() => _index = i),
///   items: const [...],
/// ).withAnalytics(tabs: [
///   AnalyticsTab('home', '首页'),
///   AnalyticsTab('discover'),  // pageName 走 PageNameMapper 自动解析
/// ])
/// ```
extension AnalyticsBottomNavExtension on BottomNavigationBar {
  /// 切换 Tab 时自动上报 AppPageViewEvent + NavigationEvent，
  /// 并更新 PageLifecycleObserver.currentPageKey。
  Widget withAnalytics({required List<AnalyticsTab> tabs}) {
    return AnalyticsBottomNavWrapper(
      tabs: tabs,
      child: this,
    );
  }
}

/// 为 [TabBar] 提供 analytics 轻导航埋点能力。
///
/// 示例：
/// ```dart
/// TabBar(
///   controller: _tabController,
///   tabs: const [Tab(text: '视频'), Tab(text: '小说')],
/// ).withAnalytics(tabs: [
///   AnalyticsTab('video', '视频'),
///   AnalyticsTab('novel'),
/// ])
/// ```
extension AnalyticsTabBarExtension on TabBar {
  /// 切换 Tab 时自动上报 NavigationEvent（轻导航，不更新 currentPageKey）。
  AnalyticsTabBarWrapper withAnalytics({required List<AnalyticsTab> tabs}) {
    return AnalyticsTabBarWrapper(
      tabs: tabs,
      child: this,
    );
  }
}
