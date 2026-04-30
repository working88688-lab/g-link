import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
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
          _sectionHeader('securityVisibilitySection'.tr()),
          _buildCard(children: [
            _visibilityItem(
              label: 'securityPrivateAccount'.tr(),
              selected: _postVisibility == _VisibilityOption.privateOnly,
              onTap: () => setState(
                  () => _postVisibility = _VisibilityOption.privateOnly),
            ),
            _divider(),
            _visibilityItem(
              label: 'securityFollowersOnly'.tr(),
              selected: _postVisibility == _VisibilityOption.followersOnly,
              onTap: () => setState(
                  () => _postVisibility = _VisibilityOption.followersOnly),
            ),
            _divider(),
            _visibilityItem(
              label: 'securitySelectedPeopleOnly'.tr(),
              selected: _postVisibility == _VisibilityOption.selectedPeople,
              onTap: () => setState(
                  () => _postVisibility = _VisibilityOption.selectedPeople),
            ),
            _divider(),
            _visibilityItem(
              label: 'securityPublic'.tr(),
              selected: _postVisibility == _VisibilityOption.publicAll,
              onTap: () =>
                  setState(() => _postVisibility = _VisibilityOption.publicAll),
            ),
          ]),
          _sectionHeader('securityAccountSection'.tr()),
          _buildCard(children: [
            _toggleItem(
              label: "securityAllowSearch".tr(),
              value: _allowSearch,
              onChanged: (v) => setState(() => _allowSearch = v),
            ),
            _divider(),
            _toggleItem(
              label: "securityAllowLikeList".tr(),
              value: _allowLikeList,
              onChanged: (v) => setState(() => _allowLikeList = v),
            ),
            _divider(),
            _toggleItem(
              label: "securityAllowComments".tr(),
              value: _allowComments,
              onChanged: (v) => setState(() => _allowComments = v),
            ),
            _divider(),
            _toggleItem(
              label: "securityAllowFollowList".tr(),
              value: _allowFollowList,
              onChanged: (v) => setState(() => _allowFollowList = v),
            ),
            _divider(),
            _arrowItem(
                label: "securityBlocklist".tr(),
                trailingText: "securityFollowingOnly".tr(),
                onTap: () {}),
            _divider(),
          ]),
          _buildCard(children: [
            _toggleItem(
              icon: MyImagePaths.iconMention,
              label: "securityMsgMutualFollow".tr(),
              value: _allowMutualFollowMessage,
              onChanged: (v) => setState(() => _allowMutualFollowMessage = v),
            ),
            _divider(),
            _toggleItem(
              icon: MyImagePaths.iconSpMessage,
              label: "securityMentions".tr(),
              value: _allowMentions,
              onChanged: (v) => setState(() => _allowMentions = v),
            ),
          ]),
          _sectionHeader('securityDataSection'.tr()),
          _buildCard(children: [
            _arrowItem(
                icon: MyImagePaths.iconKey,
                label: "securityChangePassword".tr(),
                onTap: () {}),
            _divider(),
            _arrowItem(
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

  Widget _sectionHeader(String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.w),
      child: Text(
        title,
        style: TextStyle(
          color: const Color(0xFF45556C),
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.w),
      ),
      child: Column(children: children),
    );
  }

  Widget _toggleItem({
    String? icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.w),
      child: Row(
        children: [
          if (icon != null) ...[
            MyImage.asset(
              icon,
              width: 20.w,
            ),
            SizedBox(width: 8.w),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF0F172B),
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CustomSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _arrowItem({
    String? icon,
    Color? labelColor,
    required String label,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              MyImage.asset(
                icon,
                width: 20.w,
              ),
              SizedBox(width: 8.w),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor ?? const Color(0xFF0F172B),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: TextStyle(
                  color: const Color(0xFF62748E),
                  fontSize: 14.sp,
                ),
              ),
            MyImage.asset(
              MyImagePaths.iconArrowRightBlack,
              width: 20.w,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: EdgeInsets.only(left: 16.w),
      color: const Color(0xFF1A1F2C).withAlpha(4),
    );
  }

  Widget _visibilityItem({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.w),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF0F172B),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Image.asset(
              selected ? MyImagePaths.iconSel : MyImagePaths.iconUnSel,
              width: 16.w,
              height: 16.w,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('securityDeleteAccount'.tr()),
        content: Text('updateDialogContent'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('commonCancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'commonConfirm'.tr(),
              style: const TextStyle(color: Color(0xFFFF2056)),
            ),
          ),
        ],
      ),
    );
  }
}
