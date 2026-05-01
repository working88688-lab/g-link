import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/page/mine/widgets/mine_settings_widgets.dart';
import 'package:g_link/ui_layer/widgets/app_confirm_dialog.dart';
import 'package:g_link/ui_layer/widgets/custom_switch.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'blocklist_page.dart';

// ──────────────────────────────────────────
// 枚举
// ──────────────────────────────────────────
enum _MentionOption { all, following, nobody }

enum _VisibilityOption { publicAll, followersOnly, privateOnly, selectedPeople }

// ──────────────────────────────────────────
// 页面
// ──────────────────────────────────────────
class SecurityPrivacyPage extends StatefulWidget {
  const SecurityPrivacyPage({super.key});

  @override
  State<SecurityPrivacyPage> createState() => _SecurityPrivacyPageState();
}

class _SecurityPrivacyPageState extends State<SecurityPrivacyPage> {
  // 账号隐私
  bool _allowSearch = true;
  bool _allowLikeList = true;
  _VisibilityOption _postVisibility = _VisibilityOption.publicAll;
  bool _allowMutualFollowMessage = true;
  bool _allowMentions = true;
  bool _allowComments = true;
  bool _allowFollowList = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: _buildAppBar(context),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          MineSetingsWidgets.sectionHeader('securityVisibilitySection'.tr()),
          MineSetingsWidgets.buildCard(children: [
            MineSetingsWidgets.visibilityItem(
              label: 'securityPrivateAccount'.tr(),
              selected: _postVisibility == _VisibilityOption.privateOnly,
              onTap: () => setState(
                  () => _postVisibility = _VisibilityOption.privateOnly),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.visibilityItem(
              label: 'securityFollowersOnly'.tr(),
              selected: _postVisibility == _VisibilityOption.followersOnly,
              onTap: () => setState(
                  () => _postVisibility = _VisibilityOption.followersOnly),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.visibilityItem(
              label: 'securitySelectedPeopleOnly'.tr(),
              selected: _postVisibility == _VisibilityOption.selectedPeople,
              onTap: () => setState(
                  () => _postVisibility = _VisibilityOption.selectedPeople),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.visibilityItem(
              label: 'securityPublic'.tr(),
              selected: _postVisibility == _VisibilityOption.publicAll,
              onTap: () =>
                  setState(() => _postVisibility = _VisibilityOption.publicAll),
            ),
          ]),
          MineSetingsWidgets.sectionHeader('securityAccountSection'.tr()),
          MineSetingsWidgets.buildCard(children: [
            MineSetingsWidgets.toggleItem(
              label: "securityAllowSearch".tr(),
              value: _allowSearch,
              onChanged: (v) => setState(() => _allowSearch = v),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.toggleItem(
              label: "securityAllowLikeList".tr(),
              value: _allowLikeList,
              onChanged: (v) => setState(() => _allowLikeList = v),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.toggleItem(
              label: "securityAllowComments".tr(),
              value: _allowComments,
              onChanged: (v) => setState(() => _allowComments = v),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.toggleItem(
              label: "securityAllowFollowList".tr(),
              value: _allowFollowList,
              onChanged: (v) => setState(() => _allowFollowList = v),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.arrowItem(
                label: "securityBlocklist".tr(),
                trailingText: "securityFollowingOnly".tr(),
                onTap: () {}),
            MineSetingsWidgets.divider(),
          ]),
          MineSetingsWidgets.buildCard(children: [
            MineSetingsWidgets.toggleItem(
              icon: MyImagePaths.iconMention,
              label: "securityMsgMutualFollow".tr(),
              value: _allowMutualFollowMessage,
              onChanged: (v) => setState(() => _allowMutualFollowMessage = v),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.toggleItem(
              icon: MyImagePaths.iconSpMessage,
              label: "securityMentions".tr(),
              value: _allowMentions,
              onChanged: (v) => setState(() => _allowMentions = v),
            ),
          ]),
          MineSetingsWidgets.sectionHeader('securityDataSection'.tr()),
          MineSetingsWidgets.buildCard(children: [
            MineSetingsWidgets.arrowItem(
                icon: MyImagePaths.iconKey,
                label: "securityChangePassword".tr(),
                onTap: () {}),
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
          ]),
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
