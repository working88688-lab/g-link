import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../image_paths.dart';
import '../../../widgets/custom_switch.dart';
import '../../../widgets/my_image.dart';

class MineSetingsWidgets {
  static Widget sectionHeader(String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.w),
      child: Text(
        title,
        style: TextStyle(
          color: const Color(0xFF45556C),
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static Widget buildCard({required List<Widget> children, EdgeInsetsGeometry? padding}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.w),
      ),
      padding: padding ?? EdgeInsets.symmetric(horizontal: 0.w, vertical: 0.w),
      child: Column(children: children),
    );
  }

  static Widget toggleItem(
      {String? icon,
      required String label,
      required bool value,
      required ValueChanged<bool> onChanged,
      Widget? prefix}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.w),
      child: Row(
        children: [
          if (prefix != null) ...[
            prefix,
          ],
          if (icon != null) ...[
            MyImage.asset(
              icon,
              width: 20.w,
            ),
            SizedBox(width: 8.w),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF0F172B),
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CustomSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  static Widget arrowItem({
    String? icon,
    Color? labelColor,
    required String label,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              MyImage.asset(
                icon,
                width: 20.w,
              ),
              SizedBox(width: 8.w),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor ?? const Color(0xFF0F172B),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: TextStyle(
                  color: const Color(0xFF62748E),
                  fontSize: 14.sp,
                ),
              ),
            MyImage.asset(
              MyImagePaths.iconArrowRightBlack,
              width: 20.w,
            ),
          ],
        ),
      ),
    );
  }

  static Widget divider() {
    return Container(
      height: 1.w,
      margin: EdgeInsets.only(left: 16.w),
      color: const Color(0xFF1A1F2C).withAlpha(4),
    );
  }

  static Widget dividerVertical() {
    return Container(
      width: 1.w,
      height: 30.w,
      color: const Color(0xFF1A1F2C).withAlpha(4),
    );
  }

  static Widget visibilityItem({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.w),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF0F172B),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Image.asset(
              selected ? MyImagePaths.iconSel : MyImagePaths.iconUnSel,
              width: 16.w,
              height: 16.w,
            ),
          ],
        ),
      ),
    );
  }
}
