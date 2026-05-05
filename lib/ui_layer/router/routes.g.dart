// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
      $welcomeRoute,
      $loginRoute,
      $registerRoute,
      $forgotPasswordRoute,
      $statefulShellRoute,
      $publishRoute,
      $publishAlbumRoute,
      $recommendFollowListRoute,
      $editProfileRoute,
      $guideRoute,
      $feedbackSubmitRoute,
      $notificationRoute,
      $systemNotificationDetailRoute,
      $complaintRoute,
      $chatConversationRoute,
      $userSearchRoute,
      $globalSearchRoute,
      $chatRecordsSearchRoute,
    ];

RouteBase get $welcomeRoute => GoRouteData.$route(
      path: '/',
      factory: $WelcomeRouteExtension._fromState,
    );

extension $WelcomeRouteExtension on WelcomeRoute {
  static WelcomeRoute _fromState(GoRouterState state) => const WelcomeRoute();

  String get location => GoRouteData.$location(
        '/',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $loginRoute => GoRouteData.$route(
      path: '/login',
      factory: $LoginRouteExtension._fromState,
    );

extension $LoginRouteExtension on LoginRoute {
  static LoginRoute _fromState(GoRouterState state) => const LoginRoute();

  String get location => GoRouteData.$location(
        '/login',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $registerRoute => GoRouteData.$route(
      path: '/register',
      factory: $RegisterRouteExtension._fromState,
    );

extension $RegisterRouteExtension on RegisterRoute {
  static RegisterRoute _fromState(GoRouterState state) => const RegisterRoute();

  String get location => GoRouteData.$location(
        '/register',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $forgotPasswordRoute => GoRouteData.$route(
      path: '/forgot_password',
      factory: $ForgotPasswordRouteExtension._fromState,
    );

extension $ForgotPasswordRouteExtension on ForgotPasswordRoute {
  static ForgotPasswordRoute _fromState(GoRouterState state) =>
      const ForgotPasswordRoute();

  String get location => GoRouteData.$location(
        '/forgot_password',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $statefulShellRoute => StatefulShellRouteData.$route(
      factory: $StatefulShellRouteExtension._fromState,
      branches: [
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/home',
              factory: $HomeRouteExtension._fromState,
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/short_video',
              factory: $ShortVideoRouteExtension._fromState,
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/message',
              factory: $MessageRouteExtension._fromState,
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/mine',
              factory: $MineRouteExtension._fromState,
            ),
          ],
        ),
      ],
    );

extension $StatefulShellRouteExtension on StatefulShellRoute {
  static StatefulShellRoute _fromState(GoRouterState state) =>
      const StatefulShellRoute();
}

extension $HomeRouteExtension on HomeRoute {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  String get location => GoRouteData.$location(
        '/home',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $ShortVideoRouteExtension on ShortVideoRoute {
  static ShortVideoRoute _fromState(GoRouterState state) =>
      const ShortVideoRoute();

  String get location => GoRouteData.$location(
        '/short_video',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $MessageRouteExtension on MessageRoute {
  static MessageRoute _fromState(GoRouterState state) => const MessageRoute();

  String get location => GoRouteData.$location(
        '/message',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $MineRouteExtension on MineRoute {
  static MineRoute _fromState(GoRouterState state) => const MineRoute();

  String get location => GoRouteData.$location(
        '/mine',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $publishRoute => GoRouteData.$route(
      path: '/publish',
      parentNavigatorKey: PublishRoute.$parentNavigatorKey,
      factory: $PublishRouteExtension._fromState,
    );

extension $PublishRouteExtension on PublishRoute {
  static PublishRoute _fromState(GoRouterState state) => const PublishRoute();

  String get location => GoRouteData.$location(
        '/publish',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $publishAlbumRoute => GoRouteData.$route(
      path: '/publish_album',
      parentNavigatorKey: PublishAlbumRoute.$parentNavigatorKey,
      factory: $PublishAlbumRouteExtension._fromState,
    );

extension $PublishAlbumRouteExtension on PublishAlbumRoute {
  static PublishAlbumRoute _fromState(GoRouterState state) =>
      const PublishAlbumRoute();

  String get location => GoRouteData.$location(
        '/publish_album',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $recommendFollowListRoute => GoRouteData.$route(
      path: '/mine/recommend_follow',
      parentNavigatorKey: RecommendFollowListRoute.$parentNavigatorKey,
      factory: $RecommendFollowListRouteExtension._fromState,
    );

extension $RecommendFollowListRouteExtension on RecommendFollowListRoute {
  static RecommendFollowListRoute _fromState(GoRouterState state) =>
      RecommendFollowListRoute(
        limit:
            _$convertMapValue('limit', state.uri.queryParameters, int.parse) ??
                10,
      );

  String get location => GoRouteData.$location(
        '/mine/recommend_follow',
        queryParams: {
          if (limit != 10) 'limit': limit.toString(),
        },
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

T? _$convertMapValue<T>(
  String key,
  Map<String, String> map,
  T Function(String) converter,
) {
  final value = map[key];
  return value == null ? null : converter(value);
}

RouteBase get $editProfileRoute => GoRouteData.$route(
      path: '/mine/edit_profile',
      parentNavigatorKey: EditProfileRoute.$parentNavigatorKey,
      factory: $EditProfileRouteExtension._fromState,
    );

extension $EditProfileRouteExtension on EditProfileRoute {
  static EditProfileRoute _fromState(GoRouterState state) => EditProfileRoute(
        nickname: state.uri.queryParameters['nickname']!,
        username: state.uri.queryParameters['username']!,
        bio: state.uri.queryParameters['bio']!,
        userLocation: state.uri.queryParameters['user-location']!,
        avatarUrl: state.uri.queryParameters['avatar-url']!,
        coverUrl: state.uri.queryParameters['cover-url']!,
      );

  String get location => GoRouteData.$location(
        '/mine/edit_profile',
        queryParams: {
          'nickname': nickname,
          'username': username,
          'bio': bio,
          'user-location': userLocation,
          'avatar-url': avatarUrl,
          'cover-url': coverUrl,
        },
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $guideRoute => GoRouteData.$route(
      path: '/guide',
      factory: $GuideRouteExtension._fromState,
    );

extension $GuideRouteExtension on GuideRoute {
  static GuideRoute _fromState(GoRouterState state) => const GuideRoute();

  String get location => GoRouteData.$location(
        '/guide',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $feedbackSubmitRoute => GoRouteData.$route(
      path: '/feedback_submit',
      parentNavigatorKey: FeedbackSubmitRoute.$parentNavigatorKey,
      factory: $FeedbackSubmitRouteExtension._fromState,
    );

extension $FeedbackSubmitRouteExtension on FeedbackSubmitRoute {
  static FeedbackSubmitRoute _fromState(GoRouterState state) =>
      const FeedbackSubmitRoute();

  String get location => GoRouteData.$location(
        '/feedback_submit',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $notificationRoute => GoRouteData.$route(
      path: '/notification',
      parentNavigatorKey: NotificationRoute.$parentNavigatorKey,
      factory: $NotificationRouteExtension._fromState,
    );

extension $NotificationRouteExtension on NotificationRoute {
  static NotificationRoute _fromState(GoRouterState state) =>
      const NotificationRoute();

  String get location => GoRouteData.$location(
        '/notification',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $systemNotificationDetailRoute => GoRouteData.$route(
      path: '/systemNotificationDetail',
      parentNavigatorKey: SystemNotificationDetailRoute.$parentNavigatorKey,
      factory: $SystemNotificationDetailRouteExtension._fromState,
    );

extension $SystemNotificationDetailRouteExtension
    on SystemNotificationDetailRoute {
  static SystemNotificationDetailRoute _fromState(GoRouterState state) =>
      SystemNotificationDetailRoute(
        title: state.uri.queryParameters['title']!,
      );

  String get location => GoRouteData.$location(
        '/systemNotificationDetail',
        queryParams: {
          'title': title,
        },
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $complaintRoute => GoRouteData.$route(
      path: '/complaint',
      parentNavigatorKey: ComplaintRoute.$parentNavigatorKey,
      factory: $ComplaintRouteExtension._fromState,
    );

extension $ComplaintRouteExtension on ComplaintRoute {
  static ComplaintRoute _fromState(GoRouterState state) => ComplaintRoute(
        targetId: _$convertMapValue(
            'target-id', state.uri.queryParameters, int.parse),
        targetType: state.uri.queryParameters['target-type'],
      );

  String get location => GoRouteData.$location(
        '/complaint',
        queryParams: {
          if (targetId != null) 'target-id': targetId!.toString(),
          if (targetType != null) 'target-type': targetType,
        },
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $chatConversationRoute => GoRouteData.$route(
      path: '/chat_conversation',
      parentNavigatorKey: ChatConversationRoute.$parentNavigatorKey,
      factory: $ChatConversationRouteExtension._fromState,
    );

extension $ChatConversationRouteExtension on ChatConversationRoute {
  static ChatConversationRoute _fromState(GoRouterState state) =>
      ChatConversationRoute(
        name: state.uri.queryParameters['name']!,
        avatarUrl: state.uri.queryParameters['avatar-url']!,
        uid: int.parse(state.uri.queryParameters['uid']!),
      );

  String get location => GoRouteData.$location(
        '/chat_conversation',
        queryParams: {
          'name': name,
          'avatar-url': avatarUrl,
          'uid': uid.toString(),
        },
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $userSearchRoute => GoRouteData.$route(
      path: '/user_search',
      parentNavigatorKey: UserSearchRoute.$parentNavigatorKey,
      factory: $UserSearchRouteExtension._fromState,
    );

extension $UserSearchRouteExtension on UserSearchRoute {
  static UserSearchRoute _fromState(GoRouterState state) =>
      const UserSearchRoute();

  String get location => GoRouteData.$location(
        '/user_search',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $globalSearchRoute => GoRouteData.$route(
      path: '/global_search',
      parentNavigatorKey: GlobalSearchRoute.$parentNavigatorKey,
      factory: $GlobalSearchRouteExtension._fromState,
    );

extension $GlobalSearchRouteExtension on GlobalSearchRoute {
  static GlobalSearchRoute _fromState(GoRouterState state) =>
      const GlobalSearchRoute();

  String get location => GoRouteData.$location(
        '/global_search',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $chatRecordsSearchRoute => GoRouteData.$route(
      path: '/chat_records_search',
      parentNavigatorKey: ChatRecordsSearchRoute.$parentNavigatorKey,
      factory: $ChatRecordsSearchRouteExtension._fromState,
    );

extension $ChatRecordsSearchRouteExtension on ChatRecordsSearchRoute {
  static ChatRecordsSearchRoute _fromState(GoRouterState state) =>
      ChatRecordsSearchRoute(
        chatId: _$convertMapValue(
                'chat-id', state.uri.queryParameters, int.parse) ??
            0,
      );

  String get location => GoRouteData.$location(
        '/chat_records_search',
        queryParams: {
          if (chatId != 0) 'chat-id': chatId.toString(),
        },
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}
