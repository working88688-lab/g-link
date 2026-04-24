import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'search_models.dart';

// ─────────────────────────────────────────
//  SubView 3：某个联系人的聊天记录列表
// ─────────────────────────────────────────

class ChatRecordsSubView extends StatelessWidget {
  final String contactName;
  final String query;
  final VoidCallback? onBack;

  const ChatRecordsSubView({
    super.key,
    required this.contactName,
    required this.query,
    this.onBack,
  });

  // 模拟数据
  List<ChatRecordItem> get _records => [
        const ChatRecordItem(name: '2025-03-01', preview: '太优秀了吧'),
        const ChatRecordItem(name: '2025-02-18', preview: '优秀到无可救药'),
        const ChatRecordItem(name: '2024-12-25', preview: '真的太优秀了'),
      ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      children: [
        SizedBox(height: 8.w),
        ..._records.map((r) => _ChatRecordDetailTile(item: r, keyword: query)),
        SizedBox(height: 24.w),
      ],
    );
  }
}

class _ChatRecordDetailTile extends StatelessWidget {
  final ChatRecordItem item;
  final String keyword;
  const _ChatRecordDetailTile({required this.item, required this.keyword});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.w),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF8F9FE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期标签
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              item.name,
              style: TextStyle(fontSize: 11.sp, color: const Color(0xFF62748E)),
            ),
          ),
          SizedBox(height: 6.w),
          // 消息内容（高亮关键词）
          highlight(
            item.preview,
            keyword,
            base: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF0F172B),
            ),
            hl: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF00C67E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
