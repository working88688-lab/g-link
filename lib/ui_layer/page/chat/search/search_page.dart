import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import './search_subviews.dart';

// ─────────────────────────────────────────
//  SearchMode：控制搜索页展示哪些分区
// ─────────────────────────────────────────

enum SearchMode {
  all, // 全部（联系人 + 聊天记录 + 用户）
  contactsAndRecords, // 联系人 + 聊天记录
  users, // 仅用户搜索
  chatRecords, // 仅聊天记录
}

// ─────────────────────────────────────────
//  ChatSearchPage
// ─────────────────────────────────────────

enum _Sub { initial, results, chatRecords }

class ChatSearchPage extends StatefulWidget {
  final SearchMode mode;

  const ChatSearchPage({super.key, this.mode = SearchMode.all});

  @override
  State<ChatSearchPage> createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends State<ChatSearchPage> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  late _Sub _sub;
  String? _drillContact;

  final List<String> _history = [
    '超级无敌帅哥',
    '体育生',
    '耍酷',
    '杭州西湖打卡超美的风景无敌',
    '帅哥',
  ];

  @override
  void initState() {
    super.initState();
    // 只有 消息/联系人 模式才有初始（历史记录）页
    _sub = widget.mode == SearchMode.contactsAndRecords ? _Sub.initial : _Sub.results;
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

  void _onQueryChanged(String val) {
    setState(() {
      _query = val.trim();
      if (_query.isEmpty && widget.mode == SearchMode.contactsAndRecords) {
        _sub = _Sub.initial;
      } else {
        _sub = _Sub.results;
      }
      _drillContact = null;
    });
  }

  void _clearQuery() {
    _ctrl.clear();
    _onQueryChanged('');
    _focusNode.requestFocus();
  }

  void _clearHistory() => setState(() => _history.clear());

  void _removeHistory(String tag) => setState(() => _history.remove(tag));

  void _enterChatRecords(String contactName) {
    setState(() {
      _sub = _Sub.chatRecords;
      _drillContact = contactName;
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
      appBar: widget.mode == SearchMode.users
          ? AppBar(
              backgroundColor: Colors.white,
              title: Text("搜索用户",
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1D293D))),
              centerTitle: true,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.w),
      child: Row(
        children: [
          Expanded(
            child: _buildSearch(),
          ),
          if (widget.mode != SearchMode.users) ...[
            SizedBox(width: 11.w),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                '取消',
                style: TextStyle(
                  fontSize: 15.sp,
                  color: const Color(0xFF0F172B),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      height: 40.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: TextField(
        controller: _ctrl,
        focusNode: _focusNode,
        onChanged: _onQueryChanged,
        style: TextStyle(
          fontSize: 14.sp,
          color: const Color(0xFF0F172B),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 9.w, horizontal: 8.w),
          prefixIcon: Stack(
            alignment: Alignment.center,
            children: [Image.asset("./assets/images/icon_search.png", width: 22.w, height: 22.w)],
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 40.w),
          hintText: '搜索',
          hintStyle: TextStyle(
            fontSize: 13.sp,
            color: const Color(0xFF90A1B9),
          ),
          suffixIcon: _query.isNotEmpty
              ? GestureDetector(
                  onTap: _clearQuery,
                  child: Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: Image.asset("./assets/images/icon_input_clear.png", width: 24.w, height: 24.w),
                  ),
                )
              : null,
          suffixIconConstraints: BoxConstraints(minWidth: 36.w),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_sub) {
      case _Sub.initial:
        return SearchInitialView(
          history: _history,
          onClear: _clearHistory,
          onRemove: _removeHistory,
          onTapTag: (tag) {
            _ctrl.text = tag;
            _onQueryChanged(tag);
          },
        );
      case _Sub.results:
        return SearchResultsView(
          query: _query,
          mode: widget.mode,
          onEnterChatRecords: _enterChatRecords,
        );
      case _Sub.chatRecords:
        return ChatRecordsSubView(
          contactName: _drillContact ?? '',
          query: _query,
          onBack: _backToResults,
        );
    }
  }
}
