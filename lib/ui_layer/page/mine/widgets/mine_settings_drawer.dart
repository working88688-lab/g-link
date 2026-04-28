import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import '../history_favorites_page.dart';
import '../offline_cache_page.dart';
import '../security_privacy_page.dart';
import '../general_settings_page.dart';
import '../content_preference_page.dart';
import '../help_feedback_page.dart';

class MineSettingsDrawer extends StatelessWidget {
  const MineSettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 260.w,
      backgroundColor: Color(0xFFF8F9FE),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 2.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildItem(
                            context,
                            icon: MyImagePaths.iconSettingRecord,
                            label: 'mineDrawerHistory'.tr(),
                            onTap: () => _push(
                              context,
                              const HistoryFavoritesPage(
                                  mode: HistoryFavoritesMode.history),
                            ),
                          ),
                          _buildItem(
                            context,
                            icon: MyImagePaths.iconSettingCollection,
                            label: 'mineMenuCollections'.tr(),
                            onTap: () => _push(
                              context,
                              const HistoryFavoritesPage(
                                  mode: HistoryFavoritesMode.favorites),
                            ),
                          ),
                          _buildItem(
                            context,
                            icon: MyImagePaths.iconSettingCache,
                            label: 'mineDrawerOfflineCache'.tr(),
                            onTap: () =>
                                _push(context, const OfflineCachePage()),
                          ),
                          _buildItem(
                            context,
                            icon: MyImagePaths.iconSettingCustomer,
                            label: 'mineDrawerCustomerService'.tr(),
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 8.w,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 2.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildItem(
                            context,
                            icon: MyImagePaths.iconSettingPrivacySecurity,
                            label: 'mineDrawerPrivacySecurity'.tr(),
                            onTap: () =>
                                _push(context, const SecurityPrivacyPage()),
                          ),
                          _buildItem(
                            context,
                            icon: MyImagePaths.iconSettingGeneralSettings,
                            label: 'mineDrawerGeneralSettings'.tr(),
                            onTap: () =>
                                _push(context, const GeneralSettingsPage()),
                          ),
                          _buildItem(
                            context,
                            icon: MyImagePaths.iconSettingPreference,
                            label: 'mineDrawerContentPref'.tr(),
                            onTap: () =>
                                _push(context, const ContentPreferencePage()),
                          ),
                          _buildItem(
                            context,
                            icon: MyImagePaths.iconSettingHelp,
                            label: 'mineMenuHelp'.tr(),
                            onTap: () =>
                                _push(context, const HelpFeedbackPage()),
                          ),
                          _buildItem(
                            context,
                            icon: MyImagePaths.iconSettingLogout,
                            label: 'mineDrawerLogout'.tr(),
                            onTap: () {},
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 10.w, 20.w, 15.w),
      child: Text(
        'mineDrawerTitle'.tr(),
        style: TextStyle(
          color: const Color(0xFF1A1F2C),
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      child: Padding(
        padding:
            EdgeInsets.only(left: 12.w, right: 5.w, top: 10.w, bottom: 10.w),
        child: Row(
          children: [
            MyImage.asset(
              icon,
              width: 16.w,
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF1A1F2C),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            MyImage.asset(
              MyImagePaths.iconArrowRight,
              width: 16.w,
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: const Color(0xFFEDF0F5),
    );
  }
}
