import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─────────────────────────────────────────
//  数据模型
// ─────────────────────────────────────────

class ContactItem {
  final String name;
  const ContactItem(this.name);
}

class ChatRecordItem {
  final String name;
  final String preview;
  final int? extraCount;
  const ChatRecordItem({
    required this.name,
    required this.preview,
    this.extraCount,
  });
}

class UserItem {
  final String name;
  final String followers;
  const UserItem({required this.name, required this.followers});
}

// ─────────────────────────────────────────
//  通用工具函数 & 内部小组件
// ─────────────────────────────────────────

/// 高亮关键词
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

Widget searchAvatar({double radius = 12}) => Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius.r),
        color: const Color(0xFFD1D1D6),
      ),
      child: Icon(Icons.person, size: 22.sp, color: Colors.white),
    );

class SearchSectionHeader extends StatelessWidget {
  final String title;
  const SearchSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 16.w, bottom: 8.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172B),
        ),
      ),
    );
  }
}
