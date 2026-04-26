import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/domain/type_def.dart';

abstract class ProfileDomain {
  AsyncResult<UserProfile> getUserProfile({required int uid});
  AsyncResult<UserProfile> getMyProfile();

  AsyncResult<List<UserVideoItem>> getUserVideos({
    required int uid,
    String? cursor,
    int? limit,
  });
  AsyncResult<List<UserPostItem>> getUserPosts({
    required int uid,
    String? cursor,
    int? limit,
  });
  AsyncResult<List<UserPostItem>> getUserLikes({
    required int uid,
    String? cursor,
    int? limit,
  });
  AsyncResult<List<UserVideoItem>> getMyVideos({
    String? cursor,
    int? limit,
  });
  AsyncResult<List<UserPostItem>> getMyPosts({
    String? cursor,
    int? limit,
  });
  AsyncResult<List<UserPostItem>> getMyLikes({
    String? cursor,
    int? limit,
  });

  AsyncResult<List<InterestTag>> getInterestTags();

  AsyncResult submitOnboardingInterests({
    required List<int> tagIds,
  });

  AsyncResult completeOnboarding();
}
