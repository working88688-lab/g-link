import 'package:g_link/domain/type_def.dart';

import 'base_service.dart';

class ProfileService extends BaseService {
  ProfileService(super._dio);

  @override
  final service = 'v1';

  AsyncJson getUserProfile({required int uid}) =>
      get('/users/$uid', encrypted: false);
  AsyncJson getMyProfile() => get('/users/me', encrypted: false);

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
  AsyncJson getUserPosts({
    required int uid,
    String? cursor,
    int? limit,
  }) =>
      get(
        '/users/$uid/posts',
        queryParameters: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          if (limit != null) 'limit': limit,
        },
        encrypted: false,
      );
  AsyncJson getUserLikes({
    required int uid,
    String? cursor,
    int? limit,
  }) =>
      get(
        '/users/$uid/likes',
        queryParameters: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          if (limit != null) 'limit': limit,
        },
        encrypted: false,
      );
  AsyncJson getMyVideos({
    String? cursor,
    int? limit,
  }) =>
      get(
        '/users/me/videos',
        queryParameters: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          if (limit != null) 'limit': limit,
        },
        encrypted: false,
      );
  AsyncJson getMyPosts({
    String? cursor,
    int? limit,
  }) =>
      get(
        '/users/me/posts',
        queryParameters: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          if (limit != null) 'limit': limit,
        },
        encrypted: false,
      );
  AsyncJson getMyLikes({
    String? cursor,
    int? limit,
  }) =>
      get(
        '/users/me/likes',
        queryParameters: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          if (limit != null) 'limit': limit,
        },
        encrypted: false,
      );

  AsyncJson getInterests() => get('/interests', encrypted: false);

  AsyncJson submitOnboardingInterests({
    required List<int> tagIds,
  }) =>
      post('/onboarding/interests',
          data: {
            'tag_ids': tagIds,
          },
          jsonBody: true,
          encrypted: false);

  AsyncJson completeOnboarding() =>
      post('/onboarding/complete', data: {}, jsonBody: true, encrypted: false);
}
