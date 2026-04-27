import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/video_item_model.dart';

class NotInterestedSheet extends StatefulWidget {
  final VideoItemModel item;

  const NotInterestedSheet({super.key, required this.item});

  @override
  State<NotInterestedSheet> createState() => _NotInterestedSheetState();
}

class _NotInterestedSheetState extends State<NotInterestedSheet> {
  final TextEditingController _kwCtrl = TextEditingController();

  @override
  void dispose() {
    _kwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    // 构建带标签的选项列表：作者 + 音乐 + 所有话题
    final chips = <({String label, String value})>[
      (label: 'shortVideoNotInterestedLabelAuthor'.tr(), value: item.authorName),
      (label: 'shortVideoNotInterestedLabelMusic'.tr(), value: item.music),
      ...item.tags.map((t) => (label: 'shortVideoNotInterestedLabelTopic'.tr(), value: t)),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        0,
        16.w,
        16.w + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 标题行 ─────────────────────────────
          Container(
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'shortVideoNotInterestedTitle'.tr(),
                  style: TextStyle(
                    color: const Color(0xFF1A1F2C),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Positioned(
                  right: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'shortVideoNotInterestedUndo'.tr(),
                      style: TextStyle(
                        color: const Color(0xFF62748E),
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 6.w),
          // ── 副标题 ─────────────────────────────
          Center(
            child: Text(
              'shortVideoNotInterestedSubtitle'.tr(),
              style: TextStyle(color: const Color(0xFF62748E), fontSize: 14.sp),
            ),
          ),
          SizedBox(height: 24.w),
          // ── 我不想看 ───────────────────────────
          Text(
            'shortVideoNotInterestedWhy'.tr(),
            style: TextStyle(
              color: const Color(0xFF1A1F2C),
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10.w),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 13.w,
              mainAxisSpacing: 11.w,
              childAspectRatio: 165 / 50,
            ),
            itemCount: chips.length,
            itemBuilder: (_, idx) {
              final chip = chips[idx];
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FE),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      chip.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF62748E),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    Text(
                      chip.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF0F172B),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 20.w),
          // ── 关键词屏蔽 ─────────────────────────
          Text(
            'shortVideoNotInterestedKeyword'.tr(),
            style: TextStyle(
              color: const Color(0xFF1A1F2C),
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10.w),
          Container(
            height: 46.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FE),
              borderRadius: BorderRadius.circular(4.w),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kwCtrl,
                    maxLength: 10,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                    style: TextStyle(color: const Color(0xFF1A1F2C), fontSize: 12.sp),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'shortVideoNotInterestedKeywordHint'.tr(),
                      hintStyle: TextStyle(
                        color: const Color(0xFF90A1B9),
                        fontSize: 12.sp,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Text(
                  '${_kwCtrl.text.length}/10',
                  style: TextStyle(color: const Color(0xFF90A1B9), fontSize: 12.sp),
                ),
              ],
            ),
          ),
          SizedBox(height: 28.w),
          // ── 提交按钮 ───────────────────────────
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              height: 46.w,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172B),
                borderRadius: BorderRadius.circular(43.w),
                border: Border.all(color: const Color(0xFFE3E7ED)),
              ),
              alignment: Alignment.center,
              child: Text(
                'shortVideoNotInterestedSubmit'.tr(),
                style: TextStyle(
                  color: const Color(0xFFF8F9FE),
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
