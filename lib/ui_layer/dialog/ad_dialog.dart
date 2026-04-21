import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';

import '../../../../../report/ui_layer/report_gesture_detector.dart';

class AdDialog extends StatefulWidget {
  const AdDialog(
      {super.key,
      required this.cancel,
      required this.confirm,
      this.adWidth = 100,
      this.adHeight = 100,
      required this.adUrl});

  final String adUrl;
  final VoidCallback cancel;
  final VoidCallback confirm;
  final int? adWidth;
  final int? adHeight;

  @override
  State<AdDialog> createState() => AdDialogState();
}

class AdDialogState extends State<AdDialog> {
  DateTime? _lastClickTime;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black38,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            ReportGestureDetector(
              onTap: () => widget.confirm.call(),
              child: RepaintBoundary(
                child: Image.network(
                  widget.adUrl,
                  width: widget.adWidth?.w,
                  height: widget.adHeight?.w,
                ),
              ),
            ),
            SizedBox(height: 20.w),
            ReportGestureDetector(
              onTap: _handleCancelTap,
              child: SizedBox(
                child: MyImage.asset(
                  MyImagePaths.appCancelWithCircle,
                  fit: BoxFit.cover,
                  width: 33.w,
                  height: 33.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCancelTap() {
    final currentTime = DateTime.now();
    // 检查上一次点击时间，如果两次点击间隔小于 1秒，则忽略此次点击
    if (_lastClickTime == null ||
        currentTime.difference(_lastClickTime!) >
            const Duration(milliseconds: 1000)) {
      _lastClickTime = currentTime;
      // 执行点击事件逻辑
      widget.cancel.call();
    }
  }
}
