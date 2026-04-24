import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ──────────────────────────────────────────
// 下拉菜单数据模型
// ──────────────────────────────────────────
class OverlayMenuItem {
  final String value;
  final String icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const OverlayMenuItem({
    required this.value,
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });
}

// ──────────────────────────────────────────
// 右上角下拉菜单按钮（自包含 Overlay 逻辑）
// ──────────────────────────────────────────
class OverlayMenuButton extends StatefulWidget {
  final List<OverlayMenuItem> items;
  final Widget? child;

  const OverlayMenuButton({super.key, required this.items, this.child});

  @override
  State<OverlayMenuButton> createState() => _OverlayMenuButtonState();
}

class _OverlayMenuButtonState extends State<OverlayMenuButton> {
  final _btnKey = GlobalKey();
  OverlayEntry? _overlay;

  void _show() {
    final btn = _btnKey.currentContext!.findRenderObject() as RenderBox;
    final overlayState = Navigator.of(context).overlay!;
    final overlayBox = overlayState.context.findRenderObject() as RenderBox;
    final btnPos = btn.localToGlobal(Offset.zero, ancestor: overlayBox);
    final double top = btnPos.dy + btn.size.height + 8;
    final double right = 14.w;
    final double menuWidth = 140.w;
    final items = widget.items;

    _overlay = OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _close,
        onPanDown: (_) => _close(),
        child: SizedBox.expand(
          child: Stack(
            children: [
              Positioned(
                top: top,
                right: right,
                width: menuWidth,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(10.r),
                  color: Colors.white,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(items.length, (i) {
                        final e = items[i];
                        final isFirst = i == 0;
                        final isLast = i == items.length - 1;
                        final radius = BorderRadius.vertical(
                          top: isFirst ? Radius.circular(10.r) : Radius.zero,
                          bottom: isLast ? Radius.circular(10.r) : Radius.zero,
                        );
                        return InkWell(
                          borderRadius: radius,
                          onTap: () {
                            _close();
                            e.onTap?.call();
                          },
                          child: SizedBox(
                            height: 49.w,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (e.icon.isNotEmpty)
                                    ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                        e.color ?? const Color(0xFF0F172B),
                                        BlendMode.srcIn,
                                      ),
                                      child: Image.asset(
                                        './assets/images/${e.icon}.png',
                                        width: 20.w,
                                        height: 20.w,
                                      ),
                                    ),
                                  if (e.icon.isNotEmpty) SizedBox(width: 8.w),
                                  Text(
                                    e.label,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: e.color ?? const Color(0xFF0F172B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    overlayState.insert(_overlay!);
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void deactivate() {
    _close();
    super.deactivate();
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _btnKey,
      onTap: _show,
      child: widget.child ??
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172B),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(Icons.add, color: Colors.white, size: 22.sp),
          ),
    );
  }
}
