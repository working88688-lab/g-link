import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:g_link/ui_layer/notifier/app_chat_notifier.dart';
import 'package:g_link/ui_layer/theme/app_design.dart';
import 'package:g_link/ui_layer/widgets/chat_message_bubble.dart';
import 'package:provider/provider.dart';

class ChatPageV2 extends StatefulWidget {
  const ChatPageV2({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<ChatPageV2> createState() => _ChatPageV2State();
}

class _ChatPageV2State extends State<ChatPageV2> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppChatNotifier>().markRead(widget.sessionId);
      _jumpBottom();
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppChatNotifier>(
      builder: (_, chat, __) {
        final session = chat.sessionById(widget.sessionId);
        final msgs = chat.messagesOf(widget.sessionId);
        if (session == null) {
          return Scaffold(
              body: Center(child: Text('messageSessionMissing'.tr())));
        }
        return Scaffold(
          backgroundColor: AppDesign.bg,
          appBar: AppBar(title: Text(session.name)),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    return ChatMessageBubble(message: msgs[i]);
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputCtrl,
                          decoration: InputDecoration(
                              hintText: 'messageInputHint'.tr()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _send(chat),
                        child: Text('commonSend'.tr()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _send(AppChatNotifier chat) {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    chat.sendText(widget.sessionId, text);
    _inputCtrl.clear();
    _jumpBottom();
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      chat.mockReply(widget.sessionId, 'messageAutoReply'.tr());
      _jumpBottom();
    });
  }

  void _jumpBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
