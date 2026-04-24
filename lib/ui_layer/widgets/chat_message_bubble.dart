import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/notifier/app_chat_notifier.dart';
import 'package:g_link/ui_layer/theme/app_design.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isTimeline) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            message.content,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: BoxConstraints(maxWidth: 250.w),
        decoration: BoxDecoration(
          color: message.isMine ? AppDesign.brand : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: message.isMine ? Colors.white : AppDesign.textPrimary,
          ),
        ),
      ),
    );
  }
}
