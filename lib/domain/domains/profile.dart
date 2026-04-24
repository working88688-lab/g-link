import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/domain/type_def.dart';

abstract class ProfileDomain {
  AsyncResult<UserProfile> getUserProfile({required int uid});

  AsyncResult<List<UserVideoItem>> getUserVideos({
    required int uid,
    String? cursor,
    int? limit,
  });

  AsyncResult<List<InterestTag>> getInterestTags();
}
