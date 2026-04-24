import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/ui_layer/notifier/profile_notifier.dart';
import 'package:provider/provider.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MineNotifier()),
        ChangeNotifierProvider(
          create: (ctx) => ProfileNotifier(ctx.read<ProfileDomain>())
            ..fetchProfileAndVideos(uid: 5001),
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F1F5),
        body: Consumer<MineNotifier>(builder: (context, notifier, _) {
          final profile =
              context.select<ProfileNotifier, UserProfile?>((n) => n.profile);
          final videos = context
              .select<ProfileNotifier, List<UserVideoItem>>((n) => n.videos);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildTopHero(
                  context: context,
                  notifier: notifier,
                  profile: profile,
                  videos: videos,
                ),
              ),
              SliverToBoxAdapter(child: _buildProfileLoadStatus(context)),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: _buildTabs(),
                ),
              ),
              _buildMediaContent(context),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTopHero({
    required BuildContext context,
    required MineNotifier notifier,
    required UserProfile? profile,
    required List<UserVideoItem> videos,
  }) {
    final cover = videos.isNotEmpty ? videos.first.coverUrl : '';
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          SizedBox(
            height: 252,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (cover.isNotEmpty)
                  Image.network(
                    cover,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFF30333A)),
                  )
                else
                  Container(color: const Color(0xFF30333A)),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x55000000), Color(0xCC1B1E24)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 2,
            left: 8,
            right: 8,
            child: Row(
              children: [
                const SizedBox(width: 44, height: 44),
                const Spacer(),
                IconButton(
                  onPressed: () => context
                      .read<ProfileNotifier>()
                      .fetchProfileAndVideos(uid: 5001),
                  icon:
                      const Icon(Icons.settings_outlined, color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).padding.top + 54),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 37,
                  backgroundColor: Colors.white24,
                  backgroundImage: (profile?.avatarUrl.isNotEmpty == true)
                      ? NetworkImage(profile!.avatarUrl)
                      : const AssetImage('assets/images/logo_gradient.png')
                          as ImageProvider,
                ),
                const SizedBox(height: 10),
                Text(
                  profile?.nickname.isNotEmpty == true
                      ? profile!.nickname
                      : 'mineUserTitle'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile?.bio.isNotEmpty == true
                      ? profile!.bio
                      : notifier.signature(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xFFD3D7DF), fontSize: 12),
                ),
                const SizedBox(height: 14),
                _buildMetrics(context, notifier, profile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(
    BuildContext context,
    MineNotifier notifier,
    UserProfile? profile,
  ) {
    Widget item(String value, String title) {
      return Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(color: Color(0xFFC8CDD8), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          item('${profile?.videoCount ?? notifier.following}',
              'mineFollowCount'.tr()),
          item('${profile?.followerCount ?? notifier.followers}',
              'mineFansCount'.tr()),
          item(
              '${profile?.likeCount ?? notifier.likes}', 'mineLikesCount'.tr()),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 38,
      child: Row(
        children: [
          _buildTabItem(0, '帖子'),
          const SizedBox(width: 18),
          _buildTabItem(1, 'shortVideoTitle'.tr()),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    final active = _tabIndex == index;
    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: active ? const Color(0xFF22252D) : const Color(0xFF9AA2B1),
              fontSize: 15,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: 24,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF242933) : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    return Consumer<ProfileNotifier>(
      builder: (_, notifier, __) {
        if (notifier.loadingVideos) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (notifier.errorMessage != null && notifier.videos.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notifier.errorMessage!,
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context
                        .read<ProfileNotifier>()
                        .fetchProfileAndVideos(uid: 5001),
                    child: Text('commonRetry'.tr()),
                  ),
                ],
              ),
            ),
          );
        }

        if (_tabIndex == 0) {
          return SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Text(
                'messageEmpty'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8C95A4), fontSize: 13),
              ),
            ),
          );
        }

        if (notifier.videos.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Text(
                'messageEmpty'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8C95A4), fontSize: 13),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
          sliver: SliverGrid.builder(
            itemCount: notifier.videos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 0.74,
            ),
            itemBuilder: (_, i) {
              final video = notifier.videos[i];
              return ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: const Color(0xFFE5E7ED)),
                    if (video.coverUrl.isNotEmpty)
                      Image.network(video.coverUrl, fit: BoxFit.cover),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${video.playCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProfileLoadStatus(BuildContext context) {
    return Consumer<ProfileNotifier>(
      builder: (_, notifier, __) {
        if (!notifier.authExpired) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          padding: const EdgeInsets.all(10.5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4ED),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFB54708)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'mineAuthExpiredHint'.tr(),
                  style:
                      const TextStyle(color: Color(0xFF7A2E0E), fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MineNotifier extends ChangeNotifier {
  int following = 248;
  int followers = 1632;
  int likes = 8912;
  bool _useAltSignature = false;

  String signature(BuildContext context) =>
      _useAltSignature ? 'mineSignatureA'.tr() : 'mineSignatureB'.tr();

  void switchSignature() {
    _useAltSignature = !_useAltSignature;
    notifyListeners();
  }
}
