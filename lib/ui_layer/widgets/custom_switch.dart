import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomSwitch extends StatelessWidget {
  const CustomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 46,
    this.height = 26,
    this.padding = 2,
    this.thumbSize = 22,
    this.activeColor = const Color(0xFF0F172B),
    this.inactiveColor = const Color(0xFFE3E7ED),
    this.thumbColor = const Color(0xFFF8F9FE),
    this.animationDuration = const Duration(milliseconds: 220),
    this.curve = Curves.easeInOut,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  final double width;
  final double height;
  final double padding;
  final double thumbSize;

  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;

  final Duration animationDuration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final double trackWidth = width.w;
    final double trackHeight = height.w;
    final double trackPadding = padding.w;
    final double thumbDiameter = thumbSize.w;
    final double travelDistance = (trackWidth - (trackPadding * 2) - thumbDiameter)
        .clamp(0.0, double.infinity);

    return Semantics(
      checked: value,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: animationDuration,
          curve: curve,
          width: trackWidth,
          height: trackHeight,
          padding: EdgeInsets.all(trackPadding),
          decoration: BoxDecoration(
            color: value ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(trackHeight / 2),
          ),
          child: AnimatedAlign(
            duration: animationDuration,
            curve: curve,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: animationDuration,
              curve: curve,
              width: thumbDiameter,
              height: thumbDiameter,
              decoration: BoxDecoration(
                color: thumbColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172B).withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
