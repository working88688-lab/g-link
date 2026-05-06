import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:g_link/domain/domains/feed.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/feed_models.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/ui_layer/event/event_bus.dart';

class ProfileNotifier extends ChangeNotifier {
  /// 默认构造给「我的主页」使用：[targetUid] 为空走 `getMyProfile` + 草稿置顶。
  /// 看他人主页时通过 [targetUid] 指定目标 uid，会走 `getUserProfile(uid)` 并
  /// 跳过本地草稿装载——草稿是当前登录用户专属。
  ProfileNotifier(
    this._profileDomain,
    this._feedDomain, {
    int? targetUid,
  }) : _targetUid = targetUid {
    _postPublishedSub = eventBus.on<PostPublishedEvent>().listen((_) {
      _onPostPublishedElsewhere();
    });
  }

  final ProfileDomain _profileDomain;
  final FeedDomain _feedDomain;
  final int? _targetUid;
  bool _disposed = false;

  /// `true` = 看自己的主页（顶部带「编辑资料」+ 草稿置顶 + 设置抽屉）；
  /// `false` = 看他人主页（顶部「关注 / 发消息」+ 三点菜单 + 拉黑态）。
  bool get isOwnProfile => _targetUid == null;
  int? get targetUid => _targetUid;

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

  /// 「作品」/「视频」tab 上要置顶展示的最新草稿；为空表示当前用户没有对应类型的草稿。
  /// 由 `_loadTabData` 与对应列表接口并行拉取，失败不影响主列表展示。
  DraftItem? postDraft;
  DraftItem? videoDraft;

  int tabIndex = 0;

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

    if (profile != null && !(profile!.isBlocked || profile!.isBlockedBy)) {
      // 拉黑后端通常会返 lists 空，但能省一次请求就省一次。
      await _loadTabData(force: true);
    }

    loadingProfile = false;
    loadingVideos = false;
    _safeNotify();
  }

  /// 进入他人主页时调用（与 [bootstrapMineProfile] 等价的入口，但不读本地缓存
  /// 也不写本地缓存——他人资料没有缓存的必要）。
  Future<void> bootstrapOtherProfile({required int uid}) async {
    await fetchProfileAndVideos(uid: uid);
  }

  /// 冷启动 / 首次进入 MinePage 时调用：先把本地缓存灌到 UI 上立刻可见，
  /// 然后异步请求最新数据替换。这样个人主页第一次也不需要等到接口回来才有内容。
  ///
  /// **仅自己主页**入口——他人主页走 [bootstrapOtherProfile]。
  Future<void> bootstrapMineProfile() async {
    assert(
      isOwnProfile,
      'bootstrapMineProfile() called on a non-self ProfileNotifier '
      '(targetUid=$_targetUid). Use bootstrapOtherProfile(uid:) instead.',
    );
    if (!isOwnProfile) return;
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
  ///
  /// 他人主页不应该走这条路径——它对应的是 `/me` 节流逻辑。如果调用方误用，
  /// 这里直接 no-op，避免在他人主页上产生「打开后立刻又拉一次 /me」的副作用。
  Future<void> refreshIfStale({
    Duration minInterval = const Duration(seconds: 8),
  }) async {
    if (!isOwnProfile) {
      developer.log(
        '[mine-refresh] skip: not own profile (uid=$_targetUid)',
        name: 'mine-refresh',
      );
      return;
    }
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

  /// 拉自己的资料 + 当前 tab 列表。**仅自己主页**调用——他人主页应走
  /// [fetchProfileAndVideos] / [bootstrapOtherProfile]。这里 `!isOwnProfile`
  /// 时直接 no-op，作为防御性兜底。
  Future<void> fetchMineProfileAndVideos() async {
    if (!isOwnProfile) {
      developer.log(
        '[mine-refresh] skip fetchMine: not own profile (uid=$_targetUid)',
        name: 'mine-refresh',
      );
      return;
    }
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

  /// 强制刷新当前 tab 的列表与置顶草稿（供草稿箱管理页删除返回时调用，
  /// 让网格里那张「草稿箱」cell 不至于停留在已删除项的封面上）。
  Future<void> reloadCurrentTab() => _loadTabData(force: true);

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
      // 列表与「最新一条草稿」并行拉取——草稿失败/为空都不影响主列表展示。
      // 他人主页不下发草稿。
      final postsFuture =
          _profileDomain.getUserPosts(uid: profile!.uid, limit: 21);
      final draftFuture = isOwnProfile
          ? _feedDomain.getDrafts(type: 'post', limit: 1)
          : null;
      final postResult = await postsFuture;
      if (postResult.status == 0 && postResult.data != null) {
        posts = postResult.data!;
      } else {
        _handleError(postResult.status, postResult.msg,
            fallback: 'Load posts failed');
      }
      if (draftFuture != null) {
        final draftResult = await draftFuture;
        if (draftResult.status == 0 && draftResult.data != null) {
          final list = draftResult.data!;
          postDraft = list.isNotEmpty ? list.first : null;
        } else {
          postDraft = null;
        }
      } else {
        postDraft = null;
      }
    } else if (tabIndex == 1) {
      final videosFuture =
          _profileDomain.getUserVideos(uid: profile!.uid, limit: 21);
      final draftFuture = isOwnProfile
          ? _feedDomain.getDrafts(type: 'video', limit: 1)
          : null;
      final videoResult = await videosFuture;
      if (videoResult.status == 0 && videoResult.data != null) {
        videos = videoResult.data!;
      } else {
        _handleError(videoResult.status, videoResult.msg,
            fallback: 'Load videos failed');
      }
      if (draftFuture != null) {
        final draftResult = await draftFuture;
        if (draftResult.status == 0 && draftResult.data != null) {
          final list = draftResult.data!;
          videoDraft = list.isNotEmpty ? list.first : null;
        } else {
          videoDraft = null;
        }
      } else {
        videoDraft = null;
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

  // ---- 他人主页交互 ---------------------------------------------------------

  /// 关注按钮 inflight 标记：避免双击两次扣两份请求。
  bool _followInflight = false;

  /// 拉黑/解除拉黑按钮 inflight 标记。
  bool _blockInflight = false;

  bool get followInflight => _followInflight;
  bool get blockInflight => _blockInflight;

  /// 切换关注：当前已关注就 unfollow，否则 follow。
  /// 服务端返回最新 follower_count / is_friend 后写回本地。返回值表示成功与否。
  Future<bool> toggleFollow() async {
    final p = profile;
    if (p == null || p.isSelf || _followInflight) return false;
    _followInflight = true;
    final before = p.isFollowing;
    // 乐观更新：UI 立刻翻按钮态。失败时回滚。
    profile = p.copyWith(
      isFollowing: !before,
      followerCount: (p.followerCount + (before ? -1 : 1))
          .clamp(0, 1 << 31),
    );
    _safeNotify();
    final result = before
        ? await _profileDomain.unfollowUser(uid: p.uid)
        : await _profileDomain.followUser(uid: p.uid);
    _followInflight = false;
    if (result.status == 0 && result.data != null) {
      final r = result.data!;
      profile = profile!.copyWith(
        isFollowing: r.isFollowing,
        isFriend: r.isFriend,
        followerCount: r.followerCount,
        followerCountDisplay: r.followerCountDisplay,
      );
      _safeNotify();
      return true;
    }
    profile = p; // 回滚
    errorMessage = result.msg ?? 'follow failed';
    _safeNotify();
    return false;
  }

  /// 拉黑当前 profile。成功后立刻翻 [UserProfile.isBlocked] = true，
  /// MinePage 在 isBlocked 状态下用空白「对方已被你拉黑」占位替代正文。
  Future<bool> blockCurrent() async {
    final p = profile;
    if (p == null || p.isSelf || _blockInflight) return false;
    _blockInflight = true;
    _safeNotify();
    final result = await _profileDomain.blockUser(uid: p.uid);
    _blockInflight = false;
    if (result.status == 0) {
      // 拉黑后清掉列表：被拉黑用户的内容不再展示。
      posts = const [];
      videos = const [];
      likes = const [];
      profile = p.copyWith(isBlocked: true, isFollowing: false);
      _safeNotify();
      return true;
    }
    errorMessage = result.msg ?? 'block failed';
    _safeNotify();
    return false;
  }

  /// 解除拉黑后重新拉一次主页 + 列表，恢复展示。
  Future<bool> unblockCurrent() async {
    final p = profile;
    if (p == null || p.isSelf || _blockInflight) return false;
    _blockInflight = true;
    _safeNotify();
    final result = await _profileDomain.unblockUser(uid: p.uid);
    _blockInflight = false;
    if (result.status == 0) {
      profile = p.copyWith(isBlocked: false);
      _safeNotify();
      // 重新拉资料 + 列表，让被拉黑期间没拿到的内容重新呈现。
      await fetchProfileAndVideos(uid: p.uid);
      return true;
    }
    errorMessage = result.msg ?? 'unblock failed';
    _safeNotify();
    return false;
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
