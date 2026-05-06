import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/notifier/follow_list_notifier.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:g_link/utils/my_toast.dart';
import 'package:provider/provider.dart';

/// 关注列表页：互关 / 关注 / 粉丝 三个 tab，按下哪个入口就预选哪个 tab。
///
/// 数据接口：
/// - 互关 `GET /api/v1/users/{uid}/mutual`（不分页，最多 20 条）
/// - 关注 `GET /api/v1/users/{uid}/followings`（cursor 分页）
/// - 粉丝 `GET /api/v1/users/{uid}/followers`（cursor 分页）
///
/// 设计图三状态对应右侧按钮：
/// - 关注 tab：行内 `已关注`（描边胶囊，再点一次取消关注）
/// - 粉丝 tab：未回关 `回关`（黑底白字胶囊），已回关 `已关注`（描边胶囊）
/// - 互关 tab：`发消息`（描边胶囊；后续接入 IM 时跳到聊天会话）
class FollowListPage extends StatefulWidget {
  const FollowListPage({
    super.key,
    required this.uid,
    this.initialTab = FollowListTab.followings,
  });

  final int uid;
  final FollowListTab initialTab;

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  static const Color _titleColor = Color(0xFF1A1F2C);
  static const Color _subTitleColor = Color(0xFF8D96A8);
  static const Color _tabInactiveColor = Color(0xFF8D96A8);
  static const Color _pillBorderColor = Color(0xFFD3D7E0);
  static const Color _pillTextColor = Color(0xFF5F6778);
  static const Color _pillFillBg = Color(0xFFF5F6F8);

  /// 三个 tab 顺序：互关(0) / 关注(1) / 粉丝(2)。PageView 与 [FollowListTab]
  /// 之间的互转都走 [_tabToIndex] / [_indexToTab]，保持单一来源。
  static const List<FollowListTab> _tabs = <FollowListTab>[
    FollowListTab.mutual,
    FollowListTab.followings,
    FollowListTab.followers,
  ];

  /// 关注 / 粉丝 tab 各自一份 ScrollController，用于上拉加载更多。
  /// 互关 tab 不分页，无需挂监听。
  final ScrollController _followingsCtrl = ScrollController();
  final ScrollController _followersCtrl = ScrollController();

  late final PageController _pageController = PageController(
    initialPage: _tabToIndex(widget.initialTab),
  );

  /// 标记「正在执行编程式 animateToPage」，期间忽略 [PageView.onPageChanged]
  /// 触发的 tab 切换——避免点 tab 时一次手势触发多次 changeTab + 闪烁。
  bool _animatingToPage = false;

  /// 缓存自己在 [build] 里创建的 [FollowListNotifier]——
  /// ScrollController listener 在 State.context（位于 Provider 之上）里查不到
  /// Provider，会抛 `Could not find the correct Provider` 异常。
  /// 这里直接持引用，绕过 context lookup。MinePage 的 [ProfileNotifier]
  /// 也是同样做法。
  FollowListNotifier? _notifier;

  @override
  void initState() {
    super.initState();
    _followingsCtrl.addListener(() => _onScroll(FollowListTab.followings));
    _followersCtrl.addListener(() => _onScroll(FollowListTab.followers));
  }

  int _tabToIndex(FollowListTab tab) => _tabs.indexOf(tab);

  FollowListTab _indexToTab(int index) {
    if (index < 0 || index >= _tabs.length) return FollowListTab.followings;
    return _tabs[index];
  }

  void _onScroll(FollowListTab tab) {
    final ctrl =
        tab == FollowListTab.followings ? _followingsCtrl : _followersCtrl;
    if (!ctrl.hasClients) return;
    if (!mounted) return;
    final notifier = _notifier;
    if (notifier == null) return;
    // PageView 切到非当前 tab 时，旧 tab 的 ListView 仍在内存里(KeepAlive)，
    // 但用户看不到它——这时即使滚到底也不应该触发加载更多。
    if (notifier.currentTab != tab) return;
    final position = ctrl.position;
    if (position.pixels >= position.maxScrollExtent - 80) {
      notifier.loadMore();
    }
  }

  @override
  void dispose() {
    _followingsCtrl.dispose();
    _followersCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FollowListNotifier>(
      create: (ctx) {
        final n = FollowListNotifier(
          uid: widget.uid,
          profileDomain: ctx.read<ProfileDomain>(),
          initialTab: widget.initialTab,
        )..load();
        _notifier = n;
        return n;
      },
      child: Consumer<FollowListNotifier>(
        builder: (context, n, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(context, n),
            body: SafeArea(top: false, child: _buildBody(n)),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, FollowListNotifier n) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: Icon(Icons.chevron_left_rounded, size: 28.sp, color: _titleColor),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _tabItem(n, FollowListTab.mutual, 'followListTabMutual'.tr()),
          SizedBox(width: 22.w),
          _tabItem(n, FollowListTab.followings, 'followListTabFollowing'.tr()),
          SizedBox(width: 22.w),
          _tabItem(n, FollowListTab.followers, 'followListTabFollower'.tr()),
        ],
      ),
    );
  }

  Widget _tabItem(FollowListNotifier n, FollowListTab tab, String label) {
    final selected = n.currentTab == tab;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabTap(n, tab),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: TextStyle(
            color: selected ? _titleColor : _tabInactiveColor,
            fontSize: selected ? 17.sp : 14.sp,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  /// 点 tab：先切 notifier 状态（让 AppBar 文本立刻 hi-light），再编程式
  /// animate 到对应 PageView 页。`_animatingToPage` 期间会屏蔽
  /// [PageView.onPageChanged] 的回调，避免和 tap 重复 changeTab。
  Future<void> _onTabTap(FollowListNotifier n, FollowListTab tab) async {
    if (n.currentTab == tab) return;
    n.changeTab(tab);
    if (!_pageController.hasClients) return;
    _animatingToPage = true;
    try {
      await _pageController.animateToPage(
        _tabToIndex(tab),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } finally {
      if (mounted) _animatingToPage = false;
    }
  }

  /// 用户左右滑 PageView 时由 PageView 触发；编程式动画期间被 [_onTabTap] 屏蔽。
  void _onPageChanged(FollowListNotifier n, int index) {
    if (_animatingToPage) return;
    final tab = _indexToTab(index);
    if (n.currentTab != tab) n.changeTab(tab);
  }

  Widget _buildBody(FollowListNotifier n) {
    return PageView.builder(
      controller: _pageController,
      itemCount: _tabs.length,
      // AlwaysScrollable 让两端到底也能起拖动反馈，与系统 tab 切换体验一致。
      physics: const AlwaysScrollableScrollPhysics(),
      onPageChanged: (i) => _onPageChanged(n, i),
      itemBuilder: (context, index) {
        final tab = _indexToTab(index);
        return _KeepAliveTab(
          key: ValueKey<FollowListTab>(tab),
          child: _buildTabBody(n, tab),
        );
      },
    );
  }

  /// 渲染指定 tab 的列表（互关 / 关注 / 粉丝 共用同一份排版，按 tab 取数据）。
  Widget _buildTabBody(FollowListNotifier n, FollowListTab tab) {
    final list = switch (tab) {
      FollowListTab.mutual => n.mutualList,
      FollowListTab.followings => n.followingsList,
      FollowListTab.followers => n.followersList,
    };
    final loading = switch (tab) {
      FollowListTab.mutual => n.mutualLoading,
      FollowListTab.followings => n.followingsLoading,
      FollowListTab.followers => n.followersLoading,
    };

    if (loading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (list.isEmpty) {
      // 空态也包一层 ListView 让 RefreshIndicator 能下拉刷新。
      return RefreshIndicator(
        onRefresh: () => n.load(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 120.h),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  n.errorMessage ?? 'followListEmpty'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _subTitleColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final ctrl = switch (tab) {
      FollowListTab.mutual => null,
      FollowListTab.followings => _followingsCtrl,
      FollowListTab.followers => _followersCtrl,
    };
    final hasMore = switch (tab) {
      FollowListTab.mutual => false,
      FollowListTab.followings => n.followingsHasMore,
      FollowListTab.followers => n.followersHasMore,
    };
    final loadingMore = switch (tab) {
      FollowListTab.mutual => false,
      FollowListTab.followings => n.followingsLoadingMore,
      FollowListTab.followers => n.followersLoadingMore,
    };

    final itemCount = list.length + (hasMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () => n.load(force: true),
      child: ListView.separated(
        controller: ctrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 18.h),
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(height: 14.h),
        itemBuilder: (context, index) {
          if (index >= list.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              child: Center(
                child: SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: loadingMore
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : null,
                ),
              ),
            );
          }
          final user = list[index];
          return _buildUserRow(context, n, user);
        },
      ),
    );
  }

  Widget _buildUserRow(
    BuildContext context,
    FollowListNotifier n,
    FollowedUser user,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => OtherProfileRoute(uid: user.uid).push<void>(context),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE4E7EE),
            ),
            clipBehavior: Clip.antiAlias,
            child: user.avatarUrl.isNotEmpty
                ? MyImage.network(user.avatarUrl, fit: BoxFit.cover)
                : MyImage.asset(MyImagePaths.defaultHeader, fit: BoxFit.cover),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nickname.isNotEmpty ? user.nickname : user.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _titleColor,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _subtitleFor(user),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _subTitleColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          _trailingButton(context, n, user),
        ],
      ),
    );
  }

  /// 副标题：API 没有 follower_count，按用户体验依次回退到 bio / @username。
  String _subtitleFor(FollowedUser user) {
    if (user.bio.trim().isNotEmpty) return user.bio.trim();
    if (user.username.isNotEmpty) return '@${user.username}';
    return '';
  }

  Widget _trailingButton(
    BuildContext context,
    FollowListNotifier n,
    FollowedUser user,
  ) {
    final inflight = n.isFollowInflight(user.uid);
    switch (n.currentTab) {
      case FollowListTab.mutual:
        return _pill(
          label: 'followListSendMessage'.tr(),
          filled: false,
          loading: false,
          onTap: () => _onSendMessage(context, user),
        );
      case FollowListTab.followings:
        // 关注列表里所有人理论上都是已关注；显示「已关注」+ 点击取消关注。
        return _pill(
          label: user.isFollowing
              ? 'followListAlreadyFollowing'.tr()
              : 'followListFollow'.tr(),
          filled: !user.isFollowing,
          loading: inflight,
          onTap: () => _toggleFollow(context, n, user),
        );
      case FollowListTab.followers:
        // 粉丝列表：未回关展示黑底「回关」；已回关展示描边「已关注」。
        return _pill(
          label: user.isFollowing
              ? 'followListAlreadyFollowing'.tr()
              : 'followListFollowBack'.tr(),
          filled: !user.isFollowing,
          loading: inflight,
          onTap: () => _toggleFollow(context, n, user),
        );
    }
  }

  Widget _pill({
    required String label,
    required bool filled,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: loading ? null : onTap,
      child: Container(
        constraints: BoxConstraints(minWidth: 64.w),
        height: 30.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? _titleColor : _pillFillBg,
          border:
              filled ? null : Border.all(color: _pillBorderColor, width: 1),
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: loading
            ? SizedBox(
                width: 14.w,
                height: 14.w,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    filled ? Colors.white : _pillTextColor,
                  ),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.white : _pillTextColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _toggleFollow(
    BuildContext context,
    FollowListNotifier n,
    FollowedUser user,
  ) async {
    final ok = await n.toggleFollow(user.uid);
    if (!mounted) return;
    if (!ok && n.errorMessage != null) {
      MyToast.showText(text: n.errorMessage!);
    }
  }

  void _onSendMessage(BuildContext context, FollowedUser user) {
    // 私信入口暂未接入：当前 IM 路由依赖会话 uuid，等会话创建接口接好后再开。
    // 这里给一个轻提示，避免点了无反馈。
    MyToast.showText(text: 'publishComingSoon'.tr());
  }
}

/// PageView 子页 keep-alive 包装：左右滑切走另一个 tab 时保留滚动位置 +
/// 已加载数据，避免每次回头都要重新构建列表。
class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({super.key, required this.child});

  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
