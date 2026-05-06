import 'dart:async';
import 'dart:math' show pi;

import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:g_link/ui_layer/page/media_picker_page.dart';
import 'package:g_link/ui_layer/page/publish_compose_page.dart';
import 'package:g_link/ui_layer/page/publish_video_record_review_page.dart';
import 'package:g_link/ui_layer/router/approute_observer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

enum PublishCaptureMode { post, shortVideo }

/// 全屏拍摄页：发布帖子（拍照）/ 发布短视频（点按开始/停止录制），与设计稿布局一致。
class PublishPage extends StatefulWidget {
  const PublishPage({super.key});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage>
    with WidgetsBindingObserver, RouteAware {
  static const Duration _maxVideoRecord = Duration(seconds: 15);

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  PublishCaptureMode _mode = PublishCaptureMode.shortVideo;
  bool _recording = false;
  bool _busy = false;
  bool _loadingCam = true;
  String? _camError;
  Timer? _recordTicker;
  Duration _recordElapsed = Duration.zero;

  bool _routeAwareSubscribed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    unawaited(_prepareCamera());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routeAwareSubscribed) {
      final route = ModalRoute.of(context);
      if (route is PageRoute) {
        AppRouteObserver().routeObserver.subscribe(this, route);
        _routeAwareSubscribed = true;
      }
    }
  }

  @override
  void dispose() {
    if (_routeAwareSubscribed) {
      AppRouteObserver().routeObserver.unsubscribe(this);
      _routeAwareSubscribed = false;
    }
    _recordTicker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeController());
    super.dispose();
  }

  @override
  void didPopNext() {
    unawaited(_resumeCameraPreviewIfNeeded());
  }

  Future<void> _resumeCameraPreviewIfNeeded() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || kIsWeb) return;
    try {
      await c.resumePreview();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (c != null && c.value.isInitialized) {
        _recordTicker?.cancel();
        _recordTicker = null;
        unawaited(_disposeController());
        if (mounted) {
          setState(() {
            _recording = false;
            _recordElapsed = Duration.zero;
          });
        }
      }
      return;
    }
    if (state == AppLifecycleState.resumed && !kIsWeb) {
      if (_controller == null || !(_controller?.value.isInitialized ?? false)) {
        unawaited(_prepareCamera());
      }
    }
  }

  Future<void> _disposeController() async {
    final old = _controller;
    _controller = null;
    await old?.dispose();
  }

  Future<void> _prepareCamera() async {
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _loadingCam = false;
          _camError = 'publishCameraWebUnsupported'.tr();
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loadingCam = true;
        _camError = null;
      });
    }

    final camOk = await Permission.camera.request();
    if (!camOk.isGranted) {
      if (mounted) {
        setState(() {
          _loadingCam = false;
          _camError = 'publishCameraPermission'.tr();
        });
      }
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _loadingCam = false;
            _camError = 'publishCameraInitFailed'.tr();
          });
        }
        return;
      }
      final backIdx = _cameras
          .indexWhere((d) => d.lensDirection == CameraLensDirection.back);
      _cameraIndex =
          backIdx >= 0 ? backIdx : _cameraIndex.clamp(0, _cameras.length - 1);
      await _bindCamera(_cameraIndex);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingCam = false;
          _camError = 'publishCameraInitFailed'.tr();
        });
      }
    }
  }

  Future<void> _bindCamera(int index) async {
    await _disposeController();
    if (_cameras.isEmpty) return;

    final i = index.clamp(0, _cameras.length - 1);
    final desc = _cameras[i];

    final next = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await next.initialize();
      if (!mounted) {
        await next.dispose();
        return;
      }
      setState(() {
        _controller = next;
        _cameraIndex = i;
        _loadingCam = false;
        _camError = null;
      });
    } catch (_) {
      await next.dispose();
      if (mounted) {
        setState(() {
          _loadingCam = false;
          _camError = 'publishCameraInitFailed'.tr();
        });
      }
    }
  }

  Future<void> _flipCamera() async {
    if (_recording || _busy || _cameras.length < 2) return;
    final current = _cameras[_cameraIndex].lensDirection;
    final want = current == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    final idx = _cameras.indexWhere((c) => c.lensDirection == want);
    if (idx < 0) return;
    setState(() => _busy = true);
    await _bindCamera(idx);
    if (mounted) setState(() => _busy = false);
  }

  void _cancelRecordTicker() {
    _recordTicker?.cancel();
    _recordTicker = null;
  }

  void _startRecordTicker() {
    _cancelRecordTicker();
    _recordElapsed = Duration.zero;
    _recordTicker = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (!_recording) {
        t.cancel();
        return;
      }
      final next = _recordElapsed + const Duration(milliseconds: 50);
      if (next >= _maxVideoRecord) {
        _recordElapsed = _maxVideoRecord;
        t.cancel();
        _recordTicker = null;
        setState(() {});
        unawaited(_completeVideoRecording());
        return;
      }
      setState(() => _recordElapsed = next);
    });
  }

  Future<void> _completeVideoRecording() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _busy) return;
    if (!c.value.isRecordingVideo) return;

    _cancelRecordTicker();
    setState(() => _busy = true);
    try {
      final file = await c.stopVideoRecording();
      if (!mounted) return;
      if (!kIsWeb) {
        try {
          await c.pausePreview();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _recording = false;
        _recordElapsed = Duration.zero;
      });
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (ctx) => PublishVideoRecordReviewPage(xFile: file),
          fullscreenDialog: true,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _recording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('publishCameraInitFailed'.tr())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _recordElapsed = Duration.zero;
        });
      }
    }
  }

  Future<void> _onShutter() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _busy) return;

    if (_mode == PublishCaptureMode.post) {
      setState(() => _busy = true);
      try {
        final file = await c.takePicture();
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (ctx) =>
                PublishComposePage(media: [file], isVideo: false),
            fullscreenDialog: true,
          ),
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('publishCameraInitFailed'.tr())),
          );
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    if (_recording) {
      await _completeVideoRecording();
      return;
    }

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('publishMicPermission'.tr())),
        );
      }
      return;
    }
    setState(() => _busy = true);
    try {
      await c.startVideoRecording();
      if (mounted) {
        setState(() {
          _recording = true;
          _busy = false;
        });
        _startRecordTicker();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _cancelRecordTicker();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('publishCameraInitFailed'.tr())),
        );
      }
    }
  }

  Future<void> _openAlbum() async {
    if (_busy || _recording) return;
    setState(() => _busy = true);
    try {
      if (kIsWeb) {
        final picker = ImagePicker();
        if (_mode == PublishCaptureMode.post) {
          final list = await picker.pickMultiImage();
          if (list.isNotEmpty && mounted) {
            await Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (ctx) => PublishComposePage(
                  media: list,
                  isVideo: false,
                ),
                fullscreenDialog: true,
              ),
            );
          }
          return;
        }
        final XFile? x =
            await picker.pickVideo(source: ImageSource.gallery);
        if (x != null && mounted) {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (ctx) => PublishComposePage(
                media: [x],
                isVideo: true,
              ),
              fullscreenDialog: true,
            ),
          );
        }
        return;
      }

      final result = await Navigator.of(context).push<MediaPickResult?>(
        MaterialPageRoute<MediaPickResult?>(
          fullscreenDialog: true,
          builder: (ctx) => MediaPickerPage(
            maxSelection:
                _mode == PublishCaptureMode.post ? 9 : 1,
          ),
        ),
      );
      if (result != null && mounted) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (ctx) => PublishComposePage(
              media: result.files,
              isVideo: result.isVideo,
            ),
            fullscreenDialog: true,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toastComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('publishComingSoon'.tr())),
    );
  }

  void _onModeChanged(PublishCaptureMode mode) {
    if (_mode == mode) return;
    if (_recording) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('publishStopRecordingFirst'.tr())),
      );
      return;
    }
    setState(() => _mode = mode);
  }

  /// 横向滑动切换模式（单套 UI，只更新 [_mode]）。
  void _onHorizontalSwipeEnd(DragEndDetails details) {
    if (_recording) return;
    final v = details.primaryVelocity;
    if (v == null) return;
    const threshold = 280.0;
    if (v < -threshold) {
      if (_mode != PublishCaptureMode.shortVideo) {
        setState(() => _mode = PublishCaptureMode.shortVideo);
      }
    } else if (v > threshold) {
      if (_mode != PublishCaptureMode.post) {
        setState(() => _mode = PublishCaptureMode.post);
      }
    }
  }

  /// 拍摄页控件层：仅一份，状态由 [_mode] 驱动。
  Widget _buildCaptureChrome(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return GestureDetector(
      onHorizontalDragEnd: _onHorizontalSwipeEnd,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 44, minHeight: 44),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ModeTab(
                            label: 'publishCaptureTabPost'.tr(),
                            selected: _mode == PublishCaptureMode.post,
                            onTap: () =>
                                _onModeChanged(PublishCaptureMode.post),
                          ),
                          const SizedBox(width: 28),
                          _ModeTab(
                            label: 'publishCaptureTabVideo'.tr(),
                            selected:
                                _mode == PublishCaptureMode.shortVideo,
                            onTap: () => _onModeChanged(
                                PublishCaptureMode.shortVideo),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              if (_mode == PublishCaptureMode.shortVideo)
                Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toastComingSoon,
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.music_note,
                                color: Colors.white.withValues(alpha: 0.95),
                                size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'publishSelectMusic'.tr(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(6, 0, 6, bottomInset + 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _BottomThumb(
                          onTap: _toastComingSoon,
                          icon: Icons.auto_awesome,
                          label: 'publishEffect'.tr(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _ShutterButton(
                        recording: _recording,
                        busy: _busy,
                        onTap: _onShutter,
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _BottomThumb(
                          onTap: _openAlbum,
                          icon: Icons.image_outlined,
                          label: 'publishAlbum'.tr(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 4,
          bottom: bottomInset + 108,
          child: _RightToolColumn(
            mode: _mode,
            onFlip: _flipCamera,
            onClip: _toastComingSoon,
            onCrop: _toastComingSoon,
            onText: _toastComingSoon,
            onBeautify: _toastComingSoon,
            onFilter: _toastComingSoon,
            flipEnabled: !_recording && !_busy && _cameras.length > 1,
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildPreview() {
    final c = _controller;
    if (c != null && c.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: c.value.previewSize?.height ?? 1,
          height: c.value.previewSize?.width ?? 1,
          child: CameraPreview(c),
        ),
      );
    }
    return ColoredBox(
      color: Colors.grey.shade900,
      child: Center(
        child: Icon(Icons.videocam_off_outlined,
            size: 56, color: Colors.white.withValues(alpha: 0.4)),
      ),
    );
  }

  Widget _buildErrorLayer() {
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _camError ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _prepareCamera,
              child: Text('commonRetry'.tr(),
                  style: const TextStyle(color: Colors.white)),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final immersiveShortVideoRecord =
        _recording && _mode == PublishCaptureMode.shortVideo;
    final recordProgress = (_recordElapsed.inMilliseconds /
            _maxVideoRecord.inMilliseconds)
        .clamp(0.0, 1.0);

    if (_camError != null && !_loadingCam) {
      return Scaffold(body: _buildErrorLayer());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreview(),
          if (_loadingCam && _camError == null)
            const ColoredBox(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          if (!immersiveShortVideoRecord)
            Positioned.fill(
              child: _buildCaptureChrome(context),
            ),
          if (immersiveShortVideoRecord) ...[
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 220 + bottomInset,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomInset + 24,
              child: Center(
                child: _ShortVideoRecordShutter(
                  progress: recordProgress,
                  elapsed: _recordElapsed,
                  maxDuration: _maxVideoRecord,
                  busy: _busy,
                  onTap: _onShutter,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShortVideoRecordShutter extends StatelessWidget {
  const _ShortVideoRecordShutter({
    required this.progress,
    required this.elapsed,
    required this.maxDuration,
    required this.busy,
    required this.onTap,
  });

  final double progress;
  final Duration elapsed;
  final Duration maxDuration;
  final bool busy;
  final VoidCallback onTap;

  static String _fmtMmSs(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final timerLabel =
        '${_fmtMmSs(elapsed)} / ${_fmtMmSs(maxDuration)}';

    const double outer = 112;
    const double innerWhite = 66;
    const double stop = 22;

    return GestureDetector(
      onTap: busy ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timerLabel,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              height: 1.2,
              shadows: const [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(0, 1),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: outer,
            height: outer,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(outer, outer),
                  painter: _OuterRecordDiscPainter(progress: progress),
                ),
                Container(
                  width: innerWhite,
                  height: innerWhite,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: stop,
                  height: stop,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3040),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 外层半透明圆盘 + 贴外缘的红色进度弧（12 点起顺时针）。
class _OuterRecordDiscPainter extends CustomPainter {
  _OuterRecordDiscPainter({required this.progress});

  final double progress;

  static const Color _red = Color(0xFFFF3040);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;

    final base = Paint()..color = Colors.white.withValues(alpha: 0.42);
    canvas.drawCircle(c, outerR - 0.5, base);

    if (progress <= 0) return;

    const stroke = 6.0;
    final arcR = outerR - stroke / 2 - 1.5;
    final arc = Paint()
      ..color = _red
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final sweep = 2 * pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: arcR),
      -pi / 2,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _OuterRecordDiscPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.55),
            fontSize: 16,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _RightToolColumn extends StatelessWidget {
  const _RightToolColumn({
    required this.mode,
    required this.onFlip,
    required this.onClip,
    required this.onCrop,
    required this.onText,
    required this.onBeautify,
    required this.onFilter,
    required this.flipEnabled,
  });

  /// 帖子：翻转、文字、美颜、滤镜；短视频：剪辑、文字、美颜、滤镜、裁剪。
  final PublishCaptureMode mode;
  final VoidCallback onFlip;
  final VoidCallback onClip;
  final VoidCallback onCrop;
  final VoidCallback onText;
  final VoidCallback onBeautify;
  final VoidCallback onFilter;
  final bool flipEnabled;

  @override
  Widget build(BuildContext context) {
    Widget item({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool enabled = true,
    }) {
      final opacity = enabled ? 1.0 : 0.35;
      return GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Opacity(
            opacity: opacity,
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 30),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final textBeautifyFilter = <Widget>[
      item(
        icon: Icons.text_fields_rounded,
        label: 'publishToolText'.tr(),
        onTap: onText,
      ),
      item(
        icon: Icons.face_retouching_natural,
        label: 'publishToolBeautify'.tr(),
        onTap: onBeautify,
      ),
      item(
        icon: Icons.blur_circular_outlined,
        label: 'publishToolFilter'.tr(),
        onTap: onFilter,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (mode == PublishCaptureMode.post) ...[
          item(
            icon: Icons.cameraswitch_outlined,
            label: 'publishToolFlip'.tr(),
            onTap: onFlip,
            enabled: flipEnabled,
          ),
          ...textBeautifyFilter,
        ] else ...[
          item(
            icon: Icons.content_cut_rounded,
            label: 'publishToolClip'.tr(),
            onTap: onClip,
          ),
          ...textBeautifyFilter,
          item(
            icon: Icons.crop_rounded,
            label: 'publishToolCrop'.tr(),
            onTap: onCrop,
          ),
        ],
      ],
    );
  }
}

class _BottomThumb extends StatelessWidget {
  const _BottomThumb({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.recording,
    required this.busy,
    required this.onTap,
  });

  final bool recording;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        alignment: Alignment.center,
        child: Container(
          width: recording ? 28 : 58,
          height: recording ? 28 : 58,
          decoration: BoxDecoration(
            color: recording ? Colors.redAccent : Colors.white,
            shape: recording ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: recording ? BorderRadius.circular(6) : null,
          ),
        ),
      ),
    );
  }
}
