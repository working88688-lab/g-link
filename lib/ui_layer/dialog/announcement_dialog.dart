import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/report/ui_layer/report_gesture_detector.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:g_link/utils/common_utils.dart';

class AnnouncementDialog extends StatelessWidget {
  const AnnouncementDialog({
    super.key,
    required this.confirm,
    required this.cancel,
    required this.text,
  });

  final VoidCallback confirm;
  final VoidCallback cancel;
  final String text;

  List<String> get textList => text.split('#');

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ReportGestureDetector(
            onTap: () => cancel.call(),
            child: const ColoredBox(
              color: Colors.black38,
            ),
          ),
        ),
        Center(
          child: Stack(
            children: [
              Container(
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                margin: EdgeInsets.symmetric(horizontal: 35.w),
                height: 450.w,
                child: Stack(
                  children: [
                    const MyImage.asset(MyImagePaths.appAnnouncementUpBg),
                    Container(
                      margin:
                          EdgeInsets.only(top: (1.sw - 70.w) / 305 * 117 - 2.w),
                      color: const Color(0xFFFCFCFC),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                                  CommonUtils.getContentSpan(
                                    text,
                                    style: TextStyle(
                                      color: const Color(0xff636363),
                                      fontSize: 15.sp,
                                      decoration: TextDecoration.none,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                // RichText(
                                //     text: TextSpan(
                                //   text: text,
                                //   style: TextStyle(
                                //     color: const Color(0xff636363),
                                //     fontSize: 15.sp,
                                //     decoration: TextDecoration.none,
                                //     fontWeight: FontWeight.normal,
                                //   ),
                                // ))
                              ],
                            ),
                          )),
                          SizedBox(height: 15.w),
                          Padding(
                            padding: EdgeInsets.only(
                              left: MyTheme.pagePadding,
                              right: MyTheme.pagePadding,
                              bottom: 15.w,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ReportGestureDetector(
                                  onTap: () => confirm.call(),
                                  child: Container(
                                    width: 110.w,
                                    height: 32.w,
                                    decoration: BoxDecoration(
                                      gradient: MyTheme.gradient_90_114,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(16.w),
                                      ),
                                    ),
                                    child: Center(
                                      child: RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: tr('wygq'),
                                              style: MyTheme.white255_14_M,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Positioned(
                top: 30.w,
                left: 0,
                right: 0,
                child: MyImage.asset(
                  MyImagePaths.appAnnouncement,
                  width: 119.w,
                  height: 29.w,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
