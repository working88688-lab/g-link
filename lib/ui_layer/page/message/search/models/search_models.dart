import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';

// ─────────────────────────────────────────
//  SearchMode
// ─────────────────────────────────────────

enum SearchMode {
  all, // 全局搜索（联系人 + 聊天记录 + 用户）
  contactsAndRecords, // 联系人 + 聊天记录（message_page 入口）
  chatRecords, // 仅聊天记录（chat_page 内搜索）
  users, // 仅用户搜索
}

// ─────────────────────────────────────────
//  数据模型
// ─────────────────────────────────────────

class ContactItem {
  final int uid;
  final String name;
  final String avatarUrl;

  const ContactItem(this.name, {this.uid = 0, this.avatarUrl = ''});
}

class ChatRecordItem {
  final int msgId;
  final int chatId;
  final String name;
  final String preview;
  final String createdAt;
  final int? extraCount;
  final int? senderUid;

  const ChatRecordItem({
    this.msgId = 0,
    this.chatId = 0,
    required this.name,
    required this.preview,
    this.createdAt = '',
    this.extraCount,
    this.senderUid
  });
}

class UserItem {
  final int uid;
  final String username;
  final String nickname;
  final String avatarUrl;
  final int followerCount;
  bool isFollowing;

  UserItem({
    required this.uid,
    required this.username,
    required this.nickname,
    required this.avatarUrl,
    required this.followerCount,
    this.isFollowing = false,
  });

  String get displayName => nickname.isNotEmpty ? nickname : username;
}

// ─────────────────────────────────────────
//  共享工具函数 & 小组件
// ─────────────────────────────────────────

/// 关键词高亮
Widget highlight(
  String text,
  String keyword, {
  TextStyle? base,
  TextStyle? hl,
}) {
  if (keyword.isEmpty) return Text(text, style: base);
  final lower = text.toLowerCase();
  final lk = keyword.toLowerCase();
  final spans = <TextSpan>[];
  int start = 0;
  while (true) {
    final idx = lower.indexOf(lk, start);
    if (idx == -1) {
      spans.add(TextSpan(text: text.substring(start), style: base));
      break;
    }
    if (idx > start) {
      spans.add(TextSpan(text: text.substring(start, idx), style: base));
    }
    spans.add(TextSpan(
      text: text.substring(idx, idx + keyword.length),
      style: hl,
    ));
    start = idx + keyword.length;
  }
  return RichText(text: TextSpan(children: spans));
}

Widget searchAvatar({double? size, String? avatarUrl}) {
  final s = size ?? 32.w;
  return Container(
    width: s,
    height: s,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(s),
      color: const Color(0xFFD1D1D6),
    ),
    child: (avatarUrl == null || avatarUrl.isEmpty)
        ? Icon(Icons.person, size: 22.sp, color: Colors.white)
        : ClipRRect(
            borderRadius: BorderRadius.circular(s),
            child: Image.network(avatarUrl, fit: BoxFit.cover),
          ),
  );
}

class SearchSectionHeader extends StatelessWidget {
  final String title;

  const SearchSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 14.w, bottom: 6.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0F172B),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  共享搜索输入框
// ─────────────────────────────────────────

class SearchInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback onClear;
  final bool showCancel;
  final VoidCallback? onCancel;
  final String hintText;
  final double? radius;

  const SearchInputBar(
      {super.key,
      required this.controller,
      required this.focusNode,
      required this.query,
      required this.onChanged,
      this.onSubmitted,
      required this.onClear,
      this.showCancel = true,
      this.onCancel,
      this.hintText = "搜索",
      this.radius});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.w),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FE),
                borderRadius: BorderRadius.circular(radius ?? 100.r),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF0F172B),
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 9.w, horizontal: 8.w),
                  prefixIcon: Stack(
                    alignment: Alignment.center,
                    children: [
                      MyImage.asset(MyImagePaths.iconSearch, width: 22.w, height: 22.w),
                    ],
                  ),
                  prefixIconConstraints: BoxConstraints(minWidth: 40.w),
                  hintText: hintText,
                  hintStyle: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF90A1B9),
                  ),
                  suffixIcon: query.isNotEmpty
                      ? GestureDetector(
                          onTap: onClear,
                          child: Padding(
                            padding: EdgeInsets.only(right: 12.w),
                            child: MyImage.asset(MyImagePaths.iconInputClear, width: 24.w, height: 24.w),
                          ),
                        )
                      : null,
                  suffixIconConstraints: BoxConstraints(minWidth: 36.w),
                ),
              ),
            ),
          ),
          if (showCancel) ...[
            SizedBox(width: 11.w),
            GestureDetector(
              onTap: onCancel ?? () => Navigator.of(context).pop(),
              child: Text(
                '取消',
                style: TextStyle(
                  fontSize: 15.sp,
                  color: const Color(0xFF0F172B),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
