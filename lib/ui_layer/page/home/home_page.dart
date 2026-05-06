import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/feed.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/feed_models.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/notifier/home_feed_notifier.dart';
import 'package:g_link/ui_layer/page/home/search_home_page.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/widgets/feed_post_card.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:g_link/utils/my_toast.dart';
import 'package:provider/provider.dart';

/// 首页：顶部头像故事条 + 推荐关注横滑卡片 + 推荐流瀑布。
///
/// 数据来源：
///   - `/api/v1/feed/recommend`     —— 主帖子流
///   - `/api/v1/users/recommendations` —— 顶部头像 / 推荐关注卡片复用同一数据源
///
/// 设计稿没有显式 tab 栏（推荐/关注/热门），所以本页面默认只展示推荐流；
/// [HomeFeedNotifier] 仍保留三 tab 能力，留待后续上 Tab 栏直接接入。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  late final ScrollController _scrollCtrl;
  HomeFeedNotifier? _notifier;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final n = _notifier;
    if (n == null) return;
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    // 距离底部 480 像素就预拉下一页，体验比刚到底再加载更顺。
    if (pos.pixels + 480 >= pos.maxScrollExtent && !n.isLoading(n.currentTab) && n.hasMore(n.currentTab)) {
      n.loadMore(n.currentTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider<HomeFeedNotifier>(
      create: (ctx) {
        final notifier = HomeFeedNotifier(
          feedDomain: ctx.read<FeedDomain>(),
          profileDomain: ctx.read<ProfileDomain>(),
        )..bootstrap();
        _notifier = notifier;
        return notifier;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: _HomeAppBar(),
        body: Consumer<HomeFeedNotifier>(
          builder: (context, n, _) {
            return RefreshIndicator(
              color: const Color(0xFF1A1F2C),
              onRefresh: () => n.refresh(n.currentTab),
              child: _buildBody(context, n),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeFeedNotifier n) {
    final tab = n.currentTab;
    final posts = n.postsOf(tab);
    final initialLoading = n.isLoading(tab) && !n.isBootstrapped(tab);
    final empty = n.isBootstrapped(tab) && posts.isEmpty;
    final loadingMore = n.isLoading(tab) && n.isBootstrapped(tab);

    return CustomScrollView(
      controller: _scrollCtrl,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        if (initialLoading)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: SizedBox(
                width: 28.w,
                height: 28.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF1A1F2C),
                ),
              ),
            ),
          )
        else ...[
          SliverToBoxAdapter(child: SizedBox(height: 3.w)),
          SliverToBoxAdapter(
            child: _StoriesRow(
              users: n.recommendUsers,
              currentUserUid: n.currentUserUid,
            ),
          ),
          SliverToBoxAdapter(
            child: _RecommendUsersSection(
              users: n.recommendUsers,
              loading: n.recommendUsersLoading,
              isFollowing: n.isFollowing,
              onToggleFollow: (uid) => _toggleFollow(context, n, uid),
              onMore: () => _onTapRecommendMore(context),
              currentUserUid: n.currentUserUid,
            ),
          ),
          if (empty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyView(
                message: n.errorOf(tab) ?? 'commonNoResults'.tr(),
                onRetry: () => n.refresh(tab),
              ),
            )
          else
            SliverList.separated(
              itemCount: posts.length + 1,
              itemBuilder: (context, index) {
                if (index == posts.length) {
                  return _FeedFooter(
                    loading: loadingMore,
                    hasMore: n.hasMore(tab),
                  );
                }
                final post = posts[index];
                return FeedPostCard(
                  key: ValueKey(post.postId),
                  post: post,
                  showAuthorFollowButton:
                      n.currentUserUid == null ||
                      post.author.uid != n.currentUserUid,
                  isAuthorFollowed: n.isFollowing(post.author.uid, fallback: post.author.isFollowing ?? false,),
                onToggleAuthorFollow: () => _toggleFollow(context, n, post.author.uid),
                onToggleLike: () => _onToggleLike(context, n, post),
              );
            },
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
          ),],
      ],
    );
  }

  Future<void> _toggleFollow(
    BuildContext context,
    HomeFeedNotifier n,
    int uid,
  ) async {
    final ok = await n.toggleFollow(uid);
    if (!mounted || !context.mounted) return;
    if (!ok) {
      MyToast.showText(text: 'homeFollowFailed'.tr());
    }
  }

  Future<void> _onToggleLike(
    BuildContext context,
    HomeFeedNotifier n,
    FeedPost post,
  ) async {
    final ok = await n.toggleLike(post.postId);
    if (!mounted || !context.mounted) return;
    if (!ok) {
      MyToast.showText(text: 'homeLikeFailed'.tr());
    }
  }

  void _onTapRecommendMore(BuildContext context) {
    const RecommendFollowListRoute(limit: 30).push(context);
  }
}

// ──────────────────────────────────────────────────────────────────────
// AppBar
// ──────────────────────────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(56.w);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleSpacing: 16.w,
      title: Row(
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2C),
              borderRadius: BorderRadius.circular(8.r),
            ),
            alignment: Alignment.center,
            child: Text(
              'G',
              style: TextStyle(
                color: const Color(0xFFF4F5F7),
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'Link',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1F2C),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => const SearchHomePage()),
          ),
          icon: Image.asset(
            MyImagePaths.search,
            width: 21.w,
            height: 21.w,
            color: const Color(0xFF1A1F2C),
          ),
        ),
        SizedBox(width: 4.w),
        Padding(
          padding: EdgeInsets.only(right: 10.w),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => NotificationRoute().push(context),
                icon: Image.asset(
                  MyImagePaths.notification,
                  width: 21.w,
                  height: 21.w,
                  color: const Color(0xFF1A1F2C),
                ),
              ),
              // 设计稿角标。当前无真实未读数接口，先用静态 "3" 占位。
              Positioned(
                  right: 6.w,
                  top: 6.h,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      constraints: BoxConstraints(minWidth: 14.w, minHeight: 14.w),
                      padding: EdgeInsets.symmetric(horizontal: 3.w),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(999.r),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Top stories row（顶部头像故事条）
// ──────────────────────────────────────────────────────────────────────

class _StoriesRow extends StatelessWidget {
  const _StoriesRow({required this.users, this.currentUserUid});

  final List<RecommendedUser> users;

  /// 当前登录用户 uid，用于头像点击时判断「自己头像不跳」。
  /// `null` 表示尚未登录或资料还没拉到，按"非自己"处理（允许跳转）。
  final int? currentUserUid;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return SizedBox(height: 60.h);
    }
    final visibleUsers = users.take(10).toList();
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: EdgeInsets.only(top: 8.w, bottom: 8.w),
      child: SizedBox(
        height: 60.w,
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          scrollDirection: Axis.horizontal,
          itemCount: visibleUsers.length,
          separatorBuilder: (_, __) => SizedBox(width: 11.w),
          itemBuilder: (context, index) {
            final user = visibleUsers[index];
            // 红点指示"有新内容"，目前后端没有 stories 接口，先按设计给前几位加红点占位。
            final showDot = index < 4;
            return _StoryAvatar(
              user: user,
              showDot: showDot,
              currentUserUid: currentUserUid,
            );
          },
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  const _StoryAvatar({
    required this.user,
    required this.showDot,
    this.currentUserUid,
  });

  final RecommendedUser user;
  final bool showDot;
  final int? currentUserUid;

  @override
  Widget build(BuildContext context) {
    // 顶部头像故事条点击 → 跳转该用户的「最新帖子」列表页（接口
    // `/users/{uid}/posts`），不是他人主页。设计上 stories 风格 = 看其最近内容流；
    // 自己的头像不响应点击，避免出现「看自己 stories」的奇怪入口。
    final canOpen = currentUserUid == null || user.uid != currentUserUid;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canOpen
          ? () => UserPostsRoute(uid: user.uid).push<void>(context)
          : null,
      child: SizedBox(
        width: 58.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 58.w,
                  height: 58.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1F2532),
                      width: 1.2,
                    ),
                  ),
                  padding: EdgeInsets.all(2.5.w),
                  child: ClipOval(
                    child: user.avatarUrl.isNotEmpty
                        ? MyImage.network(
                            user.avatarUrl,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            MyImagePaths.defaultHeader,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                if (showDot)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 11.w,
                      height: 11.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// "推荐关注" 区
// ──────────────────────────────────────────────────────────────────────

class _RecommendUsersSection extends StatelessWidget {
  const _RecommendUsersSection({
    required this.users,
    required this.loading,
    required this.isFollowing,
    required this.onToggleFollow,
    required this.onMore,
    this.currentUserUid,
  });

  final List<RecommendedUser> users;
  final bool loading;
  final bool Function(int uid, {bool fallback}) isFollowing;
  final ValueChanged<int> onToggleFollow;
  final VoidCallback onMore;

  /// 当前登录用户 uid，用于卡片头像点击时判断「自己头像不跳」。
  final int? currentUserUid;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty && !loading) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.only(top: 0.h, bottom: 10.h),
      padding: EdgeInsets.only(top: 14.h, bottom: 12.h),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Text(
                  'homeRecommendFollow'.tr(),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1F2C),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onMore,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 4.h),
                    child: Text(
                      'homeViewMore'.tr(),
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF62748E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.w),
          SizedBox(
            height: 174..w,
            child: loading && users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => SizedBox(width: 12.w),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _RecommendUserCard(
                        user: user,
                        isFollowing: isFollowing(user.uid, fallback: false),
                        onToggle: () => onToggleFollow(user.uid),
                        currentUserUid: currentUserUid,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecommendUserCard extends StatelessWidget {
  const _RecommendUserCard({
    required this.user,
    required this.isFollowing,
    required this.onToggle,
    this.currentUserUid,
  });

  final RecommendedUser user;
  final bool isFollowing;
  final VoidCallback onToggle;
  final int? currentUserUid;

  @override
  Widget build(BuildContext context) {
    final canOpen = currentUserUid == null || user.uid != currentUserUid;
    return Container(
      width: 135.w,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF1F5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canOpen
                ? () => OtherProfileRoute(uid: user.uid).push<void>(context)
                : null,
            child: Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE2E5EB),
              ),
              child: ClipOval(
                child: user.avatarUrl.isNotEmpty
                    ? MyImage.network(user.avatarUrl, fit: BoxFit.cover)
                    : Image.asset(
                        MyImagePaths.defaultHeader,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            user.nickname.isNotEmpty ? user.nickname : user.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1F2C),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'commonFollowerCount'.tr(namedArgs: {
              'count': CommonUtils.renderEnFixedNumber(user.followerCount),
            }),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF62748E),
            ),
          ),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              height: 34.w,
              alignment: Alignment.center,
              margin: EdgeInsets.symmetric(horizontal: 15.w),
              decoration: BoxDecoration(
                color: isFollowing ? Colors.transparent : const Color(0xFF1A1F2C),
                border: isFollowing ? Border.all(color: const Color(0xFFCCCCCC), width: 1) : null,
                borderRadius: BorderRadius.circular(99.r),
              ),
              child: Text(
                isFollowing ? 'commonFollowed'.tr() : 'commonFollow'.tr(),
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isFollowing ? const Color(0xFF1A1F2C) : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Footer / empty / error widgets
// ──────────────────────────────────────────────────────────────────────

class _FeedFooter extends StatelessWidget {
  const _FeedFooter({required this.loading, required this.hasMore});

  final bool loading;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    if (!loading && hasMore) {
      return SizedBox(height: 12.h);
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 18.h),
      child: Center(
        child: loading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1A1F2C),
                ),
              )
            : Text(
                'homeNoMore'.tr(),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF8C95A8),
                ),
              ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56.sp, color: const Color(0xFFCFD3DC)),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF62748E),
              ),
            ),
            SizedBox(height: 16.h),
            OutlinedButton(
              onPressed: onRetry,
              child: Text('commonRetry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
