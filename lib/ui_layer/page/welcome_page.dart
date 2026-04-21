import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:g_link/ui_layer/theme/theme_manager.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), _routeOnboardingPage);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _routeOnboardingPage() async {
    _timer?.cancel();
    const HomeRoute().go(context);
  }

  @override
  Widget build(BuildContext context) {
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
        body: MyImage.asset(
          MyImagePaths.splash,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
