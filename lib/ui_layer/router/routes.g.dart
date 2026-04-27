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
      $guideRoute,
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
              path: '/publish',
              factory: $PublishRouteExtension._fromState,
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

RouteBase get $complaintRoute => GoRouteData.$route(
      path: '/complaint',
      parentNavigatorKey: ComplaintRoute.$parentNavigatorKey,
      factory: $ComplaintRouteExtension._fromState,
    );

extension $ComplaintRouteExtension on ComplaintRoute {
  static ComplaintRoute _fromState(GoRouterState state) => ComplaintRoute(
        targetId: int.tryParse(state.uri.queryParameters['target-id'] ?? ''),
        targetType: state.uri.queryParameters['target-type'],
      );

  String get location => GoRouteData.$location(
        '/complaint',
        queryParams: {
          if (targetId != null) 'target-id': '$targetId',
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
        avatarUrl: state.uri.queryParameters['avatar-url'] ?? '',
        isOnline: _$convertMapValue(
                'is-online', state.uri.queryParameters, _$boolConverter) ??
            false,
      );

  String get location => GoRouteData.$location(
        '/chat_conversation',
        queryParams: {
          'name': name,
          if (avatarUrl != '') 'avatar-url': avatarUrl,
          if (isOnline != false) 'is-online': isOnline.toString(),
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

bool _$boolConverter(String value) {
  switch (value) {
    case 'true':
      return true;
    case 'false':
      return false;
    default:
      throw UnsupportedError('Cannot convert "$value" into a bool.');
  }
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
      const ChatRecordsSearchRoute();

  String get location => GoRouteData.$location(
        '/chat_records_search',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}
