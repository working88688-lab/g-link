import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/notifier/app_chat_notifier.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:provider/provider.dart';

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
                  badgeCount: context.select<AppChatNotifier, int>(
                    (n) => n.totalUnread,
                  ),
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

  Widget _buildTabItem(
    int index,
    String icon,
    String activeIcon, {
    int badgeCount = 0,
  }) {
    final isActive = index == currentIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Image.asset(
              isActive ? activeIcon : icon,
              width: 30.w,
              height: 30.w,
            ),
            if (badgeCount > 0)
              Positioned(
                right: -6.w,
                top: -4.w,
                child: Container(
                  constraints: BoxConstraints(minWidth: 16.w),
                  height: 16.w,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2056),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
