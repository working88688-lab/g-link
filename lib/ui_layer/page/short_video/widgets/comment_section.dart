import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/data_layer/repo/repo.dart';
import 'package:g_link/domain/model/comment_models.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:provider/provider.dart';

import '../../../router/routes.dart';

class CommentContent extends StatefulWidget {
  final int targetId;
  final String targetType;
  final String authorName;
  final bool showTitle;
  final Widget? scrollTopChild;

  const CommentContent({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.authorName,
    this.showTitle = false,
    this.scrollTopChild,
  });

  @override
  State<CommentContent> createState() => _CommentContentState();
}

class _CommentContentState extends State<CommentContent> {
  final List<CommentItemModel> _comments = [];
  final Set<int> _loadingReplyIds = {};
  final Set<int> _likedIds = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  String _formatCount(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}w';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()}周前';
    if (diff.inDays >= 1) return '${diff.inDays}天前';
    if (diff.inHours >= 1) return '${diff.inHours}小时前';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}分钟前';
    return '刚刚';
  }

  Future<void> _loadComments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context.read<AppRepo>().getComments(
            targetType: widget.targetType,
            targetId: widget.targetId,
          );
      if (!mounted) return;
      setState(() {
        _comments
          ..clear()
          ..addAll(page.items);
        _loading = false;
      });
      for (final comment in page.items.where((e) => e.replyCount > 0)) {
        _loadReplies(comment.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '加载失败';
      });
    }
  }

  Future<void> _loadReplies(int commentId) async {
    if (_loadingReplyIds.contains(commentId)) return;
    _loadingReplyIds.add(commentId);
    try {
      final page = await context.read<AppRepo>().getCommentReplies(commentId: commentId);
      if (!mounted) return;
      final index = _comments.indexWhere((e) => e.id == commentId);
      if (index == -1) return;
      setState(() {
        _comments[index] = _comments[index].copyWith(replies: page.items);
      });
    } catch (_) {
    } finally {
      _loadingReplyIds.remove(commentId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _toggleLike(CommentItemModel comment) async {
    if (_likedIds.contains(comment.id)) return;
    _likedIds.add(comment.id);
    try {
      final result = comment.isLiked
          ? await context.read<AppRepo>().unlikeComment(comment.id)
          : await context.read<AppRepo>().likeComment(comment.id);
      if (!mounted) return;
      final index = _comments.indexWhere((e) => e.id == comment.id);
      if (index != -1) {
        setState(() {
          _comments[index] = _comments[index].copyWith(
            isLiked: result.liked,
            likeCount: result.likeCount,
          );
        });
      }
    } catch (_) {
    } finally {
      _likedIds.remove(comment.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _toggleReplyLike(int commentId, CommentItemModel reply) async {
    if (_likedIds.contains(reply.id)) return;
    _likedIds.add(reply.id);
    try {
      final result = reply.isLiked
          ? await context.read<AppRepo>().unlikeComment(reply.id)
          : await context.read<AppRepo>().likeComment(reply.id);
      if (!mounted) return;
      final index = _comments.indexWhere((e) => e.id == commentId);
      if (index == -1) return;
      final replies = List<CommentItemModel>.from(_comments[index].replies);
      final replyIndex = replies.indexWhere((e) => e.id == reply.id);
      if (replyIndex == -1) return;
      replies[replyIndex] = replies[replyIndex].copyWith(
        isLiked: result.liked,
        likeCount: result.likeCount,
      );
      setState(() {
        _comments[index] = _comments[index].copyWith(replies: replies);
      });
    } catch (_) {
    } finally {
      _likedIds.remove(reply.id);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.72 - 40,
      child: Column(
        children: [
          if (widget.showTitle) ...[
            Text(
              'shortVideoCommentTitle'.tr(namedArgs: {'count': '${_comments.length}'}),
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16.w),
          ],
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  if (widget.scrollTopChild != null) widget.scrollTopChild!,
                  if (_loading && _comments.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.w),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null && _comments.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.w),
                      child: Text(_error!, style: TextStyle(fontSize: 12.sp)),
                    )
                  else
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _comments.length,
                      itemBuilder: (_, i) => CommentItem(
                        comment: _comments[i],
                        formatCount: _formatCount,
                        formatTime: _formatTime,
                        onLike: () => _toggleLike(_comments[i]),
                        onReplyLike: (reply) => _toggleReplyLike(_comments[i].id, reply),
                        onLoadMoreReplies: _comments[i].replyCount > _comments[i].replies.length
                            ? () => _loadReplies(_comments[i].id)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const CommentInput(),
        ],
      ),
    );
  }
}

class CommentItem extends StatelessWidget {
  final CommentItemModel comment;
  final String Function(int) formatCount;
  final String Function(DateTime?) formatTime;
  final VoidCallback onLike;
  final void Function(CommentItemModel reply) onReplyLike;
  final VoidCallback? onLoadMoreReplies;

  const CommentItem({
    super.key,
    required this.comment,
    required this.formatCount,
    required this.formatTime,
    required this.onLike,
    required this.onReplyLike,
    this.onLoadMoreReplies,
  });

  @override
  Widget build(BuildContext context) {
    final authorName = comment.user.nickname.isNotEmpty
        ? comment.user.nickname
        : comment.user.username;
    return Padding(
      padding: EdgeInsets.only(bottom: 16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommentAvatar(radius: 20.w, avatarUrl: comment.user.avatarUrl),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(authorName,
                        style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF45556C))),
                    if (comment.isAuthor) ...[
                      SizedBox(width: 6.w),
                      Text('作者', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF90A1B9))),
                    ],
                    SizedBox(width: 6.w),
                    Text(formatTime(comment.createdAt),
                        style: TextStyle(
                            fontSize: 12.sp, color: const Color(0xFF90A1B9))),
                  ],
                ),
                SizedBox(height: 2.w),
                Text(comment.content,
                    style: TextStyle(
                        fontSize: 12.sp, color: const Color(0xFF45556C))),
                SizedBox(height: 8.w),
                CommentActions(
                  likes: comment.likeCount,
                  isLiked: comment.isLiked,
                  formatCount: formatCount,
                  onLike: onLike,
                ),
                if (comment.replies.isNotEmpty) ...[
                  SizedBox(height: 12.w),
                  ...comment.replies.asMap().entries.map(
                        (e) => Padding(
                          padding: EdgeInsets.only(bottom: 8.w),
                          child: CommentReplyItem(
                            reply: e.value,
                            formatCount: formatCount,
                            formatTime: formatTime,
                            onLike: () => onReplyLike(e.value),
                          ),
                        ),
                      ),
                ],
                if (onLoadMoreReplies != null) ...[
                  SizedBox(height: 4.w),
                  GestureDetector(
                    onTap: onLoadMoreReplies,
                    child: Text(
                      'shortVideoMoreReplies'.tr(namedArgs: {
                        'count': '${comment.replyCount - comment.replies.length}'
                      }),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF45556C),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommentReplyItem extends StatelessWidget {
  final CommentItemModel reply;
  final String Function(int) formatCount;
  final String Function(DateTime?) formatTime;
  final VoidCallback onLike;

  const CommentReplyItem({
    super.key,
    required this.reply,
    required this.formatCount,
    required this.formatTime,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final authorName = reply.user.nickname.isNotEmpty
        ? reply.user.nickname
        : reply.user.username;
    final replyToName = reply.replyTo?.nickname.isNotEmpty == true
        ? reply.replyTo!.nickname
        : reply.replyTo?.username ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommentAvatar(radius: 12.w, avatarUrl: reply.user.avatarUrl),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(authorName,
                      style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF45556C))),
                  if (reply.isAuthor) ...[
                    SizedBox(width: 6.w),
                    Text('作者', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF90A1B9))),
                  ],
                  if (replyToName.isNotEmpty) ...[
                    SizedBox(width: 6.w),
                    Text('回复 $replyToName', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF90A1B9))),
                  ],
                  SizedBox(width: 6.w),
                  Text(formatTime(reply.createdAt),
                      style: TextStyle(
                          fontSize: 12.sp, color: const Color(0xFF90A1B9))),
                ],
              ),
              SizedBox(height: 2.w),
              Text(reply.content,
                  style: TextStyle(
                      fontSize: 12.sp, color: const Color(0xFF45556C))),
              SizedBox(height: 8.w),
              CommentActions(
                likes: reply.likeCount,
                isLiked: reply.isLiked,
                formatCount: formatCount,
                onLike: onLike,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CommentActions extends StatelessWidget {
  final int likes;
  final bool isLiked;
  final String Function(int) formatCount;
  final VoidCallback onLike;

  const CommentActions({
    super.key,
    required this.likes,
    required this.isLiked,
    required this.formatCount,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {},
          child: Text(
            'shortVideoReply'.tr(),
            style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF45556C)),
          ),
        ),
        SizedBox(width: 16.w),
        GestureDetector(
          onTap: () => const ComplaintRoute(targetId: 1, targetType: 'comment')
              .push(context),
          child: Text(
            'shortVideoReport'.tr(),
            style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF90A1B9)),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onLike,
          child: Row(
            children: [
              MyImage.asset(
                isLiked ? MyImagePaths.iconLiked : MyImagePaths.iconOmmentUnlike,
                width: 18.w,
              ),
              SizedBox(width: 3.w),
              Text(
                formatCount(likes),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isLiked
                      ? const Color(0xFFFF2056)
                      : const Color(0xFF90A1B9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CommentAvatar extends StatelessWidget {
  final double radius;
  final String avatarUrl;

  const CommentAvatar({super.key, required this.radius, this.avatarUrl = ''});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFD1D1D6),
        backgroundImage: NetworkImage(avatarUrl),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFD1D1D6),
      child: Icon(Icons.person, size: radius * 1.1, color: Colors.white),
    );
  }
}

class CommentInput extends StatefulWidget {
  const CommentInput({super.key});

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController _inputCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (!_hasText) return;
    _inputCtrl.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 4.w, offset: Offset(0, -1.w))
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 46.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FE),
                  borderRadius: BorderRadius.circular(46.r),
                  border:
                      Border.all(color: const Color(0xFFE3E7ED), width: 0.84.w),
                ),
                child: TextField(
                  controller: _inputCtrl,
                  focusNode: _focusNode,
                  style: TextStyle(
                      fontSize: 12.sp, color: const Color(0xFF0F172B)),
                  onChanged: (v) =>
                      setState(() => _hasText = v.trim().isNotEmpty),
                  onSubmitted: (_) {
                    _sendMessage();
                    _focusNode.requestFocus();
                  },
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 15.w, vertical: 13.w),
                    hintText: 'shortVideoCommentHint'.tr(),
                    hintStyle: TextStyle(
                        fontSize: 12.sp, color: const Color(0xFF90A1B9)),
                    suffixIcon: GestureDetector(
                      onTap: () {},
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: MyImage.asset(MyImagePaths.iconEmoji,
                            width: 24.w, height: 24.w),
                      ),
                    ),
                    suffixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
