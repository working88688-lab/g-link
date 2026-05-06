import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/ui_layer/notifier/user_posts_notifier.dart';
import 'package:g_link/ui_layer/widgets/feed_post_card.dart';
import 'package:provider/provider.dart';

/// 用户最新帖子列表页（截图：← + 「最新帖子」标题 + 第一张大卡 + 「更早之前帖子」分隔
/// 后展示其余卡片）。
///
/// 数据：`GET /api/v1/users/{uid}/posts`（[ProfileDomain.getUserPostsFeed]），
/// cursor 翻页，下拉刷新强刷，触底翻下一页。整体复用 [FeedPostCard] 与首页帖子流
/// 同一份卡片视觉，避免风格分裂。
class UserPostsPage extends StatefulWidget {
  const UserPostsPage({super.key, required this.uid});

  final int uid;

  @override
  State<UserPostsPage> createState() => _UserPostsPageState();
}

class _UserPostsPageState extends State<UserPostsPage> {
  final ScrollController _scrollCtrl = ScrollController();
  UserPostsNotifier? _notifier;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// 距底 240px 之内开始预加载下一页，让滚动体感保持平顺、不出现明显加载条停顿。
  void _onScroll() {
    final n = _notifier;
    if (n == null) return;
    if (!_scrollCtrl.hasClients) return;
    final remaining =
        _scrollCtrl.position.maxScrollExtent - _scrollCtrl.position.pixels;
    if (remaining <= 240) {
      n.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserPostsNotifier>(
      create: (ctx) {
        final n = UserPostsNotifier(
          uid: widget.uid,
          profileDomain: ctx.read<ProfileDomain>(),
        )..load();
        _notifier = n;
        return n;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: _buildAppBar(),
        body: Consumer<UserPostsNotifier>(
          builder: (context, n, _) {
            if (n.loading && n.posts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (n.posts.isEmpty) {
              return RefreshIndicator(
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
            return RefreshIndicator(
              onRefresh: n.refresh,
              child: ListView.builder(
                controller: _scrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
                // 行结构（贴 1:1 设计稿）：
                //   index 0      → 第一条帖子（最新一条）
                //   index 1      → 「更早之前帖子」分隔（仅当还有第二条时展示）
                //   index 2..N-1 → 其余帖子
                //   index N      → footer（loading / no-more）
                itemCount: () {
                  final posts = n.posts.length;
                  if (posts <= 1) return posts + 1;
                  return posts + 2;
                }(),
                itemBuilder: (context, index) {
                  final posts = n.posts;
                  final hasDivider = posts.length > 1;
                  if (index == 0) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: FeedPostCard(
                        key: ValueKey('user-post-${posts[0].postId}'),
                        post: posts[0],
                        showAuthorFollowButton: false,
                      ),
                    );
                  }
                  if (hasDivider && index == 1) {
                    return _buildEarlierDivider();
                  }
                  final realIndex = hasDivider ? index - 1 : index;
                  if (realIndex < posts.length) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: FeedPostCard(
                        key: ValueKey('user-post-${posts[realIndex].postId}'),
                        post: posts[realIndex],
                        showAuthorFollowButton: false,
                      ),
                    );
                  }
                  // footer
                  return _buildFooter(n);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
        'userPostsTitle'.tr(),
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
