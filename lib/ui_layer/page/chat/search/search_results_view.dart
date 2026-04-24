import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'search_models.dart';
import 'search_page.dart';

// ─────────────────────────────────────────
//  SubView 2：搜索结果（联系人 / 聊天记录 / 用户）
// ─────────────────────────────────────────

class SearchResultsView extends StatelessWidget {
  final String query;
  final SearchMode mode;
  final ValueChanged<String> onEnterChatRecords;

  const SearchResultsView({
    super.key,
    required this.query,
    this.mode = SearchMode.all,
    required this.onEnterChatRecords,
  });

  bool get _showContacts =>
      mode == SearchMode.all || mode == SearchMode.contactsAndRecords;
  bool get _showChatRecords =>
      mode == SearchMode.all ||
      mode == SearchMode.contactsAndRecords ||
      mode == SearchMode.chatRecords;
  bool get _showUsers => mode == SearchMode.all || mode == SearchMode.users;

  // ── 模拟数据（实际替换为真实搜索结果） ──
  List<ContactItem> get _contacts => [
        const ContactItem('优秀大帅哥'),
        const ContactItem('优秀大帅哥'),
        const ContactItem('优秀大帅哥'),
      ];

  List<ChatRecordItem> get _chatRecords => [
        const ChatRecordItem(name: '优秀大帅哥', preview: '太优秀了吧', extraCount: 5),
        const ChatRecordItem(name: '优秀大帅哥', preview: '太优秀了吧'),
        const ChatRecordItem(name: '优秀大帅哥', preview: '太优秀了吧'),
      ];

  List<UserItem> get _users => [
        const UserItem(name: '优秀用户', followers: '5.4w粉丝'),
        const UserItem(name: '优秀达人', followers: '12w粉丝'),
      ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      children: [
        // 联系人
        if (_showContacts && _contacts.isNotEmpty) ...[
          SearchSectionHeader(title: '联系人'),
          ..._contacts.map(
            (c) => _ContactTile(name: c.name, keyword: query),
          ),
        ],
        // 聊天记录
        if (_showChatRecords && _chatRecords.isNotEmpty) ...[
          SearchSectionHeader(title: '聊天记录'),
          ..._chatRecords.map(
            (r) => _ChatRecordTile(
              item: r,
              keyword: query,
              onTap: r.extraCount != null
                  ? () => onEnterChatRecords(r.name)
                  : null,
            ),
          ),
        ],
        // 用户
        if (_showUsers && _users.isNotEmpty) ...[
          SearchSectionHeader(title: '用户'),
          ..._users.map(
            (u) => _UserTile(
              name: u.name,
              followers: u.followers,
              keyword: query,
            ),
          ),
        ],
        SizedBox(height: 24.w),
      ],
    );
  }
}

// ── 联系人行 ─────────────────────────────

class _ContactTile extends StatelessWidget {
  final String name;
  final String keyword;
  const _ContactTile({required this.name, required this.keyword});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.w),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF8F9FE))),
      ),
      child: Row(
        children: [
          searchAvatar(radius: 40),
          SizedBox(width: 12.w),
          highlight(
            name,
            keyword,
            base: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0F172B),
            ),
            hl: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF00C67E),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 聊天记录行 ───────────────────────────

class _ChatRecordTile extends StatelessWidget {
  final ChatRecordItem item;
  final String keyword;
  final VoidCallback? onTap;
  const _ChatRecordTile({
    required this.item,
    required this.keyword,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.w),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF8F9FE))),
        ),
        child: Row(
          children: [
            searchAvatar(),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  highlight(
                    item.name,
                    keyword,
                    base: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172B),
                    ),
                    hl: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF00C67E),
                    ),
                  ),
                  SizedBox(height: 2.w),
                  item.extraCount != null
                      ? Text(
                          '${item.extraCount}条相关聊天记录',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF62748E),
                          ),
                        )
                      : highlight(
                          item.preview,
                          keyword,
                          base: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF62748E),
                          ),
                          hl: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF00C67E),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 用户行 ───────────────────────────────

class _UserTile extends StatelessWidget {
  final String name;
  final String followers;
  final String keyword;
  const _UserTile({
    required this.name,
    required this.followers,
    required this.keyword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.w),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF8F9FE))),
      ),
      child: Row(
        children: [
          searchAvatar(radius: 40),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                highlight(
                  name,
                  keyword,
                  base: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172B),
                  ),
                  hl: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00C67E),
                  ),
                ),
                SizedBox(height: 2.w),
                Text(
                  followers,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF62748E),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            height: 30.w,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172B),
              borderRadius: BorderRadius.circular(100.r),
            ),
            alignment: Alignment.center,
            child: Text(
              '关注',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
