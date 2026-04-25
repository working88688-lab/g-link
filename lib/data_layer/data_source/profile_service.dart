import 'package:g_link/domain/type_def.dart';

import 'base_service.dart';

class ProfileService extends BaseService {
  ProfileService(super._dio);

  @override
  final service = 'v1';

  AsyncJson getUserProfile({required int uid}) =>
      get('/users/$uid', encrypted: false);

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
        encrypted: false,
      );

  AsyncJson getInterests() => get('/interests', encrypted: false);

  AsyncJson getRecommendedUsers({int limit = 20}) => get(
        '/users/recommendations',
        queryParameters: {'limit': limit},
        encrypted: false,
      );
}
