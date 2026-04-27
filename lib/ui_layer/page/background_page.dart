import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:g_link/ui_layer/theme/theme_manager.dart';

class BackgroundPage extends StatelessWidget {
  final String? backgroundImage;
  final PreferredSizeWidget? appBar;
  final LinearGradient? backgroundGradient;
  final Color? backgroundColor;
  final Color? systemNavigationBarColor;
  final Color? statusBarColor;
  final Brightness? androidStatusBarIcon;
  final Brightness? iosStatusBarIcon;
  final Widget body;

  const BackgroundPage({
    super.key,
    this.backgroundImage,
    this.appBar,
    this.backgroundGradient,
    this.backgroundColor,
    this.systemNavigationBarColor,
    this.statusBarColor,
    this.androidStatusBarIcon,
    this.iosStatusBarIcon,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: statusBarColor ?? Colors.transparent,
        statusBarIconBrightness: androidStatusBarIcon ??
            ThemeManager.statusBarIconBrightness(context),
        statusBarBrightness:
            iosStatusBarIcon ?? ThemeManager.getBrightness(context),
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor:
            systemNavigationBarColor ?? Color.fromRGBO(26, 31, 44, 1),
        systemNavigationBarIconBrightness:
            ThemeManager.statusBarIconBrightness(context),
        systemNavigationBarDividerColor:
            systemNavigationBarColor ?? Color.fromRGBO(26, 31, 44, 1),
        systemNavigationBarContrastEnforced: false,
      ),
      child: Stack(
        children: [
          if (backgroundGradient != null)
            Container(
              decoration: BoxDecoration(
                gradient: backgroundGradient,
              ),
            ),
          if (backgroundImage != null && backgroundImage!.isNotEmpty)
            Positioned.fill(
              child: Image.asset(
                backgroundImage!,
                fit: BoxFit.cover,
              ),
            ),
          Positioned.fill(
            child: Scaffold(
              backgroundColor: backgroundColor ?? Colors.transparent,
              appBar: appBar,
              body: body,
            ),
          ),
        ],
      ),
    );
  }
}
