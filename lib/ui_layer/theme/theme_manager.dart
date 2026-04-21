import 'package:flutter/material.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:g_link/ui_layer/theme/theme_mode.dart';

class ThemeManager {
  static ThemeData getLightTheme() {
    final ThemeData lightTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: MyTheme.primaryColor,
      scaffoldBackgroundColor: MyTheme.white255Color,
      primarySwatch: Colors.purple,
      appBarTheme: AppBarTheme(
        color: MyTheme.white255Color,
      ),
    );
    return lightTheme;
  }

  static Brightness statusBarIconBrightness(BuildContext context) {
    if (getBrightness(context) == Brightness.dark) {
      return Brightness.light;
    } else if (getBrightness(context) == Brightness.light) {
      return Brightness.dark;
    }
    return getBrightness(context);
  }

  static ThemeData getDarkTheme() {
    final ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: MyTheme.darkPrimaryColor,
      scaffoldBackgroundColor: MyTheme.blackColor18,
      primarySwatch: Colors.deepOrange,
      appBarTheme: AppBarTheme(color: MyTheme.blackColor),
    );
    return darkTheme;
  }

  static ThemeMode currentThemeMode = ThemeMode.system;

  // static Future<ThemeMode> initThemeMode() async {
  //   final modeName = await CommonManager.getThemeModeName();
  //   if (modeName == MyThemeMode.system.name) {
  //     currentThemeMode = ThemeMode.system;
  //   } else if (modeName == MyThemeMode.dark.name) {
  //     currentThemeMode = ThemeMode.dark;
  //   } else if (modeName == MyThemeMode.light.name) {
  //     currentThemeMode = ThemeMode.light;
  //   } else {
  //     currentThemeMode = ThemeMode.system;
  //   }
  //   return currentThemeMode;
  // }
  //
  // static void modeNameToThemeMode(MyThemeMode myThemeMode) {
  //   CommonManager.saveThemeModeName(myThemeMode.name);
  //   if (myThemeMode == MyThemeMode.system) {
  //     currentThemeMode = ThemeMode.system;
  //   } else if (myThemeMode == MyThemeMode.dark) {
  //     currentThemeMode = ThemeMode.dark;
  //   } else if (myThemeMode == MyThemeMode.light) {
  //     currentThemeMode = ThemeMode.light;
  //   } else {
  //     currentThemeMode = ThemeMode.system;
  //   }
  // }

  static ThemeMode myThemeModeToThemeMode(MyThemeMode myThemeMode) {
    if (myThemeMode == MyThemeMode.system) {
      return ThemeMode.system;
    } else if (myThemeMode == MyThemeMode.dark) {
      return ThemeMode.dark;
    } else if (myThemeMode == MyThemeMode.light) {
      return ThemeMode.light;
    } else {
      return ThemeMode.system;
    }
  }

  static Brightness getBrightness(BuildContext context) {
    return Theme.of(context).brightness;
  }
}
