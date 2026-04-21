import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          elevation: 0, // 去掉系统阴影
          child: Container(
            height: 62.w,
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabItem(
                  0,
                  MyImagePaths.appTabHomeN,
                  MyImagePaths.appTabHomeS,
                ),
                _buildTabItem(
                  1,
                  MyImagePaths.appTabDspN,
                  MyImagePaths.appTabDspS,
                ),
                SizedBox(width: 60.w),
                _buildTabItem(
                  3,
                  MyImagePaths.appTabMsgN,
                  MyImagePaths.appTabMsgS,
                ),
                _buildTabItem(
                  4,
                  MyImagePaths.appTabMineN,
                  MyImagePaths.appTabMineS,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -8.w,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => onTap(2), // 中间按钮索引
              child: Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  MyImagePaths.appTabPublish,
                  width: 30.w,
                  height: 30.w,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabItem(int index, String icon, String activeIcon) {
    final isActive = index == currentIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Image.asset(
          isActive ? activeIcon : icon,
          width: 30.w,
          height: 30.w,
        ),
      ),
    );
  }
}
