import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/notifier/app_chat_notifier.dart';

class ChatSessionTile extends StatelessWidget {
  const ChatSessionTile({
    super.key,
    required this.session,
    required this.onTap,
    required this.onPinToggle,
    required this.onMuteToggle,
  });

  final ChatSession session;
  final VoidCallback onTap;
  final VoidCallback onPinToggle;
  final VoidCallback onMuteToggle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade300,
        child: session.avatarUrl.isEmpty
            ? const Icon(Icons.person, color: Colors.white)
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              session.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            session.time,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              session.lastMsg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (session.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: session.isMuted ? Colors.blueGrey : Colors.redAccent,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                session.unreadCount > 99 ? '99+' : '${session.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz_rounded),
        onSelected: (value) {
          if (value == 'pin') onPinToggle();
          if (value == 'mute') onMuteToggle();
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'pin',
            child: Text(
              session.isPinned ? 'chatActionUnpin'.tr() : 'chatActionPin'.tr(),
            ),
          ),
          PopupMenuItem(
            value: 'mute',
            child: Text(
              session.isMuted ? 'chatActionUnmute'.tr() : 'chatActionMute'.tr(),
            ),
          ),
        ],
      ),
    );
  }
}
