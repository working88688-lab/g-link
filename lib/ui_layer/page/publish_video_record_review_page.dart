import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:g_link/ui_layer/page/publish_compose_page.dart';
import 'package:g_link/ui_layer/page/publish_video_editor_page.dart';
import 'package:g_link/ui_layer/widgets/publish_video_preview_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

/// 短视频拍摄完成后的全屏预览：播放本地成片文件（非实时预览），点击画面播放/暂停。
class PublishVideoRecordReviewPage extends StatefulWidget {
  const PublishVideoRecordReviewPage({super.key, required this.xFile});

  final XFile xFile;

  @override
  State<PublishVideoRecordReviewPage> createState() =>
      _PublishVideoRecordReviewPageState();
}

class _PublishVideoRecordReviewPageState
    extends State<PublishVideoRecordReviewPage> {
  VideoPlayerController? _controller;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    unawaited(_initVideo());
  }

  /// 录制刚结束时文件可能尚未落盘完毕，稍等再交给 [VideoPlayer]。
  Future<void> _waitForRecordedBytes() async {
    for (var i = 0; i < 80; i++) {
      try {
        final len = await widget.xFile.length();
        if (len > 0) return;
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  Future<void> _initVideo() async {
    try {
      await _waitForRecordedBytes();
      if (!mounted) return;
      final c = await publishVideoPreviewCreateController(widget.xFile);
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      await c.setLooping(true);
      await c.pause();
      await c.seekTo(Duration.zero);
      c.addListener(_onVideoControllerTick);
      setState(() {
        _controller = c;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  void _onVideoControllerTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final c = _controller;
    if (c != null) {
      c.removeListener(_onVideoControllerTick);
      c.dispose();
    }
    super.dispose();
  }

  void _toastComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('publishComingSoon'.tr())),
    );
  }

  void _openClipEditor() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (ctx) => PublishVideoEditorPage(xFile: widget.xFile),
        ),
      ),
    );
  }

  Future<void> _togglePlayPause() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      final atEnd = c.value.duration > Duration.zero &&
          c.value.position >= c.value.duration;
      if (atEnd) {
        await c.seekTo(Duration.zero);
      }
      await c.play();
    }
    if (mounted) setState(() {});
  }

  void _goCompose() {
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) =>
            PublishComposePage(media: [widget.xFile], isVideo: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller != null &&
              _controller!.value.isInitialized &&
              _error == null)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlayPause,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                    if (!_controller!.value.isPlaying)
                      Center(
                        child: Icon(
                          Icons.play_circle_rounded,
                          size: 72,
                          color: Colors.white.withValues(alpha: 0.92),
                          shadows: const [
                            Shadow(
                              blurRadius: 12,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            )
          else if (_loading)
            const ColoredBox(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            ColoredBox(
              color: Colors.black,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'publishVideoLoadError'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
          SafeArea(
            bottom: true,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 48,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: IconButton(
                          padding: const EdgeInsets.only(left: 4),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                      _TopPillButton(
                        onTap: _toastComingSoon,
                        icon: Icons.music_note_rounded,
                        label: 'publishSelectMusic'.tr(),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 2,
                  top: 52,
                  bottom: 168,
                  child: Align(
                    alignment: Alignment.center,
                    child: _ReviewRightToolColumn(
                      onClip: _openClipEditor,
                      onCrop: _toastComingSoon,
                      onText: _toastComingSoon,
                      onBeautify: _toastComingSoon,
                      onFilter: _toastComingSoon,
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: _TopPillButton(
                          onTap: _toastComingSoon,
                          icon: Icons.auto_awesome_rounded,
                          label: 'publishSelectEffect'.tr(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _goCompose,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF111111),
                            elevation: 0,
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text('mediaPickerNext'.tr()),
                        ),
                      ),
                    ],
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

class _TopPillButton extends StatelessWidget {
  const _TopPillButton({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.95), size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewRightToolColumn extends StatelessWidget {
  const _ReviewRightToolColumn({
    required this.onClip,
    required this.onCrop,
    required this.onText,
    required this.onBeautify,
    required this.onFilter,
  });

  final VoidCallback onClip;
  final VoidCallback onCrop;
  final VoidCallback onText;
  final VoidCallback onBeautify;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    Widget item({
      required IconData iconData,
      required String label,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconData, color: Colors.white, size: 28),
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
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        item(
          iconData: Icons.content_cut_rounded,
          label: 'publishToolClip'.tr(),
          onTap: onClip,
        ),
        item(
          iconData: Icons.text_fields_rounded,
          label: 'publishToolText'.tr(),
          onTap: onText,
        ),
        item(
          iconData: Icons.face_retouching_natural,
          label: 'publishToolBeautify'.tr(),
          onTap: onBeautify,
        ),
        item(
          iconData: Icons.blur_circular_outlined,
          label: 'publishToolFilter'.tr(),
          onTap: onFilter,
        ),
        item(
          iconData: Icons.crop_rounded,
          label: 'publishToolCrop'.tr(),
          onTap: onCrop,
        ),
      ],
    );
  }
}
