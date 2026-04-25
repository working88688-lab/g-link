import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/page/chat/search/models/search_models.dart';

/// 聊天记录搜索结果 — 列表项
/// - 有 [extraCount] 时显示 "N 条相关聊天记录"，可点击钻取详情
/// - 无 [extraCount] 时直接高亮显示消息预览
class ChatRecordTile extends StatelessWidget {
  final ChatRecordItem item;
  final String keyword;
  final VoidCallback? onTap;

  const ChatRecordTile({
    super.key,
    required this.item,
    required this.keyword,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.w),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1A1F2C).withOpacity(.05)))),
        child: Row(
          children: [
            searchAvatar(),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w400, color: const Color(0xFF1A1F2C)),
                  ),
                  SizedBox(height: 8.w),
                  item.extraCount != null
                      ? Text(
                          '${item.extraCount}条相关聊天记录',
                          style:
                              TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: const Color(0xFF0F172B)),
                        )
                      : highlight(
                          item.preview,
                          keyword,
                          base: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: const Color(0xFF0F172B)),
                          hl: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: const Color(0xFF00C67E)),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 聊天记录钻取详情 — 单条消息项
/// 顶部显示日期标签，正文关键词高亮
class ChatRecordDetailTile extends StatelessWidget {
  final ChatRecordItem item;
  final String keyword;

  const ChatRecordDetailTile({
    super.key,
    required this.item,
    required this.keyword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.w),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF8F9FE)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
            decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(4.r)),
            child: Text(
              item.name,
              style: TextStyle(fontSize: 11.sp, color: const Color(0xFF62748E)),
            ),
          ),
          SizedBox(height: 6.w),
          highlight(
            item.preview,
            keyword,
            base: TextStyle(fontSize: 14.sp, color: const Color(0xFF0F172B)),
            hl: TextStyle(fontSize: 14.sp, color: const Color(0xFF00C67E), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
