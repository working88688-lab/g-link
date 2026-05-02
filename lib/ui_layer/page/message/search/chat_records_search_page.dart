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

enum _Sub { results, detail }

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
  List<ChatRecordItem> _chatRecords = [];

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
        _chatRecords = [
          ...result.messages.map(
            (m) => ChatRecordItem(
              name: result.contacts.isNotEmpty ? result.contacts.first.nickname : 'chat',
              preview: m.content,
            ),
          ),
        ];
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

  void _enterDetail(String contact) {
    setState(() {
      _sub = _Sub.detail;
      _drillContact = contact;
    });
  }

  void _backToResults() {
    setState(() {
      _sub = _Sub.results;
      _drillContact = null;
    });
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
                onEnterContact: _enterDetail),
            SizedBox(height: 24.w),
          ],
        );
      case _Sub.detail:
        return _ChatDetailSection(
          contactName: _drillContact ?? '',
          query: _query,
          onBack: _backToResults,
        );
    }
  }
}

// ─────────────────────────────────────────
//  聊天记录结果列表
// ─────────────────────────────────────────

class _ChatRecordsSection extends StatelessWidget {
  final String query;
  final List<ChatRecordItem> items;
  final ValueChanged<String>? onEnterContact;

  const _ChatRecordsSection(
      {required this.query, required this.items, this.onEnterContact});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...items.map((r) => ChatRecordTile(
              item: r,
              keyword: query,
              onTap: r.extraCount != null
                  ? () => onEnterContact?.call(r.name)
                  : null,
            )),
      ],
    );
  }
}

class _ChatRecordTile extends StatelessWidget {
  final ChatRecordItem item;
  final String keyword;
  final VoidCallback? onTap;

  const _ChatRecordTile(
      {required this.item, required this.keyword, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.w),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF8F9FE)))),
        child: Row(
          children: [
            searchAvatar(),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  highlight(item.name, keyword,
                      base: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172B)),
                      hl: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00C67E))),
                  SizedBox(height: 2.w),
                  item.extraCount != null
                      ? Text('${item.extraCount}条相关聊天记录',
                          style: TextStyle(
                              fontSize: 12.sp, color: const Color(0xFF62748E)))
                      : highlight(item.preview, keyword,
                          base: TextStyle(
                              fontSize: 12.sp, color: const Color(0xFF62748E)),
                          hl: TextStyle(
                              fontSize: 12.sp, color: const Color(0xFF00C67E))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  聊天记录钻取详情
// ─────────────────────────────────────────

class _ChatDetailSection extends StatefulWidget {
  final String contactName;
  final String query;
  final VoidCallback? onBack;

  const _ChatDetailSection(
      {required this.contactName, required this.query, this.onBack});

  @override
  State<_ChatDetailSection> createState() => _ChatDetailSectionState();
}

class _ChatDetailSectionState extends State<_ChatDetailSection> {
  bool _isLoading = true;
  List<ChatRecordItem> _records = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // TODO: 替换为真实 API 调用
  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _records = [
        const ChatRecordItem(name: '2025-03-01', preview: '太优秀了吧'),
        const ChatRecordItem(name: '2025-02-18', preview: '优秀到无可救药'),
        const ChatRecordItem(name: '2024-12-25', preview: '真的太优秀了'),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
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
        SizedBox(height: 8.w),
        ..._records
            .map((r) => ChatRecordDetailTile(item: r, keyword: widget.query)),
        SizedBox(height: 24.w),
      ],
    );
  }
}
