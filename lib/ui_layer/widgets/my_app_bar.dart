import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../image_paths.dart';
import '../theme.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar(
      {super.key,
      this.title,
      this.rightWidget,
      this.backgroundColor = Colors.white,
      this.backArrowOnTap,
      this.flexibleSpaceColor,
      this.leftWidget,
      this.titleWidget,
      this.showDiver = false,
      this.showBoxShadow = true,
      this.actionWidget})
      : preferredSize = const Size.fromHeight(45);
  final String? title;
  final Widget? rightWidget;
  final Color? backgroundColor;
  final VoidCallback? backArrowOnTap;
  final Color? flexibleSpaceColor;
  final Widget? leftWidget;
  final bool showDiver;
  final bool showBoxShadow;
  final Widget? titleWidget;
  final Widget? actionWidget;

  @override
  final Size preferredSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: MyTheme.navbarHegiht,
          decoration: BoxDecoration(
              boxShadow: showBoxShadow
                  ? [
                      BoxShadow(
                        offset: Offset(0, 1.w),
                        blurRadius: 3.w,
                        spreadRadius: 0,
                        color: Color(0x80E2E8F0),
                      ),
                    ]
                  : [],
              border: showDiver
                  ? Border(
                      bottom: BorderSide(
                        color: const Color.fromRGBO(255, 255, 255, 0.04),
                        width: 0.5.w,
                      ),
                    )
                  : null),
          child: Container(
            color: backgroundColor ?? Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                    left: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        leftWidget == null
                            ? Align(
                                alignment: Alignment.center,
                                child: GestureDetector(
                                  child: Image.asset(
                                    MyImagePaths.appBackIcon,
                                    width: 24.w,
                                    height: 24.w,
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
                    )),
                titleWidget ??
                    (title != null
                        ? Container(
                            alignment: Alignment.center,
                            // padding: EdgeInsets.symmetric(
                            //   horizontal: 2 * MyTheme.pagePadding,
                            // ),
                            child: Text(title!,
                                style: TextStyle(
                                    fontSize: 16.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1D293D))),
                          )
                        : const SizedBox.shrink()),
                if (actionWidget != null) Positioned(right: 0, child: actionWidget!)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
