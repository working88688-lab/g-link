import 'package:flutter/material.dart';
import 'package:g_link/ui_layer/page/bottom_navi_bar.dart';
import 'package:g_link/ui_layer/page/home_page.dart';
import 'package:g_link/ui_layer/page/chat/message_page.dart';
import 'package:g_link/ui_layer/page/mine_page.dart';
import 'package:g_link/ui_layer/page/publish_page.dart';
import 'package:g_link/ui_layer/page/short_video_page.dart';
import 'package:g_link/ui_layer/page/welcome_page.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:go_router/go_router.dart';
import 'paths.dart';

part 'routes.g.dart';

@TypedGoRoute<WelcomeRoute>(path: AppRouterPaths.root)
class WelcomeRoute extends GoRouteData {
  const WelcomeRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: const WelcomePage(),
    );
  }
}

@TypedStatefulShellRoute<StatefulShellRoute>(
  branches: [
    TypedStatefulShellBranch(
      routes: [
        TypedGoRoute<HomeRoute>(
          path: AppRouterPaths.home,
        ),
      ],
    ),
    TypedStatefulShellBranch(
      routes: [
        // TypedGoRoute<OriginAndGroupChatRoute>(
        TypedGoRoute<ShortVideoRoute>(
          path: AppRouterPaths.shortVideo,
        ),
      ],
    ),
    TypedStatefulShellBranch(
      routes: [
        TypedGoRoute<PublishRoute>(
          path: AppRouterPaths.publish,
        ),
      ],
    ),
    TypedStatefulShellBranch(
      routes: [
        TypedGoRoute<MessageRoute>(
          path: AppRouterPaths.message,
        ),
      ],
    ),
    TypedStatefulShellBranch(
      routes: [
        TypedGoRoute<MineRoute>(
          path: AppRouterPaths.mine,
        ),
      ],
    ),
  ],
)
class StatefulShellRoute extends StatefulShellRouteData {
  const StatefulShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state,
      StatefulNavigationShell navigationShell) {
    return BottomNaviBar(navigationShell: navigationShell);
  }
}

class HomeRoute extends GoRouteData {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

class ShortVideoRoute extends GoRouteData {
  const ShortVideoRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ShortVideoPage();
}

class PublishRoute extends GoRouteData {
  const PublishRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PublishPage();
}

class MessageRoute extends GoRouteData {
  const MessageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MessagePage();
}

class MineRoute extends GoRouteData {
  const MineRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const MinePage();
}


//
// @TypedGoRoute<WebViewRoute>(path: AppRouterPaths.webView)
// class WebViewRoute extends GoRouteData {
//   static final GlobalKey<NavigatorState> $parentNavigatorKey =
//       AppRouter.rootNavigatorKey;
//
//   const WebViewRoute(this.url);
//
//   final String url;
//
//   @override
//   Widget build(BuildContext context, GoRouterState state) {
//     late final userNotifier = context.read<UserNotifier>();
//     late Member member = userNotifier.member;
//     String webUrl = url
//         .replaceAll('{enc_aff}', member.encToken['{enc_aff}'] ?? '')
//         .replaceAll('%7Benc_aff%7D', member.encToken['%7Benc_aff%7D'] ?? '');
//     return WebViewScreen(url: webUrl);
//   }
// }
//
// @TypedGoRoute<BitPostDetailRoute>(path: AppRouterPaths.bitPostDetail)
// class BitPostDetailRoute extends GoRouteData {
//   static final GlobalKey<NavigatorState> $parentNavigatorKey =
//       AppRouter.rootNavigatorKey;
//
//   const BitPostDetailRoute(this.id);
//
//   final String id;
//
//   @override
//   Page<void> buildPage(BuildContext context, GoRouterState state) {
//     return CommonUtils.buildSlideTransitionPage(
//         state: state, child: BitPostDetailScreen(id: id));
//   }
// }

