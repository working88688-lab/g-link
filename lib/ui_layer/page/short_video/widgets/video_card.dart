import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import 'package:g_link/domain/model/video_feed_models.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';

class VideoCard extends StatefulWidget {
  final VideoFeedItem item;
  final bool isFollowing;
  final bool isFavorited;
  final bool isMuted;
  final bool isCurrentPage;
  final bool isDetailLoading;
  final VoidCallback onToggleFollow;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleMute;
  final VoidCallback onComment;
  final VoidCallback onMore;
  final VoidCallback onShare;
  final VoidCallback? onExpandTap;
  final VoidCallback? onMusicTap;

  const VideoCard({
    super.key,
    required this.item,
    required this.isFollowing,
    required this.isFavorited,
    required this.isMuted,
    required this.isCurrentPage,
    this.isDetailLoading = false,
    required this.onToggleFollow,
    required this.onToggleLike,
    required this.onToggleFavorite,
    required this.onToggleMute,
    required this.onComment,
    required this.onMore,
    required this.onShare,
    this.onExpandTap,
    this.onMusicTap,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _failed = false;
  final double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _syncPlayback();
  }

  @override
  void didUpdateWidget(covariant VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.videoUrl != widget.item.videoUrl || oldWidget.isCurrentPage != widget.isCurrentPage) {
      unawaited(_syncPlayback());
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      await controller.pause();
      await controller.dispose();
    }
  }

  Future<void> _syncPlayback() async {
    if (!widget.isCurrentPage) {
      await _disposeController();
      if (mounted) setState(() {});
      return;
    }
    if (_controller != null && _controller!.dataSource == widget.item.videoUrl && _controller!.value.isInitialized) {
      if (!_controller!.value.isPlaying) {
        await _controller!.play();
      }
      return;
    }
    _loading = true;
    _failed = false;
    if (mounted) setState(() {});
    await _disposeController();
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.item.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _controller = controller;
      controller.addListener(() {
        if (mounted) setState(() {});
      });
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(1);
      await controller.setPlaybackSpeed(_speed);
      await controller.play();
    } catch (e) {
      if (e is PlatformException) {
        debugPrint('Video init failed: ${e.message}');
      } else {
        debugPrint('Video init failed: $e');
      }
      _failed = true;
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final authorName = item.author.nickname;
    final locationLabel = '杭州·西湖';
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: _buildVideo()),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.1, 0.2, 0.8, 0.9, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.403),
                  Colors.black.withValues(alpha: 0.259),
                  Colors.black.withValues(alpha: 0.0001),
                  Colors.black.withValues(alpha: 0.0001),
                  Colors.black.withValues(alpha: 0.261),
                  Colors.black.withValues(alpha: 0.699),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 8.w,
          bottom: 40.w,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              VideoActionBar(
                item: item,
                isFollowing: widget.isFollowing,
                isFavorited: widget.isFavorited,
                isMuted: widget.isMuted,
                onToggleFollow: widget.onToggleFollow,
                onToggleLike: widget.onToggleLike,
                onToggleFavorite: widget.onToggleFavorite,
                onToggleMute: widget.onToggleMute,
                onComment: widget.onComment,
                onMore: widget.onMore,
                onShare: widget.onShare,
              ),
              if (widget.isDetailLoading)
                Positioned(
                  top: -28.w,
                  right: 0,
                  child: SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          left: 8.w,
          right: 75.w,
          bottom: 40.w,
          child: VideoContentInfo(
            authorName: authorName,
            locationLabel: locationLabel,
            item: item,
            onExpandTap: widget.onExpandTap,
            onMusicTap: widget.onMusicTap,
          ),
        ),
        const Positioned(left: 0, right: 0, bottom: 0, child: VideoProgressBar()),
      ],
    );
  }

  Widget _buildVideo() {
    if (_failed) {
      return _buildCover();
    }
    if (_loading || _controller == null || !_controller!.value.isInitialized) {
      return _buildCover();
    }
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller!,
      builder: (_, value, __) {
        if (value.hasError) return _buildCover();
        return Center(
          child: AspectRatio(
            aspectRatio: value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
        );
      },
    );
  }

  Widget _buildCover() {
    return widget.item.coverUrl.isNotEmpty
        ? Image.network(widget.item.coverUrl, fit: BoxFit.cover)
        : Container(
            color: Colors.black,
            child: Center(
              child: Icon(Icons.play_circle_outline, size: 72.sp, color: Colors.white24),
            ),
          );
  }
}

class VideoActionBar extends StatelessWidget {
  final VideoFeedItem item;
  final bool isFollowing;
  final bool isFavorited;
  final bool isMuted;
  final VoidCallback onToggleFollow;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleMute;
  final VoidCallback onComment;
  final VoidCallback onMore;
  final VoidCallback onShare;

  const VideoActionBar({
    super.key,
    required this.item,
    required this.isFollowing,
    required this.isFavorited,
    required this.isMuted,
    required this.onToggleFollow,
    required this.onToggleLike,
    required this.onToggleFavorite,
    required this.onToggleMute,
    required this.onComment,
    required this.onMore,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VideoAvatarWithFollow(item: item, isFollowing: isFollowing, onToggleFollow: onToggleFollow),
        SizedBox(height: 26.w),
        VideoActionBtn(
          icon: MyImage.asset(item.isLiked ? MyImagePaths.iconLiked : MyImagePaths.iconLike, width: 32.w),
          color: item.isLiked ? const Color(0xFFFF2D55) : Colors.white,
          count: item.stats.likeCount,
          onTap: onToggleLike,
        ),
        SizedBox(height: 20.w),
        VideoActionBtn(
          icon: MyImage.asset(MyImagePaths.iconComment, width: 32.w),
          color: Colors.white,
          count: item.stats.commentCount,
          onTap: onComment,
        ),
        SizedBox(height: 20.w),
        VideoActionBtn(
          icon: MyImage.asset(MyImagePaths.iconCollection, width: 32.w),
          color: isFavorited ? const Color(0xFFFFB800) : Colors.white,
          count: item.stats.favoriteCount + (isFavorited ? 1 : 0),
          onTap: onToggleFavorite,
        ),
        SizedBox(height: 20.w),
        VideoActionBtn(
          icon: MyImage.asset(MyImagePaths.iconShare, width: 32.w),
          color: Colors.white,
          count: item.stats.shareCount,
          onTap: onShare,
          flipHorizontal: true,
        ),
        SizedBox(height: 20.w),
        VideoActionBtn(
          icon: MyImage.asset(MyImagePaths.iconMore, width: 32.w),
          color: Colors.white,
          onTap: onMore,
        ),
        SizedBox(height: 20.w),
        GestureDetector(
          onTap: onToggleMute,
          child: SizedBox(
            width: 30.w,
            height: 30.w,
            child: MyImage.asset(isMuted ? MyImagePaths.iconVolumeOff : MyImagePaths.iconMute, width: 30.w),
          ),
        ),
      ],
    );
  }
}

class VideoAvatarWithFollow extends StatelessWidget {
  final VideoFeedItem item;
  final bool isFollowing;
  final VoidCallback onToggleFollow;

  const VideoAvatarWithFollow({super.key, required this.item, required this.isFollowing, required this.onToggleFollow});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF444444),
            border: Border.all(color: Colors.white, width: 2.w),
          ),
          child: item.author.avatarUrl.isNotEmpty
              ? ClipOval(child: Image.network(item.author.avatarUrl, fit: BoxFit.cover))
              : Icon(Icons.person, color: Colors.white, size: 26.sp),
        ),
        if (!isFollowing)
          Positioned(
            bottom: -8.w,
            child: GestureDetector(
              onTap: onToggleFollow,
              child: MyImage.asset(MyImagePaths.iconShortVideoFollow, width: 16.w),
            ),
          ),
      ],
    );
  }
}

class VideoActionBtn extends StatelessWidget {
  final Widget icon;
  final Color color;
  final int? count;
  final VoidCallback onTap;
  final bool flipHorizontal;

  const VideoActionBtn({
    super.key,
    required this.icon,
    required this.color,
    this.count,
    required this.onTap,
    this.flipHorizontal = false,
  });

  String _formatCount(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}w';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          if (count != null) ...[
            SizedBox(height: 2.w),
            Text(_formatCount(count!),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: const Color(0x43000000), blurRadius: 4.w)])),
          ],
        ],
      ),
    );
  }
}

class VideoContentInfo extends StatelessWidget {
  final VideoFeedItem item;
  final String authorName;
  final String locationLabel;
  final VoidCallback? onExpandTap;
  final VoidCallback? onMusicTap;

  const VideoContentInfo(
      {super.key,
      required this.item,
      required this.authorName,
      required this.locationLabel,
      this.onExpandTap,
      this.onMusicTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 5.w),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(30.w),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyImage.asset(MyImagePaths.iconLocate, width: 16.w),
              SizedBox(width: 3.w),
              Text(locationLabel,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                      shadows: [Shadow(color: const Color(0x1F000000), blurRadius: 4.w)])),
            ],
          ),
        ),
        SizedBox(height: 8.w),
        Text(authorName,
            style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: const Color(0x1F000000), blurRadius: 4.w)])),
        SizedBox(height: 8.w),
        Wrap(
          spacing: 6.w,
          children: item.tags
              .map((t) => Text('#$t',
                  style: TextStyle(
                      color: const Color(0xFFFAB200),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: const Color(0x1F000000), blurRadius: 4.w)])))
              .toList(),
        ),
        SizedBox(height: 2.w),
        VideoExpandableText(
          text: item.description,
          style: TextStyle(
              color: Colors.white, fontSize: 13.sp, shadows: [Shadow(color: const Color(0x1F000000), blurRadius: 4.w)]),
          moreStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
              shadows: [Shadow(color: const Color(0x1F000000), blurRadius: 4.w)]),
          onExpandTap: onExpandTap,
        ),
        SizedBox(height: 16.w),
        GestureDetector(
          onTap: onMusicTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(6.w),
              boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4.w, offset: Offset(0, 2.w))],
            ),
            padding: EdgeInsets.only(left: 6.w, top: 7.w, bottom: 7.w, right: 17.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyImage.asset(MyImagePaths.iconMusical, width: 16.w),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text("都是月亮惹的祸 ｜ 章鱼",
                      style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class VideoExpandableText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextStyle moreStyle;
  final VoidCallback? onExpandTap;

  const VideoExpandableText(
      {super.key, required this.text, required this.style, required this.moreStyle, this.onExpandTap});

  @override
  State<VideoExpandableText> createState() => _VideoExpandableTextState();
}

class _VideoExpandableTextState extends State<VideoExpandableText> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final textDir = Directionality.of(ctx);
        final tp =
            TextPainter(text: TextSpan(text: widget.text, style: widget.style), maxLines: 1, textDirection: textDir)
              ..layout(maxWidth: constraints.maxWidth);
        if (!tp.didExceedMaxLines) return Text(widget.text, style: widget.style);
        final moreText = '...  ${'shortVideoExpand'.tr()} ';
        final moreTp =
            TextPainter(text: TextSpan(text: moreText, style: widget.moreStyle), maxLines: 1, textDirection: textDir)
              ..layout();
        const iconWidth = 16.0;
        final availableWidth = constraints.maxWidth - moreTp.width - iconWidth;
        final mainTp =
            TextPainter(text: TextSpan(text: widget.text, style: widget.style), maxLines: 1, textDirection: textDir)
              ..layout(maxWidth: availableWidth);
        final offset = mainTp.getPositionForOffset(Offset(availableWidth, mainTp.height / 2)).offset;
        final truncated = widget.text.substring(0, offset);
        return RichText(
          maxLines: 1,
          overflow: TextOverflow.clip,
          text: TextSpan(
            children: [
              TextSpan(text: truncated, style: widget.style),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onExpandTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(moreText, style: widget.moreStyle),
                      MyImage.asset(MyImagePaths.iconArrowDown, width: 16.w),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class VideoProgressBar extends StatelessWidget {
  const VideoProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: LinearProgressIndicator(
        value: 0.35,
        backgroundColor: Colors.white24,
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        minHeight: 3,
      ),
    );
  }
}
