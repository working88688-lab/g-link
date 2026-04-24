import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../image_paths.dart';
import '../theme.dart';

import '../../../report/ui_layer/report_gesture_detector.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({
    super.key,
    this.title,
    this.rightWidget,
    this.backgroundColor,
    this.backArrowOnTap,
    this.flexibleSpaceColor,
    this.leftWidget,
    this.titleWidget,
    this.showDiver = false,
  }) : preferredSize = const Size.fromHeight(45);
  final String? title;
  final Widget? rightWidget;
  final Color? backgroundColor;
  final VoidCallback? backArrowOnTap;
  final Color? flexibleSpaceColor;
  final Widget? leftWidget;
  final bool showDiver;
  final Widget? titleWidget;

  @override
  final Size preferredSize;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: MyTheme.pagePadding),
        height: MyTheme.navbarHegiht,
        decoration: BoxDecoration(
            color: backgroundColor,
            border: showDiver
                ? Border(
                    bottom: BorderSide(
                      color: const Color.fromRGBO(255, 255, 255, 0.04),
                      width: 0.5.w,
                    ),
                  )
                : null),
        child: ColoredBox(
          color: backgroundColor ?? Colors.transparent,
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  leftWidget == null
                      ? Align(
                          alignment: Alignment.center,
                          child: ReportGestureDetector(
                            child: Image.asset(
                              MyImagePaths.appBackIcon,
                              width: 20.w,
                              height: 20.w,
                            ),
                            onTap: () {
                              if (backArrowOnTap != null) {
                                backArrowOnTap?.call();
                              } else {
                                context.pop();
                              }
                            },
                          ),
                        )
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: leftWidget!,
                        ),
                  rightWidget == null ? const SizedBox.shrink() : rightWidget!
                ],
              ),
              titleWidget ??
                  (title != null
                      ? Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(
                            horizontal: 2 * MyTheme.pagePadding,
                          ),
                          child: Text(title!, style: MyTheme.white255_18_B),
                        )
                      : const SizedBox.shrink())
            ],
          ),
        ),
      ),
    );
  }
}
