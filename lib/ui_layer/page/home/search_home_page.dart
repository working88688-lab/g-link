import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/domains/search.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/domain/model/search_models.dart';
import 'package:g_link/ui_layer/event/event_bus.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:g_link/utils/my_toast.dart';
import 'package:provider/provider.dart';

/// 综合搜索：落地（历史/热搜/推荐）+ 结果（账户 / 帖子 / 短视频 / 音乐）。
///
/// - `/api/v1/search?tab=user|post|video`
/// - `/api/v1/bgms/search`（音乐）
class SearchHomePage extends StatefulWidget {
  const SearchHomePage({super.key});

  @override
  State<SearchHomePage> createState() => _SearchHomePageState();
}

class _SearchHomePageState extends State<SearchHomePage>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final TabController _tabController;

  bool _landingLoading = true;
  List<String> _history = const [];
  List<SearchHotItem> _hot = const [];
  List<RecommendedUser> _users = const [];
  final Map<int, bool> _followOverride = <int, bool>{};
  final Set<int> _followInflight = <int>{};

  /// 已提交给接口的关键词（>=2 字才进入结果区）。
  String _committedQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _controller.addListener(() => setState(() {}));
    _loadLanding();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadLanding() async {
    setState(() => _landingLoading = true);
    final searchDomain = context.read<SearchDomain>();
    try {
      final home = await searchDomain.getSearchHome();
      if (!mounted) return;
      final users = home.recommendUsers.take(6).toList();
      for (final u in users) {
        _followOverride[u.uid] = u.isFollowing;
      }
      setState(() {
        _history = home.history;
        _hot = home.hot;
        _users = users;
      });
    } catch (_) {
      if (mounted) {
        MyToast.showText(text: 'commonRetry'.tr());
      }
    } finally {
      if (mounted) setState(() => _landingLoading = false);
    }
  }

  bool _isFollowingReco(RecommendedUser user) =>
      _followOverride[user.uid] ?? user.isFollowing;

  Future<void> _toggleFollowReco(RecommendedUser user) async {
    if (_followInflight.contains(user.uid)) return;
    final before = _isFollowingReco(user);
    _followInflight.add(user.uid);
    setState(() => _followOverride[user.uid] = !before);
    final profileDomain = context.read<ProfileDomain>();
    final result = before
        ? await profileDomain.unfollowUser(uid: user.uid)
        : await profileDomain.followUser(uid: user.uid);
    _followInflight.remove(user.uid);
    if (!mounted) return;
    if (result.status != 0 || result.data == null) {
      setState(() => _followOverride[user.uid] = before);
      MyToast.showText(text: result.msg ?? 'commonRetry'.tr());
      return;
    }
    setState(() => _followOverride[user.uid] = result.data!.isFollowing);
    eventBus.fire(
      FollowStatusChangedEvent(
        uid: user.uid,
        isFollowing: result.data!.isFollowing,
      ),
    );
  }

  void _commitSearch(String raw) {
    final q = raw.trim();
    if (q.length < 2) {
      MyToast.showText(text: 'searchMinChars'.tr());
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _committedQuery = q);
  }

  void _onCancel() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchRow(),
            if (_committedQuery.length >= 2) ...[
              _buildSearchTabs(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _SearchAccountsTab(
                      key: const ValueKey('tab-accounts'),
                      query: _committedQuery,
                    ),
                    _SearchPostsTab(
                      key: const ValueKey('tab-posts'),
                      query: _committedQuery,
                    ),
                    _SearchVideosTab(
                      key: const ValueKey('tab-videos'),
                      query: _committedQuery,
                    ),
                    _SearchMusicTab(
                      key: const ValueKey('tab-music'),
                      query: _committedQuery,
                    ),
                  ],
                ),
              ),
            ] else
              Expanded(child: _buildLanding()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchRow() {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 6.w, 12.w, 6.w),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42.w,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F5),
                borderRadius: BorderRadius.circular(36.r),
              ),
              child: Row(
                children: [
                  Image.asset(
                    MyImagePaths.search,
                    color: const Color(0xFF8C95A8),
                    width: 20.w,
                    height: 20.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _commitSearch,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'commonSearchHint'.tr(),
                        hintStyle: TextStyle(
                          color: const Color(0xFF9DA8BC),
                          fontSize: 15.sp,
                        ),
                      ),
                      style: TextStyle(
                        color: const Color(0xFF1A1F2C),
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        setState(() {});
                      },
                      child: Icon(Icons.cancel,
                          size: 18.sp, color: const Color(0xFFB8C0CC)),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: _onCancel,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'commonCancel'.tr(),
                style: TextStyle(
                  color: const Color(0xFF1A1F2C),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTabs() {
    return Container(
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8ECF3), width: 0.6),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent, // 水波纹颜色
          highlightColor: Colors.transparent, // 点击高亮
          splashFactory: NoSplash.splashFactory, // 完全禁用水波纹
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          padding: EdgeInsets.only(left: 8.w),
          labelPadding: EdgeInsets.symmetric(horizontal: 14.w),
          indicatorSize: TabBarIndicatorSize.label,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 3.h, color: const Color(0xFF1A1F2C)),
          ),
          labelColor: const Color(0xFF1A1F2C),
          unselectedLabelColor: const Color(0xFF8C95A8),
          labelStyle: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: 'searchTabAccounts'.tr()),
            Tab(text: 'searchTabPosts'.tr()),
            Tab(text: 'searchTabVideos'.tr()),
            Tab(text: 'searchTabMusic'.tr()),
          ],
        ),
      ),
    );
  }

  Widget _buildLanding() {
    if (_landingLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHistory(),
          SizedBox(height: 18.h),
          _buildHotSearch(),
          SizedBox(height: 18.h),
          _buildRecommendUsers(),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'searchHistoryTitle'.tr(),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1F2C),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _history = const []),
              child: Text(
                'searchHistoryClear'.tr(),
                style: TextStyle(
                  color: const Color(0xFF93A0B8),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _history.map((kw) {
            return GestureDetector(
              onTap: () {
                _controller.text = kw;
                _commitSearch(kw);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF1F6),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  kw,
                  style: TextStyle(
                    color: const Color(0xFF222B3C),
                    fontSize: 13.sp,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHotSearch() {
    if (_hot.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'searchHotTitle'.tr(),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1F2C),
          ),
        ),
        SizedBox(height: 10.h),
        ..._hot.take(10).map((item) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: GestureDetector(
                onTap: () {
                  _controller.text = item.keyword;
                  _commitSearch(item.keyword);
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    _rankBadge(item.rank),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        item.keyword,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF1B2436),
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      CommonUtils.renderEnFixedNumber(item.score).toString(),
                      style: TextStyle(
                        color: const Color(0xFF8FA0B8),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _rankBadge(int rank) {
    final color = switch (rank) {
      1 => const Color(0xFFF14A45),
      2 => const Color(0xFFF58A3A),
      3 => const Color(0xFFF2B228),
      _ => const Color(0xFFD4DBE7),
    };
    return Container(
      width: 20.w,
      height: 20.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildRecommendUsers() {
    if (_users.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'homeRecommendFollow'.tr(),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1F2C),
          ),
        ),
        SizedBox(height: 12.h),
        ..._users.map((user) {
          final following = _isFollowingReco(user);
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                ClipOval(
                  child: user.avatarUrl.isNotEmpty
                      ? MyImage.network(
                          user.avatarUrl,
                          width: 42.w,
                          height: 42.w,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          MyImagePaths.defaultHeader,
                          width: 42.w,
                          height: 42.w,
                          fit: BoxFit.cover,
                        ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nickname.isNotEmpty
                            ? user.nickname
                            : user.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF1A1F2C),
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'commonFollowerCount'.tr(namedArgs: {
                          'count': CommonUtils.renderEnFixedNumber(
                              user.followerCount),
                        }),
                        style: TextStyle(
                          color: const Color(0xFF8D96A8),
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleFollowReco(user),
                  child: Container(
                    width: 72.w,
                    height: 32.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: following
                          ? Colors.transparent
                          : const Color(0xFF1A1F2C),
                      border: following
                          ? Border.all(color: const Color(0xFFD3D7E0))
                          : null,
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      following ? 'commonFollowed'.tr() : 'commonFollow'.tr(),
                      style: TextStyle(
                        color:
                            following ? const Color(0xFF5F6778) : Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tab: accounts
// ─────────────────────────────────────────────────────────────────────────

class _SearchAccountsTab extends StatefulWidget {
  const _SearchAccountsTab({super.key, required this.query});

  final String query;

  @override
  State<_SearchAccountsTab> createState() => _SearchAccountsTabState();
}

class _SearchAccountsTabState extends State<_SearchAccountsTab>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();
  final List<UserSearchItem> _items = [];
  String? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  bool _boot = false;
  final Map<int, bool> _follow = {};
  final Set<int> _inflight = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.query.length >= 2) {
        _loadFirst();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _SearchAccountsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients || _loading || !_hasMore) return;
    final pos = _scroll.position;
    if (pos.pixels + 360 >= pos.maxScrollExtent) {
      _loadMore();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _cursor = null;
      _hasMore = true;
      _boot = false;
      _follow.clear();
    });
    await _loadFirst();
  }

  Future<void> _loadFirst() async {
    if (_loading) return;
    setState(() => _loading = true);
    final r = await context.read<SearchDomain>().searchUsers(
          q: widget.query,
          cursor: null,
        );
    if (!mounted) return;
    _applyUserResult(r);
    setState(() {
      _loading = false;
      _boot = true;
    });
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore || _cursor == null || _cursor!.isEmpty) return;
    setState(() => _loading = true);
    final r = await context.read<SearchDomain>().searchUsers(
          q: widget.query,
          cursor: _cursor,
        );
    if (!mounted) return;
    _appendUserResult(r);
    setState(() => _loading = false);
  }

  void _applyUserResult(UserSearchResult r) {
    for (final u in r.items) {
      _follow[u.uid] = u.isFollowing;
    }
    _items
      ..clear()
      ..addAll(r.items);
    _cursor = r.nextCursor;
    _hasMore = r.hasMore && (r.nextCursor != null && r.nextCursor!.isNotEmpty);
  }

  void _appendUserResult(UserSearchResult r) {
    for (final u in r.items) {
      _follow.putIfAbsent(u.uid, () => u.isFollowing);
    }
    _items.addAll(r.items);
    _cursor = r.nextCursor;
    _hasMore = r.hasMore && (r.nextCursor != null && r.nextCursor!.isNotEmpty);
  }

  bool _isFollowing(UserSearchItem u) => _follow[u.uid] ?? u.isFollowing;

  Future<void> _toggle(UserSearchItem u) async {
    if (_inflight.contains(u.uid)) return;
    final before = _isFollowing(u);
    _inflight.add(u.uid);
    setState(() => _follow[u.uid] = !before);
    final profile = context.read<ProfileDomain>();
    final result = before
        ? await profile.unfollowUser(uid: u.uid)
        : await profile.followUser(uid: u.uid);
    _inflight.remove(u.uid);
    if (!mounted) return;
    if (result.status != 0 || result.data == null) {
      setState(() => _follow[u.uid] = before);
      MyToast.showText(text: result.msg ?? 'commonRetry'.tr());
      return;
    }
    setState(() => _follow[u.uid] = result.data!.isFollowing);
    eventBus.fire(
      FollowStatusChangedEvent(
        uid: u.uid,
        isFollowing: result.data!.isFollowing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_boot && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _boot) {
      return Center(
        child: Text(
          'commonNoResults'.tr(),
          style: TextStyle(color: const Color(0xFF62748E), fontSize: 14.sp),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final u = _items[index];
          final followed = _isFollowing(u);
          return Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipOval(
                  child: u.avatarUrl.isNotEmpty
                      ? MyImage.network(
                          u.avatarUrl,
                          width: 48.w,
                          height: 48.w,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          MyImagePaths.defaultHeader,
                          width: 48.w,
                          height: 48.w,
                          fit: BoxFit.cover,
                        ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.nickname.isNotEmpty ? u.nickname : u.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1F2C),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '@${u.username} ${CommonUtils.renderEnFixedNumber(u.followerCount)}${'searchFollowersSuffix'.tr()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF8C95A8),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggle(u),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
                    decoration: BoxDecoration(
                      color: followed
                          ? Colors.transparent
                          : const Color(0xFF1A1F2C),
                      border: followed
                          ? Border.all(color: const Color(0xFFCCCCCC))
                          : null,
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      followed ? 'commonFollowed'.tr() : 'commonFollow'.tr(),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color:
                            followed ? const Color(0xFF5F6778) : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tab: posts (two-column)
// ─────────────────────────────────────────────────────────────────────────

class _SearchPostsTab extends StatefulWidget {
  const _SearchPostsTab({super.key, required this.query});

  final String query;

  @override
  State<_SearchPostsTab> createState() => _SearchPostsTabState();
}

class _SearchPostsTabState extends State<_SearchPostsTab>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();
  final List<PostSearchItem> _items = [];
  String? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  bool _boot = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.query.length >= 2) {
        _loadFirst();
      }
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SearchPostsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _refresh();
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients || _loading || !_hasMore) return;
    final pos = _scroll.position;
    if (pos.pixels + 500 >= pos.maxScrollExtent) _loadMore();
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _cursor = null;
      _hasMore = true;
      _boot = false;
    });
    await _loadFirst();
  }

  Future<void> _loadFirst() async {
    if (_loading) return;
    setState(() => _loading = true);
    final r = await context.read<SearchDomain>().searchPosts(
          q: widget.query,
          cursor: null,
        );
    if (!mounted) return;
    _items
      ..clear()
      ..addAll(r.items);
    _cursor = r.nextCursor;
    _hasMore = r.hasMore && (r.nextCursor != null && r.nextCursor!.isNotEmpty);
    setState(() {
      _loading = false;
      _boot = true;
    });
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore || _cursor == null || _cursor!.isEmpty) return;
    setState(() => _loading = true);
    final r = await context.read<SearchDomain>().searchPosts(
          q: widget.query,
          cursor: _cursor,
        );
    if (!mounted) return;
    _items.addAll(r.items);
    _cursor = r.nextCursor;
    _hasMore = r.hasMore && (r.nextCursor != null && r.nextCursor!.isNotEmpty);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_boot && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _boot) {
      return Center(
          child: Text('commonNoResults'.tr(),
              style:
                  TextStyle(color: const Color(0xFF62748E), fontSize: 14.sp)));
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        itemCount: (_items.length + 1) ~/ 2,
        itemBuilder: (context, row) {
          final i0 = row * 2;
          final i1 = i0 + 1;
          final left = _items[i0];
          final right = i1 < _items.length ? _items[i1] : null;
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _PostSearchCard(item: left)),
                SizedBox(width: 8.w),
                Expanded(
                  child: right != null
                      ? _PostSearchCard(item: right)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PostSearchCard extends StatelessWidget {
  const _PostSearchCard({required this.item});

  final PostSearchItem item;

  String _displayName() {
    if (item.authorNickname.isNotEmpty) return item.authorNickname;
    if (item.authorUsername.isNotEmpty) return '@${item.authorUsername}';
    return 'homeAnonymousAuthor'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final img = item.images.isNotEmpty ? item.images.first : '';
    final nImg = item.images.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: AspectRatio(
            aspectRatio: 0.82,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (img.isNotEmpty)
                  MyImage.network(img, fit: BoxFit.cover)
                else
                  Container(
                    color: const Color(0xFFE8ECF3),
                    alignment: Alignment.center,
                    child: Icon(Icons.image_outlined,
                        color: const Color(0xFFA8B0BF), size: 36.sp),
                  ),
                if (nImg > 1)
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(99.r),
                      ),
                      child: Text(
                        '1/$nImg',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          item.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1F2C),
            height: 1.35,
          ),
        ),
        SizedBox(height: 6.h),
        Row(
          children: [
            ClipOval(
              child: item.authorAvatarUrl.isNotEmpty
                  ? MyImage.network(
                      item.authorAvatarUrl,
                      width: 18.w,
                      height: 18.w,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      MyImagePaths.defaultHeader,
                      width: 18.w,
                      height: 18.w,
                      fit: BoxFit.cover,
                    ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                _displayName(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: const Color(0xFF8C95A8),
                ),
              ),
            ),
            Icon(Icons.favorite_border_rounded,
                size: 15.sp, color: const Color(0xFF1A1F2C)),
            SizedBox(width: 2.w),
            Text(
              CommonUtils.renderEnFixedNumber(item.likeCount).toString(),
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1F2C),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tab: videos
// ─────────────────────────────────────────────────────────────────────────

class _SearchVideosTab extends StatefulWidget {
  const _SearchVideosTab({super.key, required this.query});

  final String query;

  @override
  State<_SearchVideosTab> createState() => _SearchVideosTabState();
}

class _SearchVideosTabState extends State<_SearchVideosTab>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();
  final List<VideoSearchItem> _items = [];
  String? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  bool _boot = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.query.length >= 2) {
        _loadFirst();
      }
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SearchVideosTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _refresh();
  }

  void _onScroll() {
    if (!_scroll.hasClients || _loading || !_hasMore) return;
    if (_scroll.position.pixels + 420 >= _scroll.position.maxScrollExtent) {
      _loadMore();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _cursor = null;
      _hasMore = true;
      _boot = false;
    });
    await _loadFirst();
  }

  Future<void> _loadFirst() async {
    if (_loading) return;
    setState(() => _loading = true);
    final r = await context.read<SearchDomain>().searchVideos(
          q: widget.query,
          cursor: null,
        );
    if (!mounted) return;
    _items
      ..clear()
      ..addAll(r.items);
    _cursor = r.nextCursor;
    _hasMore = r.hasMore && (r.nextCursor != null && r.nextCursor!.isNotEmpty);
    setState(() {
      _loading = false;
      _boot = true;
    });
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore || _cursor == null || _cursor!.isEmpty) return;
    setState(() => _loading = true);
    final r = await context.read<SearchDomain>().searchVideos(
          q: widget.query,
          cursor: _cursor,
        );
    if (!mounted) return;
    _items.addAll(r.items);
    _cursor = r.nextCursor;
    _hasMore = r.hasMore && (r.nextCursor != null && r.nextCursor!.isNotEmpty);
    setState(() => _loading = false);
  }

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_boot && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _boot) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Text(
            'searchVideosEmpty'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: const Color(0xFF62748E), fontSize: 14.sp),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: GridView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8.h,
          crossAxisSpacing: 8.w,
          childAspectRatio: 0.72,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final v = _items[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Stack(
              fit: StackFit.expand,
              children: [
                v.coverUrl.isNotEmpty
                    ? MyImage.network(v.coverUrl, fit: BoxFit.cover)
                    : Container(color: const Color(0xFF2C2C2E)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 8.w,
                  bottom: 8.h,
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 22.sp),
                      SizedBox(width: 2.w),
                      Text(
                        _fmt(v.durationSec > 0 ? v.durationSec : 0),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tab: music
// ─────────────────────────────────────────────────────────────────────────

class _SearchMusicTab extends StatefulWidget {
  const _SearchMusicTab({super.key, required this.query});

  final String query;

  @override
  State<_SearchMusicTab> createState() => _SearchMusicTabState();
}

class _SearchMusicTabState extends State<_SearchMusicTab>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();
  final List<BgmSearchItem> _items = [];
  String? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  bool _boot = false;

  int? _expandedId;
  bool _playing = false;
  double _progress = 0;
  Timer? _timer;
  final Set<int> _fav = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.query.length >= 2) {
        _loadFirst();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SearchMusicTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _timer?.cancel();
      _refresh();
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients || _loading || !_hasMore) return;
    if (_scroll.position.pixels + 400 >= _scroll.position.maxScrollExtent) {
      _loadMore();
    }
  }

  Future<void> _refresh() async {
    _timer?.cancel();
    setState(() {
      _items.clear();
      _cursor = null;
      _hasMore = true;
      _boot = false;
      _expandedId = null;
      _playing = false;
      _progress = 0;
    });
    await _loadFirst();
  }

  Future<void> _loadFirst() async {
    if (_loading) return;
    setState(() => _loading = true);
    final r = await context.read<SearchDomain>().searchMusic(
          q: widget.query,
          cursor: null,
        );
    if (!mounted) return;
    _items
      ..clear()
      ..addAll(r.items);
    _cursor = r.nextCursor;
    _hasMore = r.hasMore && (r.nextCursor != null && r.nextCursor!.isNotEmpty);
    setState(() {
      _loading = false;
      _boot = true;
    });
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore || _cursor == null || _cursor!.isEmpty) return;
    setState(() => _loading = true);
    final r = await context.read<SearchDomain>().searchMusic(
          q: widget.query,
          cursor: _cursor,
        );
    if (!mounted) return;
    _items.addAll(r.items);
    _cursor = r.nextCursor;
    _hasMore = r.hasMore && (r.nextCursor != null && r.nextCursor!.isNotEmpty);
    setState(() => _loading = false);
  }

  void _onTapRow(BgmSearchItem item) {
    setState(() {
      if (_expandedId == item.id) {
        _expandedId = null;
        _timer?.cancel();
        _playing = false;
        _progress = 0;
      } else {
        _expandedId = item.id;
        _progress = 0;
        _playing = false;
        _timer?.cancel();
      }
    });
  }

  void _togglePlay(BgmSearchItem item) {
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
    } else {
      final total = item.durationMs > 0 ? item.durationMs : 180000;
      setState(() => _playing = true);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 300), (t) {
        if (!mounted) return;
        setState(() {
          _progress += 300 / total;
          if (_progress >= 1) {
            _progress = 1;
            _playing = false;
            t.cancel();
          }
        });
      });
    }
  }

  String _fmtMs(int ms) {
    final sec = (ms / 1000).round();
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_boot && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _boot) {
      return Center(
          child: Text('commonNoResults'.tr(),
              style:
                  TextStyle(color: const Color(0xFF62748E), fontSize: 14.sp)));
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final m = _items[index];
          final expanded = _expandedId == m.id;
          final totalMs = m.durationMs > 0 ? m.durationMs : 180000;
          final curMs = (totalMs * _progress).round();
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _onTapRow(m),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: m.coverUrl.isNotEmpty
                            ? MyImage.network(
                                m.coverUrl,
                                width: 52.w,
                                height: 52.w,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 52.w,
                                height: 52.w,
                                color: const Color(0xFFE8ECF3),
                              ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onTapRow(m),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1F2C),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    m.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF8C95A8),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${m.useCount} ${'searchBgmUseSuffix'.tr()}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF8C95A8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_fav.contains(m.id)) {
                            _fav.remove(m.id);
                          } else {
                            _fav.add(m.id);
                          }
                        });
                      },
                      icon: Icon(
                        _fav.contains(m.id)
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: _fav.contains(m.id)
                            ? const Color(0xFF1A1F2C)
                            : const Color(0xFF8C95A8),
                      ),
                    ),
                  ],
                ),
                if (expanded) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Text(
                        _fmtMs(curMs),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF8C95A8),
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12),
                          ),
                          child: Slider(
                            value: _progress.clamp(0.0, 1.0),
                            onChanged: (v) {
                              setState(() => _progress = v);
                            },
                          ),
                        ),
                      ),
                      Text(
                        _fmtMs(totalMs),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF8C95A8),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _togglePlay(m),
                        icon: Icon(
                          _playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: const Color(0xFF1A1F2C),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
