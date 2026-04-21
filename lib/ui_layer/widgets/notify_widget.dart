import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/model/tip_model.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:g_link/ui_layer/widgets/swiper_tips.dart';

class NotifyWidget extends StatelessWidget {
  final List<TipModel> tips;

  const NotifyWidget({super.key, required this.tips});

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) return const SizedBox();
    return Padding(
      padding: EdgeInsets.only(
        left: MyTheme.pagePadding,
        top: 8.w,
        right: MyTheme.pagePadding,
        bottom: 3.w,
      ),
      child: Row(
        children: [
          MyImage.asset(
            MyImagePaths.appLivesNoticeIcon,
            width: 18.w,
            height: 14.w,
          ),
          Expanded(
            child: Stack(
              children: [
                SwiperTips(tips: tips),
                Container(
                  width: 30.w,
                  height: 20.w,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 0, 0, 0),
                        Color.fromARGB(0, 0, 0, 0)
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
