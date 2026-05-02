import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/page/mine/widgets/mine_settings_widgets.dart';
import 'package:g_link/ui_layer/widgets/app_confirm_dialog.dart';
import 'package:g_link/ui_layer/widgets/custom_switch.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:provider/provider.dart';
import 'blocklist_page.dart';

// ──────────────────────────────────────────
// 页面
// ──────────────────────────────────────────
class SecurityPrivacyPage extends StatefulWidget {
  const SecurityPrivacyPage({super.key});

  @override
  State<SecurityPrivacyPage> createState() => _SecurityPrivacyPageState();
}

class _SecurityPrivacyPageState extends State<SecurityPrivacyPage> {
  bool _loading = true;
  AppSettings? _settings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSettings());
  }

  Future<void> _loadSettings() async {
    try {
      final result = await context.read<ProfileDomain>().getMySettings();
      final settings = result.data;
      if (!mounted || settings == null) return;
      setState(() {
        _loading = false;
        _settings = settings;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings({
    String? whoCanFollow,
    String? whoCanMessage,
    String? whoCanMention,
    bool? showFollowingList,
    bool? showFollowerList,
    bool? showLikeCount,
  }) async {
    final current = _settings ??
        AppSettings(
          privacy: const PrivacySettings(
            whoCanFollow: 'all',
            whoCanMessage: 'following',
            whoCanMention: 'all',
            showFollowingList: true,
            showFollowerList: true,
            showLikeCount: true,
          ),
          notification: const NotificationSettings(
            notifyFollow: true,
            notifyLike: true,
            notifyComment: true,
            notifyMention: true,
            notifySystem: true,
            pushEnabled: true,
          ),
          contentPref: const ContentPrefSettings(
            safeMode: false,
            autoPlayVideo: true,
            preferredLang: 'zh_CN',
          ),
          general: const GeneralSettings(
            darkMode: 'auto',
            locale: 'zh_CN',
            notificationSound: true,
          ),
        );
    final next = AppSettings(
      privacy: current.privacy.copyWith(
        whoCanFollow: whoCanFollow,
        whoCanMessage: whoCanMessage,
        whoCanMention: whoCanMention,
        showFollowingList: showFollowingList,
        showFollowerList: showFollowerList,
        showLikeCount: showLikeCount,
      ),
      notification: current.notification,
      contentPref: current.contentPref,
      general: current.general,
    );
    setState(() => _settings = next);

    var r = await context.read<ProfileDomain>().updatePrivacySettings(
          whoCanFollow: next.privacy.whoCanFollow,
          whoCanMessage: next.privacy.whoCanMessage,
          whoCanMention: next.privacy.whoCanMention,
          showFollowingList: next.privacy.showFollowingList,
          showFollowerList: next.privacy.showFollowerList,
          showLikeCount: next.privacy.showLikeCount,
        );
    if (!mounted) return;
    setState(() => _settings = r!.data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: _buildAppBar(context),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          MineSetingsWidgets.sectionHeader('securityVisibilitySection'.tr()),
          MineSetingsWidgets.buildCard(
              children: Column(children: [
            MineSetingsWidgets.visibilityItem(
              label: 'securityPrivateAccount'.tr(),
              selected: _settings?.privacy.whoCanFollow == 'approved',
              onTap: () => _saveSettings(whoCanFollow: 'approved'),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.visibilityItem(
              label: 'securityFollowersOnly'.tr(),
              selected: _settings?.privacy.whoCanFollow == 'followers_only',
              onTap: () => _saveSettings(whoCanFollow: 'followers_only'),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.visibilityItem(
              label: 'securitySelectedPeopleOnly'.tr(),
              selected: false,
              onTap: () => _saveSettings(whoCanFollow: 'approved'),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.visibilityItem(
              label: 'securityPublic'.tr(),
              selected: _settings?.privacy.whoCanFollow == 'all',
              onTap: () => _saveSettings(whoCanFollow: 'all'),
            ),
          ])),
          MineSetingsWidgets.sectionHeader('securityAccountSection'.tr()),
          MineSetingsWidgets.buildCard(
              children: Column(children: [
            MineSetingsWidgets.toggleItem(
              label: "securityAllowSearch".tr(),
              value: _settings?.privacy.showFollowerList ?? true,
              onChanged: (v) => _saveSettings(showFollowerList: v),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.toggleItem(
              label: "securityAllowLikeList".tr(),
              value: _settings?.privacy.showLikeCount ?? true,
              onChanged: (v) => _saveSettings(showLikeCount: v),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.toggleItem(
              label: "securityAllowComments".tr(),
              value: _settings?.privacy.showFollowingList ?? true,
              onChanged: (v) => _saveSettings(showFollowingList: v),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.toggleItem(
              label: "securityAllowFollowList".tr(),
              value: _settings?.privacy.showFollowingList ?? true,
              onChanged: (v) => _saveSettings(showFollowingList: v),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.arrowItem(
                label: "securityBlocklist".tr(), trailingText: "securityFollowingOnly".tr(), onTap: () {}),
            MineSetingsWidgets.divider(),
          ])),
          MineSetingsWidgets.buildCard(
              children: Column(children: [
            MineSetingsWidgets.toggleItem(
              icon: MyImagePaths.iconMention,
              label: "securityMsgMutualFollow".tr(),
              value: _settings?.privacy.whoCanMessage == 'following',
              onChanged: (v) => _saveSettings(whoCanMessage: v ? 'following' : 'none'),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.toggleItem(
              icon: MyImagePaths.iconSpMessage,
              label: "securityMentions".tr(),
              value: _settings?.privacy.whoCanMention == 'all',
              onChanged: (v) => _saveSettings(whoCanMention: v ? 'all' : 'following'),
            ),
          ])),
          MineSetingsWidgets.sectionHeader('securityDataSection'.tr()),
          MineSetingsWidgets.buildCard(
              children: Column(children: [
            MineSetingsWidgets.arrowItem(
                icon: MyImagePaths.iconKey, label: "securityChangePassword".tr(), onTap: () {}),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.arrowItem(
                icon: MyImagePaths.iconLogOff,
                labelColor: Color(0xFFFF2056),
                label: "securityDeleteAccount".tr(),
                onTap: () {
                  AppConfirmDialog.show(
                      context: context,
                      title: "securityDeleteAccount".tr(),
                      content: "securityDeleteAccountDesc".tr(),
                      onConfirm: () {});
                }),
          ])),
          SizedBox(height: 24.w),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20.w,
          color: const Color(0xFF1D293D),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'mineDrawerPrivacySecurity'.tr(),
        style: TextStyle(
          color: const Color(0xFF1D293D),
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFEDF0F5)),
      ),
    );
  }
}
