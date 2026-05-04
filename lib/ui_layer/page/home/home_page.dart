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

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
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
    if (pos.pixels + 480 >= pos.maxScrollExtent &&
        !n.isLoading(n.currentTab) &&
        n.hasMore(n.currentTab)) {
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
          SliverToBoxAdapter(child: _StoriesRow(users: n.recommendUsers)),
          SliverToBoxAdapter(
            child: _RecommendUsersSection(
              users: n.recommendUsers,
              loading: n.recommendUsersLoading,
              isFollowing: n.isFollowing,
              onToggleFollow: (uid) => _toggleFollow(context, n, uid),
              onMore: () => _onTapRecommendMore(context),
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
                return _FeedCard(
                  key: ValueKey(post.postId),
                  post: post,
                  showAuthorFollowButton:
                      n.currentUserUid == null ||
                      post.author.uid != n.currentUserUid,
                  isAuthorFollowed: n.isFollowing(
                    post.author.uid,
                    fallback: post.author.isFollowing ?? false,
                  ),
                  onToggleAuthorFollow: () =>
                      _toggleFollow(context, n, post.author.uid),
                  onToggleLike: () => _onToggleLike(context, n, post),
                );
              },
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
            ),
        ],
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
                onPressed: () => MyToast.showText(
                    text: 'homeNotificationsComingSoon'.tr()),
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
              ),
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
  const _StoriesRow({required this.users});

  final List<RecommendedUser> users;

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
            return _StoryAvatar(user: user, showDot: showDot);
          },
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  const _StoryAvatar({required this.user, required this.showDot});

  final RecommendedUser user;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
  });

  final List<RecommendedUser> users;
  final bool loading;
  final bool Function(int uid, {bool fallback}) isFollowing;
  final ValueChanged<int> onToggleFollow;
  final VoidCallback onMore;

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
  });

  final RecommendedUser user;
  final bool isFollowing;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
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
          Container(
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
                border: isFollowing
                    ? Border.all(color: const Color(0xFFCCCCCC), width: 1)
                    : null,
                borderRadius: BorderRadius.circular(99.r),
              ),
              child: Text(
                isFollowing ? 'commonFollowed'.tr() : 'commonFollow'.tr(),
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color:
                      isFollowing ? const Color(0xFF1A1F2C) : Colors.white,
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
// Feed card（单条帖子）
// ──────────────────────────────────────────────────────────────────────

class _FeedCard extends StatefulWidget {
  const _FeedCard({
    super.key,
    required this.post,
    required this.showAuthorFollowButton,
    required this.isAuthorFollowed,
    required this.onToggleAuthorFollow,
    required this.onToggleLike,
  });

  final FeedPost post;
  final bool showAuthorFollowButton;
  final bool isAuthorFollowed;
  final VoidCallback onToggleAuthorFollow;
  final VoidCallback onToggleLike;

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant _FeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.postId != widget.post.postId) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(post),
          if (post.images.isNotEmpty) _buildImages(post.images),
          _buildActionsBar(post),
          _buildContent(post),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  Widget _buildHeader(FeedPost post) {
    final author = post.author;
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 10.h),
      child: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE2E5EB),
            ),
            child: ClipOval(
              child: author.avatarUrl.isNotEmpty
                  ? MyImage.network(author.avatarUrl, fit: BoxFit.cover)
                  : Image.asset(
                      MyImagePaths.defaultHeader,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author.nickname.isNotEmpty
                      ? author.nickname
                      : 'homeAnonymousAuthor'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1F2C),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _formatRelativeTime(post.createdAt),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF8C95A8),
                  ),
                ),
              ],
            ),
          ),
          if (widget.showAuthorFollowButton)
            GestureDetector(
              onTap: widget.onToggleAuthorFollow,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 74.w,
                height: 30.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.isAuthorFollowed
                      ? Colors.transparent
                      : const Color(0xFF1A1F2C),
                  border: widget.isAuthorFollowed
                      ? Border.all(color: const Color(0xFFCCCCCC), width: 1)
                      : null,
                  borderRadius: BorderRadius.circular(99.r),
                ),
                child: Text(
                  widget.isAuthorFollowed
                      ? 'commonFollowed'.tr()
                      : 'commonFollow'.tr(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: widget.isAuthorFollowed
                        ? const Color(0xFF1A1F2C)
                        : Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImages(List<FeedImage> images) {
    final controller = PageController();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: AspectRatio(
          aspectRatio: _safeAspectRatio(images.first.aspectRatio),
          child: Stack(
            children: [
              PageView.builder(
                controller: controller,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return MyImage.network(
                    images[index].url,
                    fit: BoxFit.cover,
                  );
                },
              ),
              if (images.length > 1)
                Positioned(
                  right: 8.w,
                  top: 8.h,
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      // 控制器尚未 attach 时 page == null。
                      final raw = controller.hasClients ? controller.page : 0.0;
                      final page = (raw ?? 0).round();
                      return Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 7.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${page + 1}/${images.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsBar(FeedPost post) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 8.h),
      child: Row(
        children: [
          _ActionItem(
            icon: post.isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            iconColor:
                post.isLiked ? const Color(0xFFFF3B30) : const Color(0xFF1A1F2C),
            label: CommonUtils.renderEnFixedNumber(post.likeCount).toString(),
            onTap: widget.onToggleLike,
          ),
          SizedBox(width: 20.w),
          _ActionItem(
            icon: Icons.mode_comment_outlined,
            iconColor: const Color(0xFF1A1F2C),
            label:
                CommonUtils.renderEnFixedNumber(post.commentCount).toString(),
            onTap: () =>
                MyToast.showText(text: 'homeCommentsComingSoon'.tr()),
          ),
          SizedBox(width: 20.w),
          _ActionItem(
            icon: Icons.share_outlined,
            iconColor: const Color(0xFF1A1F2C),
            label: CommonUtils.renderEnFixedNumber(post.shareCount).toString(),
            onTap: () => MyToast.showText(text: 'homeShareComingSoon'.tr()),
          ),
          const Spacer(),
          IconButton(
            iconSize: 21.sp,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () =>
                MyToast.showText(text: 'homeFavoriteComingSoon'.tr()),
            icon: Icon(Icons.star_border_rounded,
                color: const Color(0xFF1A1F2C)),
          ),
          SizedBox(width: 14.w),
          IconButton(
            iconSize: 18.sp,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () =>
                MyToast.showText(text: 'homePostMoreComingSoon'.tr()),
            icon: Icon(Icons.more_vert_rounded,
                color: const Color(0xFF8C95A8)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(FeedPost post) {
    final hasContent = post.content.isNotEmpty;
    final hasLocation = post.location.isNotEmpty;
    final tagText = post.tags.isEmpty
        ? ''
        : post.tags.map((t) => '#$t').join(' ');

    if (tagText.isEmpty && !hasContent) {
      if (!hasLocation) return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spans = _postBodySpans(
            context,
            tagText: tagText,
            content: post.content,
          );
          final exceedsTwo = spans.isEmpty
              ? false
              : _richTextExceedsMaxLines(
                  context,
                  constraints.maxWidth,
                  spans,
                  maxLines: 2,
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tagText.isNotEmpty || hasContent)
                Text.rich(
                  TextSpan(children: spans),
                  maxLines: _expanded ? null : 2,
                  overflow:
                      _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
              if (hasLocation || exceedsTwo)
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Row(
                    children: [
                      if (hasLocation) ...[
                        Icon(
                          Icons.location_on_outlined,
                          size: 13.sp,
                          color: const Color(0xFF62748E),
                        ),
                        SizedBox(width: 2.w),
                        Flexible(
                          child: Text(
                            post.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF62748E),
                            ),
                          ),
                        ),
                      ],
                      if (hasLocation && exceedsTwo) const Spacer(),
                      if (!hasLocation && exceedsTwo) const Spacer(),
                      if (exceedsTwo)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () =>
                              setState(() => _expanded = !_expanded),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 2.w, vertical: 4.h),
                            child: Text(
                              _expanded
                                  ? 'homeCollapse'.tr()
                                  : 'homeExpand'.tr(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF1A1F2C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  double _safeAspectRatio(double raw) {
    // 多图列表中第一张高度作为视图基准；过窄/过高会破坏卡片比例，做下钳制。
    if (raw.isNaN || raw <= 0) return 4 / 3;
    return raw.clamp(0.6, 1.6);
  }

  String _formatRelativeTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.isNegative) return 'homeJustNow'.tr();
    if (diff.inMinutes < 1) return 'homeJustNow'.tr();
    if (diff.inMinutes < 60) {
      return 'homeMinutesAgo'.tr(namedArgs: {'n': '${diff.inMinutes}'});
    }
    if (diff.inHours < 24) {
      return 'homeHoursAgo'.tr(namedArgs: {'n': '${diff.inHours}'});
    }
    if (diff.inDays < 30) {
      return 'homeDaysAgo'.tr(namedArgs: {'n': '${diff.inDays}'});
    }
    final months = (diff.inDays / 30).floor();
    if (months < 12) {
      return 'homeMonthsAgo'.tr(namedArgs: {'n': '$months'});
    }
    final years = (diff.inDays / 365).floor();
    return 'homeYearsAgo'.tr(namedArgs: {'n': '$years'});
  }

  List<InlineSpan> _postBodySpans(
    BuildContext context, {
    required String tagText,
    required String content,
  }) {
    final spans = <InlineSpan>[];
    if (tagText.isNotEmpty) {
      spans.add(TextSpan(
        text: tagText,
        style: TextStyle(
          color: const Color(0xFF1A1F2C),
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),
      ));
      if (content.isNotEmpty) spans.add(const TextSpan(text: ' '));
    }
    if (content.isNotEmpty) {
      spans.add(TextSpan(
        text: content,
        style: TextStyle(
          color: const Color(0xFF1A1F2C),
          fontSize: 13.sp,
          height: 1.45,
        ),
      ));
    }
    return spans;
  }

  bool _richTextExceedsMaxLines(
    BuildContext context,
    double maxWidth,
    List<InlineSpan> spans, {
    required int maxLines,
  }) {
    if (spans.isEmpty || maxWidth <= 0) return false;
    final painter = TextPainter(
      text: TextSpan(children: spans),
      textDirection: Directionality.of(context),
      maxLines: maxLines,
      textScaler: MediaQuery.textScalerOf(context),
      ellipsis: '…',
    );
    painter.layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 21.sp, color: iconColor),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1F2C),
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
            Icon(Icons.inbox_outlined,
                size: 56.sp, color: const Color(0xFFCFD3DC)),
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
