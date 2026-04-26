import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domain.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:provider/provider.dart';

class WelcomeGuide2Page extends StatefulWidget {
  const WelcomeGuide2Page({super.key});

  @override
  State<WelcomeGuide2Page> createState() => _WelcomeGuide2PageState();
}

class _WelcomeGuide2PageState extends State<WelcomeGuide2Page> {
  bool _isLoadingPrefs = true;
  List<InterestTag> _interests = const [];
  final Set<int> _selectedTagIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final profileDomain = context.read<ProfileDomain>();
    final interestResult = await profileDomain.getInterestTags();
    if (!mounted) return;
    setState(() {
      _interests = interestResult.data ?? const [];
      _selectedTagIds
        ..clear()
        ..addAll(_interests.where((e) => e.isSelected).map((e) => e.id));
      _isLoadingPrefs = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 13.w),
      child: _isLoadingPrefs
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.w),
                    Text(
                      'guideInterestTitle'.tr(),
                      style: MyTheme.black16bold.copyWith(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromRGBO(26, 31, 44, 1),
                      ),
                    ),
                    SizedBox(height: 6.w),
                    Text(
                      'guideInterestSubtitle'.tr(),
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color.fromRGBO(118, 136, 160, 1),
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 18.w),
                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.only(bottom: 120.w),
                        itemCount: _interests.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10.w,
                          mainAxisSpacing: 10.w,
                          childAspectRatio: 0.78,
                        ),
                        itemBuilder: (_, index) {
                          final tag = _interests[index];
                          final selected = _selectedTagIds.contains(tag.id);
                          return _buildInterestCard(tag, selected);
                        },
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20.w,
                  child: GestureDetector(
                    onTap: _submitSelection,
                    child: Container(
                      alignment: Alignment.center,
                      margin: EdgeInsets.symmetric(horizontal: 2.w),
                      height: 56.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111A2C),
                        borderRadius: BorderRadius.all(Radius.circular(30.w)),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(text: 'guideEnterApp'.tr()),
                            TextSpan(
                              text: ' ${'guideSelectedCount'.tr(args: [
                                    '${_selectedTagIds.length}'
                                  ])}',
                              style: TextStyle(
                                color: const Color(0xFF7E879A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInterestCard(InterestTag tag, bool selected) {
    final icon = _interestEmoji(tag);
    return GestureDetector(
      onTap: () => _toggleTag(tag.id),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(
            color: selected ? const Color(0xFF1A2233) : Colors.transparent,
            width: 1.4,
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.w, horizontal: 6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: TextStyle(fontSize: 27.sp),
            ),
            SizedBox(height: 8.w),
            Text(
              tag.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A2233),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTag(int id) {
    final next = Set<int>.from(_selectedTagIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      if (next.length >= 10) {
        _showToast('guideInterestMax'.tr());
        return;
      }
      next.add(id);
    }
    setState(() {
      _selectedTagIds
        ..clear()
        ..addAll(next);
    });
  }

  Future<void> _submitSelection() async {
    if (_selectedTagIds.length < 3) {
      _showToast('guideInterestMin'.tr());
      return;
    }
    final profileDomain = context.read<ProfileDomain>();
    final result = await profileDomain.submitOnboardingInterests(
      tagIds: _selectedTagIds.toList(),
    );
    if (!mounted) return;
    if (result.status != 0) {
      _showToast(result.msg ?? 'commonRetry'.tr());
      return;
    }
    final completeResult = await profileDomain.completeOnboarding();
    if (!mounted) return;
    if (completeResult.status != 0) {
      _showToast(completeResult.msg ?? 'commonRetry'.tr());
      return;
    }
    final appDomain = context.read<AppDomain>();
    await appDomain.cache.upsertGuideCompleted(true);
    if (!mounted) return;
    const HomeRoute().go(context);
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _interestEmoji(InterestTag tag) {
    const map = <String, String>{
      '摄影': '📷',
      '旅行': '✈️',
      '美食': '🍜',
      '穿搭': '👗',
      '健身': '💪',
      '音乐': '🎵',
      '影视': '🎬',
      '电影': '🎬',
      '游戏': '🎮',
      '科技': '💻',
      '绘画': '🎨',
      '手帐': '📒',
      '读书': '📖',
      '宠物': '🐾',
      '搞笑': '😁',
      '汽车': '🚗',
    };
    return map[tag.name] ?? '✨';
  }
}
