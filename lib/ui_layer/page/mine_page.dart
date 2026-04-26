import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/notifier/profile_notifier.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:provider/provider.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => ProfileNotifier(ctx.read<ProfileDomain>())
            ..fetchMineProfileAndVideos(),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Consumer<ProfileNotifier>(builder: (context, notifier, _) {
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
              RefreshIndicator(
                onRefresh: () => notifier.fetchMineProfileAndVideos(),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeader(context, profile),
                    ),
                    SliverToBoxAdapter(
                      child: _buildProfileCard(context, profile, notifier),
                    ),
                    SliverToBoxAdapter(
                      child: _buildTabs(notifier),
                    ),
                    _buildMediaContent(
                      notifier,
                      initialLoading:
                          notifier.loadingProfile && notifier.profile == null,
                    ),
                  ],
                ),
              ),
              if (notifier.loadingProfile && notifier.profile == null)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    UserProfile profile,
  ) {
    final cover = profile.coverUrl;
    return SizedBox(
      height: 220.w,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cover.isNotEmpty)
            MyImage.network(cover, fit: BoxFit.cover, placeHolder: null)
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF0F3F8),
                    Color(0xFFE2E7F0),
                    Color(0xFFD6DDE9),
                  ],
                ),
              ),
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 6.w,
            left: 14.w,
            right: 14.w,
            child: Row(
              children: [
                _navSquare(Icons.arrow_back_ios_new_rounded),
                const Spacer(),
                _navSquare(Icons.camera_alt_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navSquare(IconData icon) {
    return Container(
      width: 38.w,
      height: 38.w,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10.w),
      ),
      child: Icon(icon, color: Colors.white, size: 19.w),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    UserProfile profile,
    ProfileNotifier notifier,
  ) {
    return Transform.translate(
      offset: Offset(0, -20.w),
      child: Container(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(22.w),
            topRight: Radius.circular(22.w),
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 2.w),
                  width: 74.w,
                  height: 74.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEFF4),
                    borderRadius: BorderRadius.circular(37.w),
                    border: Border.all(color: Colors.white, width: 2.w),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: profile.avatarUrl.isNotEmpty
                      ? MyImage.network(profile.avatarUrl, fit: BoxFit.cover)
                      : MyImage.asset(MyImagePaths.logoGradient,
                          fit: BoxFit.cover),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 8.w),
                    child: Text(
                      profile.nickname.isNotEmpty
                          ? profile.nickname
                          : 'mineUserTitle'.tr(),
                      style: TextStyle(
                        color: const Color(0xFF141A2A),
                        fontSize: 34.sp * 0.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Container(
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
              ],
            ),
            SizedBox(height: 8.w),
            Row(
              children: [
                Text(
                  '@${profile.username}',
                  style: TextStyle(
                    color: const Color(0xFF5A6477),
                    fontSize: 16.sp * 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 12.w),
                Icon(Icons.place_rounded,
                    size: 16.w, color: const Color(0xFF5A6477)),
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
                      fontSize: 16.sp * 0.5,
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricItem(profile.postCountDisplay, 'minePostCount'.tr()),
                _metricItem(profile.followerCountDisplay, 'mineFansCount'.tr()),
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
      ),
    );
  }

  Widget _metricItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF151B2A),
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 2.w),
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
    Widget item(int index, IconData icon) {
      final active = notifier.tabIndex == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => notifier.changeTab(index),
          child: SizedBox(
            height: 44.w,
            child: Icon(
              icon,
              size: 23.w,
              color: active ? const Color(0xFF3A465D) : const Color(0xFF9AA2B1),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFEDF0F5), width: 1),
          bottom: BorderSide(color: Color(0xFFEDF0F5), width: 1),
        ),
      ),
      child: Row(
        children: [
          item(0, Icons.article_rounded),
          item(1, Icons.play_arrow_rounded),
          item(2, Icons.favorite_rounded),
        ],
      ),
    );
  }

  Widget _buildMediaContent(
    ProfileNotifier notifier, {
    required bool initialLoading,
  }) {
    if (initialLoading) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final isPosts = notifier.tabIndex == 0;
    final isVideos = notifier.tabIndex == 1;
    final postLikeItems = isPosts ? notifier.posts : notifier.likes;
    if (notifier.loadingVideos &&
        ((isVideos && notifier.videos.isEmpty) ||
            (!isVideos && postLikeItems.isEmpty))) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if ((isVideos && notifier.videos.isEmpty) ||
        (!isVideos && postLikeItems.isEmpty)) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 34.w),
          child: Center(
            child: Text(
              'messageEmpty'.tr(),
              style: TextStyle(color: const Color(0xFF8C95A4), fontSize: 13.sp),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: EdgeInsets.only(top: 2.w),
      sliver: SliverGrid.builder(
        itemCount: notifier.videos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 0.74,
        ),
        itemBuilder: (_, i) {
          final coverUrl = isVideos
              ? notifier.videos[i].coverUrl
              : postLikeItems[i].coverUrl;
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
      ),
    );
  }
}
