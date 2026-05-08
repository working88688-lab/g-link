part of '../repo.dart';

mixin _Comment on _BaseAppRepo implements CommentDomain {
  @override
  Future<CommentPage<CommentItemModel>> getComments({
    required String targetType,
    required int targetId,
    String? cursor,
    int limit = 10,
  }) async {
    return await _commentService.fetchComments(
      targetType: targetType,
      targetId: targetId,
      cursor: cursor,
      limit: limit,
    );
  }

  @override
  Future<CommentPage<CommentItemModel>> getCommentReplies({
    required int commentId,
    String? cursor,
    int limit = 10,
  }) async {
    return await _commentService.fetchCommentReplies(
      commentId: commentId,
      cursor: cursor,
      limit: limit,
    );
  }

  @override
  Future<CommentLikeActionResult> likeComment(int commentId) async {
    return await _commentService.likeComment(commentId);
  }

  @override
  Future<CommentLikeActionResult> unlikeComment(int commentId) async {
    return await _commentService.unlikeComment(commentId);
  }
}
