import 'dart:async';
import 'dart:io';

import 'package:analytics_sdk/analytics_sdk.dart';
import 'package:analytics_sdk/manager/page_name_manager.dart';
import 'package:analytics_sdk/observer/page_lifecycle_observer.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_swiper_null_safety_flutter3/flutter_swiper_null_safety_flutter3.dart';
import 'package:g_link/report/ui_layer/report_app_down_center_dialog.dart';
import 'package:g_link/report/ui_layer/report_gesture_detector.dart';
import 'package:g_link/report/ui_layer/report_popup_alert.dart';
import 'package:g_link/report/ui_layer/report_timing_observer.dart';
import 'package:g_link/ui_layer/dialog/announcement_dialog.dart';
import 'package:g_link/ui_layer/dialog/download_apk_dialog.dart';
import 'package:g_link/ui_layer/dialog/regular_dialog.dart';
import 'package:g_link/ui_layer/dialog/update_dialog.dart';
import 'package:g_link/ui_layer/event/event_bus.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/notifier/home_config_notifier.dart';
import 'package:g_link/ui_layer/notifier/user_notifier.dart';
import 'package:g_link/ui_layer/widgets/custom_bottom_nav_bar.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:g_link/ui_layer/theme/app_design.dart';
import 'package:g_link/ui_layer/theme/theme_manager.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:g_link/ui_layer/widgets/pop_scope_wrapper.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../app_config.dart';
import '../../domain/domain.dart';
import '../../domain/enum.dart';
import '../../domain/model/home_data_model.dart';

class BottomNaviBar extends StatefulWidget {
  const BottomNaviBar({
    required this.navigationShell,
    super.key = const ValueKey<String>('ScaffoldWithNavBar'),
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<BottomNaviBar> createState() => _BottomNaviBarState();
}

class _BottomNaviBarState extends State<BottomNaviBar> {
  late final _userNotifier = context.read<UserNotifier>();
  late final homeConfigNotifier = context.read<HomeConfigNotifier>();
  late final targetVersion = homeConfigNotifier.homeData.versionMsg;
  late final domain = context.read<AppDomain>();
  late final cache = domain.cache;
  MyTokenStatus? currentTokenStatus;

  bool _isInit = false;
  late StreamSubscription<MyEvent> _subscription;

  bool get openLive => homeConfigNotifier.config.openLive == 1 ? true : false;

  @override
  void initState() {
    super.initState();
  }

  /// 活动弹窗 带report
  void _showActivityDialogReport() {
    final popAds = homeConfigNotifier.homeData.popAds;
    ReportPopupAlert(
      popAds,
      context,
      cancel: () {
        _showAppDownCenterDialog();
      },
    );
  }

  /// 检查更新
  Future<void> _checkUpdateAnnouncement() async {
    if (targetVersion?.version case final version?) {
      final packageInfo = await PackageInfo.fromPlatform();
      final String localVersion = packageInfo.version;
      final currentVersion = localVersion.replaceAll('.', '');

      final String targetNumber = version.replaceAll('.', '');

      final needUpdate = (int.tryParse(targetNumber) ?? 0) >
          (int.tryParse(currentVersion) ?? 0);

      if (kIsWeb) {
        // Web端检测线路key版本是否变更，变更则弹窗提醒前往官网下载新版
        _checkWebLineKeyUpdate();
        return;
      }
      if (needUpdate) {
        _showAppUpdateDialog();
        return;
      }
      _showActivityDialogReport();
      // _showActivityDialog(index: 0); // 无更新，展示广告
    }
  }

  /// Web端：检测linesUrlKey版本是否变更，变更则弹窗提醒前往官网下载新版
  Future<void> _checkWebLineKeyUpdate() async {
    String currentKey = BuildConfig.linesUrlKey; // 当前代码中的 key，如 "lines_url_v4"
    String? savedKey = await cache.readWebCachedLineKeyVersion();

    if (savedKey == null || savedKey.isEmpty) {
      // 本地没有存过，首次使用，存一份
      await cache.upsertWebCachedLineKeyVersion(currentKey);
      // 首次不弹窗，正常展示广告/公告
      _showActivityDialogReport();
    } else if (savedKey != currentKey) {
      // 本地key和当前key不同，说明线路版本已更新，弹窗提醒
      _showWebUpdateAlert(currentKey);
    } else {
      // 版本一致，正常展示广告/公告
      _showActivityDialogReport();
    }
  }

  /// Web端弹窗提醒前往官网下载新版
  void _showWebUpdateAlert(String currentKey) {
    final Config config = homeConfigNotifier.config;
    String officeSite = config.officeSite ?? '';
    CommonUtils.showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RegularDialog(
        title: 'updateDialogTitle'.tr(),
        content: Text(
          'updateDialogContent'.tr(),
          style: MyTheme.white255_14,
          textAlign: TextAlign.center,
        ),
        cancelText: 'commonCancel'.tr(),
        buttonText: 'updateDialogGoUpdate'.tr(),
        cancelOnTap: () {
          Navigator.of(ctx).pop();
          // 更新本地key（不再重复提醒），继续展示广告/公告
          cache.upsertWebCachedLineKeyVersion(currentKey);
          _showActivityDialogReport();
        },
        confirmOnTap: () {
          Navigator.of(ctx).pop();
          // 更新本地key，跳转官网，继续展示广告/公告
          cache.upsertWebCachedLineKeyVersion(currentKey);
          if (officeSite.isNotEmpty) {
            CommonUtils.launchUrl(officeSite);
          }
          _showActivityDialogReport();
        },
      ),
    );
  }

  /// 更新弹窗
  void _showAppUpdateDialog() {
    final Config config = homeConfigNotifier.config;
    String apkUrl = homeConfigNotifier.homeData.upgradeApk ?? '';
    BotToast.showWidget(
        toastBuilder: (cancelFunc) => UpdateDialog(
              cancel: () {
                cancelFunc();
                _showActivityDialogReport();
                // _showActivityDialog(index: 0);
              },
              confirm: () {
                cancelFunc();
                if (kIsWeb) {
                  CommonUtils.launchUrl(config.officeSite ?? '');
                } else {
                  if (Platform.isAndroid) {
                    BotToast.showWidget(
                      toastBuilder: (cancelFunc) => DownloadApkDialog(
                        version: targetVersion?.version ?? '',
                        url: targetVersion?.apk ?? '',
                        // onTap: () {
                        //   cancelFunc();
                        // },
                      ),
                    );
                  } else {
                    CommonUtils.launchUrl(apkUrl);
                  }
                }
              },
              tips: targetVersion?.tips ?? '',
              mustUpdate: targetVersion?.must == 1,
              officialWebUrl: config.officeSite ?? '',
              solution: config.solution ?? '',
            ));
  }

  /// 活动弹窗点击事件
  void _adOnTap({Notice? notice}) {
    if (notice == null) return;
    final json = notice.toJson();
    // CommonUtils.openRoute(context, json);
  }

  ///推荐app下载列表弹窗
  void _showAppDownCenterDialog() {
    final homeData = homeConfigNotifier.homeData;

    if (homeData.noticeApps?.isNotEmpty ?? false) {
      BotToast.showWidget(
          toastBuilder: (cancelFunc) => ReportAppDownCenterDialog(
                cancel: () {
                  cancelFunc();
                  _showAnnouncementDialog(); //app推荐下载弹窗展示完后再展示公告
                },
              ));
    } else {
      _showAnnouncementDialog(); //app推荐为空直接展示公告
    }
  }

  /// 系统公告弹窗
  void _showAnnouncementDialog() {
    if (targetVersion?.mstatus != 1) return;

    BotToast.showWidget(
      toastBuilder: (cancelFunc) => AnnouncementDialog(
        cancel: () {
          cancelFunc();
        },
        confirm: () {
          // cancelFunc();
          // const MineAgentRoute().push(context);
        },
        text: homeConfigNotifier.homeData.versionMsg?.message ?? '',
      ),
    );
  }

  // 初始化下载状态
  Future<void> _initDownloadStatus() async {
    if (await cache.readDownloadVideoTasks() case final tasks) {
      for (var task in tasks) {
        task['downloading'] = false;
        task['isWaiting'] = false;
      }
      await cache.upsertDownloadVideoTasks(tasks: tasks);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  late final appDomain = context.read<AppDomain>();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: ThemeManager.statusBarIconBrightness(
          context,
        ),
        statusBarBrightness: ThemeManager.getBrightness(context),
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: MyTheme.bgColor,
        systemNavigationBarIconBrightness: ThemeManager.statusBarIconBrightness(
          context,
        ),
        systemNavigationBarDividerColor: MyTheme.bgColor,
        systemNavigationBarContrastEnforced: false,
      ),
      child: PopScopeWrapper(
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: AppDesign.bg,
              body: widget.navigationShell,
              bottomNavigationBar: DecoratedBox(
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 2.0,
                      spreadRadius: 1.5,
                      offset: Offset(0.0, -0.5),
                      color: Color.fromRGBO(240, 240, 240, 1),
                    ),
                  ],
                ),
                child: Selector<HomeConfigNotifier, int>(
                  selector: (_, homeConfigNotifier) =>
                      homeConfigNotifier.currentIndex,
                  builder: (_, currentIndex, __) {
                    return CustomBottomNavBar(
                      currentIndex: currentIndex,
                      onTap: (index) {
                        homeConfigNotifier.setCurrentIndex(index);
                        _goBranch(index);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );

    // 获取当前路由的路径
    final currentLocation =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();

    PageInfo info = PageInfo.path(currentLocation);
    RouteStore.currentPageKey = info.key;
    RouteStore.currentPageName = info.name;

    AnalyticsSdk.instance.track({
      'event': 'navigation',
      'navigation_key': currentLocation.startsWith('/')
          ? currentLocation.substring(1)
          : currentLocation,
      'navigation_name':
          PageNameMapper.getPageName(PageLifecycleObserver.currentPageKey),
    });
  }
}

//悬浮广告view
class TopADWidget extends StatefulWidget {
  const TopADWidget({super.key, required this.toADs});

  final List<AdModel> toADs;

  @override
  State<StatefulWidget> createState() => _TopADWidgetState();
}

class _TopADWidgetState extends State<TopADWidget> {
  bool offstage = false;

  @override
  Widget build(BuildContext context) {
    return widget.toADs.isEmpty ? Container() : _buildButton();
  }

  Widget _buildButton() {
    return Offstage(
      offstage: offstage,
      child: SizedBox(
        width: 120.w,
        height: 120.w,
        child: Stack(
          children: [
            Positioned.fill(
                child: Container(
              alignment: Alignment.center,
              margin: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                  // color: Colors.red,
                  borderRadius: BorderRadius.all(Radius.circular(5.w))),
              child: Swiper(
                autoplay: widget.toADs.length > 1,
                loop: widget.toADs.length > 1,
                itemBuilder: (BuildContext context, int index) {
                  double w = 80.w;
                  return ReportGestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      // CommonUtils.openRoute(
                      //   context,
                      //   widget.toADs[index].toJson(),
                      // );
                    },
                    child: SizedBox(
                      width: w,
                      height: w,
                      child: MyImage.network(
                        CommonUtils.getThumb(widget.toADs[index].toJson()),
                        borderRadius: 5.w,
                      ),
                    ),
                  );
                },
                itemCount: widget.toADs.length,
                pagination: widget.toADs.length > 1
                    ? SwiperPagination(
                        margin: EdgeInsets.only(bottom: 5.w),
                        builder: SwiperCustomPagination(
                          builder: (context, config) {
                            int count = widget.toADs.length;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(count, (index) {
                                return config.activeIndex == index
                                    ? Container(
                                        width: 4.w,
                                        height: 4.w,
                                        margin: EdgeInsets.only(right: 4.w),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(2.w)),
                                        ),
                                      )
                                    : Container(
                                        width: 4.w,
                                        height: 4.w,
                                        margin: EdgeInsets.only(right: 4.w),
                                        decoration: BoxDecoration(
                                          color: MyTheme.grayColor150,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(2.w)),
                                        ),
                                      );
                              }),
                            );
                          },
                        ),
                      )
                    : null,
              ),
            )),
            Positioned(
              right: 0,
              top: 0,
              width: 20.w,
              height: 20.w,
              child: ReportGestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    offstage = true;
                  });
                },
                child: const MyImage.asset(MyImagePaths.appDialogClose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
