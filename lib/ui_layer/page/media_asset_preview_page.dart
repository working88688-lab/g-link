import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

/// 相册中点击缩略图后的全屏预览（图片可缩放，视频可播放）。
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

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'mediaPickerPreview'.tr(),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
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
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AspectRatio(
              aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
              child: VideoPlayer(c),
            ),
          ),
          const SizedBox(height: 20),
          IconButton(
            iconSize: 56,
            color: Colors.white,
            icon: Icon(
              c.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            ),
            onPressed: () async {
              if (c.value.isPlaying) {
                await c.pause();
              } else {
                await c.play();
              }
              if (mounted) setState(() {});
            },
          ),
        ],
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
