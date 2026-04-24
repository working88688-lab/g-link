import 'package:flutter/material.dart';
import 'package:g_link/ui_layer/notifier/app_chat_notifier.dart';
import 'package:g_link/ui_layer/page/chat_page_v2.dart';
import 'package:provider/provider.dart';

/// Legacy entry kept for compatibility, now delegating to V2 chat flow.
class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.name,
    this.avatarUrl = '',
    this.isOnline = false,
  });

  final String name;
  final String avatarUrl;
  final bool isOnline;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final String _sessionId;

  @override
  void initState() {
    super.initState();
    _sessionId = context.read<AppChatNotifier>().ensureSession(
          name: widget.name,
          avatarUrl: widget.avatarUrl,
          isOnline: widget.isOnline,
        );
  }

  @override
  Widget build(BuildContext context) {
    return ChatPageV2(sessionId: _sessionId);
  }
}
