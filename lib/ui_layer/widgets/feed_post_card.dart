import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/model/feed_models.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:g_link/utils/my_toast.dart';

/// 帖子流卡片，主页推荐流 / 用户最新帖子列表页 / 任何展示 [FeedPost] 的地方都用它。
///
/// 视觉结构（自上而下）：
///   1. 顶部头像行：头像 + 昵称 + 相对时间 + 可选「关注」按钮。
///   2. 图片轮播（若有）。
///   3. 操作行：点赞 / 评论 / 分享 / 收藏 / 更多。
///   4. 正文（含 #tag），最多 2 行省略，点击「展开」可查看全文。
///
/// 复用注意：
/// - [showAuthorFollowButton]：调用方根据「作者是否当前用户」决定是否展示关注按钮。
///   关注按钮存在时也用同一条件判断头像点击是否打开他人主页（避免点自己头像跳到自己）。
/// - [onToggleAuthorFollow] / [onToggleLike] 均为可选；为 null 时点击降级为 toast。
/// - [onAvatarTap] 优先级高于内置「点头像跳他人主页」行为；不传时按
///   `showAuthorFollowButton == true` 跳 [OtherProfileRoute]，
///   `false` 时点击不响应。
class FeedPostCard extends StatefulWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    this.showAuthorFollowButton = true,
    this.isAuthorFollowed = false,
    this.onToggleAuthorFollow,
    this.onToggleLike,
    this.onAvatarTap,
  });

  final FeedPost post;
  final bool showAuthorFollowButton;
  final bool isAuthorFollowed;
  final VoidCallback? onToggleAuthorFollow;
  final VoidCallback? onToggleLike;

  /// 点击作者头像时的覆盖动作；`null` 时按内置规则跳他人主页。
  final VoidCallback? onAvatarTap;

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant FeedPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.postId != widget.post.postId) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(post),
          if (post.images.isNotEmpty) _buildImages(post.images),
          _buildActionsBar(post),
          _buildContent(post),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  Widget _buildHeader(FeedPost post) {
    final author = post.author;
    // 头像点击规则：
    // - onAvatarTap 显式指定 → 用调用方的逻辑；
    // - 否则按 showAuthorFollowButton 当作「作者不是自己」标志，true 时点击跳他人主页，
    //   false 时不响应（自己头像 / 已经在自己上下文里）。
    final defaultCanOpen = widget.showAuthorFollowButton;
    final VoidCallback? avatarTap = widget.onAvatarTap ??
        (defaultCanOpen
            ? () => OtherProfileRoute(uid: author.uid).push<void>(context)
            : null);
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 10.h),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: avatarTap,
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE2E5EB),
              ),
              child: ClipOval(
                child: author.avatarUrl.isNotEmpty
                    ? MyImage.network(author.avatarUrl, fit: BoxFit.cover)
                    : Image.asset(
                        MyImagePaths.defaultHeader,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author.nickname.isNotEmpty
                      ? author.nickname
                      : 'homeAnonymousAuthor'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1F2C),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _formatRelativeTime(post.createdAt),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF8C95A8),
                  ),
                ),
              ],
            ),
          ),
          if (widget.showAuthorFollowButton &&
              widget.onToggleAuthorFollow != null)
            GestureDetector(
              onTap: widget.onToggleAuthorFollow,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 74.w,
                height: 30.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.isAuthorFollowed
                      ? Colors.transparent
                      : const Color(0xFF1A1F2C),
                  border: widget.isAuthorFollowed
                      ? Border.all(color: const Color(0xFFCCCCCC), width: 1)
                      : null,
                  borderRadius: BorderRadius.circular(99.r),
                ),
                child: Text(
                  widget.isAuthorFollowed
                      ? 'commonFollowed'.tr()
                      : 'commonFollow'.tr(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: widget.isAuthorFollowed
                        ? const Color(0xFF1A1F2C)
                        : Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImages(List<FeedImage> images) {
    final controller = PageController();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: AspectRatio(
          aspectRatio: _safeAspectRatio(images.first.aspectRatio),
          child: Stack(
            children: [
              PageView.builder(
                controller: controller,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return MyImage.network(
                    images[index].url,
                    fit: BoxFit.cover,
                  );
                },
              ),
              if (images.length > 1)
                Positioned(
                  right: 8.w,
                  top: 8.h,
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      final raw = controller.hasClients ? controller.page : 0.0;
                      final page = (raw ?? 0).round();
                      return Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 7.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${page + 1}/${images.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsBar(FeedPost post) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 8.h),
      child: Row(
        children: [
          _ActionItem(
            icon: post.isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            iconColor:
                post.isLiked ? const Color(0xFFFF3B30) : const Color(0xFF1A1F2C),
            label:
                CommonUtils.renderEnFixedNumber(post.likeCount).toString(),
            onTap: widget.onToggleLike ??
                () => MyToast.showText(text: 'publishComingSoon'.tr()),
          ),
          SizedBox(width: 20.w),
          _ActionItem(
            icon: Icons.mode_comment_outlined,
            iconColor: const Color(0xFF1A1F2C),
            label:
                CommonUtils.renderEnFixedNumber(post.commentCount).toString(),
            onTap: () => MyToast.showText(text: 'homeCommentsComingSoon'.tr()),
          ),
          SizedBox(width: 20.w),
          _ActionItem(
            icon: Icons.share_outlined,
            iconColor: const Color(0xFF1A1F2C),
            label:
                CommonUtils.renderEnFixedNumber(post.shareCount).toString(),
            onTap: () => MyToast.showText(text: 'homeShareComingSoon'.tr()),
          ),
          const Spacer(),
          IconButton(
            iconSize: 21.sp,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () =>
                MyToast.showText(text: 'homeFavoriteComingSoon'.tr()),
            icon: Icon(Icons.star_border_rounded,
                color: const Color(0xFF1A1F2C)),
          ),
          SizedBox(width: 14.w),
          IconButton(
            iconSize: 18.sp,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () =>
                MyToast.showText(text: 'homePostMoreComingSoon'.tr()),
            icon:
                Icon(Icons.more_vert_rounded, color: const Color(0xFF8C95A8)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(FeedPost post) {
    final hasContent = post.content.isNotEmpty;
    final hasLocation = post.location.isNotEmpty;
    final tagText =
        post.tags.isEmpty ? '' : post.tags.map((t) => '#$t').join(' ');

    if (tagText.isEmpty && !hasContent) {
      if (!hasLocation) return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spans = _postBodySpans(
            context,
            tagText: tagText,
            content: post.content,
          );
          final exceedsTwo = spans.isEmpty
              ? false
              : _richTextExceedsMaxLines(
                  context,
                  constraints.maxWidth,
                  spans,
                  maxLines: 2,
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tagText.isNotEmpty || hasContent)
                Text.rich(
                  TextSpan(children: spans),
                  maxLines: _expanded ? null : 2,
                  overflow: _expanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
              if (hasLocation || exceedsTwo)
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Row(
                    children: [
                      if (hasLocation) ...[
                        Icon(
                          Icons.location_on_outlined,
                          size: 13.sp,
                          color: const Color(0xFF62748E),
                        ),
                        SizedBox(width: 2.w),
                        Flexible(
                          child: Text(
                            post.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF62748E),
                            ),
                          ),
                        ),
                      ],
                      if (hasLocation && exceedsTwo) const Spacer(),
                      if (!hasLocation && exceedsTwo) const Spacer(),
                      if (exceedsTwo)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _expanded = !_expanded),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 2.w, vertical: 4.h),
                            child: Text(
                              _expanded
                                  ? 'homeCollapse'.tr()
                                  : 'homeExpand'.tr(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF1A1F2C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  double _safeAspectRatio(double raw) {
    if (raw.isNaN || raw <= 0) return 4 / 3;
    return raw.clamp(0.6, 1.6);
  }

  String _formatRelativeTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.isNegative) return 'homeJustNow'.tr();
    if (diff.inMinutes < 1) return 'homeJustNow'.tr();
    if (diff.inMinutes < 60) {
      return 'homeMinutesAgo'.tr(namedArgs: {'n': '${diff.inMinutes}'});
    }
    if (diff.inHours < 24) {
      return 'homeHoursAgo'.tr(namedArgs: {'n': '${diff.inHours}'});
    }
    if (diff.inDays < 30) {
      return 'homeDaysAgo'.tr(namedArgs: {'n': '${diff.inDays}'});
    }
    final months = (diff.inDays / 30).floor();
    if (months < 12) {
      return 'homeMonthsAgo'.tr(namedArgs: {'n': '$months'});
    }
    final years = (diff.inDays / 365).floor();
    return 'homeYearsAgo'.tr(namedArgs: {'n': '$years'});
  }

  List<InlineSpan> _postBodySpans(
    BuildContext context, {
    required String tagText,
    required String content,
  }) {
    final spans = <InlineSpan>[];
    if (tagText.isNotEmpty) {
      spans.add(TextSpan(
        text: tagText,
        style: TextStyle(
          color: const Color(0xFF1A1F2C),
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),
      ));
      if (content.isNotEmpty) spans.add(const TextSpan(text: ' '));
    }
    if (content.isNotEmpty) {
      spans.add(TextSpan(
        text: content,
        style: TextStyle(
          color: const Color(0xFF1A1F2C),
          fontSize: 13.sp,
          height: 1.45,
        ),
      ));
    }
    return spans;
  }

  bool _richTextExceedsMaxLines(
    BuildContext context,
    double maxWidth,
    List<InlineSpan> spans, {
    required int maxLines,
  }) {
    if (spans.isEmpty || maxWidth <= 0) return false;
    final painter = TextPainter(
      text: TextSpan(children: spans),
      textDirection: Directionality.of(context),
      maxLines: maxLines,
      textScaler: MediaQuery.textScalerOf(context),
      ellipsis: '…',
    );
    painter.layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 21.sp, color: iconColor),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1F2C),
            ),
          ),
        ],
      ),
    );
  }
}
