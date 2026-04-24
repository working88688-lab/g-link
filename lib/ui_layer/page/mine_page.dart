import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:g_link/domain/domain.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/notifier/profile_notifier.dart';
import 'package:g_link/ui_layer/theme/app_design.dart';
import 'package:g_link/ui_layer/widgets/app_bottom_sheet.dart';
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
        ChangeNotifierProvider(create: (_) => MineNotifier()),
        ChangeNotifierProvider(
          create: (ctx) => ProfileNotifier(ctx.read<ProfileDomain>())
            ..fetchProfileAndVideos(uid: 5001),
        ),
      ],
      child: Scaffold(
        backgroundColor: AppDesign.bg,
        appBar: AppBar(
          title: Text('mineTitle'.tr(), style: AppDesign.appBarTitle),
          actions: [
            IconButton(
              onPressed: () => _openSettingsSheet(context),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: Consumer<MineNotifier>(
          builder: (context, notifier, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _buildProfileLoadStatus(context),
                _buildProfileCard(context, notifier),
                AppDesign.sectionGap,
                _buildMetrics(context, notifier),
                AppDesign.sectionGap,
                _buildUserVideoSection(context),
                AppDesign.sectionGap,
                ..._buildMenus(context, notifier),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, MineNotifier notifier) {
    final profile =
        context.select<ProfileNotifier, UserProfile?>((n) => n.profile);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F2C), Color(0xFF364153)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundImage: AssetImage('assets/images/logo_gradient.png'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.nickname.isNotEmpty == true
                      ? profile!.nickname
                      : 'mineUserTitle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ).tr(),
                const SizedBox(height: 4),
                Text(
                  (profile?.bio.isNotEmpty == true)
                      ? profile!.bio
                      : notifier.signature(context),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: notifier.switchSignature,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white70),
              foregroundColor: Colors.white,
            ),
            child: Text('mineSwitchSignature'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(BuildContext context, MineNotifier notifier) {
    final profile =
        context.select<ProfileNotifier, UserProfile?>((n) => n.profile);
    Widget item(String title, String value) {
      return Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppDesign.cardRadius),
      ),
      child: Row(
        children: [
          item(
            'mineFollowCount'.tr(),
            '${profile?.followingCount ?? notifier.following}',
          ),
          item(
            'mineFansCount'.tr(),
            '${profile?.followerCount ?? notifier.followers}',
          ),
          item(
            'mineLikesCount'.tr(),
            '${profile?.likeCount ?? notifier.likes}',
          ),
        ],
      ),
    );
  }

  Widget _buildUserVideoSection(BuildContext context) {
    return Consumer<ProfileNotifier>(
      builder: (_, notifier, __) {
        if (notifier.loadingVideos) {
          return const Center(child: CircularProgressIndicator());
        }
        if (notifier.errorMessage != null && notifier.videos.isEmpty) {
          return Column(
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
          );
        }
        if (notifier.videos.isEmpty) {
          return Text(
            'messageEmpty'.tr(),
            style: TextStyle(color: Colors.grey.shade600),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'shortVideoTitle'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifier.videos.length.clamp(0, 6),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 9 / 14,
              ),
              itemBuilder: (_, i) {
                final video = notifier.videos[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: Colors.grey.shade300),
                      if (video.coverUrl.isNotEmpty)
                        Image.network(video.coverUrl, fit: BoxFit.cover),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Text(
                            video.title.isEmpty
                                ? 'Video #${video.id}'
                                : video.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildMenus(BuildContext context, MineNotifier notifier) {
    final menu = <({IconData icon, String title, String? action})>[
      (
        icon: Icons.settings_outlined,
        title: 'mineMenuSettings'.tr(),
        action: 'settings'
      ),
      (
        icon: Icons.bookmark_outline_rounded,
        title: 'mineMenuCollections'.tr(),
        action: null
      ),
      (
        icon: Icons.history_rounded,
        title: 'mineMenuHistory'.tr(),
        action: null
      ),
      (
        icon: Icons.verified_user_outlined,
        title: 'mineMenuSecurity'.tr(),
        action: null
      ),
      (
        icon: Icons.help_outline_rounded,
        title: 'mineMenuHelp'.tr(),
        action: null
      ),
      (
        icon: Icons.restart_alt_rounded,
        title: 'mineMenuResetGuide'.tr(),
        action: 'resetGuide'
      ),
      (
        icon: Icons.auto_awesome_rounded,
        title: 'mineMenuReenterGuide'.tr(),
        action: 'goGuide'
      ),
    ];

    return menu
        .map(
          (item) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: Icon(item.icon),
              title: Text(item.title),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () =>
                  _onMenuTap(context, notifier, item.title, item.action),
            ),
          ),
        )
        .toList();
  }

  Future<void> _onMenuTap(
    BuildContext context,
    MineNotifier notifier,
    String title,
    String? action,
  ) async {
    switch (action) {
      case 'settings':
        _openSettingsSheet(context);
        return;
      case 'resetGuide':
        await context.read<AppDomain>().cache.upsertGuideCompleted(false);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('mineGuideResetDone'.tr())),
        );
        return;
      case 'goGuide':
        await context.read<AppDomain>().cache.upsertGuideCompleted(false);
        if (!context.mounted) return;
        const GuideRoute().go(context);
        return;
      default:
        notifier.increaseTapCount();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title 点击 ${notifier.tapCount} 次')),
        );
    }
  }

  Future<void> _openSettingsSheet(BuildContext context) async {
    final appDomain = context.read<AppDomain>();
    bool pushNotice = await appDomain.cache.readGuidePushNoticeEnabled();
    bool darkMode = await appDomain.cache.readGuideDataSaverEnabled();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (_, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: Text('mineSettingPush'.tr()),
                    value: pushNotice,
                    onChanged: (value) async {
                      setSheetState(() => pushNotice = value);
                      await appDomain.cache.upsertGuidePushNoticeEnabled(value);
                    },
                  ),
                  SwitchListTile(
                    title: Text('mineSettingDark'.tr()),
                    value: darkMode,
                    onChanged: (value) async {
                      setSheetState(() => darkMode = value);
                      await appDomain.cache.upsertGuideDataSaverEnabled(value);
                    },
                  ),
                  ListTile(
                    title: Text('mineSettingClearCache'.tr()),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await AppBottomSheet.showSimpleList(
                        context: context,
                        title: 'mineSettingClearCache'.tr(),
                        items: [
                          'mineCacheCleared1'.tr(),
                          'mineCacheCleared2'.tr(),
                          'mineCacheCleared3'.tr(),
                        ],
                        leadingIcon: Icons.cleaning_services_outlined,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileLoadStatus(BuildContext context) {
    return Consumer<ProfileNotifier>(
      builder: (_, notifier, __) {
        if (!notifier.authExpired) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4ED),
            borderRadius: BorderRadius.circular(10),
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
  int tapCount = 0;
  bool _useAltSignature = false;

  String signature(BuildContext context) =>
      _useAltSignature ? 'mineSignatureA'.tr() : 'mineSignatureB'.tr();

  void switchSignature() {
    _useAltSignature = !_useAltSignature;
    notifyListeners();
  }

  void increaseTapCount() {
    tapCount++;
    notifyListeners();
  }
}
