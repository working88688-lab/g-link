import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
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
import 'package:g_link/ui_layer/page/home/home_page.dart';
import 'package:g_link/ui_layer/page/mine/mine_page.dart';
import 'package:g_link/ui_layer/page/mine/feedback_submit_page.dart';
import 'package:g_link/ui_layer/page/mine/notification_detail_page.dart';
import 'package:g_link/ui_layer/page/mine/notification_page.dart';
import 'package:g_link/ui_layer/page/mine/profile_edit_page.dart';
import 'package:g_link/ui_layer/page/mine/recommend_follow_list_page.dart';
import 'package:g_link/ui_layer/page/message_page_v2.dart';
import 'package:g_link/ui_layer/page/publish/publish_album_page.dart';
import 'package:g_link/ui_layer/page/publish/publish_composer_page.dart';
import 'package:g_link/ui_layer/page/publish/publish_page.dart';
import 'package:g_link/ui_layer/page/short_video/short_video_page.dart';
import 'package:g_link/ui_layer/page/register/register_page.dart';
import 'package:g_link/ui_layer/page/welcome_page.dart';
import 'package:g_link/ui_layer/notifier/auth_notifier.dart';
import 'package:g_link/domain/domains/auth.dart';
import 'package:g_link/domain/domains/report.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
        create: (_) => AuthNotifier(
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
        create: (_) => AuthNotifier(
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
  Widget builder(BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
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
  Widget build(BuildContext context, GoRouterState state) => const ShortVideoPage();
}

@TypedGoRoute<PublishRoute>(path: AppRouterPaths.publish)
class PublishRoute extends GoRouteData {
  const PublishRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: PublishPage(),
      begin: const Offset(0, 1),
    );
  }
}

@TypedGoRoute<PublishAlbumRoute>(path: AppRouterPaths.publishAlbum)
class PublishAlbumRoute extends GoRouteData {
  const PublishAlbumRoute({this.initialSelectedAssets = const []});

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

  final List<AssetEntity> initialSelectedAssets;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: PublishAlbumPage(initialSelectedAssets: initialSelectedAssets),
      begin: const Offset(0, 1),
    );
  }
}

class MessageRoute extends GoRouteData {
  const MessageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const MessagePage();
}

class MineRoute extends GoRouteData {
  const MineRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const MinePage();
}

@TypedGoRoute<RecommendFollowListRoute>(path: AppRouterPaths.mineRecommendFollow)
class RecommendFollowListRoute extends GoRouteData {
  const RecommendFollowListRoute({this.limit = 10});

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

  final int limit;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: RecommendFollowListPage(limit: limit),
    );
  }
}

@TypedGoRoute<EditProfileRoute>(path: AppRouterPaths.mineEditProfile)
class EditProfileRoute extends GoRouteData {
  const EditProfileRoute({
    required this.nickname,
    required this.username,
    required this.bio,
    required this.userLocation,
    required this.avatarUrl,
    required this.coverUrl,
  });

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

  final String nickname;
  final String username;
  final String bio;
  final String userLocation;
  final String avatarUrl;
  final String coverUrl;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: ProfileEditPage(
        nickname: nickname,
        username: username,
        bio: bio,
        location: userLocation,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
      ),
    );
  }
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

@TypedGoRoute<FeedbackSubmitRoute>(path: AppRouterPaths.feedbackSubmit)
class FeedbackSubmitRoute extends GoRouteData {
  const FeedbackSubmitRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: const FeedbackSubmitPage(),
    );
  }
}

@TypedGoRoute<NotificationRoute>(path: AppRouterPaths.notification)
class NotificationRoute extends GoRouteData {
  const NotificationRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: const NotificationPage(),
    );
  }
}

@TypedGoRoute<SystemNotificationDetailRoute>(path: AppRouterPaths.systemNotificationDetail)
class SystemNotificationDetailRoute extends GoRouteData {
  const SystemNotificationDetailRoute({required this.title});

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

  final String title;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: NotificationDetailPage(title: title),
    );
  }
}

@TypedGoRoute<ComplaintRoute>(path: AppRouterPaths.complaint)
class ComplaintRoute extends GoRouteData {
  const ComplaintRoute({this.targetId, this.targetType});

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

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
    required this.avatarUrl,
    required this.uid,
  });

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

  final String name;
  final String avatarUrl;
  final int uid;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: ChatPage(
        uid: uid,
        name: name,
        avatarUrl: avatarUrl,
      ),
    );
  }
}

@TypedGoRoute<UserSearchRoute>(path: AppRouterPaths.userSearch)
class UserSearchRoute extends GoRouteData {
  const UserSearchRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

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

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

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
  const ChatRecordsSearchRoute({this.chatId = 0});

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

  final int chatId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CommonUtils.buildSlideTransitionPage(
      state: state,
      child: ChatRecordsSearchPage(chatId: chatId),
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
