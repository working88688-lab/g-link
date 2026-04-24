import 'package:g_link/domain/type_def.dart';

import 'base_service.dart';

class ProfileService extends BaseService {
  ProfileService(super._dio);

  @override
  final service = 'v1';

  AsyncJson getUserProfile({required int uid}) => get('/users/$uid');

  AsyncJson getUserVideos({
    required int uid,
    String? cursor,
    int? limit,
  }) =>
      get(
        '/users/$uid/videos',
        queryParameters: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          if (limit != null) 'limit': limit,
        },
      );

  AsyncJson getInterests() => get('/interests');
}
