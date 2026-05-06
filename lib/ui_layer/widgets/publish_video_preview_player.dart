import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:g_link/ui_layer/widgets/publish_video_preview_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_player/video_player.dart';
import 'package:volume_controller/volume_controller.dart';

/// 发布编辑页内嵌：短视频预览（使用 [VideoPreviewPlayerSurface]）。
class PublishVideoPreviewPlayer extends StatefulWidget {
  const PublishVideoPreviewPlayer({super.key, required this.xFile});

  final XFile xFile;

  @override
  State<PublishVideoPreviewPlayer> createState() =>
      _PublishVideoPreviewPlayerState();
}

class _PublishVideoPreviewPlayerState extends State<PublishVideoPreviewPlayer> {
  VideoPlayerController? _controller;
  bool _busy = true;
  Object? _error;
  bool _videoOnFullscreenRoute = false;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      final c = await _createController(widget.xFile);
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      c.addListener(_onTick);
      setState(() {
        _controller = c;
        _busy = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _busy = false;
        });
      }
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  Future<VideoPlayerController> _createController(XFile x) =>
      publishVideoPreviewCreateController(x);

  Future<void> _openFullscreen() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    setState(() => _videoOnFullscreenRoute = true);
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (ctx, _, __) => VideoPreviewFullscreenPage(
          controller: c,
        ),
      ),
    );
    if (mounted) setState(() => _videoOnFullscreenRoute = false);
  }

  @override
  void dispose() {
    final c = _controller;
    if (c != null) {
      c.removeListener(_onTick);
      c.dispose();
    }
    unawaited(ScreenBrightness.instance.resetApplicationScreenBrightness());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return AspectRatio(
        aspectRatio: 9 / 16,
        child: ColoredBox(
          color: Colors.black,
          child: Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      return AspectRatio(
        aspectRatio: 9 / 16,
        child: ColoredBox(
          color: Colors.black26,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'publishVideoLoadError'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),
        ),
      );
    }

    final c = _controller!;

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: ColoredBox(
        color: Colors.black,
        child: _videoOnFullscreenRoute
            ? const Center(
                child: Icon(Icons.fullscreen,
                    color: Colors.white38, size: 48),
              )
            : VideoPreviewPlayerSurface(
                controller: c,
                isFullscreen: false,
                onOpenFullscreen: _openFullscreen,
              ),
      ),
    );
  }
}

/// 沉浸式全屏预览：与内嵌区共用同一 [VideoPlayerController]。
class VideoPreviewFullscreenPage extends StatefulWidget {
  const VideoPreviewFullscreenPage({super.key, required this.controller});

  final VideoPlayerController controller;

  @override
  State<VideoPreviewFullscreenPage> createState() =>
      _VideoPreviewFullscreenPageState();
}

class _VideoPreviewFullscreenPageState extends State<VideoPreviewFullscreenPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_enterImmersive());
  }

  Future<void> _enterImmersive() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _exitImmersive() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    unawaited(_exitImmersive());
    unawaited(ScreenBrightness.instance.resetApplicationScreenBrightness());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: VideoPreviewPlayerSurface(
        controller: widget.controller,
        isFullscreen: true,
        onCloseFullscreen: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// 通用视频预览控制层：进度、全屏、锁屏、亮度/音量手势、静音等。
/// 由调用方创建并持有 [VideoPlayerController]，本组件不负责 dispose。
class VideoPreviewPlayerSurface extends StatefulWidget {
  const VideoPreviewPlayerSurface({
    super.key,
    required this.controller,
    required this.isFullscreen,
    this.onOpenFullscreen,
    this.onCloseFullscreen,
  });

  final VideoPlayerController controller;
  final bool isFullscreen;
  final VoidCallback? onOpenFullscreen;
  final VoidCallback? onCloseFullscreen;

  @override
  State<VideoPreviewPlayerSurface> createState() =>
      _VideoPreviewPlayerSurfaceState();
}

class _VideoPreviewPlayerSurfaceState extends State<VideoPreviewPlayerSurface> {
  /// 底部控件栏：初始隐藏，点击封面空白处切换；播放结束隐藏。
  bool _showBottomBar = false;
  bool _locked = false;
  bool _scrubbing = false;
  bool _muted = false;
  double _savedVolume = 1.0;

  /// 左：亮度 / 右：系统音量
  _SideDragKind? _sideDrag;
  double _sideDragStartValue = 0;
  double _sideDragAccum = 0;

  /// 中央提示：亮度或音量条
  bool _showGestureHint = false;
  double _gestureHintValue = 0;
  bool _gestureHintIsBrightness = true;
  Timer? _hintTimer;

  bool get _brightnessVolumeSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onVideo);
    _savedVolume = widget.controller.value.volume;
  }

  @override
  void didUpdateWidget(covariant VideoPreviewPlayerSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onVideo);
      widget.controller.addListener(_onVideo);
      _savedVolume = widget.controller.value.volume;
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    widget.controller.removeListener(_onVideo);
    VolumeController.instance.showSystemUI = true;
    super.dispose();
  }

  void _onVideo() {
    final v = widget.controller.value;
    final ms = v.duration.inMilliseconds;
    if (ms > 0) {
      final atEnd = v.position.inMilliseconds >= ms - 100;
      if (atEnd && mounted) {
        setState(() => _showBottomBar = false);
      }
    }
    if (mounted) setState(() {});
  }

  void _onBackgroundTap() {
    if (_locked) return;
    setState(() => _showBottomBar = !_showBottomBar);
  }

  Future<void> _togglePlay() async {
    final c = widget.controller;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
    if (!mounted) return;
    setState(() {
      if (c.value.isPlaying) {
        _showBottomBar = false;
      }
    });
  }

  Future<void> _toggleMute() async {
    final c = widget.controller;
    if (_muted) {
      await c.setVolume(_savedVolume <= 0 ? 1.0 : _savedVolume);
      setState(() => _muted = false);
    } else {
      _savedVolume = c.value.volume;
      if (_savedVolume <= 0) _savedVolume = 1.0;
      await c.setVolume(0);
      setState(() => _muted = true);
    }
    if (mounted) setState(() => _showBottomBar = true);
  }

  void _toggleLock() {
    setState(() {
      _locked = !_locked;
      if (_locked) {
        _showBottomBar = false;
      }
    });
  }

  Future<void> _beginSideDrag(double dx, double width) async {
    if (!_brightnessVolumeSupported || _locked) return;
    if (width <= 0) return;
    VolumeController.instance.showSystemUI = false;
    if (dx < width * 0.32) {
      _sideDrag = _SideDragKind.brightness;
      _sideDragAccum = 0;
      try {
        _sideDragStartValue = await ScreenBrightness.instance.application;
      } catch (_) {
        _sideDragStartValue = 0.5;
      }
    } else if (dx > width * 0.68) {
      _sideDrag = _SideDragKind.volume;
      _sideDragAccum = 0;
      try {
        _sideDragStartValue = await VolumeController.instance.getVolume();
      } catch (_) {
        _sideDragStartValue = 0.5;
      }
    } else {
      _sideDrag = null;
    }
  }

  Future<void> _updateSideDrag(double deltaDy, double height) async {
    final kind = _sideDrag;
    if (kind == null || height <= 0) return;
    _sideDragAccum += -deltaDy / height;
    final next = (_sideDragStartValue + _sideDragAccum * 1.25).clamp(0.0, 1.0);
    if (kind == _SideDragKind.brightness) {
      try {
        await ScreenBrightness.instance.setApplicationScreenBrightness(next);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _gestureHintIsBrightness = true;
          _gestureHintValue = next;
          _showGestureHint = true;
        });
      }
    } else {
      try {
        await VolumeController.instance.setVolume(next);
      } catch (_) {}
      if (_muted && next > 0.02) {
        await widget.controller.setVolume(next);
        if (mounted) setState(() => _muted = false);
      }
      if (mounted) {
        setState(() {
          _gestureHintIsBrightness = false;
          _gestureHintValue = next;
          _showGestureHint = true;
        });
      }
    }
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(milliseconds: 520), () {
      if (mounted) setState(() => _showGestureHint = false);
    });
  }

  void _endSideDrag() {
    _sideDrag = null;
    _sideDragAccum = 0;
    VolumeController.instance.showSystemUI = true;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (!c.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white70,
          strokeWidth: 2,
        ),
      );
    }

    final dur = c.value.duration;
    final pos = c.value.position;
    final playing = c.value.isPlaying;
    final maxMs =
        dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;
    final posMs = _scrubbing
        ? _scrubPositionMs
        : pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble();
    final aspect = c.value.aspectRatio > 0 ? c.value.aspectRatio : 9 / 16;

    return LayoutBuilder(
      builder: (context, bc) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _locked ? null : _onBackgroundTap,
          onVerticalDragStart: _locked
              ? null
              : (d) => unawaited(
                    _beginSideDrag(d.localPosition.dx, bc.maxWidth),
                  ),
          onVerticalDragUpdate: _locked
              ? null
              : (d) => unawaited(
                    _updateSideDrag(d.delta.dy, bc.maxHeight),
                  ),
          onVerticalDragEnd: _locked ? null : (_) => _endSideDrag(),
          onVerticalDragCancel: _endSideDrag,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Colors.black,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: aspect,
                    child: VideoPlayer(c),
                  ),
                ),
              ),
              if (!_locked)
                IgnorePointer(
                  ignoring: playing && !_showBottomBar,
                  child: Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: !playing || _showBottomBar ? 1 : 0,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _togglePlay,
                          child: Container(
                            padding: EdgeInsets.all(
                              widget.isFullscreen ? 11 : 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: widget.isFullscreen ? 30 : 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_showGestureHint && _brightnessVolumeSupported)
                Positioned(
                  left: _gestureHintIsBrightness ? 12 : null,
                  right: _gestureHintIsBrightness ? null : 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _BrightnessVolumeHint(
                      isBrightness: _gestureHintIsBrightness,
                      value: _gestureHintValue,
                    ),
                  ),
                ),
              if (_locked)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _LockedBottomGradient(
                    bottomInset: MediaQuery.paddingOf(context).bottom,
                    onUnlock: _toggleLock,
                  ),
                ),
              if (!_locked && _showBottomBar)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _ControlBar(
                    playing: playing,
                    positionMs: posMs,
                    maxMs: maxMs,
                    isMuted: _muted,
                    showFullscreen: !widget.isFullscreen,
                    bottomInset: MediaQuery.paddingOf(context).bottom,
                    onTogglePlay: _togglePlay,
                    onScrubStart: () {
                      setState(() {
                        _scrubbing = true;
                        _scrubPositionMs = posMs;
                      });
                    },
                    onScrubUpdate: (v) {
                      setState(() => _scrubPositionMs = v);
                    },
                    onScrubEnd: (v) async {
                      await c.seekTo(Duration(milliseconds: v.round()));
                      setState(() => _scrubbing = false);
                    },
                    onToggleMute: _toggleMute,
                    onToggleLock: _toggleLock,
                    onFullscreen: widget.isFullscreen
                        ? widget.onCloseFullscreen
                        : widget.onOpenFullscreen,
                    timeLabel: _formatTime(pos, dur),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  double _scrubPositionMs = 0;

  String _formatTime(Duration pos, Duration dur) {
    String two(int n) => n.toString().padLeft(2, '0');
    final p = '${two(pos.inMinutes.remainder(60))}:${two(pos.inSeconds.remainder(60))}';
    final d = '${two(dur.inMinutes.remainder(60))}:${two(dur.inSeconds.remainder(60))}';
    return '$p / $d';
  }
}

enum _SideDragKind { brightness, volume }

class _BrightnessVolumeHint extends StatelessWidget {
  const _BrightnessVolumeHint({
    required this.isBrightness,
    required this.value,
  });

  final bool isBrightness;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBrightness ? Icons.brightness_6 : Icons.volume_up_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 3,
            height: 48,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 3,
                height: 48 * value.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedBottomGradient extends StatelessWidget {
  const _LockedBottomGradient({
    required this.bottomInset,
    required this.onUnlock,
  });

  final double bottomInset;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.88),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'publishVideoUnlock'.tr(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onPressed: onUnlock,
              icon: const Icon(Icons.lock_open_rounded,
                  color: Colors.white, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.playing,
    required this.positionMs,
    required this.maxMs,
    required this.isMuted,
    required this.showFullscreen,
    required this.bottomInset,
    required this.onTogglePlay,
    required this.onScrubStart,
    required this.onScrubUpdate,
    required this.onScrubEnd,
    required this.onToggleMute,
    required this.onToggleLock,
    required this.onFullscreen,
    required this.timeLabel,
  });

  final bool playing;
  final double positionMs;
  final double maxMs;
  final bool isMuted;
  final bool showFullscreen;
  final double bottomInset;
  final Future<void> Function() onTogglePlay;
  final VoidCallback onScrubStart;
  final ValueChanged<double> onScrubUpdate;
  final ValueChanged<double> onScrubEnd;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleLock;
  final VoidCallback? onFullscreen;
  final String timeLabel;

  static const Color _accentRed = Color(0xFFFF3B4A);
  static const Color _trackBg = Color(0xFF4A4A4A);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.22),
            Colors.black.withValues(alpha: 0.62),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Theme(
          data: Theme.of(context).copyWith(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            sliderTheme: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 3.5),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 6),
              activeTrackColor: _accentRed,
              inactiveTrackColor: _trackBg,
              thumbColor: _accentRed,
              overlayColor: _accentRed.withValues(alpha: 0.16),
              padding: EdgeInsets.zero,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: SizedBox(
                  height: 18,
                  child: Slider(
                    value: positionMs.clamp(0.0, maxMs),
                    max: maxMs,
                    onChangeStart: (_) => onScrubStart(),
                    onChanged: onScrubUpdate,
                    onChangeEnd: onScrubEnd,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 0, 10, 1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _ControlBarIcon(
                      tooltip: playing
                          ? 'publishVideoPause'.tr()
                          : 'publishVideoPlay'.tr(),
                      onTap: () => onTogglePlay(),
                      icon: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                    _ControlBarIcon(
                      tooltip: isMuted
                          ? 'publishVideoUnmute'.tr()
                          : 'publishVideoMute'.tr(),
                      onTap: onToggleMute,
                      icon: Icon(
                        isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          timeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ControlBarIcon(
                          tooltip: 'publishVideoLock'.tr(),
                          onTap: onToggleLock,
                          icon: const Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                        if (showFullscreen && onFullscreen != null)
                          _ControlBarIcon(
                            tooltip: 'publishVideoFullscreen'.tr(),
                            onTap: onFullscreen!,
                            icon: const Icon(
                              Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        if (!showFullscreen && onFullscreen != null)
                          _ControlBarIcon(
                            tooltip: 'publishVideoExitFullscreen'.tr(),
                            onTap: onFullscreen!,
                            icon: const Icon(
                              Icons.fullscreen_exit_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlBarIcon extends StatelessWidget {
  const _ControlBarIcon({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final Widget icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 30,
            height: 22,
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}
