import 'package:flutter/widgets.dart';

class OpacityTansWidget extends StatefulWidget {
  const OpacityTansWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
  });

  final Widget child;

  final Duration duration;

  @override
  OpacityState createState() => OpacityState();
}

class OpacityState extends State<OpacityTansWidget>
    with TickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    duration: widget.duration,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: controller,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
