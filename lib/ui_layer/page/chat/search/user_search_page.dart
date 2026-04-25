import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/search.dart';
import 'package:g_link/domain/model/search_models.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/page/chat/widgets/recommend_users_widget.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:provider/provider.dart';
import 'models/search_models.dart';

// ─────────────────────────────────────────
//  用户搜索页
//  入口：消息列表页顶部菜单"搜索用户"
// ─────────────────────────────────────────

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  String _query = '';

  // ── 搜索结果 ──────────────────────────
  bool _isLoading = false;
  List<UserItem> _users = [];
  String? _error;

  bool _showRecommend = true;

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

  void _onChanged(String val) {
    final kw = val.trim();
    setState(() {
      _query = kw;
      if (kw.isEmpty) {
        _users = [];
        _isLoading = false;
        _error = null;
      }
    });
  }

  void _onSubmitted(String val) {
    final kw = val.trim();
    if (kw.isNotEmpty) _search(kw);
  }

  Future<void> _search(String keyword) async {
    if (keyword.isEmpty || !mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result =
          await context.read<SearchDomain>().searchUsers(q: keyword, limit: 20);
      if (!mounted || _query != keyword) return;
      setState(() {
        _isLoading = false;
        _users = result.items
            .map((e) => UserItem(
                  uid: e.uid,
                  username: e.username,
                  nickname: e.nickname,
                  avatarUrl: e.avatarUrl,
                  followerCount: e.followerCount,
                ))
            .toList();
      });
    } catch (_) {
      if (!mounted || _query != keyword) return;
      setState(() {
        _isLoading = false;
        _error = '搜索失败，请稍后重试';
      });
    }
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(Icons.arrow_back_ios,
              size: 20.sp, color: const Color(0xFF0F172B)),
        ),
        title: Text('搜索用户',
            style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172B))),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SearchInputBar(
              hintText: '搜索用户名或昵称',
              controller: _ctrl,
              focusNode: _focusNode,
              query: _query,
              onChanged: _onChanged,
              onSubmitted: _onSubmitted,
              onClear: _clearQuery,
              showCancel: false,
            ),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_query.isEmpty)
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            SizedBox(height: 300.w),
            if (_showRecommend)
              RecommendUsersWidget(
                onClose: () {
                  setState(() {
                    _showRecommend = false;
                  });
                },
              )
          ],
        ),
      );
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00C67E),
          strokeWidth: 2,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(_error!,
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF62748E))),
      );
    }
    if (_users.isEmpty) {
      return Center(
        child: Text('暂无结果',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF62748E))),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _users.length,
      itemBuilder: (_, i) => _UserTile(user: _users[i], keyword: _query),
    );
  }
}

class _UserTile extends StatefulWidget {
  final UserItem user;
  final String keyword;

  const _UserTile({required this.user, required this.keyword});

  @override
  State<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<_UserTile> {
  void _toggleFollow() {
    setState(() => widget.user.isFollowing = !widget.user.isFollowing);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Container(
      margin: EdgeInsets.only(bottom: 10.w),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF8F9FE)))),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(user),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172B)),
                    ),
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                          fontSize: 12.sp, color: const Color(0xFF62748E)),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: _toggleFollow,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
                  decoration: BoxDecoration(
                    color: user.isFollowing ? const Color(0xFF1A1F2C) : null,
                    border: user.isFollowing
                        ? null
                        : Border.all(color: const Color(0xFFCCCCCC)),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.isFollowing ? '已关注' : '关注',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: user.isFollowing
                          ? Colors.white
                          : const Color(0xFF1A1F2C),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 7.w),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2C),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  alignment: Alignment.center,
                  child: Text('发消息',
                      style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.w),
          Row(
            children: [
              SizedBox(width: 40.w),
              SizedBox(width: 12.w),
              Text(
                '${CommonUtils.renderEnFixedNumber(user.followerCount)}粉丝',
                style:
                    TextStyle(fontSize: 12.sp, color: const Color(0xFF62748E)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserItem user) {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40.r),
        color: const Color(0xFFD1D1D6),
      ),
      child: user.avatarUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(40.r),
              child: Image.network(
                user.avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.person, size: 28.sp, color: Colors.white),
              ),
            )
          : Icon(Icons.person, size: 28.sp, color: Colors.white),
    );
  }
}
