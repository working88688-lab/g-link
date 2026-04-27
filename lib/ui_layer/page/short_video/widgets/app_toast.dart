import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';

// ──────────────────────────────────────────
// Toast 类型
// ──────────────────────────────────────────
enum AppToastType {
  /// 成功（绿色 ✓）
  success,

  /// 普通信息（蓝色 ℹ）
  info,

  /// 警告（橙色 ⚠）
  warning,

  /// 错误（红色 ✕）
  error,
}

// ──────────────────────────────────────────
// AppToast 静态工具类
// ──────────────────────────────────────────
class AppToast {
  AppToast._();

  static OverlayEntry? _current;
  static Timer? _timer;

  /// 在当前页面显示 Toast。
  ///
  /// - [type]：图标 / 强调色类型
  /// - [title]：主文案
  /// - [actionLabel]：右侧行动文字，仅当 [onTap] 不为 null 时显示，默认 "查看"
  /// - [onTap]：点击整行或行动按钮的回调
  /// - [duration]：自动消失时长，默认 3 秒
  static void show(
    BuildContext context, {
    required AppToastType type,
    required String title,
    String actionLabel = '查看',
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 3),
  }) {
    _dismiss();

    final overlay = Overlay.of(context);

    _current = OverlayEntry(
      builder: (_) => _AppToastEntry(
        type: type,
        title: title,
        actionLabel: actionLabel,
        onTap: onTap != null
            ? () {
                _dismiss();
                onTap();
              }
            : null,
        onDismiss: _dismiss,
      ),
    );

    overlay.insert(_current!);

    _timer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _current?.remove();
    _current = null;
  }
}

// ──────────────────────────────────────────
// 内部动画包装
// ──────────────────────────────────────────
class _AppToastEntry extends StatefulWidget {
  final AppToastType type;
  final String title;
  final String actionLabel;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _AppToastEntry({
    required this.type,
    required this.title,
    required this.actionLabel,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_AppToastEntry> createState() => _AppToastEntryState();
}

class _AppToastEntryState extends State<_AppToastEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12.w,
      left: 17.w,
      right: 17.w,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: _AppToastBody(
              type: widget.type,
              title: widget.title,
              actionLabel: widget.actionLabel,
              onTap: widget.onTap,
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// Toast 主体 UI
// ──────────────────────────────────────────
class _AppToastBody extends StatelessWidget {
  final AppToastType type;
  final String title;
  final String actionLabel;
  final VoidCallback? onTap;

  const _AppToastBody({
    required this.type,
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  // 每种类型的强调色
  Color get _accentColor => switch (type) {
        AppToastType.success => const Color(0xFF00C67E),
        AppToastType.info => const Color(0xFF1A73E8),
        AppToastType.warning => const Color(0xFFFF9500),
        AppToastType.error => const Color(0xFFFF3B30),
      };

  // 每种类型的图标
  IconData get _icon => switch (type) {
        AppToastType.success => Icons.check,
        AppToastType.info => Icons.info_outline,
        AppToastType.warning => Icons.warning_amber_rounded,
        AppToastType.error => Icons.close,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(45.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 9.5.w),
        child: Row(
          children: [
            // 左侧圆形图标
            Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                color: _accentColor,
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: Colors.white, size: 13.w),
            ),
            SizedBox(width: 8.w),
            // 标题（自动省略）
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF1A1F2C),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 右侧行动文字 + 箭头（仅 onTap 非空时显示）
            if (onTap != null) ...[
              SizedBox(width: 4.w),
              Text(
                actionLabel,
                style: TextStyle(
                  color: const Color(0xFF90A1B9),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(width: 2.w),
              MyImage.asset(MyImagePaths.iconArrowRight, width: 16.w),
            ],
          ],
        ),
      ),
    );
  }
}
