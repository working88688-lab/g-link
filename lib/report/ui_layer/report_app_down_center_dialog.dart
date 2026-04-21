import 'package:analytics_sdk/analytics_sdk.dart';
import 'package:analytics_sdk/entity/ad_click_event.dart';
import 'package:analytics_sdk/entity/ad_impression_event.dart';
import 'package:analytics_sdk/entity/advertising_event.dart';
import 'package:analytics_sdk/manager/page_name_manager.dart';
import 'package:analytics_sdk/observer/page_lifecycle_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/notifier/home_config_notifier.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../../domain/model/home_data_model.dart';
import '../../../../../report/ui_layer/report_gesture_detector.dart';
import '../event_tracking.dart';
import 'report_timing_observer.dart';

class ReportAppDownCenterDialog extends StatefulWidget {
  const ReportAppDownCenterDialog({
    super.key,
    required this.cancel,
  });
  final VoidCallback cancel;

  @override
  State<ReportAppDownCenterDialog> createState() =>
      _ReportAppDownCenterDialogState();
}

class _ReportAppDownCenterDialogState extends State<ReportAppDownCenterDialog> {
  Map<String, bool> adIdMap = {}; // 已经显示true 未显示null
  List<String> get adIds => List<String>.from(adIdMap.keys);

  //展示广告上报 展示完或页面消失上报
  void postShowReport() {
    late final homeConfigNotifier = context.read<HomeConfigNotifier>();
    final apps = homeConfigNotifier.homeData.noticeApps;

    Notice tp = apps!.first;

    AnalyticsSdk.instance.track(
      AdImpressionEvent(
        pageKey: PageLifecycleObserver.currentPageKey,
        pageName: PageNameMapper.getPageName(PageLifecycleObserver.currentPageKey),
        adSlotKey: tp.advertiseLocationCode ?? '',
        adSlotName: tp.adSlotName ?? '',
        adId: adIds.join(","),
        creativeId: "",
        adType: tp.adType ?? '',
      ),
    );

    EventTracking().reportSingle({
      "event": "ad_impression",
      "page_key": RouteStore.currentPageKey,
      "page_name": RouteStore.currentPageName,
      "ad_slot_key": tp.advertiseLocationCode,
      "ad_slot_name": tp.adSlotName,
      "ad_id": adIds.join(","),
      "creative_id": "",
      "ad_type": tp.adType,
    });
  }

  @override
  Widget build(BuildContext context) {
    late final homeConfigNotifier = context.read<HomeConfigNotifier>();
    final apps = homeConfigNotifier.homeData.noticeApps;

    return ColoredBox(
      color: Colors.black38,
      child: ReportGestureDetector(
        behavior: HitTestBehavior.opaque,
        // onTap: () => cancel.call(),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 35.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  height: 405.w,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(22, 24, 34, 0.95),
                    borderRadius: BorderRadius.all(Radius.circular(10.w)),
                  ),
                  child: ReportAppDownCenterCard(
                    showFunc: (cardAdMap) {
                      adIdMap = cardAdMap;
                    },
                  ),
                ),
                SizedBox(height: 20.w),
                ReportGestureDetector(
                  onTap: () {
                    postShowReport();
                    widget.cancel.call();
                  },
                  child: SizedBox(
                    child: MyImage.asset(
                      MyImagePaths.appCancelWithCircle,
                      fit: BoxFit.cover,
                      width: 33.w,
                      height: 33.w,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReportAppDownCenterCard extends StatefulWidget {
  const ReportAppDownCenterCard({
    this.showFunc,
    super.key,
  });

  final Function(Map<String, bool> adIdMap)? showFunc;

  @override
  State<ReportAppDownCenterCard> createState() =>
      _ReportAppDownCenterCardState();
}

class _ReportAppDownCenterCardState extends State<ReportAppDownCenterCard> {
  late final homeConfigNotifier = context.read<HomeConfigNotifier>();
  late final apps = homeConfigNotifier.homeData.noticeApps ?? [];

  List<List<Notice>> groupedApps = [];

  // 创建一个 ScrollController
  final ScrollController _scrollController = ScrollController();

  Map<String, bool> adIdMap = {}; // 已经显示true 未显示null
  List<String> get adIds => List<String>.from(adIdMap.keys);
  bool didReport = false; //本生命周期内 只上报一次

  void _showAppAd(Notice appAd) {
    // 没存进Map 就是没上传过show 上传&记录
    if (adIdMap[appAd.advertiseCode] == null) {
      postActionReport(appAd, "show");
      adIdMap[appAd.advertiseCode ?? ''] = true;
    }

    widget.showFunc?.call(adIdMap);

    // if (adIds.length == apps.length) {
    //   postShowReport();
    // }
  }

  //上传广告行为
  void postActionReport(Notice tp, String action) {
    AnalyticsSdk.instance.track(
      AdvertisingEvent(
        eventType: action,
        advertisingKey: tp.advertiseLocationCode ?? '',
        advertisingName: tp.adSlotName ?? '',
        advertisingId: tp.advertiseCode ?? '',
      ),
    );

    // final pageName = context.parentTitle;
    // final widgetType = context.parentWidgetType.toString();

    EventTracking().reportSingle({
      "event": "advertising",
      "event_type": action,
      "advertising_key": tp.advertiseLocationCode,
      "advertising_name": tp.adSlotName,
      "advertising_id": tp.advertiseCode,
    });
  }

  //点击广告上报
  void postClickReport(Notice tp) {
    AnalyticsSdk.instance.track(
      AdClickEvent(
        pageKey: PageLifecycleObserver.currentPageKey,
        pageName: PageNameMapper.getPageName(PageLifecycleObserver.currentPageKey),
        adSlotKey: tp.advertiseLocationCode ?? '',
        adSlotName: tp.adSlotName ?? '',
        adId: tp.advertiseCode ?? '',
        creativeId: '',
        adType: tp.adType ?? '',
      ),
    );

    postActionReport(tp, "click");

    // final pageName = context.parentTitle;
    // final widgetType = context.parentWidgetType.toString();
    EventTracking().reportSingle({
      "event": "ad_click",
      "page_key": RouteStore.currentPageKey,
      "page_name": RouteStore.currentPageName,
      "ad_slot_key": tp.advertiseLocationCode,
      "ad_slot_name": tp.adSlotName,
      "ad_id": tp.advertiseCode,
      "creative_id": "",
      "ad_type": tp.adType,
    }).then((value) {
      // CommonUtils.log(value);
    });
  }

  @override
  void initState() {
    super.initState();

    // 将前6个元素放在一组，剩余元素放在另一组
    if (apps.length <= 6) {
      groupedApps.add(apps); // 如果少于或等于 6 个元素，直接将整个列表作为一组
    } else {
      groupedApps.add(apps.sublist(0, 6)); // 添加前 6 个元素
      groupedApps.add(apps.sublist(6)); // 添加剩余的元素
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); // 释放资源
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(MyTheme.white008Color), // 滑动条颜色
          trackColor: WidgetStateProperty.all(MyTheme.white008Color), // 滑动条背景颜色
          thickness: WidgetStateProperty.all(5.w), // 滑动条宽度
          radius: Radius.circular(10.w), // 滑动条圆角
          minThumbLength: 20, // 滑动条最小长度
        ),
        child: Scrollbar(
          controller: _scrollController, // 绑定 ScrollController
          thumbVisibility: true, // 显示滑动条（即使不滚动也显示）
          child: ListView(
            controller: _scrollController, // 将相同的 ScrollController 传递给 ListView
            padding: EdgeInsets.all(MyTheme.pagePadding),
            children: [
              GridView.builder(
                  shrinkWrap: true,
                  addRepaintBoundaries: false,
                  addAutomaticKeepAlives: false,
                  physics: const BouncingScrollPhysics(),
                  itemCount: groupedApps.first.length,
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 50 / 58,
                    // mainAxisSpacing: 10.w,
                    // crossAxisSpacing: 10.w,
                  ),
                  itemBuilder: (context, index) {
                    Notice? model = groupedApps.first[index];
                    return VisibilityDetector(
                      key: Key(
                          "ReportAppDownCenterDialog_item_${model.reportId}_0_$index"),
                      onVisibilityChanged: (info) {
                        // 当 Widget 可见度超过 50% 时，执行操作
                        if (info.visibleFraction > 0.5) {
                          _showAppAd(model);
                        }
                      },
                      child: ReportGestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          postClickReport(model);
                          final json = model.toJson() ?? {};
                          // CommonUtils.openRoute(context, json);
                        },
                        child: Column(
                          children: [
                            SizedBox(
                              height: 76.w,
                              width: 76.w,
                              child: MyImage.network(
                                model.imgUrl ?? '',
                                fit: BoxFit.fill,
                                borderRadius: 10.w,
                              ),
                            ),
                            SizedBox(height: 5.w),
                            Text(
                              model.title ?? '',
                              style: TextStyle(
                                  color: Colors.white,
                                  overflow: TextOverflow.ellipsis,
                                  decoration: TextDecoration.none,
                                  fontSize: 13.sp),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              groupedApps.length < 2
                  ? Container()
                  : GridView.builder(
                      shrinkWrap: true,
                      addRepaintBoundaries: false,
                      addAutomaticKeepAlives: false,
                      physics: const BouncingScrollPhysics(),
                      itemCount: groupedApps.last.length,
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 49 / 62,
                        // mainAxisSpacing: 10.w,
                        // crossAxisSpacing: 10.w,
                      ),
                      itemBuilder: (context, index) {
                        Notice? model = groupedApps.last[index];
                        return VisibilityDetector(
                          key: Key(
                              "ReportAppDownCenterDialog_item_${model.reportId}_1_$index"),
                          onVisibilityChanged: (info) {
                            // 当 Widget 可见度超过 50% 时，执行操作
                            if (info.visibleFraction > 0.5) {
                              _showAppAd(model);
                            }
                          },
                          child: ReportGestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              postClickReport(model);
                              final json = model.toJson() ?? {};
                              // CommonUtils.openRoute(context, json);
                            },
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 56.w,
                                  width: 56.w,
                                  child: MyImage.network(
                                    model.imgUrl ?? '',
                                    fit: BoxFit.fill,
                                    borderRadius: 10.w,
                                  ),
                                ),
                                SizedBox(height: 5.w),
                                Text(
                                  model.title ?? '',
                                  style: TextStyle(
                                      color: Colors.white,
                                      overflow: TextOverflow.ellipsis,
                                      decoration: TextDecoration.none,
                                      fontSize: 11.sp),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      })
            ],
          ),
        ),
      ),
    );
  }
}
