import 'dart:math';

import 'package:analytics_sdk/analytics_sdk.dart';
import 'package:analytics_sdk/entity/ad_click_event.dart';
import 'package:analytics_sdk/entity/ad_impression_event.dart';
import 'package:analytics_sdk/entity/advertising_event.dart';
import 'package:analytics_sdk/manager/page_name_manager.dart';
import 'package:analytics_sdk/observer/page_lifecycle_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/model/ad_model.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../event_tracking.dart';
import 'report_gesture_detector.dart';
import 'report_timing_observer.dart';

class ReportGeneralAppListSwiper extends StatefulWidget {
  ReportGeneralAppListSwiper({
    super.key,
    required this.data,
    this.radius = 5,
    this.aspectRatio = 7 / 3,
    this.maxWidth = 375,
    this.columnNumber = 6,
    this.useMargin = false,
  });

  List<AdModel> data;
  final double radius;
  final double aspectRatio;

  final double maxWidth;
  final int columnNumber;
  bool useMargin = false;

  @override
  State<ReportGeneralAppListSwiper> createState() => _ReportGeneralAppListSwiperState();
}

class _ReportGeneralAppListSwiperState extends State<ReportGeneralAppListSwiper> {
  final double _childAspectRatio = 57 / 82;
  int threshold = 24;
  int _ColumNumber = 6;

  Map<String, bool> adIdMap = {}; // 已经显示true 未显示null
  List<String> get adIds => List<String>.from(adIdMap.keys);
  bool didReport = false; //本生命周期内 只上报一次

  @override
  void initState() {
    super.initState();
    _ColumNumber = widget.columnNumber;
    threshold = _ColumNumber * 3;
  }

  void _showBanner(AdModel banner) {
    // 没存进Map 就是没上传过show 上传&记录

    CommonUtils.log('_showBanner ');
    if (adIdMap[banner.advertiseCode] == null) {
      CommonUtils.log('_showBanner show');
      postActionReport(banner, "show");
      adIdMap[banner.advertiseCode ?? ''] = true;
    }

    if (adIds.length == widget.data.length) {
      postShowReport();
    }
  }

  @override
  void dispose() {
    postShowReport();
    super.dispose();
  }

  //展示广告上报 展示完或页面消失上报
  void postShowReport() {
    if (didReport) return;

    // final pageName = context.parentTitle;
    // final widgetType = context.parentWidgetType.toString();
    AdModel tp = widget.data.first;
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
    }).then((value) {
      didReport = true;
      // CommonUtils.log(value);
    });
  }

  //上传广告行为
  void postActionReport(AdModel tp, String action) {
    // final pageName = context.parentTitle;
    // final widgetType = context.parentWidgetType.toString();
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
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.length > threshold) {
      final firstPart = widget.data.sublist(0, min(threshold, widget.data.length));
      final secondPart = widget.data.length > threshold ? widget.data.sublist(threshold) : [];
      final itemWidth = (ScreenUtil().screenWidth - (_ColumNumber + 1) * 6.w - MyTheme.pagePadding * 2) / _ColumNumber;

      return Builder(builder: (context) {
        return Column(
          children: [
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 2),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: List.generate(firstPart.length, (index) {
            //       final item = firstPart[index];
            //
            //       _showBanner(item);
            //       return ReportGestureDetector(
            //         onTap: () {
            //           postClickReport(widget.data[index]);
            //           CommonUtils.openRoute(context, item.toJson());
            //         },
            //         child: SizedBox(
            //             width: itemWidth,
            //             child: Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               mainAxisSize: MainAxisSize.min,
            //               children: [
            //                 SizedBox(
            //                   width: itemWidth,
            //                   height: itemWidth,
            //                   child: AspectRatio(
            //                     aspectRatio: 1,
            //                     child: MyImage.network(CommonUtils.getThumb(item.toJson()), fit: BoxFit.cover, borderRadius: 8.w),
            //                   ),
            //                 ),
            //                 SizedBox(height: 8.w),
            //                 Text(
            //                   item.name ?? item.title ?? "",
            //                   style: TextStyle(
            //                       color: Colors.white,
            //                       overflow: TextOverflow.ellipsis,
            //                       decoration: TextDecoration.none,
            //                       height: 1,
            //                       fontWeight: FontWeight.w600,
            //                       fontSize: 11.sp),
            //                 ),
            //               ],
            //             )),
            //       );
            //     }),
            //   ),
            // ),
            GridView.count(
              shrinkWrap: true,
              mainAxisSpacing: 6.w,
              crossAxisSpacing: 6.w,
              padding: EdgeInsets.only(bottom: 0.w),
              crossAxisCount: _ColumNumber,
              childAspectRatio: _childAspectRatio,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(firstPart.length, (index) {
                final item = firstPart[index];

                _showBanner(item);
                return ReportGestureDetector(
                  onTap: () {
                    postClickReport(firstPart[index]);
                    // CommonUtils.openRoute(context, item.toJson());
                  },
                  child: SizedBox(
                    width: itemWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: itemWidth,
                          height: itemWidth,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: MyImage.network(
                              fit: BoxFit.cover,
                              borderRadius: 8.w,
                              CommonUtils.getThumb(item.toJson()),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.w),
                        Text(
                          item.title ?? item.title ?? "",
                          style: TextStyle(
                            color: Colors.white,
                            overflow: TextOverflow.ellipsis,
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            if (secondPart.isNotEmpty && secondPart is List<AdModel>) SizedBox(height: 8.w),
            if (secondPart.isNotEmpty && secondPart is List<AdModel>)
              ReportInfiniteBannerList(
                banners: secondPart,
                columNumber: _ColumNumber,
                showFunc: (item) {
                  _showBanner(item);
                },
                tapFunc: (item) {
                  postClickReport(item);
                  // CommonUtils.openRoute(context, item.toJson());
                },
              ),
          ],
        );
      });
    } else {
      final itemWidth = (ScreenUtil().screenWidth - (_ColumNumber + 1) * 6.w - MyTheme.pagePadding * 2) / _ColumNumber;
      return Builder(builder: (context) {
        return GridView.count(
          shrinkWrap: true,
          mainAxisSpacing: 8.w,
          crossAxisSpacing: 8.w,
          padding: EdgeInsets.only(bottom: 8.w),
          crossAxisCount: _ColumNumber,
          childAspectRatio: _childAspectRatio,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(widget.data.length, (index) {
            final item = widget.data[index];

            _showBanner(item);
            return ReportGestureDetector(
              onTap: () {
                postClickReport(widget.data[index]);
                // CommonUtils.openRoute(context, item.toJson());
              },
              child: SizedBox(
                width: itemWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      height: itemWidth,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: MyImage.network(CommonUtils.getThumb(item.toJson()), fit: BoxFit.cover, borderRadius: 8.w),
                      ),
                    ),
                    SizedBox(height: 8.w),
                    Text(
                      item.title ?? item.title ?? "",
                      style: TextStyle(
                        color: Colors.white,
                        overflow: TextOverflow.ellipsis,
                        decoration: TextDecoration.none,
                        height: 1,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      });

      // List<List<BannerModel>> pages = [];
      // List<BannerModel> page = [];
      // for (var element in widget.data) {
      //   if (page.length >= _ColumNumber * 2) {
      //     pages.add(page);
      //     page = [];
      //   }
      //   page.add(element);
      // }
      //
      // if (page.isNotEmpty) {
      //   pages.add(page);
      // }
      //
      // return Container(
      //   child: widget.data.isEmpty
      //       ? Container()
      //       : LayoutBuilder(builder: (context, constrains) {
      //           double width = constrains.maxWidth;
      //           double itemWidth = (width - (_ColumNumber - 1) * 10.w) / _ColumNumber;
      //           double itemHeight = itemWidth / _childAspectRatio;
      //           // double bannerHeight = widget.data.length >= 10 ? itemHeight + (pages.first.length > _ColumeNumber ? 10.w : 7.w) :
      //           // (itemHeight * (pages.first.length <= _ColumeNumber ? 1 : 2)) + (pages.first.length > _ColumeNumber ? 15.w : 0);
      //           double bannerHeight =
      //               (itemHeight * (pages.first.length <= _ColumNumber ? 1 : 2)) + (pages.first.length > _ColumNumber ? 15.w : 0);
      //
      //           return SizedBox(
      //             width: width,
      //             height: bannerHeight,
      //             child: widget.data.isEmpty
      //                 ? Container()
      //                 : Swiper(
      //                     autoplay: pages.length > 1,
      //                     loop: pages.length > 1,
      //                     itemBuilder: (BuildContext context, int index) {
      //                       double w = itemWidth;
      //                       return VisibilityDetector(
      //                         key: Key("swiper_item_$index"),
      //                         onVisibilityChanged: (info) {
      //                           if (didReport) {
      //                             return;
      //                           }
      //                           if (info.visibleFraction > 0.8 && adIds.length < widget.data.length) {
      //                             for (var bannerModel in pages[index]) {
      //                               _showBanner(bannerModel);
      //                               // adIds.add(bannerModel.reportId);
      //                             }
      //                           }
      //                         },
      //                         child: SizedBox(
      //                           width: width,
      //                           child: Builder(builder: (context) {
      //                             return GridView.count(
      //                                 padding: EdgeInsets.only(bottom: 10.w),
      //                                 crossAxisCount: _ColumNumber,
      //                                 mainAxisSpacing: 10.w,
      //                                 crossAxisSpacing: 10.w,
      //                                 physics: const NeverScrollableScrollPhysics(),
      //                                 childAspectRatio: _childAspectRatio,
      //                                 shrinkWrap: true,
      //                                 children: pages[index].map((e) {
      //                                   // return Container();
      //
      //                                   return ReportGestureDetector(
      //                                       behavior: HitTestBehavior.translucent,
      //                                       onTap: () {
      //                                         FocusManager.instance.primaryFocus?.unfocus();
      //                                         postClickReport(widget.data[index]);
      //                                         CommonUtils.openRoute(context, e.toJson());
      //                                       },
      //                                       child: Column(
      //                                         mainAxisAlignment: MainAxisAlignment.center,
      //                                         children: [
      //                                           SizedBox(
      //                                             width: w,
      //                                             height: w,
      //                                             child: AspectRatio(
      //                                               aspectRatio: 1,
      //                                               child: MyImage.network(
      //                                                 CommonUtils.getThumb(e.toJson()),
      //                                                 fit: BoxFit.cover,
      //                                                 borderRadius: 8.w,
      //                                               ),
      //                                             ),
      //                                           ),
      //                                           // SizedBox(height: 8.w),
      //                                           Expanded(
      //                                             child: Container(
      //                                               alignment: Alignment.center,
      //                                               // color: Colors.blue,
      //                                               child: Text(
      //                                                 e.name ?? e.title ?? "",
      //                                                 style: TextStyle(
      //                                                     color: Colors.white,
      //                                                     overflow: TextOverflow.ellipsis,
      //                                                     decoration: TextDecoration.none,
      //                                                     height: 1,
      //                                                     fontWeight: FontWeight.w600,
      //                                                     fontSize: 11.sp),
      //                                               ),
      //                                             ),
      //                                           )
      //                                         ],
      //                                       ));
      //                                 }).toList()
      //
      //                                 // pages[index].map((e) {
      //                                 //   return Container();
      //                                 // }).toList(),
      //                                 );
      //                           }),
      //                         ),
      //                       );
      //                     },
      //                     itemCount: pages.length,
      //                     pagination: pages.length > 1 || true
      //                         ? SwiperPagination(
      //                             margin: EdgeInsets.zero,
      //                             builder: SwiperCustomPagination(builder: (context, config) {
      //                               int count = pages.length;
      //                               return Row(
      //                                 mainAxisAlignment: MainAxisAlignment.center,
      //                                 children: List.generate(count, (index) {
      //                                   return config.activeIndex == index
      //                                       ? Container(
      //                                           width: 10.w,
      //                                           height: 4.w,
      //                                           margin: EdgeInsets.only(right: 4.w),
      //                                           decoration: BoxDecoration(
      //                                             // color: StyleTheme.white255Color,
      //                                             gradient: MyTheme.gradient_90_114,
      //                                             borderRadius: BorderRadius.all(Radius.circular(2.w)),
      //                                           ),
      //                                         )
      //                                       : Container(
      //                                           width: 4.w,
      //                                           height: 4.w,
      //                                           margin: EdgeInsets.only(right: 4.w),
      //                                           decoration: BoxDecoration(
      //                                             color: MyTheme.white08Color,
      //                                             borderRadius: BorderRadius.all(Radius.circular(2.w)),
      //                                           ),
      //                                         );
      //                                 }),
      //                               );
      //                             }))
      //                         : null,
      //                   ),
      //           );
      //         }),
      // );
    }
  }
}

class ReportInfiniteBannerList extends StatefulWidget {
  final List<AdModel> banners;
  final int columNumber;
  final Function(AdModel banner)? showFunc;
  final Function(AdModel banner)? tapFunc;

  const ReportInfiniteBannerList({
    required this.banners,
    required this.columNumber,
    this.showFunc,
    this.tapFunc,
    super.key,
  });

  @override
  State<ReportInfiniteBannerList> createState() => _ReportInfiniteBannerListState();
}

class _ReportInfiniteBannerListState extends State<ReportInfiniteBannerList> {
  final ScrollController _controller = ScrollController();
  bool _isUserTouching = false;
  bool _autoScrollRunning = false;
  bool _isVisible = true; // 当前是否在屏幕可见范围内
  bool _hasInitPosition = false;
  double _itemExtent = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleLoopPosition);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shouldLoop) {
        _startAutoScroll();
      }
    });
  }

  bool get _shouldLoop => widget.banners.length > widget.columNumber;

  void _startAutoScroll() {
    if (_autoScrollRunning) return;
    _autoScrollRunning = true;

    const scrollSpeed = 1.0; // 每帧滚动像素数
    const interval = Duration(milliseconds: 32);

    Future.doWhile(() async {
      if (!mounted) return false;
      await Future.delayed(interval);

      // 若不可见或用户正在触摸，则暂停
      if (!_isVisible || _isUserTouching) return true;

      if (_controller.hasClients) {
        final pos = _controller.position.pixels;
        _controller.jumpTo(pos + scrollSpeed);
      }
      return true;
    });
  }

  void _handleLoopPosition() {
    if (!_shouldLoop || !_controller.hasClients || _itemExtent <= 0) return;
    final max = _controller.position.maxScrollExtent;
    final pos = _controller.position.pixels;
    final threshold = _itemExtent * widget.banners.length;

    if (pos <= threshold) {
      _controller.jumpTo(pos + threshold);
    } else if (pos >= max - threshold) {
      _controller.jumpTo(pos - threshold);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _autoScrollRunning = false;
    VisibilityDetectorController.instance.forget(ValueKey('ReportInfiniteBannerList_${widget.hashCode}'));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemWidth = (ScreenUtil().screenWidth - (widget.columNumber + 1) * 7 - MyTheme.pagePadding * 2) / widget.columNumber;
    final shouldLoop = _shouldLoop;
    final itemCount = shouldLoop ? widget.banners.length * 1000 : widget.banners.length;
    final itemExtent = itemWidth + 8;
    _itemExtent = itemExtent;

    if (shouldLoop && !_hasInitPosition) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        final middleIndex = itemCount ~/ 2;
        _controller.jumpTo(middleIndex * itemExtent);
        _hasInitPosition = true;
      });
    }

    return VisibilityDetector(
      key: ValueKey('ReportInfiniteBannerList_${widget.hashCode}'),
      onVisibilityChanged: (info) {
        if (!mounted) return; // 防止销毁后继续调用
        final visibleFraction = info.visibleFraction;
        final newVisible = visibleFraction > 0.1; // 超过10%算可见
        if (newVisible != _isVisible) {
          setState(() => _isVisible = newVisible);
        }
      },
      child: Listener(
        onPointerDown: (_) => _isUserTouching = true,
        onPointerUp: (_) => _isUserTouching = false,
        onPointerCancel: (_) => _isUserTouching = false,
        child: SizedBox(
          height: itemWidth + 28,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                _isUserTouching = notification.direction != ScrollDirection.idle;
                return false;
              },
              child: ListView.builder(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemExtent: itemExtent,
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  final banner = widget.banners[index % widget.banners.length];
                  widget.showFunc?.call(banner);
                  return ReportGestureDetector(
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      widget.tapFunc?.call(banner);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox.square(
                            dimension: itemWidth,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: MyImage.network(
                                CommonUtils.getThumb(banner.toJson()),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            banner.title ?? banner.title ?? "",
                            style: const TextStyle(
                              color: Colors.white,
                              overflow: TextOverflow.ellipsis,
                              decoration: TextDecoration.none,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
