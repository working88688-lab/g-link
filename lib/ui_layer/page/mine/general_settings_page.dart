import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/page/mine/widgets/mine_settings_widgets.dart';
import 'package:g_link/ui_layer/widgets/app_bottom_sheet.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';

// ──────────────────────────────────────────
// 页面
// ──────────────────────────────────────────
class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  // 播放
  bool _autoPlayWifi = true;

  // 通知
  bool _pushNotification = true;
  bool _interactionMsg = true;
  bool _systemAnnounce = true;
  bool _newFollower = true;
  bool _chatMsg = true;

  // 缓存（仅示意数据）
  static const _videoCacheMB = 132;
  static const _imageCacheMB = 322;
  static const _tempFilesMB = 32;

  int get _totalCacheMB => _videoCacheMB + _imageCacheMB + _tempFilesMB;
  static const _totalSpaceMB = 800;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: _buildAppBar(context),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // 语言与地区
          MineSetingsWidgets.sectionHeader('generalLanguageSection'.tr()),
          MineSetingsWidgets.buildCard(
              children: Column(children: [
            MineSetingsWidgets.arrowItem(
              label: 'generalLanguage'.tr(),
              trailingText: 'generalLangZhCN'.tr(),
              onTap: () {},
            ),
          ])),
          // 播放
          MineSetingsWidgets.sectionHeader('generalPlaySection'.tr()),
          MineSetingsWidgets.buildCard(
              children: Column(children: [
            MineSetingsWidgets.toggleItem(
              label: 'generalAutoPlayWifi'.tr(),
              value: _autoPlayWifi,
              onChanged: (v) => setState(() => _autoPlayWifi = v),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.arrowItem(
              label: 'generalVideoQuality'.tr(),
              trailingText: 'generalVideoQualityAuto'.tr(),
              onTap: () {},
            ),
          ])),
          // 通知
          MineSetingsWidgets.sectionHeader('generalNotificationSection'.tr()),
          MineSetingsWidgets.buildCard(
              children: Column(children: [
            MineSetingsWidgets.toggleItem(
              label: 'generalPushNotification'.tr(),
              value: _pushNotification,
              onChanged: (v) => setState(() => _pushNotification = v),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.toggleItem(
              label: 'generalInteractionMsg'.tr(),
              value: _interactionMsg,
              prefix: SizedBox(
                width: 20.w,
              ),
              onChanged: (v) => setState(() => _interactionMsg = v),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.toggleItem(
              label: 'generalSystemAnnounce'.tr(),
              value: _systemAnnounce,
              prefix: SizedBox(
                width: 20.w,
              ),
              onChanged: (v) => setState(() => _systemAnnounce = v),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.toggleItem(
              label: 'generalNewFollower'.tr(),
              value: _newFollower,
              prefix: SizedBox(
                width: 20.w,
              ),
              onChanged: (v) => setState(() => _newFollower = v),
            ),
            MineSetingsWidgets.divider(),
            MineSetingsWidgets.toggleItem(
              label: 'generalChatMsg'.tr(),
              value: _chatMsg,
              prefix: SizedBox(
                width: 20.w,
              ),
              onChanged: (v) => setState(() => _chatMsg = v),
            ),
          ])),
          // 清除缓存
          MineSetingsWidgets.sectionHeader('generalCacheSection'.tr()),
          _buildCacheCard(),
          // 关于
          MineSetingsWidgets.sectionHeader('generalAboutSection'.tr()),
          MineSetingsWidgets.buildCard(
              children: Column(children: [
            MineSetingsWidgets.arrowItem(
              label: 'generalVersionCheck'.tr(),
              trailingText: 'v1.0.0',
              onTap: () {
                AppBottomSheet.show(
                    context: context,
                    showHandle: false,
                    child: Padding(
                        padding: EdgeInsets.only(bottom: 20.w, left: 16.w, right: 16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              child: Text(
                                "generalFoundNewVersion".tr(
                                  namedArgs: {'version': 'v1.1.0'},
                                ),
                                style:
                                    TextStyle(fontSize: 18.sp, color: Color(0xFF1A1F2C), fontWeight: FontWeight.w500),
                              ),
                            ),
                            SizedBox(
                              height: 20.w,
                            ),
                            Text(
                              "· 短视频播放体验优化\n· 修复若干已知问题\n· 新增离线缓存管理功能",
                              style: TextStyle(color: Color(0xFF62748E), fontSize: 14.sp),
                            ),
                            SizedBox(
                              height: 35.w,
                            ),
                            Row(
                              children: [
                                Expanded(
                                    child: GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    height: 46.w,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFE3E7ED)),
                                      borderRadius: BorderRadius.circular(100.w),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'updateDialogLater'.tr(),
                                        style: TextStyle(
                                          color: const Color(0xFF1A1F2C),
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                                SizedBox(
                                  width: 7.w,
                                ),
                                Expanded(
                                    child: GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    height: 46.w,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172B),
                                      borderRadius: BorderRadius.circular(100.w),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'updateDialogGoUpdate'.tr(),
                                        style: TextStyle(
                                          color: const Color(0xFFF8F9FE),
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ))
                              ],
                            ),
                          ],
                        )));
              },
            ),
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
        'mineDrawerGeneralSettings'.tr(),
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

  Widget _buildCacheCard() {
    final usageRatio = _totalCacheMB / _totalSpaceMB;
    return MineSetingsWidgets.buildCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
      children: Column(children: [
        // 总空间文字
        Row(
          children: [
            Text(
              '${_totalCacheMB}MB',
              style: TextStyle(
                color: const Color(0xFF000000),
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 3.w),
            Text(
              '/${"generalTotalCache".tr()}',
              style: TextStyle(
                color: const Color(0xFF90A1B9),
                fontSize: 11.sp,
              ),
            ),
            Spacer(),
            Text(
              'generalTotalSpace'.tr(namedArgs: {'size': '${_totalSpaceMB}MB'}),
              style: TextStyle(
                color: const Color(0xFF90A1B9),
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.w),
        // 进度条
        ClipRRect(
          borderRadius: BorderRadius.circular(20.w),
          child: LinearProgressIndicator(
            value: usageRatio,
            borderRadius: BorderRadius.circular(20.w),
            minHeight: 6.w,
            backgroundColor: Color(0xFF0F172B).withAlpha(5),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A1F2C)),
          ),
        ),
        SizedBox(height: 16.w),
        // 明细
        Container(
          padding: EdgeInsets.symmetric(vertical: 11.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FE),
            borderRadius: BorderRadius.circular(6.w),
          ),
          child: Row(
            children: [
              _cacheDetailRow('generalVideoCache'.tr(), '${_videoCacheMB}MB'),
              MineSetingsWidgets.dividerVertical(),
              _cacheDetailRow('generalImageCache'.tr(), '${_imageCacheMB}MB'),
              _cacheDetailRow('generalTempFiles'.tr(), '${_tempFilesMB}MB'),
            ],
          ),
        ),
        SizedBox(height: 16.w),
        // 清除全部按钮
        GestureDetector(
          onTap: _clearAllCache,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2C),
              borderRadius: BorderRadius.circular(100.w),
            ),
            child: Center(
              child: Text(
                'generalClearAll'.tr(),
                style: TextStyle(
                  color: const Color(0xFFF8F9FE),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _cacheDetailRow(String label, String size) {
    return Expanded(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          size,
          style: TextStyle(
            color: const Color(0xFF1A1F2C),
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(
          height: 2.w,
        ),
        Text(
          label,
          style: TextStyle(color: const Color(0xFF90A1B9), fontSize: 11.sp),
        ),
      ],
    ));
  }

  void _clearAllCache() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('generalClearAll'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('commonCancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('mineCacheCleared1'.tr()),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text('commonConfirm'.tr()),
          ),
        ],
      ),
    );
  }
}
