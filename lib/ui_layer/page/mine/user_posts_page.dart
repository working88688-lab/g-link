import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/feed.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/ui_layer/notifier/user_posts_notifier.dart';
// import 'package:g_link/ui_layer/page/mine/user_posts_seed.dart';
import 'package:g_link/ui_layer/widgets/feed_post_card.dart';
import 'package:g_link/utils/my_toast.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// 用户最新帖子列表页。
///
/// 数据默认：`GET /api/v1/users/{uid}/posts`（[ProfileDomain.getUserPostsFeed]）；
/// 若带 [listSeed]（从个人 / 他人主页「作品」网格进入），首屏直接复用网格同源数据，
/// 再按需 `GET /api/v1/posts/{id}` 合并当前帖详情；锚点滚动用
/// [ScrollablePositionedList] + [ItemScrollController.jumpTo]，避免 [ListView.builder]
/// 懒渲染导致屏外 [GlobalKey] 无 context、无法 [Scrollable.ensureVisible] 的问题。
class UserPostsPage extends StatefulWidget {
  const UserPostsPage({
    super.key,
    required this.uid,
    this.anchorPostId,
    // this.listSeed,
  });

  final int uid;
  final int? anchorPostId;
  // final UserPostsListSeed? listSeed;

  @override
  State<UserPostsPage> createState() => _UserPostsPageState();
}

class _UserPostsPageState extends State<UserPostsPage> {
  final ItemScrollController _itemScrollCtrl = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  UserPostsNotifier? _notifier;
  bool _anchorRoutineScheduled = false;
  bool _didScrollAnchor = false;

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_onItemPositions);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onItemPositions);
    super.dispose();
  }

  /// 与 [ListView.builder] 的 `itemCount` 规则一致。
  int _itemCountFor(int postsLength) {
    if (postsLength <= 1) return postsLength + 1;
    return postsLength + 2;
  }

  /// 将「第几个帖子」（0-based）映射到列表行下标（含「更早之前」分割行）。
  int _listIndexForPostIndex(int postIndex, int postsLength) {
    if (postIndex < 0 || postsLength <= 0 || postIndex >= postsLength) {
      return -1;
    }
    if (postsLength == 1) return 0;
    if (postIndex == 0) return 0;
    return postIndex + 1;
  }

  void _onItemPositions() {
    final n = _notifier;
    if (n == null || n.posts.isEmpty) return;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final maxIdx = positions.map((p) => p.index).reduce(math.max);
    final count = _itemCountFor(n.posts.length);
    if (maxIdx >= count - 2) {
      n.loadMore();
    }
  }

  void _scheduleAnchorRoutineIfNeeded(UserPostsNotifier n) {
    if (_anchorRoutineScheduled) return;
    if (widget.anchorPostId == null) return;
    if (n.posts.isEmpty) return;
    _anchorRoutineScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _jumpAnchorWhenReady();
      _hydrateAnchorPost();
    });
  }

  void _jumpAnchorWhenReady() {
    final aid = widget.anchorPostId;
    final n = _notifier;
    if (aid == null || n == null || _didScrollAnchor) return;
    final ix = n.posts.indexWhere((p) => p.postId == aid);
    if (ix < 0) return;
    final listIndex = _listIndexForPostIndex(ix, n.posts.length);
    if (listIndex < 0) return;

    void attempt(int triesLeft) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didScrollAnchor) return;
        if (_itemScrollCtrl.isAttached) {
          _itemScrollCtrl.jumpTo(index: listIndex, alignment: 0.02);
          _didScrollAnchor = true;
        } else if (triesLeft > 0) {
          attempt(triesLeft - 1);
        }
      });
    }

    attempt(16);
  }

  Future<void> _hydrateAnchorPost() async {
    final aid = widget.anchorPostId;
    final n = _notifier;
    if (aid == null || n == null) return;

    final result = await context.read<FeedDomain>().getPostById(postId: aid);
    if (!mounted) return;
    if (result.status == 0 && result.data != null) {
      n.replacePostById(aid, result.data!);
    }
  }

  Future<void> _onToggleLike(
    BuildContext context,
    UserPostsNotifier n,
    int postId,
  ) async {
    final ok = await n.toggleLike(postId);
    if (!mounted || !context.mounted) return;
    if (!ok) {
      MyToast.showText(text: 'homeLikeFailed'.tr());
    }
  }

  Future<void> _onToggleFavorite(
    BuildContext context,
    UserPostsNotifier n,
    int postId,
  ) async {
    final ok = await n.toggleFavorite(postId);
    if (!mounted || !context.mounted) return;
    if (!ok) {
      MyToast.showText(text: 'homeFavoriteFailed'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserPostsNotifier>(
      create: (ctx) {
        final n = UserPostsNotifier(
          uid: widget.uid,
          profileDomain: ctx.read<ProfileDomain>(),
          feedDomain: ctx.read<FeedDomain>(),
          // listSeed: widget.listSeed,
        )..load();
        _notifier = n;
        return n;
      },
      child: Consumer<UserPostsNotifier>(
        builder: (context, n, _) {
          _scheduleAnchorRoutineIfNeeded(n);
          return Scaffold(
            backgroundColor: const Color(0xFFF6F7FB),
            appBar: _buildAppBar(n),
            body: _buildBody(context, n),
          );
        },
      ),
    );
  }

  /// 从外部带 [anchorPostId] 进入且锚定在第 2 条及以后时显示「帖子列表」；
  /// 无锚点、未找到锚点、或锚点在列表首位（最新一条）时显示「最新帖子」。
  String _appBarTitleKey(UserPostsNotifier n) {
    final aid = widget.anchorPostId;
    if (aid == null) return 'userPostsTitle';
    final ix = n.posts.indexWhere((p) => p.postId == aid);
    if (ix <= 0) return 'userPostsTitle';
    return 'userPostsListTitle';
  }

  Widget _buildBody(BuildContext context, UserPostsNotifier n) {
    if (n.loading && n.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (n.posts.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF1A1F2C),
        onRefresh: n.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 120.h),
            Center(
              child: Text(
                'userPostsEmpty'.tr(),
                style: TextStyle(
                  color: const Color(0xFF8C95A8),
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final posts = n.posts;
    final itemCount = _itemCountFor(posts.length);
    final hasDivider = posts.length > 1;

    return RefreshIndicator(
      color: const Color(0xFF1A1F2C),
      onRefresh: n.refresh,
      child: ScrollablePositionedList.builder(
        itemCount: itemCount,
        itemScrollController: _itemScrollCtrl,
        itemPositionsListener: _itemPositionsListener,
        padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        itemBuilder: (context, index) {
          if (index == 0) {
            final post = posts[0];
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: FeedPostCard(
                key: ValueKey('user-post-${post.postId}'),
                post: post,
                showAuthorFollowButton: false,
                onToggleLike: () => _onToggleLike(context, n, post.postId),
                onToggleFavorite: () =>
                    _onToggleFavorite(context, n, post.postId),
              ),
            );
          }
          if (hasDivider && index == 1) {
            return _buildEarlierDivider();
          }
          final realIndex = hasDivider ? index - 1 : index;
          if (realIndex < posts.length) {
            final post = posts[realIndex];
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: FeedPostCard(
                key: ValueKey('user-post-${post.postId}'),
                post: post,
                showAuthorFollowButton: false,
                onToggleLike: () => _onToggleLike(context, n, post.postId),
                onToggleFavorite: () =>
                    _onToggleFavorite(context, n, post.postId),
              ),
            );
          }
          return _buildFooter(n);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(UserPostsNotifier n) {
    return AppBar(
      backgroundColor: const Color(0xFFF6F7FB),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A1F2C), size: 18),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        _appBarTitleKey(n).tr(),
        style: TextStyle(
          color: const Color(0xFF1A1F2C),
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEarlierDivider() {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 8.h),
      child: Text(
        'userPostsEarlier'.tr(),
        style: TextStyle(
          color: const Color(0xFF8C95A8),
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFooter(UserPostsNotifier n) {
    if (n.loadingMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Center(
          child: SizedBox(
            width: 18.w,
            height: 18.w,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!n.hasMore && n.posts.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        child: Center(
          child: Text(
            '— —',
            style: TextStyle(color: const Color(0xFFB0B7C3), fontSize: 12.sp),
          ),
        ),
      );
    }
    return SizedBox(height: 12.h);
  }
}
