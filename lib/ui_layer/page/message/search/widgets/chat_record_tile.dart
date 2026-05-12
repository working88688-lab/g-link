import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/model/chat_model.dart' show MessageSearchMsg;
import 'package:g_link/ui_layer/page/message/search/models/search_models.dart';

import '../../../../router/routes.dart';

/// 聊天记录搜索结果 — 列表项
/// - 有 [extraCount] 时显示 "N 条相关聊天记录"，可点击钻取详情
/// - 无 [extraCount] 时直接高亮显示消息预览
class ChatRecordTile extends StatelessWidget {
  final MessageSearchMsg item;
  final String keyword;
  final VoidCallback? onTap;
  final int? extraCount;

  const ChatRecordTile({
    super.key,
    required this.item,
    required this.keyword,
    this.extraCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
          return;
        }
        ChatConversationRoute(
          name: item.peer.nickname,
          avatarUrl: item.peer.avatarUrl, // item.avatarUrl,
          uid: item.peerUid!,
        ).push(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.w),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1A1F2C).withOpacity(.05)))),
        child: Row(
          children: [
            searchAvatar(avatarUrl: item.sender.avatarUrl),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.sender.nickname,
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w400, color: const Color(0xFF1A1F2C)),
                  ),
                  SizedBox(height: 4.w),
                  extraCount != null
                      ? Text(
                          '${extraCount}条相关聊天记录',
                          style:
                              TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: const Color(0xFF0F172B)),
                        )
                      : highlight(
                          item.content,
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
