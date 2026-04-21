import 'package:analytics_sdk/entity/analytics_tab.dart';
import 'package:analytics_sdk/entity/app_page_view_event.dart';
import 'package:analytics_sdk/entity/navigation_event.dart';
import 'package:analytics_sdk/observer/page_lifecycle_observer.dart';
import 'package:analytics_sdk/widget/analytics_bottom_nav_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BottomNavigationBar _buildNav({
  int currentIndex = 0,
  void Function(int)? onTap,
}) {
  return BottomNavigationBar(
    currentIndex: currentIndex,
    onTap: onTap,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
      BottomNavigationBarItem(icon: Icon(Icons.explore), label: '发现'),
    ],
  );
}

void main() {
  group('AnalyticsBottomNavWrapper', () {
    setUp(() {
      PageLifecycleObserver.currentPageKey = 'main';
    });

    testWidgets('点击新 Tab 时上报 AppPageViewEvent + NavigationEvent', (tester) async {
      final tracked = <dynamic>[];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AnalyticsBottomNavWrapper(
            tabs: const [AnalyticsTab('home', '首页'), AnalyticsTab('discover', '发现')],
            onTrack: tracked.add,
            child: _buildNav(currentIndex: 0),
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.explore));
      await tester.pump();

      expect(tracked.length, 2);
      expect(tracked[0], isA<AppPageViewEvent>());
      expect(tracked[1], isA<NavigationEvent>());

      final pageView = tracked[0] as AppPageViewEvent;
      expect(pageView.pageKey, 'discover');
      expect(pageView.pageName, '发现');
      expect(pageView.referrerPageKey, 'main'); // setUp 保证初始值
      expect(pageView.referrerPageName, 'main'); // PageNameMapper 无映射时 fallback 为 key 本身

      final nav = tracked[1] as NavigationEvent;
      expect(nav.navigationKey, 'discover');
      expect(nav.navigationName, '发现');
    });

    testWidgets('点击当前已选中的 Tab，不重复上报', (tester) async {
      final tracked = <dynamic>[];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AnalyticsBottomNavWrapper(
            tabs: const [AnalyticsTab('home', '首页'), AnalyticsTab('discover', '发现')],
            onTrack: tracked.add,
            child: _buildNav(currentIndex: 0),
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.home)); // 点击已选中的 tab
      await tester.pump();

      expect(tracked.length, 0);
    });

    testWidgets('原始 onTap 回调被正常触发', (tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AnalyticsBottomNavWrapper(
            tabs: const [AnalyticsTab('home'), AnalyticsTab('discover')],
            onTrack: (_) {},
            child: _buildNav(onTap: (i) => tappedIndex = i),
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.explore));
      await tester.pump();

      expect(tappedIndex, 1);
    });

    testWidgets('tabs 为空时不崩溃', (tester) async {
      final tracked = <dynamic>[];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AnalyticsBottomNavWrapper(
            tabs: const [],
            onTrack: tracked.add,
            child: _buildNav(),
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.explore));
      await tester.pump();

      expect(tracked.length, 0);
    });

    testWidgets('index 超出 tabs 长度时用 tab_N 兜底，不崩溃', (tester) async {
      final tracked = <dynamic>[];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AnalyticsBottomNavWrapper(
            tabs: const [AnalyticsTab('home')], // 只有1个，但有2个 item
            onTrack: tracked.add,
            child: _buildNav(currentIndex: 0),
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.explore)); // index=1，超出
      await tester.pump();

      expect(tracked.length, 2);
      final nav = tracked[1] as NavigationEvent;
      expect(nav.navigationKey, 'tab_1');
    });
  });
}
