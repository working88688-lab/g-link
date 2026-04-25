import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';

import '../models/video_item_model.dart';

// ──────────────────────────────────────────
// 单个视频卡片（全屏 Stack）
// ──────────────────────────────────────────
class VideoCard extends StatefulWidget {
  final VideoItemModel item;
  final VoidCallback onToggleFollow;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleMute;
  final VoidCallback onComment;
  final VoidCallback onMore;
  final VoidCallback? onExpandTap;

  const VideoCard({
    super.key,
    required this.item,
    required this.onToggleFollow,
    required this.onToggleLike,
    required this.onToggleFavorite,
    required this.onToggleMute,
    required this.onComment,
    required this.onMore,
    this.onExpandTap,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Stack(
      fit: StackFit.expand,
      children: [
        // 视频占位（后续接入播放器）
        Container(
          color: Colors.white,
          child: Center(
            child: Icon(Icons.play_circle_outline,
                size: 72.sp, color: Colors.white24),
          ),
        ),

        // 全屏渐变遮罩（顶部 + 底部双向渐变）
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

        // 右侧操作栏
        Positioned(
          right: 8.w,
          bottom: 40.w,
          child: VideoActionBar(
            item: item,
            onToggleFollow: widget.onToggleFollow,
            onToggleLike: widget.onToggleLike,
            onToggleFavorite: widget.onToggleFavorite,
            onToggleMute: widget.onToggleMute,
            onComment: widget.onComment,
            onMore: widget.onMore,
          ),
        ),

        // 左下内容信息
        Positioned(
          left: 8.w,
          right: 75.w,
          bottom: 40.w,
          child: VideoContentInfo(item: item, onExpandTap: widget.onExpandTap),
        ),

        // 底部进度条
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: VideoProgressBar(),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────
// 右侧操作栏
// ──────────────────────────────────────────
class VideoActionBar extends StatelessWidget {
  final VideoItemModel item;
  final VoidCallback onToggleFollow;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleMute;
  final VoidCallback onComment;
  final VoidCallback onMore;

  const VideoActionBar({
    super.key,
    required this.item,
    required this.onToggleFollow,
    required this.onToggleLike,
    required this.onToggleFavorite,
    required this.onToggleMute,
    required this.onComment,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VideoAvatarWithFollow(item: item, onToggleFollow: onToggleFollow),
        SizedBox(height: 26.w),
        VideoActionBtn(
          icon: MyImage.asset(
            item.isLiked ? MyImagePaths.iconLiked : MyImagePaths.iconLike,
            width: 32.w,
          ),
          color: item.isLiked ? const Color(0xFFFF2D55) : Colors.white,
          count: item.isLiked ? item.likes + 1 : item.likes,
          onTap: onToggleLike,
        ),
        SizedBox(height: 20.w),
        VideoActionBtn(
          icon: MyImage.asset(MyImagePaths.iconComment, width: 32.w),
          color: Colors.white,
          count: item.comments,
          onTap: onComment,
        ),
        SizedBox(height: 20.w),
        VideoActionBtn(
          icon: MyImage.asset(MyImagePaths.iconCollection, width: 32.w),
          color: item.isFavorited ? const Color(0xFFFFB800) : Colors.white,
          count: item.isFavorited ? item.favorites + 1 : item.favorites,
          onTap: onToggleFavorite,
        ),
        SizedBox(height: 20.w),
        VideoActionBtn(
          icon: MyImage.asset(MyImagePaths.iconShare, width: 32.w),
          color: Colors.white,
          count: item.shares,
          onTap: () {},
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
            child: MyImage.asset(MyImagePaths.iconMute, width: 30.w),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────
// 头像 + 关注按钮
// ──────────────────────────────────────────
class VideoAvatarWithFollow extends StatelessWidget {
  final VideoItemModel item;
  final VoidCallback onToggleFollow;

  const VideoAvatarWithFollow(
      {super.key, required this.item, required this.onToggleFollow});

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
          child: item.authorAvatar.isNotEmpty
              ? ClipOval(
                  child: Image.network(item.authorAvatar, fit: BoxFit.cover))
              : Icon(Icons.person, color: Colors.white, size: 26.sp),
        ),
        if (!item.isFollowing)
          Positioned(
            bottom: -8.w,
            child: GestureDetector(
              onTap: onToggleFollow,
              child:
                  MyImage.asset(MyImagePaths.iconShortVideoFollow, width: 16.w),
            ),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────
// 通用操作按钮（图标 + 数字）
// ──────────────────────────────────────────
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
            Text(
              _formatCount(count!),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(color: const Color(0x43000000), blurRadius: 4.w)
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// 左下内容信息（位置、标题、标签、描述、音乐）
// ──────────────────────────────────────────
class VideoContentInfo extends StatelessWidget {
  final VideoItemModel item;
  final VoidCallback? onExpandTap;

  const VideoContentInfo({super.key, required this.item, this.onExpandTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 地址
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
              Text(
                item.location,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                  shadows: [
                    Shadow(color: const Color(0x1F000000), blurRadius: 4.w)
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.w),
        // 标题
        Text(
          item.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: const Color(0x1F000000), blurRadius: 4.w)],
          ),
        ),
        SizedBox(height: 8.w),
        // 标签
        Wrap(
          spacing: 6.w,
          children: item.tags
              .map((t) => Text(
                    t,
                    style: TextStyle(
                      color: const Color(0xFFFAB200),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(color: const Color(0x1F000000), blurRadius: 4.w)
                      ],
                    ),
                  ))
              .toList(),
        ),
        SizedBox(height: 2.w),
        // 描述（可展开）
        VideoExpandableText(
          text: item.desc,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.sp,
            shadows: [Shadow(color: const Color(0x1F000000), blurRadius: 4.w)],
          ),
          moreStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
            shadows: [Shadow(color: const Color(0x1F000000), blurRadius: 4.w)],
          ),
          onExpandTap: onExpandTap,
        ),
        SizedBox(height: 16.w),
        // 音乐
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(6.w),
            boxShadow: [
              BoxShadow(
                  color: Colors.black45,
                  blurRadius: 4.w,
                  offset: Offset(0, 2.w))
            ],
          ),
          padding:
              EdgeInsets.only(left: 6.w, top: 7.w, bottom: 7.w, right: 17.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyImage.asset(MyImagePaths.iconMusical, width: 16.w),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  item.music,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────
// 可展开文本（超出一行才显示展开按钮）
// ──────────────────────────────────────────
class VideoExpandableText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextStyle moreStyle;
  final VoidCallback? onExpandTap;

  const VideoExpandableText({
    super.key,
    required this.text,
    required this.style,
    required this.moreStyle,
    this.onExpandTap,
  });

  @override
  State<VideoExpandableText> createState() => _VideoExpandableTextState();
}

class _VideoExpandableTextState extends State<VideoExpandableText> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final textDir = Directionality.of(ctx);
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: textDir,
        )..layout(maxWidth: constraints.maxWidth);

        if (!tp.didExceedMaxLines) {
          return Text(widget.text, style: widget.style);
        }

        final moreText = '...  ${'shortVideoExpand'.tr()} ';
        final moreTp = TextPainter(
          text: TextSpan(text: moreText, style: widget.moreStyle),
          maxLines: 1,
          textDirection: textDir,
        )..layout();
        const iconWidth = 16.0;

        final availableWidth = constraints.maxWidth - moreTp.width - iconWidth;
        final mainTp = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: textDir,
        )..layout(maxWidth: availableWidth);

        final offset = mainTp
            .getPositionForOffset(Offset(availableWidth, mainTp.height / 2))
            .offset;
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

// ──────────────────────────────────────────
// 底部进度条（占位）
// ──────────────────────────────────────────
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
