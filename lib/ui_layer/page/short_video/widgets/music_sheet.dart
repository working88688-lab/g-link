import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/widgets/app_bottom_sheet.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';

// ──────────────────────────────────────────
// 音乐点击底部弹窗
// ──────────────────────────────────────────
class MusicSheet extends StatefulWidget {
  /// 音乐文本，格式为 "歌名 | 艺术家"，如 "夜曲 | 周杰伦"
  final String musicText;

  const MusicSheet({super.key, required this.musicText});

  static Future<void> show(BuildContext context, {required String musicText}) {
    return AppBottomSheet.show(
      context: context,
      child: MusicSheet(musicText: musicText),
    );
  }

  @override
  State<MusicSheet> createState() => _MusicSheetState();
}

class _MusicSheetState extends State<MusicSheet> {
  bool _isPlaying = false;
  bool _isFavorited = false;

  // 模拟总时长 204 秒（03:24），播放进度值 0.0～1.0
  static const double _totalSeconds = 204.0;
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    final parts = widget.musicText.split(' | ');
    final title = parts.isNotEmpty ? parts[0].trim() : widget.musicText;
    final artist = parts.length > 1 ? parts[1].trim() : '';

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AppBottomSheet 已提供 handle（6px + 4px + 10px = 20px）
            // Figma 封面图距 sheet 顶 29px，补充 9px 间距
            // ── 封面图（圆形占位）────────────────
            ClipOval(
              child: Container(
                width: 155.w,
                height: 155.w,
                color: const Color(0xFFD9D9D9),
                child: Icon(
                  Icons.music_note,
                  size: 72.w,
                  color: Colors.white70,
                ),
              ),
            ),

            SizedBox(height: 20.w),

            // ── 歌名 + 收藏图标 ──────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: const Color(0xFF1A1F2C),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (artist.isNotEmpty) ...[
                        SizedBox(height: 10.w),
                        Text(
                          artist,
                          style: TextStyle(
                            color: const Color(0xFF62748E),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isFavorited = !_isFavorited),
                  child: Padding(
                    padding: EdgeInsets.only(top: 5.w),
                    child: MyImage.asset(
                      _isFavorited
                          ? MyImagePaths.iconCollection
                          : MyImagePaths.iconMusicUncollection,
                      width: 26.w,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 25.w),

            // ── 进度条 ───────────────────────────
            _ProgressSection(
              progress: _progress,
              totalSeconds: _totalSeconds,
              onChanged: (v) => setState(() => _progress = v),
            ),

            SizedBox(height: 10.w),

            // ── 播放按钮 ─────────────────────────
            GestureDetector(
              onTap: () => setState(() => _isPlaying = !_isPlaying),
              child: Container(
                width: 60.w,
                height: 60.w,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1F2C),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 30.w,
                ),
              ),
            ),

            SizedBox(height: 24.w),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// 进度条 + 时间标签
// ──────────────────────────────────────────
class _ProgressSection extends StatelessWidget {
  final double progress;
  final double totalSeconds;
  final ValueChanged<double> onChanged;

  const _ProgressSection({
    required this.progress,
    required this.totalSeconds,
    required this.onChanged,
  });

  String _fmt(double seconds) {
    final s = seconds.toInt();
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentLabel = _fmt(progress * totalSeconds);
    final totalLabel = _fmt(totalSeconds);

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2.w,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4.w),
            overlayShape: SliderComponentShape.noOverlay,
            activeTrackColor: const Color(0xFF1A1F2C),
            inactiveTrackColor: const Color(0xFFE4E4E4),
            thumbColor: const Color(0xFF1A1F2C),
          ),
          child: Slider(
            value: progress,
            onChanged: onChanged,
          ),
        ),
        SizedBox(height: 4.w,),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentLabel,
                style: TextStyle(
                  color: const Color(0xFF45556C),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                totalLabel,
                style: TextStyle(
                  color: const Color(0xFF45556C),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
