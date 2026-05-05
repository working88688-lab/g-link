import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/ui_layer/event/event_bus.dart';

class ProfileNotifier extends ChangeNotifier {
  ProfileNotifier(this._profileDomain) {
    _postPublishedSub = eventBus.on<PostPublishedEvent>().listen((_) {
      _onPostPublishedElsewhere();
    });
  }

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

  /// 标记当前展示的 [profile] 是否来自本地缓存：在缓存命中后真接口还没回来时是
  /// true，用来在 UI 上判断"是否还要显示初始 loading"——拿到了缓存就不必显示。
  bool profileFromCache = false;

  /// 记录最近一次成功拉到「我的资料」的时间戳（毫秒），用于节流：tab 切换 /
  /// 页面重新可见 / 页面下拉刷新都会触发拉新数据，但 8 秒内重复触发要被吃掉。
  int _lastMineFetchAt = 0;

  /// 当前是否有"我的资料"的拉取请求在飞，避免可见性回调撞上下拉刷新各发一份。
  bool _mineFetching = false;

  StreamSubscription<PostPublishedEvent>? _postPublishedSub;

  /// 图文发布成功后：清空帖子列表缓存；若正在「作品」tab 则立刻重拉，避免仍看到空列表。
  void _onPostPublishedElsewhere() {
    if (_disposed || profile == null) return;
    posts = const [];
    if (tabIndex == 0) {
      unawaited(_loadTabData(force: true));
    } else {
      _safeNotify();
    }
  }

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

  /// 冷启动 / 首次进入 MinePage 时调用：先把本地缓存灌到 UI 上立刻可见，
  /// 然后异步请求最新数据替换。这样个人主页第一次也不需要等到接口回来才有内容。
  Future<void> bootstrapMineProfile() async {
    if (profile == null) {
      final cached = await _profileDomain.readCachedMyProfile();
      if (_disposed) return;
      if (cached != null && profile == null) {
        // 注意：只在网络结果还没到的时候用缓存填充；网络已经先一步回来就不要回退到旧值。
        profile = cached;
        profileFromCache = true;
        _safeNotify();
      }
    }
    await fetchMineProfileAndVideos();
  }

  /// 个人主页重新可见时调用：节流控制 + 跳过重复并发，让"切 tab 回来"
  /// 不会变成密集刷新。下拉刷新走 [fetchMineProfileAndVideos] 强刷，
  /// 不过这条路径上的 [_mineFetching] 互斥仍然有效。
  Future<void> refreshIfStale({
    Duration minInterval = const Duration(seconds: 8),
  }) async {
    if (_mineFetching) {
      developer.log(
        '[mine-refresh] skip: in-flight request',
        name: 'mine-refresh',
      );
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final delta = now - _lastMineFetchAt;
    if (_lastMineFetchAt > 0 && delta < minInterval.inMilliseconds) {
      developer.log(
        '[mine-refresh] skip: throttled (${delta}ms < ${minInterval.inMilliseconds}ms)',
        name: 'mine-refresh',
      );
      return;
    }
    await fetchMineProfileAndVideos();
  }

  Future<void> fetchMineProfileAndVideos() async {
    if (_mineFetching) {
      developer.log(
        '[mine-refresh] coalesced: already fetching',
        name: 'mine-refresh',
      );
      return;
    }
    _mineFetching = true;
    // 已经有缓存先垫着的话，不显示骨架 loading，避免 UI 闪一下变空再回来；
    // 完全没数据时（首次冷启动）才走 loading。
    final hasCachedView = profile != null;
    if (!hasCachedView) {
      loadingProfile = true;
      loadingVideos = true;
    }
    authExpired = false;
    errorMessage = null;
    _safeNotify();

    try {
      final profileResult = await _profileDomain.getMyProfile();
      if (profileResult.status == 0 && profileResult.data != null) {
        profile = profileResult.data;
        profileFromCache = false;
        // 命中网络立刻把最新版本同步到本地，下次冷启动直接从缓存秒开。
        unawaited(_profileDomain.cacheMyProfile(profile!).catchError((e, s) {
          developer.log(
            '[mine-refresh] cache write failed: $e',
            name: 'mine-refresh',
            error: e,
            stackTrace: s,
          );
        }));
      } else {
        _handleError(
          profileResult.status,
          profileResult.msg,
          fallback: 'Load profile failed',
        );
      }

      await _loadTabData(force: true);
      _lastMineFetchAt = DateTime.now().millisecondsSinceEpoch;
    } finally {
      _mineFetching = false;
      loadingProfile = false;
      loadingVideos = false;
      _safeNotify();
    }
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
      final result = await _profileDomain.getUserPosts(
        uid: profile!.uid,
        limit: 21,
      );
      if (result.status == 0 && result.data != null) {
        posts = result.data!;
      } else {
        _handleError(result.status, result.msg, fallback: 'Load posts failed');
      }
    } else if (tabIndex == 1) {
      final result = await _profileDomain.getUserVideos(
        uid: profile!.uid,
        limit: 21,
      );
      if (result.status == 0 && result.data != null) {
        videos = result.data!;
      } else {
        _handleError(result.status, result.msg, fallback: 'Load videos failed');
      }
    } else {
      final result = await _profileDomain.getUserLikes(
        uid: profile!.uid,
        limit: 21,
      );
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
    _postPublishedSub?.cancel();
    _disposed = true;
    super.dispose();
  }
}
