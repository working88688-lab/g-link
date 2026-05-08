import 'package:g_link/domain/model/comment_models.dart';

abstract class CommentDomain {
  Future<CommentPage<CommentItemModel>> getComments({
    required String targetType,
    required int targetId,
    String? cursor,
    int limit,
  });

  Future<CommentPage<CommentItemModel>> getCommentReplies({
    required int commentId,
    String? cursor,
    int limit,
  });

  Future<CommentLikeActionResult> likeComment(int commentId);
  Future<CommentLikeActionResult> unlikeComment(int commentId);
}
