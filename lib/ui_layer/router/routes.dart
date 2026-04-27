import 'package:flutter/material.dart';
import 'package:g_link/domain/domain.dart';
import 'package:g_link/ui_layer/page/bottom_navi_bar.dart';
import 'package:g_link/ui_layer/page/auth_page.dart';
import 'package:g_link/ui_layer/page/message/chat_page.dart';
import 'package:g_link/ui_layer/page/message/message_page.dart';
import 'package:g_link/ui_layer/page/message/search/chat_records_search_page.dart';
import 'package:g_link/ui_layer/page/message/search/global_search_page.dart';
import 'package:g_link/ui_layer/page/message/search/user_search_page.dart';
import 'package:g_link/ui_layer/page/complaint/complaint_page.dart';
import 'package:g_link/ui_layer/page/forgot_password_page.dart';
import 'package:g_link/ui_layer/page/guide/guide_page.dart';
import 'package:g_link/ui_layer/page/home_page.dart';
import 'package:g_link/ui_layer/page/message_page_v2.dart';
import 'package:g_link/ui_layer/page/mine_page.dart';
import 'package:g_link/ui_layer/page/publish_page.dart';
import 'package:g_link/ui_layer/page/short_video/short_video_page.dart';
import 'package:g_link/ui_layer/page/register/register_page.dart';
import 'package:g_link/ui_layer/page/welcome_page.dart';
import 'package:g_link/ui_layer/notifier/auth_notifier.dart';
import 'package:g_link/domain/domains/auth.dart';
import 'package:g_link/domain/domains/report.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../page/message/message_page.dart';
import 'router.dart';
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

@TypedGoRoute<LoginRoute>(path: AppRouterPaths.login)
class LoginRoute extends GoRouteData {
  const LoginRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final authDomain = context.read<AuthDomain>();
    final appDomain = context.read<AppDomain>();
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: ChangeNotifierProvider(
        create: (_) =>
            AuthNotifier(
              authDomain,
              deviceId: '${appDomain.info['oauth_id'] ?? ''}',
              deviceType: '${appDomain.info['oauth_type'] ?? 'ios'}',
            ),
        child: const AuthPage(),
      ),
    );
  }
}

@TypedGoRoute<RegisterRoute>(path: AppRouterPaths.register)
class RegisterRoute extends GoRouteData {
  const RegisterRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: const RegisterPage(),
    );
  }
}

@TypedGoRoute<ForgotPasswordRoute>(path: AppRouterPaths.forgotPassword)
class ForgotPasswordRoute extends GoRouteData {
  const ForgotPasswordRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final authDomain = context.read<AuthDomain>();
    final appDomain = context.read<AppDomain>();
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: ChangeNotifierProvider(
        create: (_) =>
            AuthNotifier(
              authDomain,
              deviceId: '${appDomain.info['oauth_id'] ?? ''}',
              deviceType: '${appDomain.info['oauth_type'] ?? 'ios'}',
            ),
        child: const ForgotPasswordPage(),
      ),
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

@TypedGoRoute<GuideRoute>(path: AppRouterPaths.guide)
class GuideRoute extends GoRouteData {
  const GuideRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: const GuidePage(),
    );
  }
}

@TypedGoRoute<ComplaintRoute>(path: AppRouterPaths.complaint)
class ComplaintRoute extends GoRouteData {
  const ComplaintRoute({this.targetId, this.targetType});

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      AppRouter.rootNavigatorKey;

  /// 被举报对象 ID
  final int? targetId;

  /// 举报类型: 'user' | 'video' | 'comment' | 'post'，缺省 'user'
  final String? targetType;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final target = switch (targetType) {
      'video' => ReportTarget.video,
      'comment' => ReportTarget.comment,
      'post' => ReportTarget.post,
      _ => ReportTarget.user,
    };
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: ComplaintPage(targetId: targetId, reportTarget: target),
    );
  }
}

@TypedGoRoute<ChatConversationRoute>(path: AppRouterPaths.chatConversation)
class ChatConversationRoute extends GoRouteData {
  const ChatConversationRoute({
    required this.name,
    this.avatarUrl = '',
    this.isOnline = false,
  });

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      AppRouter.rootNavigatorKey;

  final String name;
  final String avatarUrl;
  final bool isOnline;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: ChatPage(
        name: name,
        avatarUrl: avatarUrl,
        isOnline: isOnline,
      ),
    );
  }
}

@TypedGoRoute<UserSearchRoute>(path: AppRouterPaths.userSearch)
class UserSearchRoute extends GoRouteData {
  const UserSearchRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      AppRouter.rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: const UserSearchPage(),
    );
  }
}

@TypedGoRoute<GlobalSearchRoute>(path: AppRouterPaths.globalSearch)
class GlobalSearchRoute extends GoRouteData {
  const GlobalSearchRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      AppRouter.rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: const GlobalSearchPage(),
    );
  }
}

@TypedGoRoute<ChatRecordsSearchRoute>(path: AppRouterPaths.chatRecordsSearch)
class ChatRecordsSearchRoute extends GoRouteData {
  const ChatRecordsSearchRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      AppRouter.rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: const ChatRecordsSearchPage(),
    );
  }
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
