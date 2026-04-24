import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domain.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/notifier/guide_page_notifier.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:provider/provider.dart';

class WelcomeGuide1Page extends StatefulWidget {
  const WelcomeGuide1Page({super.key});

  @override
  State<WelcomeGuide1Page> createState() => _WelcomeGuide1PageState();
}

class _WelcomeGuide1PageState extends State<WelcomeGuide1Page> {
  late final GuidePageNotifier _notifier = context.read<GuidePageNotifier>();

  @override
  void initState() {
    super.initState();
    _syncSavedLanguage();
  }

  Future<void> _syncSavedLanguage() async {
    final appDomain = context.read<AppDomain>();
    final languageType = await appDomain.cache.readGuideLanguageType();
    if (!mounted) return;
    _notifier.setLanguageType(languageType);
    await _applyLanguage(languageType);
  }

  Future<void> _applyLanguage(int type) async {
    final locale =
        type == 1 ? const Locale('en', 'US') : const Locale('zh', 'CN');
    await context.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 13.w),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.w),
              Text(
                'hysy'.tr(),
                style: MyTheme.black16bold.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Color.fromRGBO(26, 31, 44, 1),
                ),
              ),
              SizedBox(height: 5.h),
              Image.asset(
                MyImagePaths.glinkWhite,
                width: 111.w,
                height: 39.w,
                color: Color.fromRGBO(0, 0, 0, 1),
              ),
              SizedBox(height: 48.h),
              Text(
                'xayy'.tr(),
                style: MyTheme.black16bold.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Color.fromRGBO(98, 116, 142, 1),
                ),
              ),
              SizedBox(height: 15.w),
              _SelectLanguageItem(
                icon: MyImagePaths.cn,
                title: 'cnLanguage'.tr(),
                subtitle: 'cnjt'.tr(),
                type: 0,
              ),
              SizedBox(height: 12.w),
              _SelectLanguageItem(
                icon: MyImagePaths.us,
                title: 'usLanguage'.tr(),
                subtitle: 'usjt'.tr(),
                type: 1,
              ),
            ],
          ),
          Positioned(
            bottom: 30.w,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                _notifier.toNextStep();
              },
              child: Container(
                alignment: Alignment.center,
                margin: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 15.w,
                ),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(26, 31, 44, 1),
                  borderRadius: BorderRadius.all(
                    Radius.circular(40.w),
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: 15.w),
                child: Text(
                  'next'.tr(),
                  style: MyTheme.black16bold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectLanguageItem extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final int type;

  const _SelectLanguageItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<GuidePageNotifier, int>(
      selector: (_, notifier) => notifier.languageType,
      builder: (_, languageType, __) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.all(Radius.circular(8.w)),
            onTap: () async {
              context.read<GuidePageNotifier>().setLanguageType(type);
              await context
                  .read<AppDomain>()
                  .cache
                  .upsertGuideLanguageType(type);
              if (!context.mounted) return;
              final locale = type == 1
                  ? const Locale('en', 'US')
                  : const Locale('zh', 'CN');
              await context.setLocale(locale);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8.w)),
                color: Color.fromRGBO(227, 231, 237, 0.3),
                border: Border.all(
                  color: (languageType == type)
                      ? Color.fromRGBO(26, 31, 44, 1)
                      : Color.fromRGBO(0, 0, 0, 0),
                  width: 1.w,
                ),
              ),
              child: Row(
                children: [
                  Image.asset(
                    icon,
                    width: 24.w,
                    height: 24.w,
                  ),
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: MyTheme.black16bold.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 5.w),
                      Text(
                        subtitle,
                        style: MyTheme.black16bold.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  if (languageType == type)
                    Container(
                      width: 18.w,
                      height: 18.w,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(26, 31, 44, 1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12.w,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
