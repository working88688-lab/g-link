import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:g_link/app_global.dart';
import 'package:g_link/domain/domain.dart';
import 'package:g_link/domain/domains/home.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/theme/theme_manager.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:provider/provider.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  Timer? _timer;
  String? _splashImageUrl;
  String? _splashActionUrl;

  @override
  void initState() {
    super.initState();
    _initSplashAd();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _routeOnboardingPage() async {
    _timer?.cancel();
    final appDomain = context.read<AppDomain>();
    final guided = await appDomain.cache.readGuideCompleted();
    if (!mounted) return;
    if (guided) {
      const HomeRoute().go(context);
      return;
    }
    const GuideRoute().go(context);

    // const LoginRoute().go(context);
  }

  Future<void> _initSplashAd() async {
    var delaySeconds = 2;
    var shouldStartTimer = true;
    try {
      final result = await context
          .read<HomeDomain>()
          .getSplashAd()
          .timeout(const Duration(seconds: 2));
      if (!mounted) return;
      final ad = result.data;
      if (result.status == 0 && ad != null && ad.imageUrl.isNotEmpty) {
        setState(() {
          _splashImageUrl = ad.imageUrl;
          _splashActionUrl = ad.actionUrl;
        });
        delaySeconds = ad.duration.clamp(1, 8);
      }
    } catch (_) {
      // Keep local splash fallback.
    } finally {
      if (!mounted) {
        shouldStartTimer = false;
      }
    }
    if (shouldStartTimer && mounted) {
      _timer?.cancel();
      _timer = Timer(Duration(seconds: delaySeconds), _routeOnboardingPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppGlobal.context = context;
    // return Scaffold(
    //   body: MediaQuery.removePadding(
    //     context: context,
    //     removeTop: true,
    //     removeBottom: true,
    //     child: SizedBox.expand(
    //       child: MyImage.asset(MyImagePaths.splash, fit: BoxFit.cover),
    //     ),
    //   ),
    // );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: ThemeManager.statusBarIconBrightness(
          context,
        ),
        statusBarBrightness: ThemeManager.getBrightness(context),
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: Color.fromRGBO(26, 31, 44, 1),
        systemNavigationBarIconBrightness: ThemeManager.statusBarIconBrightness(
          context,
        ),
        systemNavigationBarDividerColor: Color.fromRGBO(26, 31, 44, 1),
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final link = _splashActionUrl ?? '';
            if (link.isNotEmpty) {
              CommonUtils.launchUrl(link);
            }
          },
          child: _splashImageUrl != null
              ? MyImage.network(
                  _splashImageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeHolder: null,
                )
              : MyImage.asset(
                  MyImagePaths.splash,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
        ),
      ),
    );
  }
}
