import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:g_link/ui_layer/theme/theme_manager.dart';

class BackgroundPage extends StatelessWidget {
  final Widget body;

  const BackgroundPage({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
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
      child: body,
    );
  }
}
