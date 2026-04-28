import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/notifier/profile_notifier.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> with WidgetsBindingObserver {
  late final List<RefreshController> _refreshControllers =
      List<RefreshController>.generate(
    3,
    (_) => RefreshController(initialRefresh: false),
  );

  /// VisibilityDetector 需要一个稳定的 key 才能正确派发 onVisibilityChanged，
  /// 用 widget 路径做 key 即可。
  static const _visibilityKey = ValueKey<String>('mine-page-visibility');

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
    if (state == AppLifecycleState.resumed && _wasVisible) {
      _notifier?.refreshIfStale();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) {
            final n = ProfileNotifier(ctx.read<ProfileDomain>())
              ..bootstrapMineProfile();
            _notifier = n;
            return n;
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        body: VisibilityDetector(
          key: _visibilityKey,
          onVisibilityChanged: (info) {
            // 阈值 50%：bottomNav 切换造成的 dispose-and-rebuild、半遮挡都不算
            // "重新可见"，避免和 [bootstrapMineProfile] 的首次拉取重复。
            final visible = info.visibleFraction >= 0.5;
            if (visible && !_wasVisible) {
              _notifier?.refreshIfStale();
            }
            _wasVisible = visible;
          },
          child: Consumer<ProfileNotifier>(builder: (context, notifier, _) {
          final profile =
              context.select<ProfileNotifier, UserProfile?>((n) => n.profile) ??
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
          return Stack(
            children: [
              Column(
                children: [
                  _buildHeaderProfileSection(context, profile, notifier),
                  Expanded(
                    child: DefaultTabController(
                      length: 3,
                      initialIndex: notifier.tabIndex,
                      child: Column(
                        children: [
                          _buildTabs(notifier),
                          Expanded(
                            child: TabBarView(
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _buildMediaTab(
                                  notifier,
                                  tabIndex: 0,
                                  initialLoading: notifier.loadingProfile &&
                                      notifier.profile == null,
                                ),
                                _buildMediaTab(
                                  notifier,
                                  tabIndex: 1,
                                  initialLoading: notifier.loadingProfile &&
                                      notifier.profile == null,
                                ),
                                _buildMediaTab(
                                  notifier,
                                  tabIndex: 2,
                                  initialLoading: notifier.loadingProfile &&
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
                _navSquare(MyImagePaths.appBackIcon),
                _navSquare(MyImagePaths.settings),
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
      child: Image.asset(icon, color: Colors.white, width: 19.w, height: 19.w,),
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
              GestureDetector(
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
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.w),
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
              ),
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
              _metricItem(profile.followerCountDisplay, 'mineFansCount'.tr()),
              SizedBox(width: 25.w),
              _metricItem(
                  profile.followingCountDisplay, 'mineFollowCount'.tr()),
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

  Widget _metricItem(String value, String label) {
    return Row(
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
        await notifier.fetchMineProfileAndVideos();
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
    if (notifier.loadingVideos &&
        ((isVideos && notifier.videos.isEmpty) ||
            (!isVideos && postLikeItems.isEmpty))) {
      return const Center(child: CircularProgressIndicator());
    }
    if ((isVideos && notifier.videos.isEmpty) ||
        (!isVideos && postLikeItems.isEmpty)) {
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
      itemCount: isVideos ? notifier.videos.length : postLikeItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.74,
      ),
      itemBuilder: (_, i) {
        final coverUrl =
            isVideos ? notifier.videos[i].coverUrl : postLikeItems[i].coverUrl;
        final countText = isVideos
            ? '${notifier.videos[i].playCount}'
            : '${postLikeItems[i].likeCount}';
        return Stack(
          fit: StackFit.expand,
          children: [
            if (coverUrl.isNotEmpty)
              MyImage.network(coverUrl, fit: BoxFit.cover, placeHolder: null)
            else
              Container(color: const Color(0xFFE5E7ED)),
            Positioned(
              right: 5.w,
              bottom: 5.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(4.w),
                ),
                child: Text(
                  countText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
