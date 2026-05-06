import 'package:flutter/foundation.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/utils/common_utils.dart';

/// 关注列表页 tab 标识。截图三个 tab 顺序：互关 / 关注 / 粉丝。
enum FollowListTab { mutual, followings, followers }

/// 关注列表页状态：互关 / 关注 / 粉丝 三个 tab。
///
/// 互关接口（[ProfileDomain.getUserMutualFollows]）不分页，单次最多 20 条；
/// 关注 / 粉丝接口走游标分页（cursor = 上一页最后一条 follow_id）。
/// 三个 tab 各自维护：列表 / 加载中 / 已加载 / 游标 / 是否还有更多。
class FollowListNotifier extends ChangeNotifier {
  FollowListNotifier({
    required this.uid,
    required ProfileDomain profileDomain,
    FollowListTab initialTab = FollowListTab.followings,
  })  : _profileDomain = profileDomain,
        currentTab = initialTab;

  final int uid;
  final ProfileDomain _profileDomain;

  FollowListTab currentTab;
  String? errorMessage;

  // ------ 三个 tab 各自的状态。 ------
  List<FollowedUser> mutualList = const [];
  List<FollowedUser> followingsList = const [];
  List<FollowedUser> followersList = const [];

  bool mutualLoading = false;
  bool followingsLoading = false;
  bool followersLoading = false;

  bool mutualLoaded = false;
  bool followingsLoaded = false;
  bool followersLoaded = false;

  /// 关注 / 粉丝 tab 的「上拉加载更多」并发标记，避免短时间内重复请求。
  bool followingsLoadingMore = false;
  bool followersLoadingMore = false;

  String? followingsCursor;
  String? followersCursor;

  bool followingsHasMore = true;
  bool followersHasMore = true;

  /// 服务端返回的「关注/粉丝总数」，用于副标题展示。互关接口字段名是 `count`。
  int? mutualCount;
  int? followingsTotal;
  int? followersTotal;

  /// 关注按钮请求中的 uid（按 uid 维度去重，避免对同一行重复点）。
  final Set<int> _followInflight = <int>{};

  bool _disposed = false;

  bool get isLoadingCurrent => switch (currentTab) {
        FollowListTab.mutual => mutualLoading,
        FollowListTab.followings => followingsLoading,
        FollowListTab.followers => followersLoading,
      };

  List<FollowedUser> get currentList => switch (currentTab) {
        FollowListTab.mutual => mutualList,
        FollowListTab.followings => followingsList,
        FollowListTab.followers => followersList,
      };

  bool get currentLoaded => switch (currentTab) {
        FollowListTab.mutual => mutualLoaded,
        FollowListTab.followings => followingsLoaded,
        FollowListTab.followers => followersLoaded,
      };

  bool isFollowInflight(int uid) => _followInflight.contains(uid);

  void changeTab(FollowListTab tab) {
    if (currentTab == tab) return;
    currentTab = tab;
    _safeNotify();
    if (!currentLoaded && !isLoadingCurrent) {
      load();
    }
  }

  Future<void> load({bool force = false}) async {
    switch (currentTab) {
      case FollowListTab.mutual:
        await _loadMutual(force: force);
        break;
      case FollowListTab.followings:
        await _loadFollowings(force: force, refresh: true);
        break;
      case FollowListTab.followers:
        await _loadFollowers(force: force, refresh: true);
        break;
    }
  }

  Future<void> loadMore() async {
    switch (currentTab) {
      case FollowListTab.mutual:
        return; // 互关接口不分页。
      case FollowListTab.followings:
        if (followingsLoadingMore || !followingsHasMore) return;
        await _loadFollowings(force: true, refresh: false);
        break;
      case FollowListTab.followers:
        if (followersLoadingMore || !followersHasMore) return;
        await _loadFollowers(force: true, refresh: false);
        break;
    }
  }

  Future<void> _loadMutual({bool force = false}) async {
    if (!force && mutualLoaded) return;
    if (mutualLoading) return;
    mutualLoading = true;
    errorMessage = null;
    _safeNotify();
    final result = await _profileDomain.getUserMutualFollows(uid: uid);
    mutualLoading = false;
    if (result.status == 0 && result.data != null) {
      mutualList = result.data!.lists;
      mutualCount = result.data!.total ?? mutualList.length;
      mutualLoaded = true;
    } else {
      errorMessage = result.msg;
    }
    _safeNotify();
  }

  Future<void> _loadFollowings({
    required bool force,
    required bool refresh,
  }) async {
    if (refresh) {
      if (followingsLoading) return;
      if (!force && followingsLoaded) return;
      followingsLoading = true;
      followingsLoadingMore = false;
      errorMessage = null;
      _safeNotify();
      final result = await _profileDomain.getUserFollowings(
        uid: uid,
        cursor: null,
      );
      followingsLoading = false;
      if (result.status == 0 && result.data != null) {
        followingsList = result.data!.lists;
        followingsCursor = result.data!.nextCursor;
        followingsHasMore = result.data!.hasMore;
        followingsTotal = result.data!.total;
        followingsLoaded = true;
      } else {
        errorMessage = result.msg;
      }
      _safeNotify();
    } else {
      followingsLoadingMore = true;
      _safeNotify();
      final result = await _profileDomain.getUserFollowings(
        uid: uid,
        cursor: followingsCursor,
      );
      followingsLoadingMore = false;
      if (result.status == 0 && result.data != null) {
        followingsList = [...followingsList, ...result.data!.lists];
        followingsCursor = result.data!.nextCursor;
        followingsHasMore = result.data!.hasMore;
        followingsTotal = result.data!.total ?? followingsTotal;
      } else {
        errorMessage = result.msg;
        followingsHasMore = false;
      }
      _safeNotify();
    }
  }

  Future<void> _loadFollowers({
    required bool force,
    required bool refresh,
  }) async {
    if (refresh) {
      if (followersLoading) return;
      if (!force && followersLoaded) return;
      followersLoading = true;
      followersLoadingMore = false;
      errorMessage = null;
      _safeNotify();
      final result = await _profileDomain.getUserFollowers(
        uid: uid,
        cursor: null,
      );
      followersLoading = false;
      if (result.status == 0 && result.data != null) {
        followersList = result.data!.lists;
        followersCursor = result.data!.nextCursor;
        followersHasMore = result.data!.hasMore;
        followersTotal = result.data!.total;
        followersLoaded = true;
      } else {
        errorMessage = result.msg;
      }
      _safeNotify();
    } else {
      followersLoadingMore = true;
      _safeNotify();
      final result = await _profileDomain.getUserFollowers(
        uid: uid,
        cursor: followersCursor,
      );
      followersLoadingMore = false;
      if (result.status == 0 && result.data != null) {
        followersList = [...followersList, ...result.data!.lists];
        followersCursor = result.data!.nextCursor;
        followersHasMore = result.data!.hasMore;
        followersTotal = result.data!.total ?? followersTotal;
      } else {
        errorMessage = result.msg;
        followersHasMore = false;
      }
      _safeNotify();
    }
  }

  /// 切换某个 user 的关注状态。
  /// - true → 调 [ProfileDomain.followUser]
  /// - false → 调 [ProfileDomain.unfollowUser]
  ///
  /// 采用「乐观 + 失败回滚」：先本地翻一下状态，再发请求；接口失败则原地恢复。
  Future<bool> toggleFollow(int targetUid) async {
    if (_followInflight.contains(targetUid)) return false;
    final beforeMutual = _findIndex(mutualList, targetUid);
    final beforeFollowings = _findIndex(followingsList, targetUid);
    final beforeFollowers = _findIndex(followersList, targetUid);

    bool? before;
    if (beforeMutual >= 0) before = mutualList[beforeMutual].isFollowing;
    if (beforeFollowings >= 0) {
      before ??= followingsList[beforeFollowings].isFollowing;
    }
    if (beforeFollowers >= 0) {
      before ??= followersList[beforeFollowers].isFollowing;
    }
    if (before == null) return false;

    final next = !before;
    _followInflight.add(targetUid);
    _applyFollowingFlag(targetUid, next);
    _safeNotify();

    final result = next
        ? await _profileDomain.followUser(uid: targetUid)
        : await _profileDomain.unfollowUser(uid: targetUid);

    _followInflight.remove(targetUid);
    if (result.status == 0 && result.data != null) {
      // 服务端返回的最新关系（含 is_friend / 双向关注），覆盖一次本地状态。
      _applyFollowingFlag(
        targetUid,
        result.data!.isFollowing,
        isFriend: result.data!.isFriend,
      );
      _safeNotify();
      return true;
    }

    _applyFollowingFlag(targetUid, before);
    errorMessage = result.msg;
    _safeNotify();
    return false;
  }

  int _findIndex(List<FollowedUser> list, int targetUid) {
    for (var i = 0; i < list.length; i++) {
      if (list[i].uid == targetUid) return i;
    }
    return -1;
  }

  void _applyFollowingFlag(
    int targetUid,
    bool isFollowing, {
    bool? isFriend,
  }) {
    void update(List<FollowedUser> list) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].uid == targetUid) {
          list[i] = list[i].copyWith(
            isFollowing: isFollowing,
            isFriend: isFriend,
          );
        }
      }
    }

    update(mutualList);
    update(followingsList);
    update(followersList);
  }

  void _safeNotify() {
    if (_disposed) return;
    try {
      notifyListeners();
    } catch (e, st) {
      CommonUtils.log(e);
      CommonUtils.log(st);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
