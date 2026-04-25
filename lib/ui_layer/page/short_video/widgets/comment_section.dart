import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';

import '../../../router/routes.dart';

// ──────────────────────────────────────────
// Mock 数据模型
// ──────────────────────────────────────────
class MockComment {
  final String authorName;
  final String timeAgo;
  final String text;
  final int likes;
  bool isLiked;
  final List<MockComment> replies;
  final int moreRepliesCount;

  MockComment({
    required this.authorName,
    required this.timeAgo,
    required this.text,
    this.likes = 0,
    this.isLiked = false,
    this.replies = const [],
    this.moreRepliesCount = 0,
  });
}

final mockCommentList = <MockComment>[
  MockComment(
    authorName: 'Sarah Jenks',
    timeAgo: '3周前',
    text: '太帅了吧，口水流了一地，太有意境了，还有舒服的晚风，美丽的大自然，太棒了，羡慕呢。',
    likes: 2300,
    isLiked: true,
    replies: [
      MockComment(
        authorName: 'Sarah Jenks',
        timeAgo: '3周前',
        text: '太帅了吧，口水流了一地，太有意境了，还有舒服的晚风，美丽的大自然，太棒了，羡慕',
        likes: 2300,
      ),
    ],
    moreRepliesCount: 3,
  ),
  MockComment(
    authorName: 'Sarah Jenks',
    timeAgo: '3周前',
    text: '太帅了吧，口水流了一地，太有意境了，还有舒服的晚风，美丽的大自然，太棒了，羡慕呢。',
    likes: 2300,
  ),
  MockComment(
    authorName: 'Sarah Jenks',
    timeAgo: '3周前',
    text: '太帅了吧，口水流了一地，太有意境了，还有',
    likes: 2300,
  ),
  MockComment(
    authorName: 'Sarah Jenks',
    timeAgo: '3周前',
    text: '太帅了吧，口水流了一地，太有意境了，还有',
    likes: 2300,
  ),
];

// ──────────────────────────────────────────
// 评论弹窗内容
// ──────────────────────────────────────────
class CommentContent extends StatefulWidget {
  final String authorName;
  final bool showTitle;
  final Widget? scrollTopChild;

  const CommentContent({
    super.key,
    required this.authorName,
    this.showTitle = false,
    this.scrollTopChild,
  });

  @override
  State<CommentContent> createState() => _CommentContentState();
}

class _CommentContentState extends State<CommentContent> {
  final List<MockComment> _comments = List.of(mockCommentList);

  String _formatCount(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}w';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.72 - 40,
      child: Column(
        children: [
          if (widget.showTitle) ...[
            Text(
              'shortVideoCommentTitle'.tr(namedArgs: {'count': '848'}),
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
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _comments.length,
                    itemBuilder: (_, i) => CommentItem(
                      comment: _comments[i],
                      formatCount: _formatCount,
                      onLike: () => setState(
                          () => _comments[i].isLiked = !_comments[i].isLiked),
                      onReplyLike: (replyIndex) => setState(
                        () => _comments[i].replies[replyIndex].isLiked =
                            !_comments[i].replies[replyIndex].isLiked,
                      ),
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

// ──────────────────────────────────────────
// 单条评论
// ──────────────────────────────────────────
class CommentItem extends StatelessWidget {
  final MockComment comment;
  final String Function(int) formatCount;
  final VoidCallback onLike;
  final void Function(int replyIndex) onReplyLike;

  const CommentItem({
    super.key,
    required this.comment,
    required this.formatCount,
    required this.onLike,
    required this.onReplyLike,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommentAvatar(radius: 20.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF45556C)),
                    ),
                    SizedBox(width: 6.w),
                    Text(comment.timeAgo,
                        style: TextStyle(
                            fontSize: 12.sp, color: const Color(0xFF90A1B9))),
                  ],
                ),
                SizedBox(height: 2.w),
                Text(comment.text,
                    style: TextStyle(
                        fontSize: 12.sp, color: const Color(0xFF45556C))),
                SizedBox(height: 8.w),
                CommentActions(
                  likes: comment.likes,
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
                            onLike: () => onReplyLike(e.key),
                          ),
                        ),
                      ),
                  if (comment.moreRepliesCount > 0)
                    Row(
                      children: [
                        SizedBox(width: 36.w),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            'shortVideoMoreReplies'.tr(namedArgs: {
                              'count': '${comment.moreRepliesCount}'
                            }),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF45556C),
                            ),
                          ),
                        ),
                      ],
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

// ──────────────────────────────────────────
// 子回复
// ──────────────────────────────────────────
class CommentReplyItem extends StatelessWidget {
  final MockComment reply;
  final String Function(int) formatCount;
  final VoidCallback onLike;

  const CommentReplyItem({
    super.key,
    required this.reply,
    required this.formatCount,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommentAvatar(radius: 12.w),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    reply.authorName,
                    style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF45556C)),
                  ),
                  SizedBox(width: 6.w),
                  Text(reply.timeAgo,
                      style: TextStyle(
                          fontSize: 12.sp, color: const Color(0xFF90A1B9))),
                ],
              ),
              SizedBox(height: 2.w),
              Text(reply.text,
                  style: TextStyle(
                      fontSize: 12.sp, color: const Color(0xFF45556C))),
              SizedBox(height: 8.w),
              CommentActions(
                likes: reply.likes,
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

// ──────────────────────────────────────────
// 评论操作行（回复 / 举报 / 点赞）
// ──────────────────────────────────────────
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
                isLiked
                    ? MyImagePaths.iconLiked
                    : MyImagePaths.iconOmmentUnlike,
                width: 18.w,
              ),
              SizedBox(width: 3.w),
              Text(
                formatCount(isLiked ? likes + 1 : likes),
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

// ──────────────────────────────────────────
// 通用头像占位
// ──────────────────────────────────────────
class CommentAvatar extends StatelessWidget {
  final double radius;

  const CommentAvatar({super.key, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFD1D1D6),
      child: Icon(Icons.person, size: radius * 1.1, color: Colors.white),
    );
  }
}

// ──────────────────────────────────────────
// 评论输入框
// ──────────────────────────────────────────
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
