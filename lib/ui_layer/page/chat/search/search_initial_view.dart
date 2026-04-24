import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─────────────────────────────────────────
//  SubView 1：初始（历史记录）
// ─────────────────────────────────────────

class SearchInitialView extends StatelessWidget {
  final List<String> history;
  final VoidCallback onClear;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onTapTag;

  const SearchInitialView({
    super.key,
    required this.history,
    required this.onClear,
    required this.onRemove,
    required this.onTapTag,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.w),
          Row(
            children: [
              Text(
                '历史记录',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172B),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClear,
                child: Text(
                  '清空',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF62748E),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.w),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.w,
            children: history
                .map(
                  (tag) => _HistoryChip(
                    label: tag,
                    onTap: () => onTapTag(tag),
                    onRemove: () => onRemove(tag),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _HistoryChip({
    required this.label,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE3E7ED)),
          borderRadius: BorderRadius.circular(100.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 200.w),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF0F172B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 4.w),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close,
                size: 13.sp,
                color: const Color(0xFF90A1B9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
