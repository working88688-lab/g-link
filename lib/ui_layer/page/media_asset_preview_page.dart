import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:g_link/ui_layer/widgets/publish_video_preview_player.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

/// 相册中点击缩略图后的全屏预览（图片可缩放，视频可播放）。
/// 顶部关闭与标题叠在画面上（Stack），预览内容在页面正中。
class MediaAssetPreviewPage extends StatefulWidget {
  const MediaAssetPreviewPage({super.key, required this.entity});

  final AssetEntity entity;

  @override
  State<MediaAssetPreviewPage> createState() => _MediaAssetPreviewPageState();
}

class _MediaAssetPreviewPageState extends State<MediaAssetPreviewPage> {
  File? _file;
  VideoPlayerController? _video;
  bool _videoBusy = true;
  Object? _error;
  bool _videoOnFullscreenRoute = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final f = await widget.entity.originFile;
      if (!mounted) return;
      if (f == null) {
        setState(() {
          _error = StateError('no file');
          _videoBusy = false;
        });
        return;
      }
      if (widget.entity.type == AssetType.video) {
        final controller = VideoPlayerController.file(f);
        await controller.initialize();
        if (!mounted) {
          await controller.dispose();
          return;
        }
        setState(() {
          _file = f;
          _video = controller;
          _videoBusy = false;
        });
        return;
      }
      setState(() {
        _file = f;
        _videoBusy = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _videoBusy = false;
        });
      }
    }
  }

  Future<void> _openVideoFullscreen(VideoPlayerController c) async {
    if (!mounted) return;
    setState(() => _videoOnFullscreenRoute = true);
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (ctx, _, __) => VideoPreviewFullscreenPage(controller: c),
      ),
    );
    if (mounted) setState(() => _videoOnFullscreenRoute = false);
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: _buildMainContent()),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: kToolbarHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: Colors.white,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'mediaPickerPreview'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'mediaPickerLoadError'.tr(),
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_videoBusy || _file == null) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    if (widget.entity.type == AssetType.video) {
      final c = _video;
      if (c == null || !c.value.isInitialized) {
        return const CircularProgressIndicator(color: Colors.white);
      }
      final ar = c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio;
      return AspectRatio(
        aspectRatio: ar,
        child: _videoOnFullscreenRoute
            ? const ColoredBox(
                color: Colors.black,
                child: Center(
                  child: Icon(
                    Icons.fullscreen,
                    color: Colors.white38,
                    size: 48,
                  ),
                ),
              )
            : VideoPreviewPlayerSurface(
                controller: c,
                isFullscreen: false,
                onOpenFullscreen: () => unawaited(_openVideoFullscreen(c)),
              ),
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4,
      child: Image.file(
        _file!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'mediaPickerLoadError'.tr(),
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
