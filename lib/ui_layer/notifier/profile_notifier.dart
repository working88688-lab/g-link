import 'package:flutter/material.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart';

class ProfileNotifier extends ChangeNotifier {
  ProfileNotifier(this._profileDomain);

  final ProfileDomain _profileDomain;

  bool loadingProfile = false;
  bool loadingVideos = false;
  bool loadingInterests = false;
  bool authExpired = false;
  String? errorMessage;

  UserProfile? profile;
  List<UserVideoItem> videos = const [];
  List<InterestTag> interestTags = const [];

  Future<void> fetchProfileAndVideos({required int uid}) async {
    loadingProfile = true;
    loadingVideos = true;
    authExpired = false;
    errorMessage = null;
    notifyListeners();

    final profileResult = await _profileDomain.getUserProfile(uid: uid);
    if (profileResult.status == 0 && profileResult.data != null) {
      profile = profileResult.data;
    } else {
      _handleError(profileResult.status, profileResult.msg,
          fallback: 'Load profile failed');
    }

    final videosResult =
        await _profileDomain.getUserVideos(uid: uid, limit: 20);
    if (videosResult.status == 0 && videosResult.data != null) {
      videos = videosResult.data!;
    } else {
      _handleError(
        videosResult.status,
        videosResult.msg,
        fallback: errorMessage ?? 'Load videos failed',
      );
    }

    loadingProfile = false;
    loadingVideos = false;
    notifyListeners();
  }

  Future<void> fetchInterests() async {
    loadingInterests = true;
    notifyListeners();
    final result = await _profileDomain.getInterestTags();
    if (result.status == 0 && result.data != null) {
      interestTags = result.data!;
    } else {
      _handleError(result.status, result.msg,
          fallback: errorMessage ?? 'Load interests failed');
    }
    loadingInterests = false;
    notifyListeners();
  }

  void _handleError(int? status, String? message, {required String fallback}) {
    if (status == -10010 || status == -10011) {
      authExpired = true;
    }
    errorMessage = message ?? fallback;
  }
}
