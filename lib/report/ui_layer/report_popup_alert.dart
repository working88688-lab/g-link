import 'package:analytics_sdk/analytics_sdk.dart';
import 'package:analytics_sdk/entity/ad_click_event.dart';
import 'package:analytics_sdk/entity/ad_impression_event.dart';
import 'package:analytics_sdk/entity/advertising_event.dart';
import 'package:analytics_sdk/manager/page_name_manager.dart';
import 'package:analytics_sdk/observer/page_lifecycle_observer.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:g_link/ui_layer/dialog/ad_dialog.dart';
import 'package:g_link/utils/common_utils.dart';

import '../../domain/model/home_data_model.dart';
import '../event_tracking.dart';
import 'report_timing_observer.dart';

class ReportPopupAlert {
  final List<Notice>? ads;
  final BuildContext context;
  final VoidCallback? cancel;
  final VoidCallback? confirm;

  ReportPopupAlert(this.ads, this.context, {this.cancel, this.confirm}) {
    singleAdShow();
  }

  void singleAdShow({int index = 0}) {
    final popAds = ads;
    final int adsLength = popAds?.length ?? 0;
    final bool isLastAd = index == adsLength - 1;
    if (popAds?.isNotEmpty == true) {
      if (index < adsLength) {
        final Notice notice = popAds![index];
        BotToast.showWidget(
            toastBuilder: (cancelFunc) => AdDialog(
                  cancel: () {
                    postActionReport(notice, "close"); //关闭上报
                    cancelFunc();
                    if (isLastAd) {
                      postShowReport();
                      cancel?.call();
                    } else {
                      singleAdShow(index: index + 1);
                    }
                  },
                  confirm: () {
                    cancelFunc();
                    if (notice.redirectType != 1) {
                      //跳转内部结束继续弹窗
                      if (isLastAd) {
                        postShowReport();
                        cancel?.call();
                      } else {
                        singleAdShow(index: index + 1);
                      }
                    }
                    _adOnTap(tp: notice);
                  },
                  adUrl: notice.imgUrl ?? '',
                  adWidth: notice.width,
                  adHeight: notice.height,
                ));
        postActionReport(notice, "show"); //展示上报
      }
    } else {
      cancel?.call();
    }
  }

  //展示广告上报 展示完或页面消失上报
  void postShowReport() {
    // final pageName = context.parentTitle;
    // final widgetType = context.parentWidgetType.toString();
    List<String> adIds = ads?.map((e) => e.advertiseCode ?? '').toList() ?? [];
    Notice tp = ads!.first;

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

  /// 活动弹窗点击事件
  void _adOnTap({Notice? tp}) {
    if (tp == null) return;

    postActionReport(tp, "click");

    // final pageName = context.parentTitle;
    // final widgetType = context.parentWidgetType.toString();
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
    EventTracking().reportSingle({
      "event": "ad_click",
      "page_key": RouteStore.currentPageKey,
      "page_name": RouteStore.currentPageName,
      "ad_slot_key": tp.advertiseCode,
      "ad_slot_name": tp.adSlotName,
      "ad_id": tp.advertiseCode,
      "creative_id": "",
      "ad_type": tp.adType,
    });
    final json = tp.toJson();
    // CommonUtils.openRoute(context, json);
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
    EventTracking().reportSingle({
      "event": "advertising",
      "event_type": action,
      "advertising_key": tp.advertiseLocationCode,
      "advertising_name": tp.adSlotName,
      "advertising_id": tp.advertiseCode,
    });
  }
}
