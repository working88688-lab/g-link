import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 全局通用询问弹窗，样式还原 Figma 节点 58:2118。
///
/// 用法：
/// ```dart
/// AppConfirmDialog.show(
///   context: context,
///   title: '全部清空？',
///   content: '清空后，所有的帖子和短视频观看历史将全部消失',
///   onConfirm: () { /* ... */ },
/// );
/// ```
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    this.content,
    this.cancelText,
    this.confirmText,
    this.cancelTextColor = const Color(0xFF1A1F2C),
    this.confirmTextColor = const Color(0xFFFF2056),
    this.showCancel = true,
    this.onCancel,
    this.onConfirm,
  });

  final String title;
  final String? content;
  final String? cancelText;
  final String? confirmText;
  final Color cancelTextColor;
  final Color confirmTextColor;
  final bool showCancel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  /// 弹出弹窗的静态方法，自动处理 Navigator.pop。
  static Future<void> show({
    required BuildContext context,
    required String title,
    String? content,
    String? cancelText,
    String? confirmText,
    Color cancelTextColor = const Color(0xFF1A1F2C),
    Color confirmTextColor = const Color(0xFFFF2056),
    bool showCancel = true,
    VoidCallback? onCancel,
    VoidCallback? onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => AppConfirmDialog(
        title: title,
        content: content,
        cancelText: cancelText,
        confirmText: confirmText,
        cancelTextColor: cancelTextColor,
        confirmTextColor: confirmTextColor,
        showCancel: showCancel,
        onCancel: onCancel,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 48.w),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.w),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 标题 + 内容区 ──────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 22.w, 20.w, 20.w),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF1A1F2C),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                if (content != null && content!.isNotEmpty) ...[
                  SizedBox(height: 10.w),
                  Text(
                    content!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF1A1F2C),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      height: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // ── 横向分割线 ─────────────────────────
          Container(height: 1, color: const Color(0xFFF8F9FE)),
          // ── 按钮区 ────────────────────────────
          SizedBox(
            height: 46.w,
            child: showCancel
                ? Row(
                    children: [
                      // 取消
                      Expanded(
                        child: _ActionButton(
                          text: cancelText ?? 'commonCancel'.tr(),
                          textColor: cancelTextColor,
                          onTap: () {
                            Navigator.of(context).pop();
                            onCancel?.call();
                          },
                        ),
                      ),
                      // 竖向分割线
                      Container(width: 1, color: const Color(0xFFF8F9FE)),
                      // 确认
                      Expanded(
                        child: _ActionButton(
                          text: confirmText ?? 'commonConfirm'.tr(),
                          textColor: confirmTextColor,
                          onTap: () {
                            Navigator.of(context).pop();
                            onConfirm?.call();
                          },
                        ),
                      ),
                    ],
                  )
                : _ActionButton(
                    text: confirmText ?? 'commonConfirm'.tr(),
                    textColor: confirmTextColor,
                    onTap: () {
                      Navigator.of(context).pop();
                      onConfirm?.call();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.text,
    required this.textColor,
    required this.onTap,
  });

  final String text;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2.w),
      child: SizedBox.expand(
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
