import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/search.dart';
import 'package:g_link/ui_layer/page/message/widgets/recommend_users_widget.dart';
import 'package:g_link/ui_layer/router/routes.dart';
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
  final _scrollController = ScrollController();

  String _query = '';

  // ── 搜索结果 ──────────────────────────
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  List<UserItem> _users = [];
  String? _error;
  String? _nextCursor;
  String? _loadingKeyword;

  bool _showRecommend = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _query.isEmpty) return;
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    final position = _scrollController.position;
    if (position.extentAfter < 220) {
      _loadMore();
    }
  }

  void _onChanged(String val) {
    final kw = val.trim();
    setState(() {
      _query = kw;
      if (kw.isEmpty) {
        _users = [];
        _isLoading = false;
        _isLoadingMore = false;
        _hasMore = false;
        _nextCursor = null;
        _loadingKeyword = null;
        _error = null;
      }
    });
  }

  void _onSubmitted(String val) {
    final kw = val.trim();
    if (kw.isNotEmpty) _search(kw, refresh: true);
  }

  Future<void> _search(String keyword, {bool refresh = false}) async {
    if (keyword.isEmpty || !mounted) return;
    if (_isLoadingMore) return;
    setState(() {
      _isLoading = true;
      _error = null;
      if (refresh) {
        _users = [];
        _nextCursor = null;
        _hasMore = false;
      }
    });
    try {
      final result = await context.read<SearchDomain>().searchUsers(
            q: keyword,
            cursor: null,
            limit: 20,
          );
      if (!mounted || _query != keyword) return;
      setState(() {
        _isLoading = false;
        _loadingKeyword = keyword;
        _users = result.items
            .map((e) => UserItem(
                  uid: e.uid,
                  username: e.username,
                  nickname: e.nickname,
                  avatarUrl: e.avatarUrl,
                  followerCount: e.followerCount,
                ))
            .toList();
        _nextCursor = result.nextCursor;
        _hasMore = result.hasMore;
      });
    } catch (_) {
      if (!mounted || _query != keyword) return;
      setState(() {
        _isLoading = false;
        _error = 'userSearchFailed'.tr();
      });
    }
  }

  Future<void> _loadMore() async {
    final keyword = _loadingKeyword ?? _query;
    if (keyword.isEmpty || _nextCursor == null) return;
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _error = null;
    });

    try {
      final result = await context.read<SearchDomain>().searchUsers(
            q: keyword,
            cursor: _nextCursor,
            limit: 20,
          );
      if (!mounted || _query != keyword) return;
      setState(() {
        _isLoadingMore = false;
        _users = [
          ..._users,
          ...result.items.map((e) => UserItem(
                uid: e.uid,
                username: e.username,
                nickname: e.nickname,
                avatarUrl: e.avatarUrl,
                followerCount: e.followerCount,
              ))
        ];
        _nextCursor = result.nextCursor;
        _hasMore = result.hasMore;
      });
    } catch (_) {
      if (!mounted || _query != keyword) return;
      setState(() {
        _isLoadingMore = false;
        _error = 'userSearchFailed'.tr();
      });
    }
  }

  Future<void> _refresh() async {
    final keyword = _query.trim();
    if (keyword.isEmpty) return;
    await _search(keyword, refresh: true);
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
        title: Text('userSearchTitle'.tr(),
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
                hintText: 'userSearchHint'.tr(),
                controller: _ctrl,
                focusNode: _focusNode,
                query: _query,
                onChanged: _onChanged,
                onSubmitted: _onSubmitted,
                onClear: _clearQuery,
                showCancel: false,
                radius: 10.r),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_query.isEmpty) {
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
    }

    return RefreshIndicator(
      color: const Color(0xFF00C67E),
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _users.length + 1,
        itemBuilder: (_, i) {
          if (_users.isEmpty) {
            return SizedBox(
              height: 420.w,
              child: _buildSearchState(),
            );
          }
          if (i == _users.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.w),
              child: Center(
                child: _isLoadingMore
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          color: Color(0xFF00C67E),
                          strokeWidth: 2,
                        ),
                      )
                    : _hasMore
                        ? Text(
                            'commonPullUpLoadMore'.tr(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF62748E),
                            ),
                          )
                        : const SizedBox.shrink(),
              ),
            );
          }
          return _UserTile(user: _users[i], keyword: _query);
        },
      ),
    );
  }

  Widget _buildSearchState() {
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
        child: Text(
          _error!,
          style: TextStyle(fontSize: 14.sp, color: const Color(0xFF62748E)),
        ),
      );
    }
    return Center(
      child: Text(
        'commonNoResults'.tr(),
        style: TextStyle(fontSize: 14.sp, color: const Color(0xFF62748E)),
      ),
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
                    border: Border.all(color: const Color(0xFFCCCCCC)),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.isFollowing
                        ? 'commonFollowed'.tr()
                        : 'commonFollow'.tr(),
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF1A1F2C),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 7.w),
              GestureDetector(
                onTap: () => ChatConversationRoute(
                  name: user.nickname,
                  avatarUrl: user.avatarUrl,
                  uid: user.uid,
                ).push(context),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2C),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  alignment: Alignment.center,
                  child: Text('commonSendMessage'.tr(),
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
                'commonFollowerCount'.tr(namedArgs: {
                  'count': CommonUtils.renderEnFixedNumber(user.followerCount)
                }),
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
