import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../widgets/my_app_bar.dart';

class NotificationDetailPage extends StatelessWidget {
  const NotificationDetailPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 14.w, 16.w, 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '通知标题通知标题',
                style: TextStyle(
                  color: const Color(0xFF1A1F2C),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 8.w),
              Text(
                '10分钟前',
                style: TextStyle(
                  color: const Color(0xFF1A1F2C),
                  fontSize: 14.sp,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 18.w),
              Text(
                '这里是描述这里是描述这里是描述这里是描述这里是描述这里是描述这里是描述这里是描述这里是描述这里是描述这里是描述这里是描述这里是描述这里是描述',
                style: TextStyle(
                  color: const Color(0xFF1A1F2C),
                  fontSize: 14.sp,
                  height: 1.6,
                ),
              ),
              SizedBox(height: 14.w),
              Container(
                width: double.infinity,
                height: 138.w,
                color: const Color(0xFFD9D9D9),
              ),
              SizedBox(height: 14.w),
              Text(
                '这里是描述这里是描述这里是描述这里是描述这里是描述这里是描述这里是描述这里是描述这里是描述这里是描述这里是描述这里是描述这里是描述这里是描述',
                style: TextStyle(
                  color: const Color(0xFF1A1F2C),
                  fontSize: 14.sp,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return MyAppBar(
      title: '通知详情',
    );
  }
}
