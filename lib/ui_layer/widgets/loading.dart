import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.text, this.width = 100});

  final String? text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 30.w,
            width: 30.w,
            child: const CircularProgressIndicator(
              color: MyTheme.jellyCyanColor103224185,
              strokeWidth: 2,
            ),
          ),
          SizedBox(height: 15.w),
          Text(
            text ?? 'zzjzsh'.tr(context: context),
            style: TextStyle(
              color: const Color(0xff666666),
              fontSize: 12.sp,
              fontWeight: FontWeight.normal,
              overflow: TextOverflow.visible,
              decoration: TextDecoration.none,
            ),
          )
        ],
      ),
    );
  }
}
