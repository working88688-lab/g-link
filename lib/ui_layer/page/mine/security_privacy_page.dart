import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  bool _privateAccount = false;
  bool _allowSearch = true;
  _MentionOption _mentionOption = _MentionOption.following;
  bool _allowLikeList = true;
  bool _msgMutualFollow = false;
  _VisibilityOption _postVisibility = _VisibilityOption.publicAll;
  bool _allowComments = true;
  bool _allowFollowList = true;

  // 黑名单数量（示例）
  final int _blocklistCount = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: _buildAppBar(context),
      body: ListView(
        children: [
          _sectionHeader('securityAccountSection'.tr()),
          _buildCard(children: [
            _toggleItem(
              label: 'securityPrivateAccount'.tr(),
              value: _privateAccount,
              onChanged: (v) => setState(() => _privateAccount = v),
            ),
            _divider(),
            _toggleItem(
              label: 'securityAllowSearch'.tr(),
              value: _allowSearch,
              onChanged: (v) => setState(() => _allowSearch = v),
            ),
            _divider(),
            _arrowItem(
              label: 'securityMentions'.tr(),
              value: _mentionOptionLabel(_mentionOption),
              onTap: () => _showMentionSheet(),
            ),
            _divider(),
            _toggleItem(
              label: 'securityFollowersOnly'.tr(),
              value: _postVisibility == _VisibilityOption.followersOnly,
              onChanged: (v) => setState(() => _postVisibility = v
                  ? _VisibilityOption.followersOnly
                  : _VisibilityOption.publicAll),
            ),
            _divider(),
            _toggleItem(
              label: 'securityAllowLikeList'.tr(),
              value: _allowLikeList,
              onChanged: (v) => setState(() => _allowLikeList = v),
            ),
            _divider(),
            _toggleItem(
              label: 'securityMsgMutualFollow'.tr(),
              value: _msgMutualFollow,
              onChanged: (v) => setState(() => _msgMutualFollow = v),
            ),
            _divider(),
            _toggleItem(
              label: 'securityAllowComments'.tr(),
              value: _allowComments,
              onChanged: (v) => setState(() => _allowComments = v),
            ),
            _divider(),
            _toggleItem(
              label: 'securityAllowFollowList'.tr(),
              value: _allowFollowList,
              onChanged: (v) => setState(() => _allowFollowList = v),
            ),
            _divider(),
            _arrowItem(
              label: 'securityBlocklist'.tr(),
              value: 'securityBlocklistCount'
                  .tr(namedArgs: {'count': '$_blocklistCount'}),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BlocklistPage()),
              ),
            ),
          ]),
          _sectionHeader('securityDataSection'.tr()),
          _buildCard(children: [
            _arrowItem(
              label: 'securityChangePassword'.tr(),
              onTap: () {},
            ),
            _divider(),
            InkWell(
              onTap: () => _confirmDeleteAccount(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'securityDeleteAccount'.tr(),
                        style: TextStyle(
                          color: const Color(0xFFFF2056),
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 20.w, 16.w, 8.w),
      child: Text(
        title,
        style: TextStyle(
          color: const Color(0xFF45556C),
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      color: Colors.white,
      child: Column(children: children),
    );
  }

  Widget _toggleItem({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.w),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF0F172B),
                fontSize: 15.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF1A1F2C),
              activeTrackColor: const Color(0xFF0F172B),
              inactiveTrackColor: const Color(0xFFE3E7EC),
              inactiveThumbColor: const Color(0xFFF8F9FE),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _arrowItem({
    required String label,
    String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF0F172B),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  color: const Color(0xFF62748E),
                  fontSize: 14.sp,
                ),
              ),
            SizedBox(width: 4.w),
            Icon(
              Icons.chevron_right_rounded,
              size: 20.w,
              color: const Color(0xFFB0BAC8),
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
      color: const Color(0xFFEDF0F5),
    );
  }

  String _mentionOptionLabel(_MentionOption opt) {
    switch (opt) {
      case _MentionOption.all:
        return 'securityPublic'.tr();
      case _MentionOption.following:
        return 'securityFollowingOnly'.tr();
      case _MentionOption.nobody:
        return 'securityPrivateAccount'.tr();
    }
  }

  void _showMentionSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.w)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _MentionOption.values.map((opt) {
            return RadioListTile<_MentionOption>(
              title: Text(_mentionOptionLabel(opt)),
              value: opt,
              groupValue: _mentionOption,
              activeColor: const Color(0xFF1A1F2C),
              onChanged: (v) {
                setState(() => _mentionOption = v!);
                Navigator.of(ctx).pop();
              },
            );
          }).toList(),
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
