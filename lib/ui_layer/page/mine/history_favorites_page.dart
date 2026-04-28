import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';

import '../../widgets/app_confirm_dialog.dart';

// ──────────────────────────────────────────
// 模式：历史 or 收藏
// ──────────────────────────────────────────
enum HistoryFavoritesMode { history, favorites }

// ──────────────────────────────────────────
// 数据模型（纯 UI 骨架）
// ──────────────────────────────────────────
class _PostItem {
  final String id;
  final String authorName;
  final String authorAvatar;
  final String timeAgo;
  final String content;
  final String coverUrl;
  final int likeCount;
  final int commentCount;
  final int shareCount;

  const _PostItem({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.timeAgo,
    required this.content,
    required this.coverUrl,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
  });
}

class _VideoItem {
  final String id;
  final String coverUrl;
  final String duration;

  const _VideoItem({
    required this.id,
    required this.coverUrl,
    required this.duration,
  });
}

// ──────────────────────────────────────────
// 页面
// ──────────────────────────────────────────
class HistoryFavoritesPage extends StatefulWidget {
  const HistoryFavoritesPage({super.key, required this.mode});

  final HistoryFavoritesMode mode;

  @override
  State<HistoryFavoritesPage> createState() => _HistoryFavoritesPageState();
}

class _HistoryFavoritesPageState extends State<HistoryFavoritesPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _posts = List.generate(
    6,
    (i) => _PostItem(
      id: '$i',
      authorName: 'Sarah Jenks',
      authorAvatar: '',
      timeAgo: '2天前',
      content: '#拍照 #摄影 分享最近用得最顺手的拍照技术整理出来了，分享给大家...',
      coverUrl: '',
      likeCount: 1284,
      commentCount: 356,
      shareCount: 356,
    ),
  );

  final _videos = List.generate(
    9,
    (i) => _VideoItem(id: '$i', coverUrl: '', duration: '09:23'),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isHistory => widget.mode == HistoryFavoritesMode.history;

  String get _title => _isHistory ? 'historyTitle'.tr() : 'favoritesTitle'.tr();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20.w,
                color: const Color(0xFF1D293D),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _title,
              style: TextStyle(
                color: const Color(0xFF1D293D),
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              if (_isHistory)
                TextButton(
                  onPressed: _clearAll,
                  child: Text(
                    'historyClear'.tr(),
                    style: TextStyle(
                      color: const Color(0xFF45556C),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(43.w),
              child: _buildTabBar(),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsGrid(),
            _buildVideosGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final tabPosts = _isHistory ? 'historyTabPosts'.tr() : 'favoritesTabPosts'.tr();
    final tabVideos = _isHistory ? 'historyTabVideos'.tr() : 'favoritesTabVideos'.tr();

    return Container(
      color: Color(0xFFF8F9FE),
      padding: EdgeInsets.only(top: 3.w),
      child: Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          labelColor: const Color(0xFF1A1F2C),
          unselectedLabelColor: const Color(0xFF45556C),
          labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
          unselectedLabelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w400),
          indicatorColor: const Color(0xFF1A1F2C),
          indicatorWeight: 2.w,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(text: tabPosts),
            Tab(text: tabVideos),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsGrid() {
    if (_posts.isEmpty) {
      return _buildEmpty();
    }

    return GridView.builder(
      padding: EdgeInsets.all(4.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4.w,
        mainAxisSpacing: 4.w,
        childAspectRatio: 120 / 119,
      ),
      itemCount: _posts.length,
      itemBuilder: (_, i) => _PostCard(
        item: _posts[i],
        showFavoriteBadge: !_isHistory,
      ),
    );
  }

  Widget _buildVideosGrid() {
    if (_videos.isEmpty) {
      return _buildEmpty();
    }
    return GridView.builder(
      padding: EdgeInsets.all(4.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4.w,
        mainAxisSpacing: 4.w,
        childAspectRatio: 120 / 119,
      ),
      itemCount: _videos.length,
      itemBuilder: (_, i) => _VideoThumbnail(
        item: _videos[i],
        showFavoriteBadge: !_isHistory,
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        'messageEmpty'.tr(),
        style: TextStyle(
          color: const Color(0xFF8C95A4),
          fontSize: 14.sp,
        ),
      ),
    );
  }

  void _clearAll() {
    AppConfirmDialog.show(
      context: context,
      title: '全部清空？',
      content: '清空后，所有的帖子和短视频观看历史将全部消失',
      onConfirm: () {
        /* 执行操作 */
      },
    );
  }
}

// ──────────────────────────────────────────
// 帖子卡片
// ──────────────────────────────────────────
class _PostCard extends StatelessWidget {
  const _PostCard({required this.item, required this.showFavoriteBadge});

  final _PostItem item;
  final bool showFavoriteBadge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.black12,
          padding: EdgeInsets.all(14.w),
        ),
        if (showFavoriteBadge)
          Positioned(
            right: 5.w,
            top: 5.w,
            child: MyImage.asset(
              MyImagePaths.iconCollection,
              width: 20.w,
            ),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────
// 视频缩略图
// ──────────────────────────────────────────
class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({required this.item, required this.showFavoriteBadge});

  final _VideoItem item;
  final bool showFavoriteBadge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (item.coverUrl.isNotEmpty)
          MyImage.network(item.coverUrl, fit: BoxFit.cover, placeHolder: null)
        else
          Container(
            color: Colors.black12,
          ),
        // 时长
        Positioned(
          right: 6.w,
          bottom: 6.w,
          child: Container(
            padding: EdgeInsets.only(left: 2.w, top: 3.w, right: 4.w, bottom: 3.w),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Row(
              children: [
                MyImage.asset(
                  MyImagePaths.iconPlay,
                  width: 14.w,
                ),
                SizedBox(
                  width: 1.w,
                ),
                Text(
                  item.duration,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                )
              ],
            ),
          ),
        ),
        // 收藏标记
        if (showFavoriteBadge)
          Positioned(
            right: 5.w,
            top: 5.w,
            child: MyImage.asset(
              MyImagePaths.iconCollection,
              width: 20.w,
            ),
          ),
      ],
    );
  }
}
