import 'package:flutter/material.dart';

class MarqueeWidget extends StatefulWidget {
  final Duration pauseDuration, forwardDuration;
  final double scrollSpeed; //滚动速度(时间单位是秒)。
  final Widget child; //子视图。
  final Function? scrollComplete; //滚动展示完后去上层切换下一个广告数据展示

  /// 注: 构造函数入参的默认值必须是常量。
  const MarqueeWidget({
    super.key,
    this.pauseDuration = const Duration(milliseconds: 100),
    this.forwardDuration = const Duration(milliseconds: 3000),
    this.scrollSpeed = 30.0,
    this.scrollComplete,
    required this.child,
  });

  @override
  State createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget>
    with SingleTickerProviderStateMixin {
  bool _validFlag = true;
  double _boxWidth = 0;
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    // debugPrint('Track_MarqueeView_dispose');
    _validFlag = false;
    _controller.removeListener(_onScroll); // 移除滚动监听器
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    scroll();
  }

  void _onScroll() {
    if (_controller.hasClients) {
      // 检查是否滚动到了末尾
      if (_controller.offset >= _controller.position.maxScrollExtent) {
        // 滚动到达末尾
        widget.scrollComplete?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    /// 使用LayoutBuilder获取组件的大小。
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _boxWidth = constraints.maxWidth;
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            // 禁止手动滑动。
            physics: const NeverScrollableScrollPhysics(),
            controller: _controller,
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: _boxWidth),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }

  void scroll() async {
    while (_validFlag) {
      // debugPrint('Track_MarqueeView_scroll');
      await Future.delayed(widget.pauseDuration);
      if (_boxWidth <= 0) {
        continue;
      }
      _controller.jumpTo(0);
      await _controller.animateTo(_controller.position.maxScrollExtent,
          duration: Duration(
              seconds:
                  (_controller.position.maxScrollExtent / widget.scrollSpeed)
                      .floor()),
          curve: Curves.linear);
    }
  }
}
