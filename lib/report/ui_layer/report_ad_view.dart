import 'dart:async';

import 'package:analytics_sdk/analytics_sdk.dart';
import 'package:analytics_sdk/entity/ad_click_event.dart';
import 'package:analytics_sdk/entity/advertising_event.dart';
import 'package:analytics_sdk/manager/page_name_manager.dart';
import 'package:analytics_sdk/observer/page_lifecycle_observer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_swiper_null_safety_flutter3/flutter_swiper_null_safety_flutter3.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:g_link/utils/common_utils.dart';
import 'report_gesture_detector.dart';
import '../../ui_layer/router/routes.dart';
import '../../domain/model/home_data_model.dart';
import '../event_tracking.dart';
import 'report_timing_observer.dart';

class ReportAdView extends StatefulWidget {
  const ReportAdView({super.key, required this.adModels});

  final List<AdModel> adModels;

  @override
  State<ReportAdView> createState() => _ReportAdViewState();
}

class _ReportAdViewState extends State<ReportAdView> {
  final ValueNotifier<int> countDownNotifier = ValueNotifier(5);
  late final Timer _timer;

  Map<String, bool> adIdMap = {}; // 已经显示true 未显示null
  List<String> get adIds => List<String>.from(adIdMap.keys);
  bool didReport = false; //本生命周期内 只上报一次

  void _showAppAd(AdModel tp) {
    // 没存进Map 就是没上传过show 上传&记录
    if (adIdMap[tp.advertiseCode] == null) {
      postActionReport(tp, "show");
      adIdMap[tp.advertiseCode ?? ''] = true;
    }
  }

  //上传广告行为
  void postActionReport(AdModel tp, String action) {
    AnalyticsSdk.instance.track(
      AdvertisingEvent(
        eventType: action,
        advertisingKey: tp.advertiseLocationCode ?? '',
        advertisingName: tp.adSlotName ?? '',
        advertisingId: tp.advertiseCode ?? '',
      ),
    );
    EventTracking().reportSingle({
      "event": "advertising",
      "event_type": action,
      "advertising_key": tp.advertiseLocationCode,
      "advertising_name": tp.adSlotName,
      "advertising_id": tp.advertiseCode,
    });
  }

  //点击广告上报
  void postClickReport(AdModel tp) {
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
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      countDownNotifier.value -= 1;
      if (countDownNotifier.value == 0) {
        _timer.cancel();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final length = widget.adModels.length;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
            child: Swiper(
          autoplay: length > 1,
          itemBuilder: (BuildContext context, int index) {
            precacheImage(
                NetworkImage(CommonUtils.getThumb(widget
                    .adModels[(index + 1).clamp(0, length - 1)]
                    .toJson())),
                context);

            final ad = widget.adModels[index];
            _showAppAd(ad);
            return ReportGestureDetector(
              onTap: () {
                postClickReport(ad);
                // CommonUtils.openRoute(context, {
                //   'report_id': ad.id,
                //   'report_type': ad.type,
                //   'link_url': ad.url,
                // });
              },
              child: MyImage.network(
                CommonUtils.getThumb(widget.adModels[index].toJson()),
                fit: BoxFit.cover,
              ),
            );
          },
          itemCount: length,
          pagination: SwiperPagination(
            builder: SwiperCustomPagination(
              builder: (context, config) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  length,
                  (index) {
                    bool isActive = config.activeIndex == index;
                    return Container(
                      width: 5.w,
                      height: 5.w,
                      margin: EdgeInsets.only(right: 7.w),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        )),
        Positioned(
          top: MediaQuery.of(context).padding.top + 10.w,
          right: 15.w,
          child: ReportGestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (countDownNotifier.value > 0) return;
              const HomeRoute().go(context);
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 5.w, horizontal: 15.w),
              height: 35.w,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(0, 0, 0, 0.5),
                borderRadius: BorderRadius.circular(35.w),
              ),
              child: Center(
                child: ValueListenableBuilder(
                  valueListenable: countDownNotifier,
                  builder: (context, count, _) => Text(
                    '${count > 0 ? count : 'adtg'.tr(context: context)}',
                    style: MyTheme.white15semibold,
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
