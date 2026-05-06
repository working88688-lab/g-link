import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/feed.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/feed_models.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/notifier/profile_notifier.dart';
import 'package:g_link/ui_layer/notifier/follow_list_notifier.dart';
import 'package:g_link/ui_layer/page/mine/drafts_page.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'widgets/mine_settings_drawer.dart';

class MinePage extends StatefulWidget {
  /// 个人主页 / 他人主页共用同一份页面。
  /// - [targetUid] 为空：本人主页，bootstrapMineProfile 走 `/users/me`，
  ///   顶部右侧是设置抽屉，资料区是「编辑个人资料」按钮，作品 tab 置顶草稿。
  /// - [targetUid] 非空：他人主页，bootstrapOtherProfile 走 `/users/{uid}`，
  ///   顶部左侧加返回键、右侧改成三点菜单（投诉 / 拉黑 / 解除拉黑），资料区
  ///   换成「关注 + 发消息」按钮，没有草稿，被拉黑时正文区替换为占位。
  const MinePage({super.key, this.targetUid});

  final int? targetUid;

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> with WidgetsBindingObserver {
  late final List<RefreshController> _refreshControllers =
      List<RefreshController>.generate(
    3,
    (_) => RefreshController(initialRefresh: false),
  );

  /// VisibilityDetector 需要一个稳定的 key 才能正确派发 onVisibilityChanged。
  /// 个人主页（Mine 分支）和他人主页（push 到根 Navigator）可能同时存在，
  /// 用 targetUid 区分（self 用固定字符串），避免两个 detector key 冲突。
  late final ValueKey<String> _visibilityKey = ValueKey<String>(
    'mine-page-visibility-${widget.targetUid ?? 'self'}',
  );

  /// 用来在 build 完成后触发首次 bootstrap，以及给 VisibilityDetector 拉新数据用。
  ProfileNotifier? _notifier;

  /// 上一次可见状态——避免 VisibilityDetector 由于 fraction 抖动多次回调时
  /// 一直触发刷新（虽然 [ProfileNotifier.refreshIfStale] 内部已经节流，但能
  /// 在外层就避开就更好）。
  bool _wasVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final c in _refreshControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // app 从后台回到前台、且当前 tab 就是个人主页时也要刷新：纯靠 visibility
    // 在某些机型 / 后台模式下不会回调。
    // 他人主页不做 stale-refresh（这里走的是 /me 节流策略；resume 时让用户
    // 手动下拉刷新即可），避免在他人主页上误触发 getMyProfile。
    if (state == AppLifecycleState.resumed && _wasVisible && _isSelf) {
      _notifier?.refreshIfStale();
    }
  }

  bool get _isSelf => widget.targetUid == null;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) {
            final n = ProfileNotifier(
              ctx.read<ProfileDomain>(),
              ctx.read<FeedDomain>(),
              targetUid: widget.targetUid,
            );
            if (_isSelf) {
              n.bootstrapMineProfile();
            } else {
              n.bootstrapOtherProfile(uid: widget.targetUid!);
            }
            _notifier = n;
            return n;
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        endDrawer: _isSelf ? const MineSettingsDrawer() : null,
        body: VisibilityDetector(
          key: _visibilityKey,
          onVisibilityChanged: (info) {
            // 阈值 50%：bottomNav 切换造成的 dispose-and-rebuild、半遮挡都不算
            // "重新可见"，避免和 [bootstrapMineProfile] 的首次拉取重复。
            // 他人主页通过 push 进入：bootstrapOtherProfile 已经发了一次
            // /users/{uid}，VisibilityDetector 第一次报 visible 时不能再让
            // 它去 fetchMineProfileAndVideos（那是 /me 接口），否则会出现
            // 「他人主页拉完紧接着又拉了一次自己的资料」的混乱。
            final visible = info.visibleFraction >= 0.5;
            if (visible && !_wasVisible && _isSelf) {
              _notifier?.refreshIfStale();
            }
            _wasVisible = visible;
          },
          child: Consumer<ProfileNotifier>(builder: (context, notifier, _) {
            final profile = context
                    .select<ProfileNotifier, UserProfile?>((n) => n.profile) ??
                const UserProfile(
                  uid: 0,
                  username: '',
                  nickname: '',
                  avatarUrl: '',
                  coverUrl: '',
                  bio: '',
                  location: '',
                  professionTags: <String>[],
                  isSelf: true,
                  followingCount: 0,
                  followingCountDisplay: '0',
                  followerCount: 0,
                  followerCountDisplay: '0',
                  likeCount: 0,
                  likeCountDisplay: '0',
                  postCount: 0,
                  postCountDisplay: '0',
                  videoCount: 0,
                  videoCountDisplay: '0',
                );
            // 已被你拉黑 / 对方拉黑你：作品区直接换占位，不再走 tab + 列表。
            // 仍然展示 header（背景图 + 资料卡 + 三点菜单），方便用户「解除拉黑」。
            final blockedView = !_isSelf &&
                (notifier.profile?.isBlocked == true ||
                    notifier.profile?.isBlockedBy == true);
            return Stack(
              children: [
                Column(
                  children: [
                    _buildHeaderProfileSection(context, profile, notifier),
                    Expanded(
                      child: blockedView
                          ? _buildBlockedPlaceholder(notifier.profile!)
                          : DefaultTabController(
                              length: 3,
                              initialIndex: notifier.tabIndex,
                              child: Column(
                                children: [
                                  _buildTabs(notifier),
                                  Expanded(
                                    child: TabBarView(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      children: [
                                        _buildMediaTab(
                                          notifier,
                                          tabIndex: 0,
                                          initialLoading:
                                              notifier.loadingProfile &&
                                                  notifier.profile == null,
                                        ),
                                        _buildMediaTab(
                                          notifier,
                                          tabIndex: 1,
                                          initialLoading:
                                              notifier.loadingProfile &&
                                                  notifier.profile == null,
                                        ),
                                        _buildMediaTab(
                                          notifier,
                                          tabIndex: 2,
                                          initialLoading:
                                              notifier.loadingProfile &&
                                                  notifier.profile == null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHeaderProfileSection(
    BuildContext context,
    UserProfile profile,
    ProfileNotifier notifier,
  ) {
    final headerHeight = 190.w;
    final avatarSize = 78.w;
    final overlap = avatarSize / 2;
    return Stack(
      children: [
        _buildHeader(context, headerHeight, profile),
        _buildProfileCard(context, headerHeight, profile, notifier),
        Positioned(
          left: 14.w,
          top: headerHeight - overlap,
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF4),
              borderRadius: BorderRadius.circular(avatarSize / 2),
              border: Border.all(color: Colors.white, width: 2.w),
            ),
            clipBehavior: Clip.antiAlias,
            child: profile.avatarUrl.isNotEmpty
                ? MyImage.network(profile.avatarUrl, fit: BoxFit.cover)
                : MyImage.asset(
                    MyImagePaths.defaultHeader,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    double headerHeight,
    UserProfile profile,
  ) {
    final cover = profile.coverUrl;
    return SizedBox(
      height: headerHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cover.isNotEmpty)
            MyImage.network(cover, fit: BoxFit.cover, placeHolder: null)
          else
            MyImage.asset(
              MyImagePaths.userBackground,
              fit: BoxFit.cover,
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 6.w,
            left: 14.w,
            right: 14.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 个人主页是 BottomNaviBar 的一级页面，左上角不需要返回键；
                // 他人主页通过 push 进入，左上角放可点击的返回键。
                if (_isSelf)
                  SizedBox(width: 30.w, height: 30.w)
                else
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: _navSquare(MyImagePaths.appBackIcon),
                  ),
                if (_isSelf)
                  GestureDetector(
                    onTap: () => Scaffold.of(context).openEndDrawer(),
                    child: _navSquare(MyImagePaths.settings),
                  )
                else
                  Builder(
                    builder: (btnCtx) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          _showOtherProfileMenu(btnCtx, profile),
                      child: _navSquare(MyImagePaths.iconMore),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navSquare(String icon) {
    return Container(
      width: 30.w,
      height: 30.w,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(8.w),
      ),
      child: Image.asset(
        icon,
        color: Colors.white,
        width: 19.w,
        height: 19.w,
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    double headerHeight,
    UserProfile profile,
    ProfileNotifier notifier,
  ) {
    return Container(
      margin: EdgeInsets.only(top: headerHeight - 5.w),
      padding: EdgeInsets.fromLTRB(14.w, 8.w, 14.w, 8.w),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(width: 84.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8.w),
                  child: Text(
                    profile.nickname.isNotEmpty
                        ? profile.nickname
                        : 'mineUserTitle'.tr(),
                    style: TextStyle(
                      color: const Color(0xFF141A2A),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (_isSelf)
                _buildEditProfileButton(profile, notifier)
              else
                _buildOtherProfileActions(context, profile, notifier),
            ],
          ),
          SizedBox(height: 8.w),
          Row(
            children: [
              Text(
                '@${profile.username}',
                style: TextStyle(
                  color: const Color(0xFF5A6477),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 12.w),
              Image.asset(
                MyImagePaths.userLocation,
                width: 14.w,
                height: 14.w,
                color: const Color(0xFF5A6477),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  profile.location.isNotEmpty
                      ? profile.location
                      : 'mineLocationUnknown'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF5A6477),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.w),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              profile.professionTags.isNotEmpty
                  ? profile.professionTags.map((e) => '✨ $e').join(' | ')
                  : profile.bio,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF232B3C),
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 10.w),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _metricItem(profile.postCountDisplay, 'minePostCount'.tr()),
              SizedBox(width: 25.w),
              _metricItem(
                profile.followerCountDisplay,
                'mineFansCount'.tr(),
                onTap: () => _openFollowList(
                  profile,
                  initialTab: FollowListTab.followers,
                ),
              ),
              SizedBox(width: 25.w),
              _metricItem(
                profile.followingCountDisplay,
                'mineFollowCount'.tr(),
                onTap: () => _openFollowList(
                  profile,
                  initialTab: FollowListTab.followings,
                ),
              ),
            ],
          ),
          if (notifier.errorMessage != null && notifier.videos.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 10.w),
              child: Text(
                notifier.errorMessage!,
                style: TextStyle(color: Colors.red.shade400, fontSize: 12.sp),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricItem(String value, String label, {VoidCallback? onTap}) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF151B2A),
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF9BA3B3),
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    if (onTap == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: row,
    );
  }

  Widget _buildTabs(ProfileNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEDF0F5), width: 0.8.w),
        ),
      ),
      child: TabBar(
        onTap: notifier.changeTab,
        indicatorColor: const Color(0xFF3A465D),
        indicatorWeight: 2,
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF3A465D),
        unselectedLabelColor: const Color(0xFF9AA2B1),
        tabs: const [
          Tab(icon: Icon(Icons.article_rounded)),
          Tab(icon: Icon(Icons.play_arrow_rounded)),
          Tab(icon: Icon(Icons.favorite_rounded)),
        ],
      ),
    );
  }

  Widget _buildMediaTab(
    ProfileNotifier notifier, {
    required int tabIndex,
    required bool initialLoading,
  }) {
    return SmartRefresher(
      controller: _refreshControllers[tabIndex],
      enablePullDown: true,
      onRefresh: () async {
        notifier.changeTab(tabIndex);
        if (_isSelf) {
          await notifier.fetchMineProfileAndVideos();
        } else {
          await notifier.fetchProfileAndVideos(uid: widget.targetUid!);
        }
        if (!mounted) return;
        _refreshControllers[tabIndex].refreshCompleted();
      },
      child: _buildMediaContent(
        notifier,
        tabIndex: tabIndex,
        initialLoading: initialLoading,
      ),
    );
  }

  Widget _buildMediaContent(
    ProfileNotifier notifier, {
    required int tabIndex,
    required bool initialLoading,
  }) {
    if (initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final isPosts = tabIndex == 0;
    final isVideos = tabIndex == 1;
    final postLikeItems = isPosts ? notifier.posts : notifier.likes;
    // 草稿是当前登录用户专属（接口走 /me 维度），他人主页一律不展示。
    final draft = !_isSelf
        ? null
        : (isPosts
            ? notifier.postDraft
            : (isVideos ? notifier.videoDraft : null));
    final mainCount =
        isVideos ? notifier.videos.length : postLikeItems.length;
    final totalCount = mainCount + (draft != null ? 1 : 0);
    if (notifier.loadingVideos && totalCount == 0) {
      return const Center(child: CircularProgressIndicator());
    }
    if (totalCount == 0) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 34.w),
            child: Center(
              child: Text(
                'messageEmpty'.tr(),
                style:
                    TextStyle(color: const Color(0xFF8C95A4), fontSize: 13.sp),
              ),
            ),
          ),
        ],
      );
    }
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: 2.w),
      itemCount: totalCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.74,
      ),
      itemBuilder: (_, i) {
        if (draft != null && i == 0) {
          return _buildDraftCell(notifier, draft, isVideos);
        }
        final realIndex = draft != null ? i - 1 : i;
        final coverUrl = isVideos
            ? notifier.videos[realIndex].coverUrl
            : postLikeItems[realIndex].coverUrl;
        if (coverUrl.isEmpty) {
          return Container(color: const Color(0xFFE5E7ED));
        }
        return MyImage.network(coverUrl, fit: BoxFit.cover, placeHolder: null);
      },
    );
  }

  /// 「作品 / 视频」tab 置顶展示的草稿卡片：封面铺满 + 左下角「草稿箱」徽标。
  /// 点击进入草稿箱列表管理页，返回时强制刷新当前 tab，确保已删条目不再展示。
  Widget _buildDraftCell(
      ProfileNotifier notifier, DraftItem draft, bool isVideoTab) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openDraftsPage(notifier, isVideoTab: isVideoTab),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (draft.coverUrl.isNotEmpty)
            MyImage.network(draft.coverUrl,
                fit: BoxFit.cover, placeHolder: null)
          else
            Container(color: const Color(0xFFE5E7ED)),
          Positioned(
            left: 5.w,
            bottom: 5.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(4.w),
              ),
              child: Text(
                'mineDraftBoxBadge'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 跳到「关注列表页」：根据点击的指标决定 tab——
  /// `mineFansCount`（粉丝）→ followers tab；`mineFollowCount`（关注）→ followings tab。
  ///
  /// 用 [MineFollowListRoute] 走 go_router 推入 Mine 分支自己的 Navigator，
  /// 这样外层 [BottomNaviBar] 的底部 tab 栏会保留可见——常见社交 app 进入
  /// 「粉丝/关注」二级页仍能看到底部 tab，是与设计稿一致的 UX。
  /// 返回后无需特别刷新：关注/取消关注会改 follower_count 但不影响列表本身的展示。
  void _openFollowList(
    UserProfile profile, {
    required FollowListTab initialTab,
  }) {
    final tab = switch (initialTab) {
      FollowListTab.mutual => 'mutual',
      FollowListTab.followings => 'followings',
      FollowListTab.followers => 'followers',
    };
    MineFollowListRoute(uid: profile.uid, tab: tab).push<void>(context);
  }

  /// 跳到草稿箱列表管理页：根据点击来源决定初始 tab，
  /// 返回后强制刷新当前 tab——避免置顶 cell 还停留在已删除项的封面上。
  Future<void> _openDraftsPage(
    ProfileNotifier notifier, {
    required bool isVideoTab,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DraftsPage(initialTab: isVideoTab ? 1 : 0),
      ),
    );
    if (!mounted) return;
    await notifier.reloadCurrentTab();
  }

  // ---- 自己 / 他人 主页差异化 UI ----------------------------------------

  /// 自己主页：「编辑个人资料」按钮，点开走 [EditProfileRoute] 编辑。
  Widget _buildEditProfileButton(
    UserProfile profile,
    ProfileNotifier notifier,
  ) {
    return GestureDetector(
      onTap: () async {
        final updated = await EditProfileRoute(
          nickname: profile.nickname,
          username: profile.username,
          bio: profile.bio,
          userLocation: profile.location,
          avatarUrl: profile.avatarUrl,
          coverUrl: profile.coverUrl,
        ).push<bool>(context);
        if (updated == true) {
          await notifier.fetchMineProfileAndVideos();
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 6.w),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.w),
        decoration: BoxDecoration(
          color: const Color(0xFF121D33),
          borderRadius: BorderRadius.circular(22.w),
        ),
        child: Text(
          'mineEditProfile'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 他人主页：右下角「关注 / 已关注」+「发消息」并排两枚胶囊按钮。
  Widget _buildOtherProfileActions(
    BuildContext context,
    UserProfile profile,
    ProfileNotifier notifier,
  ) {
    final following = profile.isFollowing;
    final inflight = notifier.followInflight;
    return Padding(
      padding: EdgeInsets.only(bottom: 6.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: inflight ? null : () => _onFollowTap(notifier),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
              decoration: BoxDecoration(
                color: following
                    ? const Color(0xFFF5F6F8)
                    : const Color(0xFF121D33),
                border: following
                    ? Border.all(color: const Color(0xFFD3D7E0), width: 1)
                    : null,
                borderRadius: BorderRadius.circular(22.w),
              ),
              child: inflight
                  ? SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.6,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          following ? const Color(0xFF5F6778) : Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      following
                          ? 'commonFollowed'.tr()
                          : 'commonFollow'.tr(),
                      style: TextStyle(
                        color: following
                            ? const Color(0xFF5F6778)
                            : Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () => _onMessageTap(profile),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                border: Border.all(color: const Color(0xFFD3D7E0), width: 1),
                borderRadius: BorderRadius.circular(22.w),
              ),
              child: Text(
                'commonSendMessage'.tr(),
                style: TextStyle(
                  color: const Color(0xFF5F6778),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 拉黑后正文区的占位：截图样式——一个圆形禁止图标 + 主副两行说明文字。
  Widget _buildBlockedPlaceholder(UserProfile profile) {
    final blockedByMe = profile.isBlocked;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF1F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.block_rounded,
                color: const Color(0xFF8C95A4),
                size: 30.w,
              ),
            ),
            SizedBox(height: 14.w),
            Text(
              blockedByMe
                  ? 'profileBlockedByMeTitle'.tr()
                  : 'profileBlockedByOtherTitle'.tr(),
              style: TextStyle(
                color: const Color(0xFF1A1F2C),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.w),
            Text(
              'profileBlockedSubtitle'.tr(),
              style: TextStyle(
                color: const Color(0xFF8C95A4),
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 三点菜单：投诉 + 拉黑 / 解除拉黑。
  /// 用 [showMenu] 复用 Material 的位置计算与 outside-tap 关闭逻辑——
  /// 1:1 复刻设计稿里小白卡 dropdown 的视觉。
  Future<void> _showOtherProfileMenu(
    BuildContext anchorContext,
    UserProfile profile,
  ) async {
    final overlay =
        Overlay.of(anchorContext).context.findRenderObject() as RenderBox?;
    final box = anchorContext.findRenderObject() as RenderBox?;
    if (overlay == null || box == null) return;
    // 用按钮右下角作为锚点，让菜单从右上往下展开。
    final anchorTopLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final anchorBottomRight = box.localToGlobal(
      box.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    final position = RelativeRect.fromLTRB(
      anchorTopLeft.dx - 100.w,
      anchorBottomRight.dy + 4.w,
      overlay.size.width - anchorBottomRight.dx,
      0,
    );
    final isBlocked = profile.isBlocked;
    final selected = await showMenu<_OtherProfileAction>(
      context: anchorContext,
      position: position,
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.w),
      ),
      items: <PopupMenuEntry<_OtherProfileAction>>[
        _menuItem(
          _OtherProfileAction.report,
          icon: Icons.error_outline_rounded,
          label: 'profileMenuReport'.tr(),
        ),
        _menuItem(
          isBlocked
              ? _OtherProfileAction.unblock
              : _OtherProfileAction.block,
          icon: isBlocked
              ? Icons.lock_open_rounded
              : Icons.block_rounded,
          label: isBlocked
              ? 'profileMenuUnblock'.tr()
              : 'profileMenuBlock'.tr(),
          danger: !isBlocked,
        ),
      ],
    );
    if (!mounted || selected == null) return;
    switch (selected) {
      case _OtherProfileAction.report:
        await ComplaintRoute(
          targetId: profile.uid,
          targetType: 'user',
        ).push(context);
        break;
      case _OtherProfileAction.block:
        await _confirmBlock(profile);
        break;
      case _OtherProfileAction.unblock:
        await _notifier?.unblockCurrent();
        break;
    }
  }

  PopupMenuItem<_OtherProfileAction> _menuItem(
    _OtherProfileAction value, {
    required IconData icon,
    required String label,
    bool danger = false,
  }) {
    final color = danger
        ? const Color(0xFFE54848)
        : const Color(0xFF1A1F2C);
    return PopupMenuItem<_OtherProfileAction>(
      value: value,
      height: 40.w,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 拉黑前再确认——和截图里中间的弹框一致：「拉黑后，对方无法搜索到你，
  /// 也不能再给你发消息」。用户点击「确认拉黑」后才真正发请求。
  Future<void> _confirmBlock(UserProfile profile) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.w),
          ),
          titlePadding: EdgeInsets.fromLTRB(20.w, 20.w, 20.w, 8.w),
          contentPadding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.w),
          actionsPadding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.w),
          title: Center(
            child: Text(
              'profileBlockConfirmTitle'.tr(),
              style: TextStyle(
                color: const Color(0xFF1A1F2C),
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          content: Text(
            'profileBlockConfirmContent'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF5A6477),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(false),
                    child: Text(
                      'commonCancel'.tr(),
                      style: TextStyle(
                        color: const Color(0xFF5A6477),
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(true),
                    child: Text(
                      'profileBlockConfirmOk'.tr(),
                      style: TextStyle(
                        color: const Color(0xFFE54848),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    await _notifier?.blockCurrent();
  }

  Future<void> _onFollowTap(ProfileNotifier notifier) async {
    final ok = await notifier.toggleFollow();
    if (!mounted) return;
    if (!ok && notifier.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notifier.errorMessage!)),
      );
    }
  }

  void _onMessageTap(UserProfile profile) {
    // IM 私信入口暂未对接（会话创建接口未上线），先 toast 占位。
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('publishComingSoon'.tr())),
    );
  }
}

/// 三点菜单触发的动作枚举——showMenu 通过它通知调用方。
enum _OtherProfileAction { report, block, unblock }
