import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ──────────────────────────────────────────
// 为你推荐用户列表
// ──────────────────────────────────────────

class RecommendUsersWidget extends StatefulWidget {
  final Function? onClose;

  const RecommendUsersWidget({super.key, this.onClose});

  @override
  State<RecommendUsersWidget> createState() => _RecommendUsersWidgetState();
}

class _RecommendUsersWidgetState extends State<RecommendUsersWidget> {
  bool _closed = false;

  @override
  Widget build(BuildContext context) {
    if (_closed) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '为你推荐',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1F2C),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                widget.onClose?.call();
                setState(() => _closed = true);
              },
              child: Text(
                '关闭',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF62748E),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 15.w),
        for (int i = 0; i < 10; i++)
          Container(
            margin: EdgeInsets.only(bottom: 20.w),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40.r),
                    color: const Color(0xFFD1D1D6),
                  ),
                  child: Icon(Icons.person, size: 28.sp, color: Colors.white),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sarah Jenks',
                        style: TextStyle(
                          color: const Color(0xFF0F172B),
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '5.4w粉丝',
                        style: TextStyle(
                          color: const Color(0xFF62748E),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  child: Container(
                    height: 33.5.w,
                    width: 60.w,
                    decoration: BoxDecoration(
                      color: i % 2 == 0 ? const Color(0xFF1A1F2C) : null,
                      border: i % 2 == 0
                          ? null
                          : Border.all(
                          color: const Color(0xFFCCCCCC), width: 1.w),
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      i % 2 == 0 ? '已关注' : '关注',
                      style: TextStyle(
                        color: i % 2 == 0
                            ? const Color(0xFFF8F9FE)
                            : const Color(0xFF1A1F2C),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
