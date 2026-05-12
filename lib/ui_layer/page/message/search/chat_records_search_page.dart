import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/chat.dart';
import 'package:g_link/domain/model/chat_model.dart';
import 'package:provider/provider.dart';
import 'models/search_models.dart';
import 'widgets/chat_record_tile.dart';

// ─────────────────────────────────────────
//  聊天记录搜索页
//  入口：单个聊天页顶部菜单"搜索"
// ─────────────────────────────────────────

enum _Sub { results }

class ChatRecordsSearchPage extends StatefulWidget {
  const ChatRecordsSearchPage({super.key, required this.chatId});

  final int chatId;

  @override
  State<ChatRecordsSearchPage> createState() => _ChatRecordsSearchPageState();
}

class _ChatRecordsSearchPageState extends State<ChatRecordsSearchPage> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  String _query = '';
  _Sub _sub = _Sub.results;
  String? _drillContact;

  // ── 搜索结果 ──────────────────────────
  bool _isLoading = false;
  List<MessageSearchMsg> _chatRecords = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── 查询 ──────────────────────────────
  Future<void> _search(String keyword) async {
    if (keyword.isEmpty || !mounted) return;
    setState(() => _isLoading = true);
    try {
      final result = await context.read<ChatDomain>().searchMessages(
            q: keyword,
            chatId: widget.chatId,
          );
      if (!mounted || _query != keyword) return;
      setState(() {
        _isLoading = false;
        _chatRecords = result.messages;
      });
    } catch (_) {
      if (!mounted || _query != keyword) return;
      setState(() => _isLoading = false);
    }
  }

  void _onChanged(String val) {
    final kw = val.trim();
    setState(() {
      _query = kw;
      _sub = _Sub.results;
      _drillContact = null;
      if (kw.isEmpty) {
        _chatRecords = [];
        _isLoading = false;
      }
    });
    if (kw.isNotEmpty) _search(kw);
  }

  void _clearQuery() {
    _ctrl.clear();
    _onChanged('');
    _focusNode.requestFocus();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SearchInputBar(
              controller: _ctrl,
              focusNode: _focusNode,
              query: _query,
              onChanged: _onChanged,
              onClear: _clearQuery,
              showCancel: true,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_sub) {
      case _Sub.results:
        if (_isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF00C67E),
              strokeWidth: 2,
            ),
          );
        }
        return ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          children: [
            _ChatRecordsSection(
              query: _query,
              items: _chatRecords,
              onOpenMessage: (msgId) => Navigator.of(context).pop(msgId),
            ),
            SizedBox(height: 24.w),
          ],
        );
    }
  }
}

// ─────────────────────────────────────────
//  聊天记录结果列表
// ─────────────────────────────────────────

class _ChatRecordsSection extends StatelessWidget {
  final String query;
  final List<MessageSearchMsg> items;
  final ValueChanged<int>? onOpenMessage;

  const _ChatRecordsSection({
    required this.query,
    required this.items,
    this.onOpenMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...items.map(
          (r) => ChatRecordTile(
            item: r,
            keyword: query,
            onTap: r.msgId > 0 ? () => onOpenMessage?.call(r.msgId) : null,
          ),
        ),
      ],
    );
  }
}