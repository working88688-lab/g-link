import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domain.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:provider/provider.dart';
import '../../../router/routes.dart';
import 'models/search_models.dart';
import 'widgets/chat_record_tile.dart';

// ─────────────────────────────────────────
//  全局搜索页（联系人 + 聊天记录 + 用户）
//  入口：消息列表页搜索栏
// ─────────────────────────────────────────

enum _Sub { initial, results, chatDetail }

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  String _query = '';
  _Sub _sub = _Sub.initial;
  String? _drillContact;

  // ── 搜索结果 ──────────────────────────
  bool _isLoading = false;
  List<ContactItem> _contacts = [];
  List<ChatRecordItem> _chatRecords = [];

  // ── 历史记录 ──────────────────────────
  static const _maxHistory = 20;
  final List<String> _history = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _loadHistory();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final list = await context.read<AppDomain>().cache.readSearchHistory();
    if (!mounted) return;
    setState(() {
      _history
        ..clear()
        ..addAll(list);
    });
  }

  void _addHistory(String kw) {
    if (kw.isEmpty) return;
    final list = [kw, ..._history.where((e) => e != kw)].take(_maxHistory).toList();
    setState(() {
      _history
        ..clear()
        ..addAll(list);
    });
    context.read<AppDomain>().cache.upsertSearchHistory(searchHistory: list);
  }

  void _removeHistory(String tag) {
    setState(() => _history.remove(tag));
    context.read<AppDomain>().cache.upsertSearchHistory(searchHistory: List.of(_history));
  }

  void _clearHistory() {
    setState(() => _history.clear());
    context.read<AppDomain>().cache.clearSearchHistory();
  }

  // ── 查询 ──────────────────────────────
  Future<void> _search(String keyword) async {
    if (keyword.isEmpty || !mounted) return;
    setState(() => _isLoading = true);
    try {
      final result = await context.read<AppDomain>().searchMessages(q: keyword, limit: 10);
      if (!mounted || _query != keyword) return;
      setState(() {
        _isLoading = false;
        _contacts = result.contacts.map((c) => ContactItem(c.nickname, uid: c.uid, avatarUrl: c.avatarUrl)).toList();
        _chatRecords = result.messages
            .map((m) => ChatRecordItem(
                  msgId: m.msgId,
                  chatId: m.chatId,
                  name: '',
                  preview: m.content,
                  createdAt: m.createdAt,
                  senderUid: m.senderUid,
                ))
            .toList();
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
      _sub = kw.isEmpty ? _Sub.initial : _sub;
      _drillContact = null;
      if (kw.isEmpty) {
        _contacts = [];
        _chatRecords = [];
        _isLoading = false;
        _sub = _Sub.initial;
      }
    });
  }

  void _onSubmitted(String val) {
    final kw = val.trim();
    if (kw.isEmpty) return;
    _addHistory(kw);
    setState(() => _sub = _Sub.results);
    _search(kw);
  }

  void _clearQuery() {
    _ctrl.clear();
    _onChanged('');
    _focusNode.requestFocus();
  }

  void _enterChatDetail(String contact) {
    setState(() {
      _sub = _Sub.chatDetail;
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
              onSubmitted: _onSubmitted,
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
      case _Sub.initial:
        return _HistoryView(
          history: _history,
          onTapTag: (tag) {
            _ctrl.text = tag;
            _addHistory(tag);
            _onChanged(tag);
            _onSubmitted(tag);
          },
          onRemove: _removeHistory,
          onClear: _clearHistory,
        );
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
            _ContactsSection(query: _query, items: _contacts),
            _ChatRecordsSection(query: _query, items: _chatRecords, onEnterContact: _enterChatDetail),
            SizedBox(height: 24.w),
          ],
        );
      case _Sub.chatDetail:
        return _ChatDetailSection(
          contactName: _drillContact ?? '',
          query: _query,
          onBack: _backToResults,
        );
    }
  }
}

// ─────────────────────────────────────────
//  历史记录视图
// ─────────────────────────────────────────

class _HistoryView extends StatelessWidget {
  final List<String> history;
  final ValueChanged<String> onTapTag;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  const _HistoryView({
    required this.history,
    required this.onTapTag,
    required this.onRemove,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 14.w),
          Row(
            children: [
              Text('searchHistoryTitle'.tr(),
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: const Color(0xFF0F172B))),
              const Spacer(),
              GestureDetector(
                onTap: onClear,
                child: Text('searchHistoryClear'.tr(),
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500, color: const Color(0xFF62748E))),
              ),
            ],
          ),
          SizedBox(height: 12.w),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.w,
            children: history
                .map((tag) => _HistoryChip(
                      label: tag,
                      onTap: () => onTapTag(tag),
                      onRemove: () => onRemove(tag),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _HistoryChip({required this.label, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 5.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FE),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 200.w),
              child: Text(label,
                  style: TextStyle(height: 0, fontSize: 12.sp, color: const Color(0xFF1A1F2C)),
                  overflow: TextOverflow.ellipsis),
            ),
            SizedBox(width: 4.w),
            GestureDetector(
              onTap: onRemove,
              child: MyImage.asset(MyImagePaths.iconInputClear, width: 13.w),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  联系人结果
// ─────────────────────────────────────────

class _ContactsSection extends StatelessWidget {
  final String query;
  final List<ContactItem> items;

  const _ContactsSection({required this.query, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchSectionHeader(title: 'searchSectionContacts'.tr()),
        ...items.map((c) => _ContactTile(
              user: c,
              keyword: query,
            )),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  final String keyword;
  final ContactItem user;

  const _ContactTile({required this.keyword, required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ChatConversationRoute(
          name: user.name,
          avatarUrl: user.avatarUrl,
          uid: user.uid,
        ).push(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.w),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: const Color(0xFF1A1F2C).withOpacity(0.05)))),
        child: Row(
          children: [
            searchAvatar(avatarUrl: user.avatarUrl),
            SizedBox(width: 8.w),
            highlight(user.name, keyword,
                base: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: const Color(0xFF1A1F2C)),
                hl: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF00C67E))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  聊天记录结果
// ─────────────────────────────────────────

class _ChatRecordsSection extends StatelessWidget {
  final String query;
  final List<ChatRecordItem> items;
  final ValueChanged<String>? onEnterContact;

  const _ChatRecordsSection({required this.query, required this.items, this.onEnterContact});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchSectionHeader(title: 'searchSectionChatRecords'.tr()),
        ...items.map((r) => ChatRecordTile(
              item: r,
              keyword: query,
              onTap: r.extraCount != null ? () => onEnterContact?.call(r.name) : null,
            )),
      ],
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

  const _ChatDetailSection({required this.contactName, required this.query, this.onBack});

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
        ..._records.map((r) => ChatRecordDetailTile(item: r, keyword: widget.query)),
        SizedBox(height: 24.w),
      ],
    );
  }
}
