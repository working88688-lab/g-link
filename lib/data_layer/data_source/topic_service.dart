import 'package:g_link/domain/type_def.dart';

import 'base_service.dart';

/// 话题模块：`GET /api/v1/topics/hot`、`GET /api/v1/topics/search`。
///
/// 与 Feed、帖子发布解耦；发布仍通过 `POST /api/v1/posts` 的 `tags` 传话题。
class TopicService extends BaseService {
  TopicService(super._dio);

  @override
  final service = 'v1';

  AsyncJson getHotTopics() => get('/topics/hot', encrypted: false);

  AsyncJson searchTopics({required String query}) => get(
        '/topics/search',
        queryParameters: {'q': query},
        encrypted: false,
      );
}
