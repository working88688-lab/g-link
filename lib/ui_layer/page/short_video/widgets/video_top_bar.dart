import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';

class VideoTopBar extends StatelessWidget {
  final TabController tabCtrl;

  const VideoTopBar({super.key, required this.tabCtrl});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 62.w,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Tab 居中
            TabBar(
              controller: tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              indicator: const BoxDecoration(),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF9D9D9D),
              labelStyle:
                  TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400),
              tabs: [
                Tab(text: 'homeTabFollowing'.tr()),
                Tab(text: 'homeTabRecommend'.tr()),
                Tab(text: 'homeTabNearby'.tr()),
              ],
            ),
            // 搜索图标浮动在右侧
            Positioned(
              right: 12.w,
              child: GestureDetector(
                child: MyImage.asset(
                  MyImagePaths.iconShortVideoSearch,
                  width: 24.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
