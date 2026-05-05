import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/data_layer/repo/repo.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/domains/video_feed.dart';
import 'package:g_link/domain/model/video_feed_models.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/page/short_video/widgets/not_interested_sheet.dart';
import 'package:g_link/ui_layer/page/short_video/widgets/short_video_toast.dart';
import 'package:g_link/ui_layer/widgets/app_bottom_sheet.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:provider/provider.dart';
import '../../router/routes.dart';
import 'widgets/comment_section.dart';
import 'widgets/music_sheet.dart';
import 'widgets/share_sheet.dart';
import 'widgets/video_card.dart';
import 'widgets/video_top_bar.dart';

class ShortVideoPage extends StatefulWidget {
  const ShortVideoPage({super.key});

  @override
  State<ShortVideoPage> createState() => _ShortVideoPageState();
}

class _ShortVideoPageState extends State<ShortVideoPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  int _tabIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this, initialIndex: _tabIndex);
    _tabCtrl.addListener(() {
      if (_tabCtrl.indexIsChanging) return;
      setState(() => _tabIndex = _tabCtrl.index);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: _tabIndex,
                children: const [
                  _ShortVideoTabPage(tab: 'follow'),
                  _ShortVideoTabPage(tab: 'recommend'),
                  _ShortVideoTabPage(tab: 'nearby'),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: VideoTopBar(tabCtrl: _tabCtrl),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortVideoTabPage extends StatefulWidget {
  const _ShortVideoTabPage({required this.tab});

  final String tab;

  @override
  State<_ShortVideoTabPage> createState() => _ShortVideoTabPageState();
}

class _ShortVideoTabPageState extends State<_ShortVideoTabPage>
    with AutomaticKeepAliveClientMixin {
  final PageController _pageCtrl = PageController();
  final _FeedTabState _tabState = _FeedTabState();
  final Map<int, VideoFeedItem> _detailCache = {};
  final Set<int> _loadingDetailIds = {};
  int _activeIndex = 0;

  List<VideoFeedItem> get _videos => _tabState.videos;

  @override
  void initState() {
    super.initState();
    _loadTab();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadTab({bool refresh = false}) async {
    if (_tabState.loading) return;
    if (!refresh && _tabState.loaded) return;

    setState(() => _tabState.loading = true);
    try {
      final result = await context.read<VideoFeedDomain>().getVideoFeed(
            tab: widget.tab,
            cursor: refresh ? null : _tabState.nextCursor,
          );
      if (!mounted) return;
      setState(() {
        _tabState.loading = false;
        _tabState.loaded = true;
        _tabState.hasMore = result.hasMore;
        _tabState.nextCursor = result.nextCursor;
        _tabState.videos =
            refresh ? result.items : [..._tabState.videos, ...result.items];
      });
      if (_tabState.videos.isNotEmpty) {
        _requestVideoDetail(_tabState
            .videos[_activeIndex.clamp(0, _tabState.videos.length - 1)].id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _tabState.loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_tabState.loading || !_tabState.hasMore || _tabState.nextCursor == null)
      return;
    final cursor = _tabState.nextCursor;
    final beforeCount = _tabState.videos.length;
    await _loadTab();
    if (mounted &&
        cursor == _tabState.nextCursor &&
        beforeCount == _tabState.videos.length) {
      setState(() => _tabState.hasMore = false);
    }
  }

  Future<void> _requestVideoDetail(int videoId) async {
    if (_detailCache.containsKey(videoId) ||
        _loadingDetailIds.contains(videoId)) return;
    _loadingDetailIds.add(videoId);
    if (mounted) setState(() {});
    try {
      final detail =
          await context.read<VideoFeedDomain>().getVideoDetail(videoId);
      if (!mounted) return;
      setState(() {
        _detailCache[videoId] = detail;
        final index = _tabState.videos.indexWhere((e) => e.id == videoId);
        if (index != -1) _tabState.videos[index] = detail;
      });
    } catch (_) {
    } finally {
      _loadingDetailIds.remove(videoId);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final videos = _videos;
    return Stack(
      children: [
        if (_tabState.loading && videos.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (videos.isEmpty)
          const Center(child: CircularProgressIndicator())
        else
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 80) {
                _loadMore();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageCtrl,
              scrollDirection: Axis.vertical,
              itemCount: videos.length,
              onPageChanged: (index) {
                _activeIndex = index;
                _requestVideoDetail(videos[index].id);
                setState(() {});
              },
              itemBuilder: (_, i) => VideoCard(
                item: videos[i],
                isFollowing: false,
                isFavorited: videos[i].isFavorited,
                isMuted: false,
                isCurrentPage: i == _activeIndex,
                isDetailLoading: _loadingDetailIds.contains(videos[i].id),
                onToggleFollow: () => _toggleFollow(videos[i]),
                onToggleLike: () => _toggleLike(videos[i]),
                onToggleFavorite: () => _toggleFavorite(videos[i]),
                onToggleMute: () {},
                onMore: () => _onMore(i),
                onShare: _openShare,
                onComment: () => _openComment(i),
                onExpandTap: () => _openDesc(i),
                onMusicTap: () => _openMusic(i),
              ),
            ),
          ),
      ],
    );
  }

  void _openMusic(int i) {
    MusicSheet.show(context, musicText: _videos[i].videoUrl);
  }

  Future<void> _openDesc(int i) async {
    final item = _videos[i];
    await AppBottomSheet.show(
      context: context,
      child: Column(
        children: [
          CommentContent(
            authorName: item.author.nickname.isNotEmpty
                ? item.author.nickname
                : item.author.username,
            showTitle: false,
            scrollTopChild: _buildDescHeader(item),
          ),
        ],
      ),
    );
  }

  Widget _buildDescHeader(VideoFeedItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF444444),
                border: Border.all(color: Colors.white, width: 2.w),
              ),
              child: item.author.avatarUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(item.author.avatarUrl,
                          fit: BoxFit.cover))
                  : Icon(Icons.person, color: Colors.white, size: 26.sp),
            ),
            SizedBox(width: 6.w),
            Text(item.title,
                style: TextStyle(
                    color: const Color(0xFF1A1F2C),
                    fontSize: 16.w,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 8.w),
                decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2C),
                    borderRadius: BorderRadius.circular(100.w)),
                child: Text('关注',
                    style: TextStyle(
                        color: const Color(0xFFF8F9FE),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.w),
        Wrap(
          spacing: 6.w,
          children: item.tags
              .map((t) => Text(t,
                  style: TextStyle(
                      color: const Color(0xFF1A1F2C),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600)))
              .toList(),
        ),
        SizedBox(height: 2.w),
        Text(item.description,
            style: TextStyle(color: const Color(0xFF62748E), fontSize: 14.sp)),
        SizedBox(height: 10.w),
        Row(
          children: [
            _buildDescChip(
                MyImagePaths.iconDescLocate,
                item.author.username.isNotEmpty
                    ? '@${item.author.username}'
                    : ''),
            SizedBox(width: 10.w),
            _buildDescChip(MyImagePaths.iconDescMusical, item.videoUrl),
          ],
        ),
        SizedBox(height: 10.w),
        Text('2月4日',
            style: TextStyle(
                color: const Color(0xFF90A1B9),
                fontWeight: FontWeight.w500,
                fontSize: 12.w)),
        SizedBox(height: 10.w),
        Divider(color: const Color(0xFFF8F9FE), thickness: 1.w),
        SizedBox(height: 16.w),
      ],
    );
  }

  Widget _buildDescChip(String iconPath, String label) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFFE3E7ED),
          borderRadius: BorderRadius.circular(30.w)),
      padding: EdgeInsets.only(left: 6.w, top: 5.w, bottom: 5.w, right: 6.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MyImage.asset(iconPath, width: 16.w),
          SizedBox(width: 3.w),
          Flexible(
            child: Text(label,
                style: TextStyle(
                    color: const Color(0xFF45556C),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Future<void> _onMore(int i) async {
    const speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
    await AppBottomSheet.show(
      context: context,
      blurSigma: 22.1,
      showHandle: false,
      decoration: BoxDecoration(
          color: const Color(0xE51B1C1F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.w))),
      child: StatefulBuilder(
        builder: (_, setModalState) => Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              _buildMoreCard([
                _buildMoreItem(
                    MyImage.asset(MyImagePaths.iconClearScreen, width: 18.w),
                    'shortVideoMoreClearScreen'.tr(),
                    const SizedBox(),
                    () {}),
                _buildMoreItem(
                    MyImage.asset(MyImagePaths.iconDowload, width: 18.w),
                    'shortVideoMoreCache'.tr(),
                    const SizedBox(), () {
                  Navigator.of(context, rootNavigator: true).pop();
                  ShortVideoToast.show(context,
                      icon:
                          MyImage.asset(MyImagePaths.iconSuccess, width: 22.w),
                      title: 'shortVideoToastCached'.tr(),
                      onTap: () {});
                }),
                _buildMoreItem(
                  MyImage.asset(MyImagePaths.iconSpeed, width: 18.w),
                  'shortVideoMoreSpeed'.tr(),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(width: 10.w),
                        ...speeds.map((s) {
                          final selected = s == _speedFor(index: i);
                          final label = s == s.truncateToDouble()
                              ? '${s.toInt()}x'
                              : '${s}x';
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _speedFor(index: i, value: s);
                                setModalState(() {});
                              },
                              child: Text(label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: selected
                                          ? const Color(0xFFF8F9FE)
                                          : const Color(0xFF999999),
                                      fontSize: 12.sp,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w500)),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  () {},
                ),
              ]),
              SizedBox(height: 20.w),
              _buildMoreCard([
                _buildMoreItem(
                    MyImage.asset(MyImagePaths.iconNotInterested, width: 18.w),
                    'shortVideoMoreNotInterested'.tr(),
                    const SizedBox(), () {
                  Navigator.of(context, rootNavigator: true).pop();
                  AppBottomSheet.show(
                      context: context,
                      child: NotInterestedSheet(item: _videos[i]));
                }),
                _buildMoreItem(
                    MyImage.asset(MyImagePaths.iconReport, width: 18.w),
                    'shortVideoReport'.tr(),
                    const SizedBox(),
                    () => const ComplaintRoute(targetId: 1, targetType: 'video')
                        .push(context)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  final Map<int, double> _speedMap = {};
  double _speedFor({required int index, double? value}) {
    if (value != null) _speedMap[index] = value;
    return _speedMap[index] ?? 1.0;
  }

  Widget _buildMoreCard(List<Widget> items) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.w),
      decoration: BoxDecoration(
          color: const Color(0xB2232529),
          borderRadius: BorderRadius.circular(10.w)),
      child: Column(children: items),
    );
  }

  Widget _buildMoreItem(
      Widget icon, String title, Widget trailing, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.w),
        child: Row(children: [
          icon,
          SizedBox(width: 12.w),
          Text(title,
              style: TextStyle(
                  color: const Color(0xFFF8F9FE),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500)),
          trailing
        ]),
      ),
    );
  }

  Future<void> _openComment(int i) async {
    final item = _videos[i];
    await AppBottomSheet.show(
        context: context,
        child:
            CommentContent(authorName: item.author.nickname, showTitle: true));
  }

  Future<void> _toggleFollow(VideoFeedItem item) async {
    final repo = context.read<AppRepo>();
    final uid = item.author.uid;
    if (uid <= 0) return;
    try {
      await repo.followUser(uid: uid);
      if (!mounted) return;
      setState(() {});
      ShortVideoToast.show(
        context,
        icon: MyImage.asset(MyImagePaths.iconSuccess, width: 22.w),
        title: '关注成功',
        onTap: () {},
      );
    } catch (_) {
      if (!mounted) return;
    }
  }

  Future<void> _toggleLike(VideoFeedItem item) async {
    try {
      final result = item.isLiked
          ? await context.read<VideoFeedDomain>().unlikeVideo(item.id)
          : await context.read<VideoFeedDomain>().likeVideo(item.id);
      final index = _videos.indexWhere((e) => e.id == item.id);
      if (index == -1) return;
      setState(() {
        _videos[index] = VideoFeedItem(
          id: item.id,
          author: item.author,
          title: item.title,
          description: item.description,
          coverUrl: item.coverUrl,
          videoUrl: item.videoUrl,
          durationMs: item.durationMs,
          width: item.width,
          height: item.height,
          tags: item.tags,
          isLiked: result.liked,
          isFavorited: item.isFavorited,
          stats: VideoFeedStats(
            playCount: item.stats.playCount,
            likeCount: result.likeCount,
            commentCount: item.stats.commentCount,
            favoriteCount: item.stats.favoriteCount,
            shareCount: item.stats.shareCount,
          ),
          publishedAt: item.publishedAt,
        );
      });
    } catch (_) {
      ShortVideoToast.show(
        context,
        icon: MyImage.asset(MyImagePaths.iconSuccess, width: 22.w),
        title: '点赞失败',
        onTap: () {},
      );
    }
  }

  Future<void> _toggleFavorite(VideoFeedItem item) async {
    try {
      final result = item.isFavorited
          ? await context.read<VideoFeedDomain>().unfavoriteVideo(item.id)
          : await context.read<VideoFeedDomain>().favoriteVideo(item.id);
      final index = _videos.indexWhere((e) => e.id == item.id);
      if (index == -1) return;
      setState(() {
        _videos[index] = VideoFeedItem(
          id: item.id,
          author: item.author,
          title: item.title,
          description: item.description,
          coverUrl: item.coverUrl,
          videoUrl: item.videoUrl,
          durationMs: item.durationMs,
          width: item.width,
          height: item.height,
          tags: item.tags,
          isLiked: item.isLiked,
          isFavorited: result.isFavorited,
          stats: VideoFeedStats(
            playCount: item.stats.playCount,
            likeCount: item.stats.likeCount,
            commentCount: item.stats.commentCount,
            favoriteCount: result.favoriteCount,
            shareCount: item.stats.shareCount,
          ),
          publishedAt: item.publishedAt,
        );
      });
    } catch (_) {
      ShortVideoToast.show(
        context,
        icon: MyImage.asset(MyImagePaths.iconSuccess, width: 22.w),
        title: '收藏失败',
        onTap: () {},
      );
    }
  }

  void _replaceVideo(VideoFeedItem updated) {
    final index = _videos.indexWhere((e) => e.id == updated.id);
    if (index == -1) return;
    setState(() {
      _videos[index] = updated;
    });
  }

  Future<void> _openShare() async {
    await AppBottomSheet.show(context: context, child: const ShareSheet());
  }
}

class _FeedTabState {
  List<VideoFeedItem> videos = [];
  String? nextCursor;
  bool hasMore = true;
  bool loading = false;
  bool loaded = false;
}
