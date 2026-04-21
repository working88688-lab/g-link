import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/report/ui_layer/report_gesture_detector.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:g_link/utils/common_utils.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({
    super.key,
    required this.cancel,
    required this.confirm,
    required this.tips,
    required this.officialWebUrl,
    required this.solution,
    required this.mustUpdate,
  });

  final VoidCallback cancel;
  final VoidCallback confirm;
  final String tips;
  final String officialWebUrl;
  final String solution;
  final bool mustUpdate;

  List<String> get textList => tips.split('#');

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
            child: ColoredBox(color: Color.fromRGBO(0, 0, 0, 0.7))),
        Positioned(
          child: Center(
            child: Stack(
              children: [
                Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 35.w),
                  height: 430.w,
                  child: Stack(
                    children: [
                      const MyImage.asset(
                        MyImagePaths.appUpdateUpBg,
                      ),
                      Container(
                        margin: EdgeInsets.only(
                            top: (1.sw - 70.w) / 305 * 147 - 2.w),
                        color: const Color(0xFFFCFCFC),
                        child: Column(
                          children: [
                            SizedBox(height: 10.w),
                            Expanded(
                                child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (final text in textList)
                                    Text(
                                      text,
                                      style: TextStyle(
                                        color: const Color(0xff636363),
                                        fontSize: 15.sp,
                                        decoration: TextDecoration.none,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    )
                                ],
                              ),
                            )),
                            Padding(
                              padding: EdgeInsets.only(
                                left: MyTheme.pagePadding,
                                right: MyTheme.pagePadding,
                              ),
                              child: Column(children: [
                                if (Platform.isAndroid)
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: MyTheme.pagePadding / 2),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: ReportGestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () =>
                                            CommonUtils.launchUrl(solution),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              tr('bbtl'),
                                              style: TextStyle(
                                                decoration: TextDecoration.none,
                                                color: const Color(0xFF636363),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                            Text(
                                              tr('gxqbkzn'),
                                              style: TextStyle(
                                                decoration:
                                                    TextDecoration.underline,
                                                color: MyTheme.cyanColor00edfd,
                                                fontWeight: FontWeight.normal,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!mustUpdate)
                                      ReportGestureDetector(
                                        onTap: () {
                                          if (mustUpdate) return;
                                          cancel.call();
                                        },
                                        child: Container(
                                          width: 110.w,
                                          height: 32.w,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF757575),
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(16.w),
                                            ),
                                          ),
                                          child: Center(
                                            child: RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: tr('zbgx'),
                                                    style:
                                                        MyTheme.white255_14_M,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (!mustUpdate) const Spacer(),
                                    ReportGestureDetector(
                                      onTap: () {
                                        if (!mustUpdate) {
                                          cancel.call();
                                        } else if (mustUpdate &&
                                            Platform.isAndroid) {
                                          cancel.call();
                                        }
                                        confirm.call();
                                      },
                                      child: Container(
                                        width: 110.w,
                                        height: 32.w,
                                        padding: EdgeInsets.zero,
                                        decoration: BoxDecoration(
                                          gradient: MyTheme.gradient_90_114,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(16.w),
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Center(
                                          child: RichText(
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: tr('ljgx'),
                                                  style: MyTheme.white255_14_M,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 15.w,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: ReportGestureDetector(
                                      onTap: () =>
                                          CommonUtils.launchUrl(officialWebUrl),
                                      child: Center(
                                        child: Text(tr('gwgx'),
                                            style: MyTheme.jellyCyan_15),
                                      ),
                                    ),
                                  ),
                                )
                              ]),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Positioned(
                  top: 105.w,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.center,
                    child: MyImage.asset(
                      MyImagePaths.appFxxbbT,
                      width: 104.w,
                      height: 21.w,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
