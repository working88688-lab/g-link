import 'package:analytics_sdk/analytics_sdk.dart';
import 'package:analytics_sdk/entity/keyword_click_event.dart';
import 'package:flutter/material.dart';
import 'package:g_link/utils/common_utils.dart';
import '../event_tracking.dart';

class ReportSearchClick extends StatefulWidget {
  final Widget child;
  final Map data;

  const ReportSearchClick({Key? key, required this.child, required this.data})
      : super(key: key);

  @override
  State<ReportSearchClick> createState() => _ReportSearchClickState();
}

class _ReportSearchClickState extends State<ReportSearchClick> {
  Offset? _downPosition;
  Duration? _downTime;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent, // 不抢事件，内部 onTap 照常生效
      onPointerDown: (PointerDownEvent event) {
        _downPosition = event.position;
        _downTime = event.timeStamp;
      },
      onPointerUp: (PointerUpEvent event) {
        if (_downPosition == null || _downTime == null) return;
        final upPos = event.position;
        final upTime = event.timeStamp;
        // 位移阈值 + 时间阈值，简单判定是“点击”而不是滑动
        const moveThreshold = 10.0; // 像素
        const timeThreshold = Duration(milliseconds: 300);

        final distance = (upPos - _downPosition!).distance;
        final dt = upTime - _downTime!;

        if (distance > moveThreshold || dt > timeThreshold) {
          return; // 当成滑动/长按，不上报 click
        }

        try {
          AnalyticsSdk.instance.track(
            KeywordClickEvent(
              keyword: widget.data['keyword'] ?? '',
              clickItemId: widget.data['click_item_id'] ?? '',
              clickItemType: widget.data['click_item_type_key'] ?? '',
              clickPosition: widget.data['click_position'] ?? '',
              searchTraceId: '',
            ),
          );
        } catch (e) {
          CommonUtils.log(e);
        }
        EventTracking().reportSingle(widget.data);
      },
      child: widget.child,
    );
  }
}
