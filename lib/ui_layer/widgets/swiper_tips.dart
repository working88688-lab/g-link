import 'package:flutter/material.dart';
import 'package:flutter_swiper_null_safety_flutter3/flutter_swiper_null_safety_flutter3.dart';
import 'package:g_link/domain/model/tip_model.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:g_link/ui_layer/widgets/marquee_widget.dart';

class SwiperTips extends StatefulWidget {
  const SwiperTips({
    super.key,
    required this.tips,
    this.radius = 0,
    this.aspectRatio = 325 / 20,
  });
  final List<TipModel> tips;
  final double radius;
  final double aspectRatio;

  @override
  State<SwiperTips> createState() => _SwiperTipsState();
}

class _SwiperTipsState extends State<SwiperTips> {

  final SwiperController _swiperController = SwiperController();

  @override
  Widget build(BuildContext context) {
    final length = widget.tips.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Swiper(
          controller: _swiperController,
          physics: const NeverScrollableScrollPhysics(), // 禁用手动滚动
          scrollDirection: Axis.vertical,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () {
                // CommonUtils.openRoute(context, widget.tips[index].toJson());
              },
              child: MarqueeWidget(
                scrollSpeed: 60,
                child: Text(
                  widget.tips[index].title ?? '',
                  style: MyTheme.white14,
                ),
                scrollComplete: () {
                  _swiperController.next();
                },
              ),
            );
          },
          itemCount: length,
        ),
      ),
    );
  }
}
