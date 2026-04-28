import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'feedback_submit_page.dart';

// ──────────────────────────────────────────
// 页面
// ──────────────────────────────────────────
class HelpFeedbackPage extends StatelessWidget {
  const HelpFeedbackPage({super.key});

  static const _faqItems = [
    '如何修改我的个人资料？',
    '忘记密码怎么办？',
    '如何关闭推送通知？',
    '帖子无法发布怎么办？',
    '怎么拉黑/举报某位用户？',
  ];

  static const _featureItems = [
    '如何使用离线缓存功能？',
    '如何保存视频到本地？',
    '私密账号功能说明',
    '内容偏好设置说明',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: _buildAppBar(context),
      body: ListView(
        children: [
          _buildSection(
            context,
            header: 'helpFeedbackCategory1'.tr(),
            items: _faqItems,
          ),
          _buildSection(
            context,
            header: 'helpFeedbackCategory2'.tr(),
            items: _featureItems,
          ),
          SizedBox(height: 24.w),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20.w,
          color: const Color(0xFF1D293D),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'helpFeedbackTitle'.tr(),
        style: TextStyle(
          color: const Color(0xFF1D293D),
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFEDF0F5)),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String header,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 20.w, 16.w, 8.w),
          child: Text(
            header,
            style: TextStyle(
              color: const Color(0xFF45556C),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(
            children: List.generate(items.length, (i) {
              return Column(
                children: [
                  _FaqTile(
                    title: items[i],
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => const FeedbackSubmitPage(),
                        ),
                      );
                    },
                  ),
                  if (i < items.length - 1)
                    Container(
                      height: 1,
                      margin: EdgeInsets.only(left: 16.w),
                      color: const Color(0xFFEDF0F5),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────
// FAQ 列表项
// ──────────────────────────────────────────
class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF000000),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20.w,
              color: const Color(0xFFB0BAC8),
            ),
          ],
        ),
      ),
    );
  }
}
