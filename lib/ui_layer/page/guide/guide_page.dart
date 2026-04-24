import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/report/ui_layer/report_gesture_detector.dart';
import 'package:g_link/ui_layer/background_page.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/notifier/guide_page_notifier.dart';
import 'package:g_link/ui_layer/page/guide/welcome_guide1_page.dart';
import 'package:g_link/ui_layer/page/guide/welcome_guide2_page.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:g_link/ui_layer/widgets/my_app_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  @override
  Widget build(BuildContext context) {
    return BackgroundPage(
      body: Scaffold(
        appBar: MyAppBar(
          titleWidget: Container(
            padding: EdgeInsets.all(MyTheme.pagePadding + 5.w),
            width: ScreenUtil().screenWidth,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _PageIndictor(0),
                SizedBox(width: 10.w),
                _PageIndictor(1),
              ],
            ),
          ),
          leftWidget: Selector<GuidePageNotifier, bool>(
            selector: (_, notifier) => notifier.showLeftWidget,
            builder: (_, showLeftWidget, __) {
              return showLeftWidget
                  ? Align(
                      alignment: Alignment.center,
                      child: ReportGestureDetector(
                        child: Image.asset(
                          MyImagePaths.appBackIcon,
                          width: 20.w,
                          height: 20.w,
                        ),
                        onTap: () {
                          final notifier = context.read<GuidePageNotifier>();
                          if (notifier.currentIndex > 0) {
                            notifier.toPreviousStep();
                            return;
                          }
                          context.pop();
                        },
                      ),
                    )
                  : SizedBox();
            },
          ),
        ),
        body: Selector<GuidePageNotifier, int>(
          builder: (_, currentIndex, __) {
            if (currentIndex == 0) {
              return WelcomeGuide1Page();
            }
            if (currentIndex == 1) {
              return WelcomeGuide2Page();
            }
            return SizedBox.shrink();
          },
          selector: (_, notifier) => notifier.currentIndex,
        ),
      ),
    );
  }
}

class _PageIndictor extends StatelessWidget {
  final int index;

  const _PageIndictor(this.index);

  @override
  Widget build(BuildContext context) {
    return Selector<GuidePageNotifier, int>(
      builder: (_, currentIndex, __) {
        return Container(
          width: index == currentIndex ? 18.w : 11.w,
          height: 6.w,
          decoration: BoxDecoration(
            color: index == currentIndex
                ? MyTheme.primaryColor
                : MyTheme.unSelectorColor,
            borderRadius: BorderRadius.all(Radius.circular(3.w)),
          ),
        );
      },
      selector: (_, notifier) => notifier.currentIndex,
    );
  }
}
