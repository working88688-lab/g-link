import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20.w,
          color: const Color(0xFF1D293D),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        '通知详情',
        style: TextStyle(
          color: const Color(0xFF1D293D),
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE9EEF5)),
      ),
    );
  }
}
