// test/page_lifecycle_observer_test.dart
//
// 覆盖 PageLifecycleObserver 的三个核心风险路径：
//   1. 正常导航：didPush / didPop 上报正确
//   2. 帧回调触发前 pop（loadTimer 修复路径）
//   3. dispose() 清理 _activeTimers
//   4. didRemove（pushAndRemoveUntil 场景）

import 'package:analytics_sdk/config/sdk_config.dart';
import 'package:analytics_sdk/entity/app_page_view_event.dart';
import 'package:analytics_sdk/entity/navigation_event.dart';
import 'package:analytics_sdk/observer/page_lifecycle_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 构造一个带路由名的 MaterialPageRoute，无需真实 BuildContext
MaterialPageRoute<void> _route(String name) => MaterialPageRoute<void>(
      builder: (_) => const SizedBox(),
      settings: RouteSettings(name: name),
    );

void main() {
  setUp(() {
    // 把超时缩短到 50ms，避免真实等待 5 秒
    SdkConfig.pageLoadTimeout = const Duration(milliseconds: 50);
  });

  tearDown(() {
    SdkConfig.reset();
  });

  // ──────────────────────────────────────────────────────────────
  // 1. 正常导航
  // ──────────────────────────────────────────────────────────────
  group('正常导航', () {
    testWidgets('didPush 在帧回调后上报 AppPageViewEvent + NavigationEvent', (tester) async {
      final tracked = <dynamic>[];
      final observer = PageLifecycleObserver(
        track: tracked.add,
        getUserType: () => 'normal',
      );

      // addPostFrameCallback 需要有活跃的 widget 树才能触发
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      final route = _route('/home');
      observer.didPush(route, null);
      await tester.pump(); // 触发 addPostFrameCallback

      final pageViews = tracked.whereType<AppPageViewEvent>().toList();
      final navEvents = tracked.whereType<NavigationEvent>().toList();

      expect(pageViews, hasLength(1),
          reason: 'didPush 应上报一条 AppPageViewEvent');
      expect(pageViews.first.pageKey, 'home',
          reason: 'pageKey 应去掉 leading slash');
      expect(navEvents, hasLength(1),
          reason: 'didPush 应上报一条 NavigationEvent');
      expect(navEvents.first.navigationKey, 'home');

      observer.dispose();
    });

    testWidgets('push 到空栈时 AppPageViewEvent 的 referrerPageKey 为空字符串', (tester) async {
      final tracked = <dynamic>[];
      final observer = PageLifecycleObserver(
        track: tracked.add,
        getUserType: () => 'normal',
      );

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      final home = _route('/home');
      observer.didPush(home, null);
      await tester.pump();

      final homeView = tracked.whereType<AppPageViewEvent>().first;
      expect(homeView.referrerPageKey, '',
          reason: '空栈 push 时，没有来源页，referrerPageKey 应为空');
      expect(homeView.pageKey, 'home');

      observer.dispose();
    });

    testWidgets('didPop 上报返回目标页的 NavigationEvent', (tester) async {
      final tracked = <dynamic>[];
      final observer = PageLifecycleObserver(
        track: tracked.add,
        getUserType: () => 'normal',
      );

      final home = _route('/home');
      final detail = _route('/detail');

      observer.didPush(home, null);
      await tester.pump();
      observer.didPush(detail, home);
      await tester.pump();
      tracked.clear();

      observer.didPop(detail, home);

      final navEvents = tracked.whereType<NavigationEvent>().toList();
      expect(navEvents, hasLength(1),
          reason: 'didPop 应上报返回目标页的 NavigationEvent');
      expect(navEvents.first.navigationKey, 'home',
          reason: '返回目标页应为 home');

      observer.dispose();
    });
  });

  // ──────────────────────────────────────────────────────────────
  // 2. 帧回调触发前 pop（loadTimer?.cancel() 修复路径）
  // ──────────────────────────────────────────────────────────────
  group('帧回调触发前 pop（loadTimer 修复）', () {
    testWidgets('push 后立即 pop，帧回调触发时不上报 AppPageViewEvent', (tester) async {
      final tracked = <dynamic>[];
      final observer = PageLifecycleObserver(
        track: tracked.add,
        getUserType: () => 'normal',
      );

      final home = _route('/home');
      final page1 = _route('/page1');

      observer.didPush(home, null);
      await tester.pump();
      tracked.clear();

      // push page1（注册 frameCallback + timer），立即 pop（取消 timer，移出栈）
      observer.didPush(page1, home);
      observer.didPop(page1, home);

      // 帧回调触发：page1 已不在栈 → 走 !stillOnStack 分支，不上报
      await tester.pump();
      // 再推进时间让 50ms timer 到期，确认 timer 不触发二次 frameCallback
      await tester.pump(const Duration(milliseconds: 200));

      final pageViews = tracked
          .whereType<AppPageViewEvent>()
          .where((e) => e.pageKey == 'page1')
          .toList();

      expect(pageViews, isEmpty,
          reason: '帧回调触发前已 pop 的页面不应上报 AppPageViewEvent');

      observer.dispose();
    });

    testWidgets('push 后立即 pop 不抛异常（崩溃安全回归）', (tester) async {
      final observer = PageLifecycleObserver(
        track: (_) {},
        getUserType: () => 'normal',
      );

      final home = _route('/home');
      final page1 = _route('/page1');

      observer.didPush(home, null);
      await tester.pump();

      observer.didPush(page1, home);
      observer.didPop(page1, home);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull,
          reason: '快速 push/pop 不应抛出任何异常');

      observer.dispose();
    });
  });

  // ──────────────────────────────────────────────────────────────
  // 3. dispose() 清理 _activeTimers
  // ──────────────────────────────────────────────────────────────
  group('dispose() Timer 清理', () {
    testWidgets('dispose() 在有挂起 timer 时不抛异常', (tester) async {
      final observer = PageLifecycleObserver(
        track: (_) {},
        getUserType: () => 'normal',
      );

      final home = _route('/home');
      observer.didPush(home, null);
      // 不 pump：frameCallback 和 timer 均挂起

      expect(() => observer.dispose(), returnsNormally,
          reason: 'dispose() 在有挂起 timer 时不应抛异常');

      // 推进时间让 timer 到期：因为已取消，不应触发额外回调
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('dispose() 后 timer 到期不触发额外上报且不崩溃', (tester) async {
      final tracked = <dynamic>[];
      final observer = PageLifecycleObserver(
        track: tracked.add,
        getUserType: () => 'normal',
      );

      final home = _route('/home');
      observer.didPush(home, null);
      // 不 pump：timer（50ms）挂起

      observer.dispose();

      // 推进 200ms：timer 已取消，只有 addPostFrameCallback 可能触发一次
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull,
          reason: 'dispose() 后 timer 到期不应崩溃');
    });

    testWidgets('dispose() 同时挂起多路由时全部安全清理，不崩溃', (tester) async {
      final observer = PageLifecycleObserver(
        track: (_) {},
        getUserType: () => 'normal',
      );

      // 快速连续推入 5 页，不 pump，所有 timer 挂起
      for (var i = 0; i < 5; i++) {
        observer.didPush(_route('/page$i'), null);
      }

      expect(() => observer.dispose(), returnsNormally,
          reason: '多路由挂起时 dispose() 不应崩溃');

      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // 4. didRemove（pushAndRemoveUntil 场景）
  // ──────────────────────────────────────────────────────────────
  group('didRemove（pushAndRemoveUntil）', () {
    testWidgets('didRemove 触发 onPageExit 回调，传出正确的 pageKey', (tester) async {
      final exitedPages = <String>[];
      final observer = PageLifecycleObserver(
        track: (_) {},
        getUserType: () => 'normal',
        onPageExit: exitedPages.add,
      );

      final home = _route('/home');
      final pageA = _route('/a');

      observer.didPush(home, null);
      await tester.pump();
      observer.didPush(pageA, home);
      await tester.pump();

      observer.didRemove(pageA, home);

      expect(exitedPages, contains('a'),
          reason: 'didRemove 应调用 onPageExit，传出被移除页面的 pageKey');

      observer.dispose();
    });

    testWidgets('didRemove 取消对应 timer，不再上报被移除页面的 AppPageViewEvent', (tester) async {
      final tracked = <dynamic>[];
      final observer = PageLifecycleObserver(
        track: tracked.add,
        getUserType: () => 'normal',
      );

      final home = _route('/home');
      final pageA = _route('/a');

      observer.didPush(home, null);
      await tester.pump();

      // push /a 但不 pump：timer 挂起
      observer.didPush(pageA, home);
      // didRemove 应取消 timer
      observer.didRemove(pageA, home);

      tracked.clear();

      // 推进时间超过 timer 时长：timer 已被 didRemove 取消
      await tester.pump(const Duration(milliseconds: 200));

      final pageViews = tracked
          .whereType<AppPageViewEvent>()
          .where((e) => e.pageKey == 'a')
          .toList();

      expect(pageViews, isEmpty,
          reason: 'didRemove 取消 timer 后不应再上报该页面的 AppPageViewEvent');

      observer.dispose();
    });
  });
}
