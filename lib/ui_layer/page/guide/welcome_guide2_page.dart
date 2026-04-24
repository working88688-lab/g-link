import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domain.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/ui_layer/notifier/guide_page_notifier.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:provider/provider.dart';

class WelcomeGuide2Page extends StatefulWidget {
  const WelcomeGuide2Page({super.key});

  @override
  State<WelcomeGuide2Page> createState() => _WelcomeGuide2PageState();
}

class _WelcomeGuide2PageState extends State<WelcomeGuide2Page> {
  bool _agreePolicy = true;
  bool _pushNoticeEnabled = true;
  bool _autoPlayEnabled = true;
  bool _dataSaverEnabled = false;
  bool _isLoadingPrefs = true;
  List<InterestTag> _interests = const [];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final appDomain = context.read<AppDomain>();
    final profileDomain = context.read<ProfileDomain>();
    final push = await appDomain.cache.readGuidePushNoticeEnabled();
    final autoPlay = await appDomain.cache.readGuideAutoPlayEnabled();
    final saver = await appDomain.cache.readGuideDataSaverEnabled();
    final interestResult = await profileDomain.getInterestTags();
    if (!mounted) return;
    setState(() {
      _pushNoticeEnabled = push;
      _autoPlayEnabled = autoPlay;
      _dataSaverEnabled = saver;
      _interests = interestResult.data ?? const [];
      _isLoadingPrefs = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<GuidePageNotifier>();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 13.w),
      child: _isLoadingPrefs
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.w),
                Text(
                  'guidePrefsTitle'.tr(),
                  style: MyTheme.black16bold.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color.fromRGBO(26, 31, 44, 1),
                  ),
                ),
                SizedBox(height: 8.w),
                Text(
                  'guidePrefsDesc'.tr(),
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color.fromRGBO(98, 116, 142, 1),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 22.w),
                _buildSwitchCard(
                  title: 'guidePushNoticeTitle'.tr(),
                  subtitle: 'guidePushNoticeDesc'.tr(),
                  value: _pushNoticeEnabled,
                  onChanged: (value) {
                    setState(() => _pushNoticeEnabled = value);
                  },
                ),
                SizedBox(height: 12.w),
                _buildSwitchCard(
                  title: 'guideAutoPlayTitle'.tr(),
                  subtitle: 'guideAutoPlayDesc'.tr(),
                  value: _autoPlayEnabled,
                  onChanged: (value) {
                    setState(() => _autoPlayEnabled = value);
                  },
                ),
                SizedBox(height: 12.w),
                _buildSwitchCard(
                  title: 'guideDataSaverTitle'.tr(),
                  subtitle: 'guideDataSaverDesc'.tr(),
                  value: _dataSaverEnabled,
                  onChanged: (value) {
                    setState(() => _dataSaverEnabled = value);
                  },
                ),
                if (_interests.isNotEmpty) ...[
                  SizedBox(height: 14.w),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _interests.take(8).map((tag) {
                      return Chip(
                        label: Text(tag.name),
                        backgroundColor: tag.isSelected
                            ? const Color(0xFF1A1F2C).withValues(alpha: 0.12)
                            : const Color(0xFFE3E7ED),
                      );
                    }).toList(),
                  ),
                ],
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(8.w),
                  onTap: () => setState(() => _agreePolicy = !_agreePolicy),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.w),
                    child: Row(
                      children: [
                        Icon(
                          _agreePolicy
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 18.w,
                          color: _agreePolicy
                              ? const Color.fromRGBO(26, 31, 44, 1)
                              : const Color.fromRGBO(98, 116, 142, 1),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'guideAgreePolicy'.tr(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color.fromRGBO(98, 116, 142, 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 6.w),
                GestureDetector(
                  onTap: () async {
                    if (!_agreePolicy) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('guideAgreePolicyRequired'.tr())),
                      );
                      return;
                    }
                    final appDomain = context.read<AppDomain>();
                    await appDomain.cache.upsertGuidePushNoticeEnabled(
                      _pushNoticeEnabled,
                    );
                    await appDomain.cache.upsertGuideAutoPlayEnabled(
                      _autoPlayEnabled,
                    );
                    await appDomain.cache.upsertGuideDataSaverEnabled(
                      _dataSaverEnabled,
                    );
                    await appDomain.cache.upsertGuideCompleted(true);
                    if (!context.mounted) return;
                    if (!context.mounted) return;
                    const HomeRoute().go(context);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    margin:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.w),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(26, 31, 44, 1),
                      borderRadius: BorderRadius.all(Radius.circular(40.w)),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15.w),
                    child: Text(
                      'guideStartExperience'.tr(),
                      style: MyTheme.black16bold.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: notifier.toPreviousStep,
                  child: Container(
                    alignment: Alignment.center,
                    margin: EdgeInsets.only(bottom: 20.w),
                    child: Text(
                      'guidePrevStep'.tr(),
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color.fromRGBO(98, 116, 142, 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.w),
        color: const Color.fromRGBO(227, 231, 237, 0.3),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromRGBO(26, 31, 44, 1),
                  ),
                ),
                SizedBox(height: 4.w),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color.fromRGBO(98, 116, 142, 1),
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
