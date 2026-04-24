import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/notifier/app_chat_notifier.dart';
import 'package:g_link/ui_layer/page/chat_page_v2.dart';
import 'package:g_link/ui_layer/theme/app_design.dart';
import 'package:g_link/ui_layer/widgets/chat_session_tile.dart';
import 'package:provider/provider.dart';

class MessagePageV2 extends StatefulWidget {
  const MessagePageV2({super.key});

  @override
  State<MessagePageV2> createState() => _MessagePageV2State();
}

class _MessagePageV2State extends State<MessagePageV2> {
  final _searchCtrl = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.bg,
      appBar: AppBar(
        title: Consumer<AppChatNotifier>(
          builder: (_, chat, __) => Text(
            'messageTitle'.tr(namedArgs: {'count': '${chat.totalUnread}'}),
            style: AppDesign.appBarTitle.copyWith(fontSize: 18.sp),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.w, 16.w, 4.w),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (value) => setState(() => _keyword = value),
              decoration: InputDecoration(
                hintText: 'messageSearchHint'.tr(),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _keyword.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _keyword = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<AppChatNotifier>(
              builder: (_, chat, __) {
                final sessions = chat.filteredSessions(_keyword);
                if (sessions.isEmpty) {
                  return Center(child: Text('messageEmpty'.tr()));
                }
                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (_, i) {
                    final item = sessions[i];
                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        color: Colors.redAccent,
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white),
                      ),
                      onDismissed: (_) => chat.deleteSession(item.id),
                      child: ChatSessionTile(
                        session: item,
                        onTap: () {
                          chat.markRead(item.id);
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => ChatPageV2(sessionId: item.id),
                            ),
                          );
                        },
                        onPinToggle: () => chat.togglePin(item.id),
                        onMuteToggle: () => chat.toggleMute(item.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
