import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/app_global.dart';

class MyTheme {
  // 页面通用边距
  static double get pagePadding => 13.w;

  // 栏目顶部导航高度
  static double get navbarHegiht => 44.w;

  static double get statusHeight =>
      kIsWeb ? 5.w : MediaQuery.of(AppGlobal.context!).padding.top;

  static bool ipx =
      kIsWeb && (ScreenUtil().screenHeight / ScreenUtil().screenWidth >= 1.26);
  static double bottom = ipx ? 15.w : 0;
  /*底部导航条高度*/
  static double get botHegiht => 55.w;
  static double get pxBotHegiht => ipx ? (botHegiht + bottom) : botHegiht;

  static const LinearGradient dhButtonGradient = LinearGradient(
    colors: [Color.fromRGBO(87, 155, 241, 1), Color.fromRGBO(61, 84, 245, 1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient shareButtonGradient = LinearGradient(
    colors: [Color.fromRGBO(55, 110, 246, 1), Color.fromRGBO(100, 150, 252, 1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color.fromRGBO(255, 111, 32, 1), Color.fromRGBO(255, 169, 3, 1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient topToBottomGradient = LinearGradient(
    colors: [Color.fromRGBO(136, 78, 214, 1), Color.fromRGBO(90, 91, 241, 1)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static final TextStyle yellow16w600 = TextStyle(
      color: const Color.fromRGBO(232, 197, 174, 1),
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.visible,
      decoration: TextDecoration.none);
  static final TextStyle whiteOpacity612w400 = TextStyle(
    color: Colors.white.withOpacity(0.6),
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
  );
  static final TextStyle whiteOpacity614w400 = TextStyle(
      color: Colors.white.withOpacity(0.6),
      fontSize: 14.sp,
      fontWeight: FontWeight.w400,
      overflow: TextOverflow.visible,
      decoration: TextDecoration.none);
  static final TextStyle white14w400 = TextStyle(
      color: Colors.white,
      fontSize: 14.sp,
      fontWeight: FontWeight.w400,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final TextStyle white12w500 = TextStyle(
    color: Colors.white,
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle jellyCyan_17 = TextStyle(
      color: jellyCyanColor103224185,
      fontSize: 17.sp,
      overflow: TextOverflow.visible,
      decoration: TextDecoration.none);
  static final TextStyle whiteOpacity612w500 = TextStyle(
      color: Colors.white.withOpacity(0.6),
      fontSize: 12.sp,
      fontWeight: FontWeight.w500);

  static final TextStyle white08_12 = TextStyle(
      color: white08Color,
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final TextStyle gray203_16 = TextStyle(
      color: const Color.fromRGBO(190, 189, 194, 1),
      fontSize: 16.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final TextStyle orange247_13 = TextStyle(
      color: orange24718713,
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final TextStyle orange247_15M = TextStyle(
      color: orange24718713,
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final TextStyle white09_15_M = TextStyle(
      color: const Color.fromRGBO(255, 255, 255, 0.9),
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final TextStyle white09_10 = TextStyle(
      color: const Color.fromRGBO(255, 255, 255, 0.9),
      fontSize: 10.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final TextStyle whiteOpacity614w500 = TextStyle(
      color: Colors.white.withOpacity(0.6),
      fontSize: 14.sp,
      fontWeight: FontWeight.w500);

  static final TextStyle white06_16 = TextStyle(
      color: white06Color,
      fontSize: 16.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final TextStyle white06_18 = TextStyle(
      color: white06Color,
      fontSize: 18.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final TextStyle white07_14 =
      TextStyle(color: white07Color, fontSize: 14.sp);

  static final TextStyle white07_14_M = TextStyle(
      color: white07Color, fontSize: 14.sp, fontWeight: FontWeight.w500);

  static final TextStyle white07_13 =
      TextStyle(color: white07Color, fontSize: 13.sp);

  static final TextStyle white07_12 = TextStyle(
    color: white07Color,
    fontSize: 12.sp,
  );

  static final TextStyle white07_11 = TextStyle(
    color: white07Color,
    fontSize: 11.sp,
  );

  static final TextStyle white07_10 =
      TextStyle(color: white07Color, fontSize: 10.sp);

  static final TextStyle white25508_16_M = TextStyle(
      color: const Color.fromRGBO(255, 255, 255, 0.8),
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final TextStyle white06_10 = TextStyle(
      color: white06Color,
      fontSize: 10.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final TextStyle white06_12 = TextStyle(
      color: white06Color,
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final TextStyle white06_15 = TextStyle(
      color: white06Color,
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final InputBorder inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(0.0),
    borderSide: const BorderSide(color: Colors.transparent, width: 0),
  );

  static const gradient_90_114_colors = [
    Color.fromRGBO(84, 158, 241, 1),
    Color.fromRGBO(55, 93, 245, 1)
  ];

  static const LinearGradient gradient_90_114 = LinearGradient(
    colors: gradient_90_114_colors,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Color imageBgColor = Color.fromRGBO(255, 255, 255, 0.03);

  static final TextStyle jellyCyan_18 = TextStyle(
      color: jellyCyanColor103224185,
      fontSize: 18.sp,
      overflow: TextOverflow.visible,
      decoration: TextDecoration.none);

  /// ----------------------

  static LinearGradient gradient_84_55 = const LinearGradient(
    colors: [Color.fromRGBO(84, 158, 241, 1), Color.fromRGBO(55, 93, 245, 1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient gradient_228_246 = const LinearGradient(
    // colors: [Color(0xff00edfd), Color(0xffbbe954)],
    colors: [
      Color.fromRGBO(228, 177, 145, 1),
      Color.fromRGBO(246, 222, 199, 1)
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient vip_gradient_228_246 = const LinearGradient(
    colors: [
      Color.fromRGBO(228, 177, 145, 0.9),
      Color.fromRGBO(246, 222, 199, 0.9)
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient gradient_61_87 = const LinearGradient(
    colors: [Color.fromRGBO(61, 84, 245, 1), Color.fromRGBO(87, 155, 241, 1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static String? get hanyi => null;

  static Color white255005Color = const Color.fromRGBO(255, 255, 255, 0.05);
  static Color white25501Color = const Color.fromRGBO(255, 255, 255, 0.1);
  static Color white25502Color = const Color.fromRGBO(255, 255, 255, 0.2);
  static Color white25503Color = const Color.fromRGBO(255, 255, 255, 0.3);
  static Color white25504Color = const Color.fromRGBO(255, 255, 255, 0.4);
  static Color white25505Color = const Color.fromRGBO(255, 255, 255, 0.5);
  static Color white25506Color = const Color.fromRGBO(255, 255, 255, 0.6);
  static Color white25507Color = const Color.fromRGBO(255, 255, 255, 0.7);
  static Color white25508Color = const Color.fromRGBO(255, 255, 255, 0.8);
  static Color white25509Color = const Color.fromRGBO(255, 255, 255, 0.9);
  static Color white255Color = const Color.fromRGBO(255, 255, 255, 1);

  static const Color yellow255Color = Color.fromRGBO(255, 197, 48, 1);

  static const Color white02Color = Color.fromRGBO(255, 255, 255, 0.2);
  static const Color white05Color = Color.fromRGBO(255, 255, 255, 0.5);
  static const Color white06Color = Color.fromRGBO(255, 255, 255, 0.6);
  static const Color white07Color = Color.fromRGBO(255, 255, 255, 0.7);
  static const Color white08Color = Color.fromRGBO(255, 255, 255, 0.8);
  static const Color white09Color = Color.fromRGBO(255, 255, 255, 0.9);
  static const Color white008Color = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color color11_10_33 = Color.fromRGBO(11, 10, 33, 1);

  static const Color whiteColor = Color.fromRGBO(255, 255, 255, 1);

  static const Color orange24718713 = Color.fromRGBO(247, 187, 13, 1);

  static const bgColor = Color.fromRGBO(255, 255, 255, 1);
  static const naviColor = Color.fromRGBO(11, 11, 33, 1);

  static const blackColor = Color.fromRGBO(0, 0, 0, 1);
  static const blackColor18 = Color.fromRGBO(18, 18, 18, 1);
  static const blackColor25 = Color.fromRGBO(25, 25, 25, 1);
  static const blackColor22 = Color.fromRGBO(22, 22, 22, 1);
  static const blackColor32 = Color.fromRGBO(32, 32, 32, 1);
  static const blackColor36 = Color.fromRGBO(36, 36, 36, 1);
  static const blackColor38 = Color.fromRGBO(38, 38, 38, 1);
  static const blackColor49 = Color.fromRGBO(49, 49, 49, 1);
  static const blackColor61 = Color.fromRGBO(61, 61, 61, 1);
  static const Color blackColor25505 = Color.fromRGBO(0, 0, 0, 0.5);


  static const Color primaryColor = Color.fromRGBO(26, 31, 44, 1);
  static const Color darkPrimaryColor = Color.fromRGBO(10, 10, 10, 1);

  static const bloodOrange2501046 = Color.fromRGBO(250, 104, 6, 1);
  static const bloodOrange2557710 = Color.fromRGBO(255, 77, 11, 1);
  static const bloodOrange2551020 = Color.fromRGBO(255, 102, 0, 1);
  static const bloodOrange255702 = Color.fromRGBO(253, 70, 2, 1);
  static const brownColor = Color.fromRGBO(114, 47, 7, 1);
  static const brownColor91_60_44 = Color.fromRGBO(118, 75, 51, 1);
  static const grayColor180 = Color.fromRGBO(180, 180, 180, 1);
  static const grayColor150 = Color.fromRGBO(150, 150, 150, 1);

  static const goldColor234_202_147 = Color.fromRGBO(234, 202, 147, 1);

  static const blueColor81_151_241 = Color.fromRGBO(55, 110, 246, 1);

  static const blueColor63 = Color.fromRGBO(63, 91, 245, 1);
  static const blueColor64 = Color.fromRGBO(64, 165, 254, 1);

  static const cyanColor00edfd = Color.fromRGBO(55, 110, 246, 1);

  static const jellyCyanColor103224185 = Color.fromRGBO(55, 110, 246, 1);
  static const jellyCyanColor108235220 = Color.fromRGBO(108, 235, 220, 1);
  static const gray117 = Color.fromRGBO(117, 117, 117, 1);

  static const redColorVIP = Color.fromRGBO(232, 62, 86, 1);

  static final bloodOrange2557710_14 = TextStyle(
      fontFamily: hanyi,
      color: bloodOrange2557710,
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final bloodOrange255702_15 = TextStyle(
      fontFamily: hanyi,
      color: bloodOrange255702,
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final bloodOrange255702_15medium = TextStyle(
      fontFamily: hanyi,
      color: bloodOrange255702,
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final brown11medium = TextStyle(
      fontFamily: hanyi,
      color: brownColor,
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final brown916044_12medium = TextStyle(
      fontFamily: hanyi,
      color: brownColor91_60_44,
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final brown916044_12semibold = TextStyle(
      fontFamily: hanyi,
      color: brownColor91_60_44,
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);

  static final hex5c402b_12_S = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xff5c402b),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);

  static final brown916044_14medium = TextStyle(
      fontFamily: hanyi,
      color: brownColor91_60_44,
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final TextStyle white08_14_M = TextStyle(
      color: white08Color,
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final TextStyle white06_15_Blod = TextStyle(
      color: white06Color,
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);

  static final TextStyle white04_10 = TextStyle(
      color: const Color.fromRGBO(255, 255, 255, 0.4),
      fontSize: 10.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final TextStyle white04_11 = TextStyle(
      color: const Color.fromRGBO(255, 255, 255, 0.4),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final TextStyle white04_14 = TextStyle(
      color: const Color.fromRGBO(255, 255, 255, 0.4),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final TextStyle white04_15B = TextStyle(
      color: const Color.fromRGBO(255, 255, 255, 0.4),
      fontSize: 15.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final TextStyle white04_13 = TextStyle(
      color: const Color.fromRGBO(255, 255, 255, 0.4),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final TextStyle white04_12 = TextStyle(
      color: const Color.fromRGBO(255, 255, 255, 0.4),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final brown1187551_12_semi = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(118, 75, 51, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);

  static final brown1187551_24_semi = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(118, 75, 51, 1),
      fontSize: 24.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);

  static final hex5c402b_24_S = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xff5c402b),
      fontSize: 24.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);

  static final brown916044_24semibold = TextStyle(
      fontFamily: hanyi,
      color: brownColor91_60_44,
      fontSize: 24.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);

  static final gold12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 219, 178, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      // fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);
  static final gold12medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 219, 178, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);
  static final gold12semibold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 219, 178, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);

  static final hexffdbb2_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xffc7a87f),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gold14medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 219, 178, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final hexf2c774_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xfff2c774),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final gold15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 219, 178, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gold18M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 219, 178, 1),
      fontSize: 18.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final copper13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(238, 196, 171, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final copper35 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(238, 196, 171, 1),
      fontSize: 35.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final copper25 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 25.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  // 字体样式
  static final black51_15_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(51, 51, 51, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final black51_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(51, 51, 51, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray150_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(153, 153, 153, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray150_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(150, 150, 150, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final black51_20_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(51, 51, 51, 1),
      fontSize: 20.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final black51_18_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(51, 51, 51, 1),
      fontSize: 18.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);

  static final black26_18_semi = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(26, 26, 26, 1),
      fontSize: 18.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);

  static final black26_15_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final gray192_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(192, 192, 192, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final gray192_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(192, 192, 192, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray199_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(180, 180, 180, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray198_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(198, 198, 198, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray205_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(205, 205, 205, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray205_14_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(205, 205, 205, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);

  static final hex00edfd_11 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xff00edfd),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.normal,
      decoration: TextDecoration.none);

  static final hex00edfd_20_M = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xff00edfd),
      fontSize: 20.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final gray192_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(192, 192, 192, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray192_14_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(192, 192, 192, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);

  static final white233_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(233, 233, 233, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white232_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(232, 232, 232, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white232_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(232, 232, 232, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white236_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(236, 236, 236, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final white237_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(237, 237, 237, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white232_13_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(232, 232, 232, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);

  static final white232_16 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(232, 232, 232, 1),
      fontSize: 16.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white232_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(232, 232, 232, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray192_13_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(192, 192, 192, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);

  static final gray105_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(105, 105, 105, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray105_16_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(105, 105, 105, 1),
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray137_14_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(137, 137, 137, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final gray139_18 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(139, 139, 139, 1),
      fontSize: 18.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final graya3a2a2_10 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xffffffff),
      fontSize: 10.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final graya8f8f8f_11 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(119, 118, 126, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final graya3a2a2_11 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xff949494),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final graya3a2a2_11_M = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xffffffff),
      fontSize: 11.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final graya3a2a2_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xffffffff),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final gray8f8e90_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xff8f8e90),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final graya3a2a2_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xffffffff),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray666_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xff666666),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final graya3a2a2_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xffffffff),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final grayaaa9a8_11 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xffaaa9a8),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final grayaaa9a8_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xffaaa9a8),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final gray105_11 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(105, 105, 105, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_8 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 8.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final brown137_8 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(137, 88, 60, 1),
      fontSize: 8.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_10 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 10.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_10_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 10.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final brown_10_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(137, 88, 60, 1),
      fontSize: 10.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white254_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 10.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray168_9 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(168, 167, 171, 1),
      fontSize: 9.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray168_16_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(153, 153, 153, 1),
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray213_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(213, 213, 213, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray213_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(213, 213, 213, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final gray202_14_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(202, 202, 202, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);

  static final gray202_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(202, 202, 202, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray204_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(204, 204, 204, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray240_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(240, 239, 244, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray204_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(204, 204, 204, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final gray204_15medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(204, 204, 204, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);
  static final gray204_18 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(204, 204, 204, 1),
      fontSize: 18.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray203_14medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(203, 203, 203, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final gray203_11 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(203, 202, 200, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray203_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(203, 202, 200, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray203_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(190, 189, 194, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final TextStyle blue80_13_M_Line = TextStyle(
    color: MyTheme.jellyCyanColor103224185,
    fontSize: 13.sp,
    decoration: TextDecoration.underline,
    decorationColor: jellyCyanColor103224185,
  );

  static final gray203_13_T = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(203, 202, 200, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.lineThrough);

  static final gray203_15medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, .8),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final gray203_18medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(203, 203, 203, 1),
      fontSize: 18.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final gray168_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(168, 167, 171, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray163_10 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(163, 162, 162, 1),
      fontSize: 10.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray163_11 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(198, 199, 217, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray190_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(190, 189, 194, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final color255_236_90 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 236, 90, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final color93_163_247_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(93, 163, 247, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray163_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(163, 162, 162, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray163_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(74, 74, 74, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray163_14_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(163, 162, 162, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final gray163_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(163, 162, 162, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray109_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(109, 109, 114, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray168_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(168, 167, 171, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray95_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(168, 167, 171, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_22_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 22.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_22_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 22.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white253_22_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(253, 70, 2, 1),
      fontSize: 22.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_24_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 24.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_20_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 20.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_25_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 25.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_20_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 20.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_24_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 24.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_24_S = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 24.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_20_S = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 20.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final hex666666_20_S = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xff666666),
      fontSize: 20.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final hex666666_24_S = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xff666666),
      fontSize: 24.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_18_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 18.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white23_18 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 18.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_18_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 18.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final brown_996619_13_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(99, 66, 19, 1),
      fontSize: 13.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final brown_1378860_14_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(137, 88, 60, 1),
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final brown72_18 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(72, 23, 14, 1),
      fontSize: 18.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final brown72_18_semi = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(72, 23, 14, 1),
      fontSize: 18.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final brown248_18 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 18.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final brown248_18_semi = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 18.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white238_18_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(238, 196, 171, 1),
      fontSize: 18.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white81_18_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(81, 43, 24, 1),
      fontSize: 18.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final yellow255_15_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 189, 57, 1),
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_18 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 18.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final blue80_18 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(80, 237, 255, 1),
      fontSize: 18.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final blue80_18_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(80, 237, 255, 1),
      fontSize: 18.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final blue80_09 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(55, 110, 246, 1),
      fontSize: 9.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final blue80_11 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(55, 110, 246, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final blue80_11_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(80, 237, 255, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final blue80_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(80, 237, 255, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final blue80_13_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(55, 110, 246, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final blue96_13_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(55, 110, 246, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final blue80_14_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(55, 110, 246, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final blue80_16_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(80, 237, 255, 1),
      fontSize: 16.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final blue80_15_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(55, 110, 246, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final blue80_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(55, 110, 246, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final blue80_16 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(55, 110, 246, 1),
      fontSize: 16.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final TextStyle orange247_15 = TextStyle(
      color: orange24718713,
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final gray143_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white9255_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_16_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white244_16 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 16.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white244_16_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(244, 244, 244, 1),
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white244_20_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(244, 244, 244, 1),
      fontSize: 20.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final teal103224185_20_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(55, 110, 246, 1),
      fontSize: 20.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final teal103224185_18_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(55, 110, 246, 1),
      fontSize: 18.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final greent113_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(113, 135, 184, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_12_M_T = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 12.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.lineThrough);

  static final white255_12_semibold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);

  static final white255_11 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_11_03 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 0.3),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final black0d141f_11 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(26, 26, 31, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final black0d141f_11_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(26, 26, 31, 1),
      fontSize: 11.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_11_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);

  static final white127_11_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(127, 72, 26, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);

  static final white217_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(217, 218, 218, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);

  static final white255_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white23_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_13_T = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.lineThrough);

  static final gry30_14_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(30, 30, 30, 1),
      fontSize: 14.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final yellow253_14_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(253, 70, 2, 1),
      fontSize: 14.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray30_14_M_T = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(30, 30, 30, 1),
      fontSize: 14.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.lineThrough);

  static final white_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 13.sp,
      fontWeight: FontWeight.w400,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_13_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 13.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_13_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 13.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_12_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);

  static final white255_12_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final red255_12_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 69, 0, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final black84_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(84, 84, 84, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_14_place = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 93, 95, 0.8),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white255_14_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);

  static final white255_14_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final white255_14_N = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.normal,
      decoration: TextDecoration.none);

  static final white255_14_M_V = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.clip,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final white255_15_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final yellowffbd39_15_M = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xffffbd39),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final white255_15_semibold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);

  static final white95_15_semibold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(168, 167, 171, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);

  static final white_17 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 17.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.normal,
      decoration: TextDecoration.none);

  static final white234_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(234, 234, 234, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white234_15_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(234, 234, 234, 1),
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final red2555713_11 = TextStyle(
      fontFamily: hanyi,
      color: blueColor81_151_241,
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray118_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(118, 118, 118, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray118_12_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(118, 118, 118, 1),
      fontSize: 12.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final gray128_11 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(128, 128, 128, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final gray666666_11 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xff666666),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final gray180_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(180, 180, 180, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray180_12medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(180, 180, 180, 1),
      fontSize: 12.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray123_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(123, 123, 123, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray148_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(148, 148, 148, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray180_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(153, 153, 153, 0.8),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray180_14medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(180, 180, 180, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final gray180_14_line = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(180, 180, 180, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final gray180_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(180, 180, 180, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray180_14_T = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(180, 180, 180, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.lineThrough);

  static final gray180_13medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(180, 180, 180, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final gray180_15_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(153, 153, 153, 1),
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray180_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(180, 180, 180, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray180_16_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(180, 180, 180, 1),
      fontSize: 16.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray206_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(206, 206, 206, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray153_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(153, 153, 153, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final gray153_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(153, 153, 153, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray127_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(153, 153, 153, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray153_14_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(153, 153, 153, 1),
      fontSize: 14.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray153_11 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(153, 153, 153, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray102_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(102, 102, 102, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray102_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(102, 102, 102, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray102_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(102, 102, 102, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray102_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(102, 102, 102, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray234_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(234, 234, 236, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray208_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(218, 218, 218, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final yellow255_11 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 77, 11, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final yellow255_14_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 73, 0, 1),
      fontSize: 14.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final yellow255_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 77, 11, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final yellow255_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 77, 11, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final yellow255_15 = TextStyle(
      color: const Color(0xFFFF4D0B),
      fontSize: 15.sp,
      decoration: TextDecoration.underline);

  static final yellow255_16_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 77, 11, 1),
      fontSize: 16.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final yellow255_14_B = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 77, 11, 1),
      fontSize: 14.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray30_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(30, 30, 30, 1),
      fontSize: 14.sp,
      decoration: TextDecoration.none);

  static final gray169_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(169, 169, 169, 1),
      fontSize: 14.sp,
      decoration: TextDecoration.none);

  static final gray172_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(110, 110, 123, 1),
      fontSize: 14.sp,
      decoration: TextDecoration.none);

  static final gray172_17 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(172, 171, 176, 1),
      fontSize: 17.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.normal,
      decoration: TextDecoration.none);

  static final gray173_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(173, 173, 173, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.normal,
      decoration: TextDecoration.none);

  static final gray168_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(168, 168, 168, 1),
      fontSize: 15.sp,
      decoration: TextDecoration.none);

  static final yellow240_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(240, 96, 0, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray157_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(157, 157, 157, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray214_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(214, 214, 214, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray179_15_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(179, 179, 179, 1),
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final hexb3b3b3_15_M = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xffb3b3b3),
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray187_15_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(187, 187, 187, 1),
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final black64_15_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(232, 232, 233, 1),
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white244_15_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white241_15_semibold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(241, 241, 241, 1),
      fontSize: 15.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white244_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(244, 244, 244, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final white244_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(244, 244, 244, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray143_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white244_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white244_14semibold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(244, 244, 244, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);
  static final white244_18 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(244, 244, 244, 1),
      fontSize: 18.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white244_20 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(244, 244, 244, 1),
      fontSize: 18.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final hex003dfd_25_M = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xff00edfd),
      fontSize: 25.sp,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final hex003dfd_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xff00edfd),
      fontSize: 13.sp,
      decoration: TextDecoration.none);

  static final black51_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(51, 51, 51, 1),
      fontSize: 14.sp,
      decoration: TextDecoration.none);

  static final white233_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(233, 233, 233, 1),
      fontSize: 14.sp,
      decoration: TextDecoration.none);

  static final gray156_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(156, 159, 166, 1),
      fontSize: 15.sp,
      decoration: TextDecoration.none);

  static final gray156_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(156, 159, 166, 1),
      fontSize: 12.sp,
      decoration: TextDecoration.none);

  static final black0_18_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(0, 0, 0, 1),
      fontSize: 18.sp,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);

  static final gray153_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(153, 153, 153, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray30_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(30, 30, 30, 1),
      fontSize: 15.sp,
      decoration: TextDecoration.none);

  static final black13_11 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(95, 95, 95, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final red255_13_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(240, 128, 128, 1.0),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final green0_13_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(0, 250, 154, 1.0),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final red255_11 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(240, 128, 128, 1.0),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  //==============================分界线=============================================

  static final gray153_10 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(153, 153, 153, 1),
      fontSize: 10.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final lgray11 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(102, 102, 102, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final lgray13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(102, 102, 102, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final lgray14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(102, 102, 102, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray12128 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(128, 128, 128, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray11 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(153, 153, 153, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(153, 153, 153, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(153, 153, 153, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray150 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(50, 50, 50, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray173 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(173, 173, 173, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(153, 153, 153, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray10 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(153, 153, 153, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray232_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(153, 153, 153, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final green85_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(172, 171, 176, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray153_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(153, 153, 153, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray16 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(102, 102, 102, 1),
      fontSize: 16.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final gray16medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(102, 102, 102, 1),
      fontSize: 16.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);
  static final gray16blod = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(102, 102, 102, 1),
      fontSize: 16.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray204 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(204, 204, 204, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray204_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(204, 204, 204, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray204_18_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(204, 204, 204, 1),
      fontSize: 18.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final red10 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(240, 75, 62, 1),
      fontSize: 10.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final red12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(240, 75, 62, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final red240 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(246, 95, 133, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final red24015 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(240, 75, 62, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final red13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 99, 71, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final red14 = TextStyle(
    fontFamily: hanyi,
    color: const Color.fromRGBO(240, 75, 62, 1),
    fontSize: 14.sp,
    overflow: TextOverflow.ellipsis,
    decoration: TextDecoration.none,
  );

  static final red16bold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 157, 18, 1),
      fontSize: 16.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final red20bold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(240, 75, 62, 1),
      fontSize: 20.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final red15bold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(240, 75, 62, 1),
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final yellow12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 157, 18, 1),
      fontSize: 12.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final black20bold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(34, 34, 34, 1),
      fontSize: 20.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final black1534 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(34, 34, 34, 1),
      fontSize: 15.sp,
      fontWeight: FontWeight.normal,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final blackBlod1534 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(34, 34, 34, 1),
      fontSize: 15.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final blackMedium1534 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(34, 34, 34, 1),
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final black1834 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(34, 34, 34, 1),
      fontSize: 18.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final black118_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(161, 161, 178, 1),
      fontSize: 12.sp,
      decoration: TextDecoration.none);

  static final black788187_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(78, 81, 87, 1),
      fontSize: 12.sp,
      decoration: TextDecoration.none);

  static final black12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(51, 51, 51, 1),
      fontSize: 12.sp,
      decoration: TextDecoration.none);

  static final black12_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(51, 51, 51, 1),
      fontWeight: FontWeight.w600,
      fontSize: 12.sp,
      decoration: TextDecoration.none);

  static final black13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(51, 51, 51, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final black13bold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(51, 51, 51, 1),
      fontSize: 13.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final black15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(51, 51, 51, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final black1434 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(34, 34, 34, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);

  static final black1234 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(34, 34, 34, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.normal,
      decoration: TextDecoration.none);

  static final black15bold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(51, 51, 51, 1),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);

  static final black20bold51 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(51, 51, 51, 1),
      fontSize: 20.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);

  static final black18bold50 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(50, 50, 50, 1),
      fontSize: 18.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);

  static final black16 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(51, 51, 51, 1),
      fontSize: 16.sp,
      decoration: TextDecoration.none);

  static final black16bold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(51, 51, 51, 1),
      fontSize: 16.sp,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);

  static final black16bold34 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(34, 34, 34, 1),
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final black16medium34 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(34, 34, 34, 1),
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final black1634 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(34, 34, 34, 1),
      fontSize: 16.sp,
      fontWeight: FontWeight.normal,
      decoration: TextDecoration.none);

  static final black18bold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(51, 51, 51, 1),
      fontSize: 18.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final black24 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(51, 51, 51, 1),
      fontSize: 24.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white10 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 10.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final hexa3a2a2_10 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xffffffff),
      fontSize: 10.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final hexa3a2a2_11 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(180, 180, 180, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white9 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 9.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final white9medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 9.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);
  static final white10medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 10.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);
  static final white10semibold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 10.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);

  static final white24 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 24.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white11 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final green11 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(87, 136, 245, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white11medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);
  static final white11semibold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);

  static final white12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final gray95_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(148, 148, 148, 1),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white12medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 12.sp,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);
  static final hexa3a2a2_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xffffffff),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final hexa0a0a0_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xffa0a0a0),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final rgb250219183_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(250, 219, 183, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final hex00a3f2_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xff00a3f2),
      fontSize: 12.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final hexff2a8a_12 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xffFF6347),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white13medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final hexa3a2a2_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xffffffff),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final hexa3a2a2_13_M = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xffffffff),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);
  static final hexfbe099_13_M = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xfffbe099),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);
  static final white14 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white14Medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 14.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final hexa3a2a2_15 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xff999999),
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white15_M = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none);

  static final white15 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 15.sp,
      // overflow: TextOverflow.fade,
      decoration: TextDecoration.none);

  static final white15bold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 15.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white15semibold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 15.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white16bold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 16.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final white16medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 16.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final color93_163_247_16medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(93, 163, 247, 1),
      fontSize: 16.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final color141_144_154_16medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(141, 144, 154, 1),
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white237242250_11medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(237, 242, 250, 1),
      fontSize: 11.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final white237242250_17medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(237, 242, 250, 1),
      fontSize: 17.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white19_semi = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 19.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white18 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 18.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final white18mudium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 18.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final white16mudium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(93, 163, 247, 1),
      fontSize: 16.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white18bold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 18.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white18semibold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 18.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final hexffbd39_18_M = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xffffbd39),
      fontSize: 18.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final hexaa5000_18_S = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xffaa5000),
      fontSize: 18.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final white20bold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 20.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final white20medium = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 20.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final white22bold = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(255, 255, 255, 1),
      fontSize: 22.sp,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final hex0d141f_11 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(26, 26, 31, 1),
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final jellyCyan_11 = TextStyle(
      fontFamily: hanyi,
      color: jellyCyanColor103224185,
      fontSize: 11.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final jellyCyan_11_M = TextStyle(
      fontFamily: hanyi,
      color: jellyCyanColor103224185,
      fontSize: 11.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final hex0d141f_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color.fromRGBO(26, 26, 31, 1),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final jellyCyan_13 = TextStyle(
      fontFamily: hanyi,
      color: jellyCyanColor103224185,
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final jellyCyan_13_M = TextStyle(
      fontFamily: hanyi,
      color: jellyCyanColor103224185,
      fontSize: 13.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final jellyCyan_14 = TextStyle(
      fontFamily: hanyi,
      color: jellyCyanColor103224185,
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final jellyCyan_15 = TextStyle(
      fontFamily: hanyi,
      color: jellyCyanColor103224185,
      fontSize: 15.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final jellyCyan_15_M = TextStyle(
      fontFamily: hanyi,
      color: jellyCyanColor103224185,
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final jellyCyan_18_M = TextStyle(
      fontFamily: hanyi,
      color: jellyCyanColor103224185,
      fontSize: 18.sp,
      fontWeight: FontWeight.w500,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final jellyCyan_25_semi = TextStyle(
      fontFamily: hanyi,
      color: jellyCyanColor103224185,
      fontSize: 25.sp,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);

  static final nav_active_13 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xff5da3f7),
      fontSize: 13.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
  static final nav_active_14 = TextStyle(
      fontFamily: hanyi,
      color: const Color(0xff5da3f7),
      fontSize: 14.sp,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none);
}

extension MyHeightEx on TextStyle {
  TextStyle get h1 => copyWith(height: 1);
}

extension MySizeEx on TextStyle {
  TextStyle get s10 => copyWith(fontSize: 10.sp);
  TextStyle get s12 => copyWith(fontSize: 12.sp);
  TextStyle get s14 => copyWith(fontSize: 14.sp);
  TextStyle get s16 => copyWith(fontSize: 16.sp);
  TextStyle get s17 => copyWith(fontSize: 17.sp);
  TextStyle get s18 => copyWith(fontSize: 18.sp);
  TextStyle get s20 => copyWith(fontSize: 20.sp);
  TextStyle get s25 => copyWith(fontSize: 25.sp);
}

extension MyWeightEx on TextStyle {
  TextStyle get w500 => copyWith(fontWeight: FontWeight.w500);
  TextStyle get w600 => copyWith(fontWeight: FontWeight.w600);
  TextStyle get w700 => copyWith(fontWeight: FontWeight.w700);
}

extension MyTextColorEx on TextStyle {
  // TextStyle get main => copyWith(color: MyTextColors.main);
  // TextStyle get subtitle => copyWith(color: MyTextColors.subTitle);

  TextStyle get error => copyWith(color: const Color(0xFFFF1D00));

  TextStyle get white25502 => copyWith(color: MyTheme.white25502Color);
  TextStyle get white25503 => copyWith(color: MyTheme.white25503Color);
  TextStyle get white25504 => copyWith(color: MyTheme.white25504Color);
  TextStyle get white25505 => copyWith(color: MyTheme.white25505Color);
  TextStyle get white25506 => copyWith(color: MyTheme.white25506Color);
  TextStyle get white25507 => copyWith(color: MyTheme.white25507Color);
  TextStyle get white25508 => copyWith(color: MyTheme.white25508Color);
  TextStyle get white25509 => copyWith(color: MyTheme.white25509Color);
  TextStyle get white => copyWith(color: MyTheme.white255Color);

  TextStyle get yellow255 => copyWith(color: MyTheme.yellow255Color);
}
