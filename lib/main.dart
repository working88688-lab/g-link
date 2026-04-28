import 'package:analytics_sdk/widget/global_click_wrapper.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/app_global.dart';
import 'package:g_link/data_layer/repo/repo.dart';
import 'package:g_link/domain/domain.dart';
import 'package:g_link/domain/domains/home.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/domains/report.dart';
import 'package:g_link/domain/domains/auth.dart';
import 'package:g_link/domain/domains/search.dart';
import 'package:g_link/report/analytics/analytics_report.dart';
import 'package:g_link/ui_layer/notifier/app_chat_notifier.dart';
import 'package:g_link/ui_layer/notifier/app_feed_notifier.dart';
import 'package:g_link/ui_layer/notifier/guide_page_notifier.dart';
import 'package:g_link/ui_layer/notifier/home_config_notifier.dart';
import 'package:g_link/ui_layer/notifier/user_notifier.dart';
import 'package:g_link/ui_layer/router/router.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:g_link/utils/common_utils.dart';

import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:utils/utils.dart';

void disableZoomOnWeb() {
  html.document.documentElement?.style.overflow = 'hidden';
  html.document.documentElement?.style.touchAction = 'manipulation';
  html.document.documentElement?.style.setProperty('user-select', 'none');
  html.document.documentElement?.style
      .setProperty('overscroll-behavior', 'contain');
}

void main() async {
  if (kIsWeb) disableZoomOnWeb();

  /// 初始化仓库，必须放在最前面
  final appRepo = AppRepo();
  await appRepo.init();
  disableUrlStrategy();
  await initAnalyticsSdk(null, oauthId: appRepo.getOAuthId());

  /// 初始化多语系
  await EasyLocalization.ensureInitialized();

  /// 强制竖屏
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  /// 设置屏幕状态栏、导航列底色
  CommonUtils.setStatusBar(isLight: true);
  runApp(
    MultiProvider(
      providers: [
        Provider<AppDomain>(lazy: false, create: (_) => appRepo),
        Provider<HomeDomain>(lazy: false, create: (_) => appRepo),
        Provider<ProfileDomain>(lazy: false, create: (_) => appRepo),
        Provider<ReportDomain>(lazy: false, create: (_) => appRepo),
        Provider<AuthDomain>(lazy: false, create: (_) => appRepo),
        Provider<SearchDomain>(lazy: false, create: (_) => appRepo),
        ChangeNotifierProvider(create: (_) => HomeConfigNotifier(appRepo)),
        ChangeNotifierProvider(create: (_) => UserNotifier(appRepo)),
        ChangeNotifierProvider(create: (_) => GuidePageNotifier()),
        ChangeNotifierProvider(create: (_) => AppFeedNotifier()),
        ChangeNotifierProvider(create: (_) => AppChatNotifier()),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
        fallbackLocale: const Locale('zh', 'CN'),
        path: 'assets/translations',
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: kIsWeb ? 430 : double.infinity,
            ),
            child: ScreenUtilInit(
              enableScaleText: () => !kIsWeb,
              enableScaleWH: () => !kIsWeb,
              designSize: const Size(375, 667),
              child: const MyApp(),
              builder: (_, child) => child!,
            ),
          ),
        ),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    AppGlobal.context = context;
    final botToastBuilder = BotToastInit();

    return MaterialApp.router(
      routerConfig: AppRouter.router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      onGenerateTitle: (context) => 'appName'.tr(context: context),
      theme: ThemeData(
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: MyTheme.jellyCyanColor103224185,
        ),
        splashColor: Colors.transparent,
        scaffoldBackgroundColor: MyTheme.bgColor,
        canvasColor: MyTheme.bgColor,
        colorScheme: const ColorScheme.light(
          surface: MyTheme.whiteColor,
        ),
        highlightColor: Colors.transparent,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: MyTheme.cyanColor00edfd,
          selectionColor: MyTheme.cyanColor00edfd.withOpacity(0.5),
          selectionHandleColor: MyTheme.cyanColor00edfd,
        ),
        inputDecorationTheme: InputDecorationTheme(
          disabledBorder: MyTheme.inputBorder,
          focusedBorder: MyTheme.inputBorder,
          enabledBorder: MyTheme.inputBorder,
          border: MyTheme.inputBorder,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
        ),
        primarySwatch: const MaterialColor(
          0xFFFFFFFF,
          <int, Color>{
            50: Color(0xFFFFFFFF),
            100: Color(0xFFFFFFFF),
            200: Color(0xFFFFFFFF),
            300: Color(0xFFFFFFFF),
            400: Color(0xFFFFFFFF),
            500: Color(0xFFFFFFFF),
            600: Color(0xFFFFFFFF),
            700: Color(0xFFFFFFFF),
            800: Color(0xFFFFFFFF),
            900: Color(0xFFFFFFFF),
          },
        ),
      ),
      debugShowCheckedModeBanner: false,
      // 设置为false来移除右上角的DEBUG横幅
      builder: (context, widget) {
        widget = botToastBuilder(context, widget!);
        widget = MediaQuery(
          //设置文字大小不随系统设置改变
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: widget,
        );
        // if (kDebugMode) {
        //   return GlobalClickWrapper(
        //     child: Column(
        //       children: [
        //         if (kDebugMode) const AnalyticsDebugBanner(),
        //         Expanded(
        //           child: ExcludeSemantics(child: widget),
        //         ),
        //       ],
        //     ),
        //   );
        // } else {
        return GlobalClickWrapper(child: ExcludeSemantics(child: widget));
        // }
      },
      scrollBehavior: ScrollConfiguration.of(context).copyWith(
        physics: const BouncingScrollPhysics(),
      ),
    );
  }
}
