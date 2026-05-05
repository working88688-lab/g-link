import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:g_link/ui_layer/widgets/publish_video_preview_controller.dart';
import 'package:video_player/video_player.dart';

/// 短视频剪辑页：对齐剪映（CapCut）式编排——顶栏、预览、时间码与工具行、刻度尺 + 中轴指示条滑动时间轴、底部六宫格。
class PublishVideoEditorPage extends StatefulWidget {
  const PublishVideoEditorPage({super.key, required this.xFile});

  final XFile xFile;

  @override
  State<PublishVideoEditorPage> createState() => _PublishVideoEditorPageState();
}

class _PublishVideoEditorPageState extends State<PublishVideoEditorPage> {
  static const Color _capCutRed = Color(0xFFFE2C55);
  static const Color _capCutBarBg = Color(0xFF121212);
  static const Color _capCutChipBg = Color(0xFF2C2C2C);
  static const Color _capCutNavMuted = Color(0xFF888888);
  static const double _thumbSegW = 46.0;
  static const double _rulerH = 22.0;
  /// 时间轴与视频缩略条之间的间距。
  static const double _rulerGap = 12.0;
  /// 缩略条下白线余量 + Stack 底部留白（白线在缩略条上下对称各伸出 [_playheadLinePad]）。
  static const double _timelineChromeBelowTrack = 18.0;
  static const double _playheadLinePad = 10.0;

  VideoPlayerController? _controller;
  bool _loading = true;
  Object? _error;
  List<Uint8List?> _thumbnails = [];
  int _capCutBottomIndex = 0;

  late final ScrollController _timelineScrollController;
  bool _timelineProgrammaticScroll = false;

  static const List<(IconData, String)> _capNavItems = [
    (Icons.content_cut_rounded, 'publishVideoEditorNavEdit'),
    (Icons.music_note_rounded, 'publishVideoEditorNavAudio'),
    (Icons.text_fields_rounded, 'publishVideoEditorNavText'),
    (Icons.emoji_emotions_outlined, 'publishVideoEditorNavSticker'),
    (Icons.picture_in_picture_alt_outlined, 'publishVideoEditorNavPip'),
    (Icons.auto_awesome_rounded, 'publishVideoEditorNavEffect'),
  ];

  @override
  void initState() {
    super.initState();
    _timelineScrollController = ScrollController();
    _timelineScrollController.addListener(_handleTimelineScroll);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    unawaited(_init());
  }

  int get _thumbTimelineSegments =>
      _thumbnails.isEmpty ? 10 : _thumbnails.length;

  void _handleTimelineScroll() {
    if (_timelineProgrammaticScroll) return;
    if (!_timelineScrollController.hasClients) return;
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final dur = c.value.duration.inMilliseconds;
    if (dur <= 0) return;
    final maxS = _timelineScrollController.position.maxScrollExtent;
    if (maxS <= 0) return;
    final off = _timelineScrollController.offset.clamp(0.0, maxS);
    final ms = (off / maxS * dur).round().clamp(0, dur);
    unawaited(c.seekTo(Duration(milliseconds: ms)));
  }

  void _syncTimelineScrollFromVideo() {
    if (!_timelineScrollController.hasClients) return;
    if (_timelineScrollController.position.isScrollingNotifier.value) {
      return;
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final dur = c.value.duration.inMilliseconds;
    if (dur <= 0) return;
    final maxS = _timelineScrollController.position.maxScrollExtent;
    if (maxS <= 0) return;
    final ms = c.value.position.inMilliseconds.clamp(0, dur);
    final target = ms / dur * maxS;
    _timelineProgrammaticScroll = true;
    _timelineScrollController.jumpTo(target.clamp(0.0, maxS));
    _timelineProgrammaticScroll = false;
  }

  Future<void> _waitForRecordedBytes() async {
    for (var i = 0; i < 80; i++) {
      try {
        final len = await widget.xFile.length();
        if (len > 0) return;
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  Future<void> _init() async {
    try {
      await _waitForRecordedBytes();
      if (!mounted) return;
      final c = await publishVideoPreviewCreateController(widget.xFile);
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      await c.pause();
      await c.seekTo(Duration.zero);
      c.addListener(_onVideoTick);
      setState(() {
        _controller = c;
        _loading = false;
      });
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _syncTimelineScrollFromVideo());
      unawaited(_loadThumbnails(c));
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadThumbnails(VideoPlayerController c) async {
    final path = widget.xFile.path;
    if (path.isEmpty) return;
    const count = 10;
    final durMs = c.value.duration.inMilliseconds;
    if (durMs <= 0) {
      if (mounted) setState(() => _thumbnails = List.filled(count, null));
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _syncTimelineScrollFromVideo());
      return;
    }
    final list = List<Uint8List?>.filled(count, null);
    for (var i = 0; i < count; i++) {
      final t =
          (durMs * i / (count > 1 ? count - 1 : 1)).round().clamp(0, durMs);
      try {
        list[i] = await VideoThumbnail.thumbnailData(
          video: path,
          timeMs: t,
          maxWidth: 160,
          maxHeight: 200,
          imageFormat: ImageFormat.JPEG,
          quality: 55,
        );
      } catch (_) {
        list[i] = null;
      }
      if (mounted) setState(() => _thumbnails = List.from(list));
    }
    if (mounted) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _syncTimelineScrollFromVideo());
    }
  }

  void _onVideoTick() {
    if (mounted) setState(() {});
    _syncTimelineScrollFromVideo();
  }

  @override
  void dispose() {
    _timelineScrollController.removeListener(_handleTimelineScroll);
    _timelineScrollController.dispose();
    final c = _controller;
    if (c != null) {
      c.removeListener(_onVideoTick);
      c.dispose();
    }
    super.dispose();
  }

  Widget _timelineThumbCell(int idx, double innerH) {
    final thumbs = _thumbnails;
    final data = idx < thumbs.length ? thumbs[idx] : null;
    if (data != null) {
      return Image.memory(
        data,
        fit: BoxFit.cover,
        width: _thumbSegW,
        height: innerH,
        gaplessPlayback: true,
      );
    }
    return Container(
      width: _thumbSegW,
      height: innerH,
      color: const Color(0xFF1E1E1E),
      alignment: Alignment.center,
      child: Icon(
        Icons.movie_outlined,
        size: 18,
        color: Colors.white.withValues(alpha: 0.2),
      ),
    );
  }

  void _toastComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('publishComingSoon'.tr())),
    );
  }

  void _pop() {
    Navigator.of(context).pop();
  }

  Future<void> _togglePreviewPlay() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      if (c.value.duration > Duration.zero &&
          c.value.position >= c.value.duration) {
        await c.seekTo(Duration.zero);
      }
      await c.play();
    }
    if (mounted) setState(() {});
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildCapCutTopBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: _pop,
                icon:
                    const Icon(Icons.close_rounded, color: Colors.white, size: 26),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: _toastComingSoon,
                icon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: 26,
                ),
              ),
              const Spacer(),
              Material(
                color: _capCutChipBg,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _toastComingSoon,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'publishVideoEditorResolution'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: _capCutRed,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: _pop,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'publishVideoEditorExport'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(VideoPlayerController c) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sw = c.value.size.width;
              final sh = c.value.size.height;
              if (sw <= 0 || sh <= 0) return const SizedBox.shrink();
              final ar = sw / sh;
              final maxW = constraints.maxWidth;
              final maxH = constraints.maxHeight;
              var dispW = maxW;
              var dispH = dispW / ar;
              if (dispH > maxH) {
                dispH = maxH;
                dispW = dispH * ar;
              }
              return SizedBox(
                width: dispW,
                height: dispH,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  fit: StackFit.expand,
                  children: [
                    FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: sw,
                        height: sh,
                        child: VideoPlayer(c),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: dispH * 0.28,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: const CircleBorder(),
                        child: IconButton(
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          onPressed: _toastComingSoon,
                          icon: Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white.withValues(alpha: 0.95),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCapCutControlRow(VideoPlayerController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 8, 4),
      child: Row(
        children: [
          Text(
            '${_fmt(c.value.position)} / ${_fmt(c.value.duration)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: _togglePreviewPlay,
            icon: Icon(
              c.value.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 38, minHeight: 40),
            onPressed: _toastComingSoon,
            icon: Icon(
              Icons.view_sidebar_rounded,
              color: Colors.white.withValues(alpha: 0.88),
              size: 22,
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 38, minHeight: 40),
            onPressed: _toastComingSoon,
            icon: Icon(
              Icons.undo_rounded,
              color: Colors.white.withValues(alpha: 0.88),
              size: 22,
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 38, minHeight: 40),
            onPressed: _toastComingSoon,
            icon: Icon(
              Icons.redo_rounded,
              color: Colors.white.withValues(alpha: 0.88),
              size: 22,
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 38, minHeight: 40),
            onPressed: _toastComingSoon,
            icon: Icon(
              Icons.fit_screen_rounded,
              color: Colors.white.withValues(alpha: 0.88),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineWithRuler(VideoPlayerController c) {
    const addBtnSize = 40.0;
    const gap = 8.0;
    const trackH = 44.0;
    final segs = _thumbTimelineSegments;
    final timelineStackH =
        _rulerH + _rulerGap + trackH + _timelineChromeBelowTrack;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final timelineW = constraints.maxWidth - addBtnSize - gap;
          return SizedBox(
            height: timelineStackH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: timelineW,
                  height: timelineStackH,
                  child: LayoutBuilder(
                    builder: (context, inner) {
                      final midW = inner.maxWidth;
                      final padW = midW / 2;
                      final stripW = segs * _thumbSegW;
                      final contentW = padW * 2 + stripW;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SingleChildScrollView(
                            controller: _timelineScrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            child: SizedBox(
                              width: contentW,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _CapCutRulerStrip(
                                    rulerHeight: _rulerH,
                                    width: contentW,
                                    padW: padW,
                                    stripW: stripW,
                                    duration: c.value.duration,
                                  ),
                                  SizedBox(height: _rulerGap),
                                  SizedBox(
                                    height: trackH,
                                    child: Row(
                                      children: [
                                        SizedBox(width: padW),
                                        for (var idx = 0; idx < segs; idx++)
                                          SizedBox(
                                            width: _thumbSegW,
                                            height: trackH,
                                            child: _timelineThumbCell(
                                                idx, trackH),
                                          ),
                                        SizedBox(width: padW),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _CapCutStackPlayhead(
                            trackTop: _rulerH + _rulerGap,
                            trackH: trackH,
                            linePadBeyondTrack: _playheadLinePad,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(width: gap),
                _AddClipButton(onTap: _toastComingSoon, size: addBtnSize),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCapCutBottomNav(double bottomInset) {
    return Padding(
      padding: EdgeInsets.fromLTRB(2, 10, 2, bottomInset + 6),
      child: Row(
        children: List.generate(_capNavItems.length, (i) {
          final spec = _capNavItems[i];
          final sel = _capCutBottomIndex == i;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() => _capCutBottomIndex = i);
                if (i != 0) _toastComingSoon();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    spec.$1,
                    size: 25,
                    color: sel ? Colors.white : _capCutNavMuted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spec.$2.tr(),
                    style: TextStyle(
                      fontSize: 10,
                      color: sel ? Colors.white : _capCutNavMuted,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCapCutTopBar(),
          Expanded(
            flex: 11,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _error != null || c == null || !c.value.isInitialized
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            kDebugMode
                                ? _error.toString()
                                : 'publishVideoLoadError'.tr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    : _buildPreview(c),
          ),
          Expanded(
            flex: 10,
            child: ColoredBox(
              color: _capCutBarBg,
              child: c != null && c.value.isInitialized
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildCapCutControlRow(c),
                        _buildTimelineWithRuler(c),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _OriginalSoundTile(onTap: _toastComingSoon),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _AddMusicBar(onTap: _toastComingSoon),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        _buildCapCutBottomNav(bottomPad),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapCutRulerStrip extends StatelessWidget {
  const _CapCutRulerStrip({
    required this.rulerHeight,
    required this.width,
    required this.padW,
    required this.stripW,
    required this.duration,
  });

  final double rulerHeight;
  final double width;
  final double padW;
  final double stripW;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, rulerHeight),
      painter: _CapCutRulerPainter(
        padW: padW,
        stripW: stripW,
        duration: duration,
      ),
    );
  }
}

class _CapCutRulerPainter extends CustomPainter {
  _CapCutRulerPainter({
    required this.padW,
    required this.stripW,
    required this.duration,
  });

  final double padW;
  final double stripW;
  final Duration duration;

  /// 参考剪映：「分:秒」两位分、两位秒，如 `00:08`。
  static String _mmSsLabel(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 按像素密度选择主刻度间隔（秒）；主刻度上显示数字，中间为奇数秒时画圆点（与 2s 主步长一致）。
  static int _pickMajorStepSec(double pxPerSec) {
    if (pxPerSec >= 18) return 2;
    if (pxPerSec >= 9) return 5;
    if (pxPerSec >= 4.5) return 10;
    if (pxPerSec >= 2) return 30;
    return 60;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final lineY = size.height - 4;
    final durMs = duration.inMilliseconds;
    if (stripW <= 0) return;

    final durSec = durMs > 0 ? durMs / 1000.0 : 0.0;

    canvas.drawLine(
      Offset(padW, lineY),
      Offset(padW + stripW, lineY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = 1,
    );

    if (durSec <= 0) {
      canvas.drawLine(
        Offset(padW, lineY - 8),
        Offset(padW, lineY),
        Paint()
            ..color = Colors.white.withValues(alpha: 0.55)
            ..strokeWidth = 1,
      );
      final tp0 = TextPainter(
        text: TextSpan(
          text: _mmSsLabel(0),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 9,
            fontWeight: FontWeight.w400,
            fontFeatures: const [ui.FontFeature.tabularFigures()],
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: 56);
      tp0.paint(canvas, Offset(padW - tp0.width / 2, 0.5));
      return;
    }

    final pxPerSec = stripW / durSec;
    final majorStep = _pickMajorStepSec(pxPerSec);
    // 仅在主步长为 2s 且密度足够时，在奇数秒画参考图里的小圆点。
    final showOddSecondDots = majorStep == 2 && pxPerSec >= 14;

    final lastSec = durSec.ceil();
    const minDotPx = 5.0;
    double? lastDotX;

    for (var sec = 0; sec <= lastSec; sec++) {
      final tSec = sec.toDouble();
      if (tSec - durSec > 1e-6) break;

      final x = padW + (tSec / durSec) * stripW;
      final isMajor = sec % majorStep == 0;

      if (isMajor) {
        canvas.drawLine(
          Offset(x, lineY - 8),
          Offset(x, lineY),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.52)
            ..strokeWidth = 1,
        );
        final tp = TextPainter(
          text: TextSpan(
            text: _mmSsLabel(sec),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 9,
              fontWeight: FontWeight.w400,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout(maxWidth: 56);
        tp.paint(canvas, Offset(x - tp.width / 2, 0.5));
        continue;
      }

      if (showOddSecondDots && sec % 2 == 1) {
        if (lastDotX != null && (x - lastDotX) < minDotPx) continue;
        lastDotX = x;
        canvas.drawCircle(
          Offset(x, lineY - 3),
          1.2,
          Paint()..color = Colors.white.withValues(alpha: 0.48),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CapCutRulerPainter old) {
    return old.padW != padW ||
        old.stripW != stripW ||
        old.duration != duration;
  }
}

class _CapCutStackPlayhead extends StatelessWidget {
  const _CapCutStackPlayhead({
    required this.trackTop,
    required this.trackH,
    required this.linePadBeyondTrack,
  });

  /// 缩略条上沿在 Stack 内的 y。
  final double trackTop;
  final double trackH;
  /// 白线在缩略条上下各多出的长度，使整条缩略条落在白线垂直范围的正中。
  final double linePadBeyondTrack;

  static const double _lineW = 1.0;

  @override
  Widget build(BuildContext context) {
    final lineTop = trackTop - linePadBeyondTrack;
    final lineBottom = trackTop + trackH + linePadBeyondTrack;
    final lineH = lineBottom - lineTop;
    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, c) {
            final cx = c.maxWidth / 2;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: cx - _lineW / 2,
                  top: lineTop,
                  width: _lineW,
                  height: lineH,
                  child: const ColoredBox(color: Colors.white),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AddClipButton extends StatelessWidget {
  const _AddClipButton({required this.onTap, required this.size});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final r = size * 0.22;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.add_rounded,
            color: Colors.black.withValues(alpha: 0.88),
            size: size * 0.56,
          ),
        ),
      ),
    );
  }
}

class _OriginalSoundTile extends StatelessWidget {
  const _OriginalSoundTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF262626),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 70,
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.volume_up_rounded,
                color: Colors.white.withValues(alpha: 0.92),
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                'publishVideoEditorOriginalSoundOn'.tr(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMusicBar extends StatelessWidget {
  const _AddMusicBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF262626),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'publishVideoEditorAddMusic'.tr(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
