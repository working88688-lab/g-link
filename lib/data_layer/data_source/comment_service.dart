import 'package:g_link/domain/model/comment_models.dart';

import 'base_service.dart';

class CommentService extends BaseService {
  CommentService(super._dio);

  @override
  final service = 'v1';

  Future<CommentPage<CommentItemModel>> fetchComments({
    required String targetType,
    required int targetId,
    String? cursor,
    int limit = 10,
  }) async {
    final params = <String, dynamic>{
      'target_type': targetType,
      'target_id': targetId,
      'limit': limit,
    };
    if (cursor != null && cursor.isNotEmpty) {
      params['cursor'] = cursor;
    }

    final res = await get('/comments', queryParameters: params, encrypted: false);
    final data = res['data'] as Map<String, dynamic>? ?? res;
    return CommentPage.fromJson(
      data,
      (json) => CommentItemModel.fromJson(json),
    );
  }

  Future<CommentPage<CommentItemModel>> fetchCommentReplies({
    required int commentId,
    String? cursor,
    int limit = 10,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      params['cursor'] = cursor;
    }

    final res = await get('/comments/$commentId/replies',
        queryParameters: params, encrypted: false);
    final data = res['data'] as Map<String, dynamic>? ?? res;
    return CommentPage.fromJson(
      data,
      (json) => CommentItemModel.fromJson(json),
    );
  }

  Future<CommentLikeActionResult> likeComment(int commentId) async {
    final res = await post('/comments/$commentId/like',
        data: const <String, dynamic>{}, encrypted: false);
    final data = res['data'] as Map<String, dynamic>? ?? res;
    return CommentLikeActionResult.fromJson(data);
  }

  Future<CommentLikeActionResult> unlikeComment(int commentId) async {
    final res = await delete('/comments/$commentId/like', encrypted: false);
    final data = res['data'] as Map<String, dynamic>? ?? res;
    return CommentLikeActionResult.fromJson(data);
  }
}
