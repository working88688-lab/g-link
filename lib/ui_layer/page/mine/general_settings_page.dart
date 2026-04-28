import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        children: [
          // 语言与地区
          _sectionHeader('generalLanguageSection'.tr()),
          _buildCard(children: [
            _arrowItem(
              label: 'generalLanguage'.tr(),
              value: 'generalLangZhCN'.tr(),
              onTap: () {},
            ),
          ]),
          // 播放
          _sectionHeader('generalPlaySection'.tr()),
          _buildCard(children: [
            _toggleItem(
              label: 'generalAutoPlayWifi'.tr(),
              value: _autoPlayWifi,
              onChanged: (v) => setState(() => _autoPlayWifi = v),
            ),
            _divider(),
            _arrowItem(
              label: 'generalVideoQuality'.tr(),
              value: 'generalVideoQualityAuto'.tr(),
              onTap: () {},
            ),
          ]),
          // 通知
          _sectionHeader('generalNotificationSection'.tr()),
          _buildCard(children: [
            _toggleItem(
              label: 'generalPushNotification'.tr(),
              value: _pushNotification,
              onChanged: (v) => setState(() => _pushNotification = v),
            ),
            _divider(),
            _toggleItem(
              label: 'generalInteractionMsg'.tr(),
              value: _interactionMsg,
              onChanged: (v) => setState(() => _interactionMsg = v),
            ),
            _divider(),
            _toggleItem(
              label: 'generalSystemAnnounce'.tr(),
              value: _systemAnnounce,
              onChanged: (v) => setState(() => _systemAnnounce = v),
            ),
            _divider(),
            _toggleItem(
              label: 'generalNewFollower'.tr(),
              value: _newFollower,
              onChanged: (v) => setState(() => _newFollower = v),
            ),
            _divider(),
            _toggleItem(
              label: 'generalChatMsg'.tr(),
              value: _chatMsg,
              onChanged: (v) => setState(() => _chatMsg = v),
            ),
          ]),
          // 关于
          _sectionHeader('generalAboutSection'.tr()),
          _buildCard(children: [
            _arrowItem(
              label: 'generalVersionCheck'.tr(),
              value: 'v1.0.0',
              onTap: () {},
            ),
          ]),
          // 清除缓存
          _sectionHeader('generalCacheSection'.tr()),
          _buildCacheCard(),
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
                color: const Color(0xFF1A1F2C),
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
              activeColor: Colors.white,
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
                  color: const Color(0xFF1A1F2C),
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

  Widget _buildCacheCard() {
    final usageRatio = _totalCacheMB / _totalSpaceMB;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              SizedBox(width: 4.w),
              Text(
                '/',
                style: TextStyle(
                  color: const Color(0xFF90A1B9),
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                'generalTotalSpace'
                    .tr(namedArgs: {'size': '${_totalSpaceMB}MB'}),
                style: TextStyle(
                  color: const Color(0xFF90A1B9),
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.w),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4.w),
            child: LinearProgressIndicator(
              value: usageRatio,
              minHeight: 8.w,
              backgroundColor: const Color(0xFFF8F9FE),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF0F172B)),
            ),
          ),
          SizedBox(height: 12.w),
          // 明细
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FE),
              borderRadius: BorderRadius.circular(8.w),
            ),
            child: Column(
              children: [
                _cacheDetailRow(Icons.videocam_outlined,
                    'generalVideoCache'.tr(), '${_videoCacheMB}MB'),
                _divider(),
                _cacheDetailRow(Icons.image_outlined, 'generalImageCache'.tr(),
                    '${_imageCacheMB}MB'),
                _divider(),
                _cacheDetailRow(Icons.insert_drive_file_outlined,
                    'generalTempFiles'.tr(), '${_tempFilesMB}MB'),
              ],
            ),
          ),
          SizedBox(height: 16.w),
          // 清除全部按钮
          GestureDetector(
            onTap: _clearAllCache,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2C),
                borderRadius: BorderRadius.circular(12.w),
              ),
              child: Center(
                child: Text(
                  'generalClearAll'.tr(),
                  style: TextStyle(
                    color: const Color(0xFFF8F9FE),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cacheDetailRow(IconData icon, String label, String size) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.w),
      child: Row(
        children: [
          Icon(icon, size: 16.w, color: const Color(0xFF90A1B9)),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: const Color(0xFF90A1B9), fontSize: 13.sp),
            ),
          ),
          Text(
            size,
            style: TextStyle(
              color: const Color(0xFF1A1F2C),
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
