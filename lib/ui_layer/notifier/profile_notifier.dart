import 'package:flutter/material.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart';

class ProfileNotifier extends ChangeNotifier {
  ProfileNotifier(this._profileDomain);

  final ProfileDomain _profileDomain;
  bool _disposed = false;

  bool loadingProfile = false;
  bool loadingVideos = false;
  bool loadingInterests = false;
  bool authExpired = false;
  String? errorMessage;

  UserProfile? profile;
  List<UserPostItem> posts = const [];
  List<UserVideoItem> videos = const [];
  List<UserPostItem> likes = const [];
  List<InterestTag> interestTags = const [];
  int tabIndex = 1;

  Future<void> fetchProfileAndVideos({required int uid}) async {
    loadingProfile = true;
    loadingVideos = true;
    authExpired = false;
    errorMessage = null;
    _safeNotify();

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
    _safeNotify();
  }

  Future<void> fetchMineProfileAndVideos() async {
    loadingProfile = true;
    loadingVideos = true;
    authExpired = false;
    errorMessage = null;
    _safeNotify();

    final profileResult = await _profileDomain.getMyProfile();
    if (profileResult.status == 0 && profileResult.data != null) {
      profile = profileResult.data;
    } else {
      _handleError(
        profileResult.status,
        profileResult.msg,
        fallback: 'Load profile failed',
      );
    }

    await _loadTabData(force: true);

    loadingProfile = false;
    loadingVideos = false;
    _safeNotify();
  }

  Future<void> fetchInterests() async {
    loadingInterests = true;
    _safeNotify();
    final result = await _profileDomain.getInterestTags();
    if (result.status == 0 && result.data != null) {
      interestTags = result.data!;
    } else {
      _handleError(result.status, result.msg,
          fallback: errorMessage ?? 'Load interests failed');
    }
    loadingInterests = false;
    _safeNotify();
  }

  void _handleError(int? status, String? message, {required String fallback}) {
    if (status == -10010 || status == -10011) {
      authExpired = true;
    }
    errorMessage = message ?? fallback;
  }

  void changeTab(int index) {
    if (tabIndex == index) return;
    tabIndex = index;
    _loadTabData();
    _safeNotify();
  }

  Future<void> _loadTabData({bool force = false}) async {
    if (profile == null) return;
    if (!force) {
      if (tabIndex == 0 && posts.isNotEmpty) return;
      if (tabIndex == 1 && videos.isNotEmpty) return;
      if (tabIndex == 2 && likes.isNotEmpty) return;
    }
    loadingVideos = true;
    _safeNotify();
    if (tabIndex == 0) {
      final result = await _profileDomain.getMyPosts(limit: 21);
      if (result.status == 0 && result.data != null) {
        posts = result.data!;
      } else {
        _handleError(result.status, result.msg, fallback: 'Load posts failed');
      }
    } else if (tabIndex == 1) {
      final result = await _profileDomain.getMyVideos(limit: 21);
      if (result.status == 0 && result.data != null) {
        videos = result.data!;
      } else {
        _handleError(result.status, result.msg, fallback: 'Load videos failed');
      }
    } else {
      final result = await _profileDomain.getMyLikes(limit: 21);
      if (result.status == 0 && result.data != null) {
        likes = result.data!;
      } else {
        _handleError(result.status, result.msg, fallback: 'Load likes failed');
      }
    }
    loadingVideos = false;
    _safeNotify();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
