// import 'package:analytics_sdk/analytics_sdk.dart';
// import 'package:analytics_sdk/entity/ad_click_event.dart';
// import 'package:analytics_sdk/entity/advertising_event.dart';
// import 'package:analytics_sdk/manager/page_name_manager.dart';
// import 'package:analytics_sdk/observer/page_lifecycle_observer.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:g_link/report/ui_layer/report_gesture_detector.dart';
// import 'package:g_link/ui_layer/theme.dart';
// import 'package:g_link/ui_layer/widgets/my_image.dart';
// import 'package:g_link/utils/common_utils.dart';
//
// import '../event_tracking.dart';
// import 'report_timing_observer.dart';
//
// class ReportAdCard extends StatefulWidget {
//   const ReportAdCard({super.key, required this.ad});
//   final FeedAdModel ad;
//
//   @override
//   State<ReportAdCard> createState() => _ReportAdCardState();
// }
//
// class _ReportAdCardState extends State<ReportAdCard> {
//   String get description => widget.ad.description ?? widget.ad.subTitle ?? '';
//
//   String get imgUrl => CommonUtils.getThumb(widget.ad.toJson());
//
//   //上传广告行为
//   void postActionReport(FeedAdModel tp, String action) {
//     AnalyticsSdk.instance.track(
//       AdvertisingEvent(
//         eventType: action,
//         advertisingKey: tp.advertiseLocationCode ?? '',
//         advertisingName: tp.adSlotName ?? '',
//         advertisingId: tp.advertiseCode ?? '',
//       ),
//     );
//     EventTracking().reportSingle({
//       "event": "advertising",
//       "event_type": action,
//       "advertising_key": tp.advertiseLocationCode,
//       "advertising_name": tp.adSlotName,
//       "advertising_id": tp.advertiseCode,
//     });
//   }
//
//   //点击广告上报
//   void postClickReport(FeedAdModel tp) {
//     AnalyticsSdk.instance.track(
//       AdClickEvent(
//         pageKey: PageLifecycleObserver.currentPageKey,
//         pageName: PageNameMapper.getPageName(PageLifecycleObserver.currentPageKey),
//         adSlotKey: tp.advertiseLocationCode ?? '',
//         adSlotName: tp.adSlotName ?? '',
//         adId: tp.advertiseCode ?? '',
//         creativeId: '',
//         adType: tp.adType ?? '',
//       ),
//     );
//
//     postActionReport(tp, "click");
//
//     EventTracking().reportSingle({
//       "event": "ad_click",
//       "page_key": RouteStore.currentPageKey,
//       "page_name": RouteStore.currentPageName,
//       "ad_slot_key": tp.advertiseLocationCode,
//       "ad_slot_name": tp.adSlotName,
//       "ad_id": tp.advertiseCode,
//       "creative_id": "",
//       "ad_type": tp.adType,
//     });
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     postActionReport(widget.ad, 'show');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ReportGestureDetector(
//       behavior: HitTestBehavior.opaque,
//       onTap: () {
//         // postClickReport(widget.ad);
//         // CommonUtils.openRoute(context, widget.ad.toJson());
//       },
//       child: LayoutBuilder(builder: (context, cons) {
//         return Column(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(
//               height: cons.maxHeight * 94 / 158,
//               child: Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   MyImage.network(
//                     imgUrl,
//                     borderRadius: 5.w,
//                     fit: BoxFit.cover,
//                   ),
//                   Positioned(
//                     left: 0,
//                     top: 0,
//                     child: Container(
//                       width: 38.w,
//                       height: 20.w,
//                       decoration: BoxDecoration(
//                         color: const Color.fromRGBO(252, 231, 80, 1),
//                         borderRadius: BorderRadius.only(
//                             topLeft: Radius.circular(3.w),
//                             bottomRight: Radius.circular(3.w)),
//                       ),
//                       child: Center(
//                           child: Text(
//                         'gg'.tr(),
//                         style: MyTheme.black12_M,
//                       )),
//                     ),
//                   )
//                 ],
//               ),
//             ),
//             // SizedBox(height: 4.w),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         widget.ad.title,
//                         style: MyTheme.white13,
//                         maxLines: 1,
//                       ),
//                       Text(
//                         description,
//                         style: MyTheme.graya3a2a2_11,
//                         maxLines: 1,
//                       ),
//                     ],
//                   ),
//                   Text(
//                     '   ',
//                     style: MyTheme.graya3a2a2_11,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         );
//       }),
//     );
//   }
// }
