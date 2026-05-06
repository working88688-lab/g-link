import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:g_link/domain/domains/feed.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/feed_models.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/domain/type_def.dart';
import 'package:g_link/ui_layer/event/event_bus.dart';

/// 首页支持三种数据源：推荐流 / 关注流 / 热门流（按设计稿底部 tab 表现的"附近"暂以热门流兜底）。
enum HomeFeedTab { recommend, following, hot }

/// 首页（推荐 / 关注 / 热门）状态机：
///   - 单 notifier 同时持有三个 tab 的列表 / 游标 / loading 状态，避免 tab 切换丢失分页进度
///   - 顶部"推荐关注"区独立维护 [_recommendUsers] + 关注覆盖
///   - 点赞 / 关注：先做乐观更新，失败再回滚，避免 UI 抖动
class HomeFeedNotifier extends ChangeNotifier {
  HomeFeedNotifier({
    required FeedDomain feedDomain,
    required ProfileDomain profileDomain,
  })  : _feedDomain = feedDomain,
        _profileDomain = profileDomain {
    _followStatusSubscription =
        eventBus.on<FollowStatusChangedEvent>().listen(_onFollowStatusChanged);
    _postPublishedSubscription =
        eventBus.on<PostPublishedEvent>().listen(_onPostPublished);
  }

  final FeedDomain _feedDomain;
  final ProfileDomain _profileDomain;

  bool _disposed = false;

  /// 当前展示中的 tab。
  HomeFeedTab _currentTab = HomeFeedTab.recommend;
  HomeFeedTab get currentTab => _currentTab;

  // 各 tab 的列表 / 游标 / loading 标志位
  final Map<HomeFeedTab, List<FeedPost>> _posts = {
    HomeFeedTab.recommend: <FeedPost>[],
    HomeFeedTab.following: <FeedPost>[],
    HomeFeedTab.hot: <FeedPost>[],
  };
  final Map<HomeFeedTab, String?> _cursor = {};
  final Map<HomeFeedTab, bool> _hasMore = {
    HomeFeedTab.recommend: true,
    HomeFeedTab.following: true,
    HomeFeedTab.hot: true,
  };
  final Map<HomeFeedTab, bool> _loading = {
    HomeFeedTab.recommend: false,
    HomeFeedTab.following: false,
    HomeFeedTab.hot: false,
  };
  final Map<HomeFeedTab, bool> _refreshing = {
    HomeFeedTab.recommend: false,
    HomeFeedTab.following: false,
    HomeFeedTab.hot: false,
  };
  final Map<HomeFeedTab, String?> _errorMessage = {
    HomeFeedTab.recommend: null,
    HomeFeedTab.following: null,
    HomeFeedTab.hot: null,
  };
  final Set<HomeFeedTab> _bootstrapped = <HomeFeedTab>{};

  // 推荐关注（横向卡片 + 顶部头像条共享一份数据）
  List<RecommendedUser> _recommendUsers = const [];
  bool _recommendUsersLoading = false;
  String? _recommendUsersError;

  /// uid -> 是否已关注。优先级高于服务器返回的 isFollowing；
  /// 通过该 map 在多个入口（顶部头像条 / 推荐卡片 / feed 卡头）共享同一关注状态。
  final Map<int, bool> _followOverride = <int, bool>{};

  // 关注请求 inflight 防抖（同一 uid 不重复并发）
  final Set<int> _followInflight = <int>{};
  // 点赞请求 inflight 防抖（同一 postId 不重复并发）
  final Set<int> _likeInflight = <int>{};
  StreamSubscription<FollowStatusChangedEvent>? _followStatusSubscription;
  StreamSubscription<PostPublishedEvent>? _postPublishedSubscription;

  // ───── getters ─────
  List<FeedPost> postsOf(HomeFeedTab tab) => List.unmodifiable(_posts[tab] ?? const []);
  bool isLoading(HomeFeedTab tab) => _loading[tab] == true;
  bool isRefreshing(HomeFeedTab tab) => _refreshing[tab] == true;
  bool hasMore(HomeFeedTab tab) => _hasMore[tab] != false;
  String? errorOf(HomeFeedTab tab) => _errorMessage[tab];
  bool isBootstrapped(HomeFeedTab tab) => _bootstrapped.contains(tab);

  List<RecommendedUser> get recommendUsers => List.unmodifiable(_recommendUsers);
  bool get recommendUsersLoading => _recommendUsersLoading;
  String? get recommendUsersError => _recommendUsersError;

  /// 当前登录用户 uid；用于隐藏本人帖子的关注按钮。
  int? get currentUserUid => _currentUserUid;

  int? _currentUserUid;

  bool isFollowing(int uid, {bool fallback = false}) =>
      _followOverride[uid] ?? fallback;

  // ───── public actions ─────

  /// MainShell 第一次进入首页时调用：拉默认 tab 数据 + 推荐关注。
  Future<void> bootstrap() async {
    await _resolveCurrentUserUid();
    await Future.wait([
      ensureLoaded(_currentTab),
      loadRecommendUsers(),
    ]);
  }

  Future<void> _resolveCurrentUserUid() async {
    final cached = await _profileDomain.readCachedMyProfile();
    if (_disposed) return;
    if (cached != null && cached.uid > 0) {
      _currentUserUid = cached.uid;
      _safeNotify();
    }
    final r = await _profileDomain.getMyProfile();
    if (_disposed) return;
    if (r.status == 0 && r.data != null && r.data!.uid > 0) {
      _currentUserUid = r.data!.uid;
      _safeNotify();
    }
  }

  void _seedFollowFromPosts(Iterable<FeedPost> posts) {
    for (final p in posts) {
      final f = p.author.isFollowing;
      if (f != null) {
        _followOverride.putIfAbsent(p.author.uid, () => f);
      }
    }
  }

  /// 切换 tab。第一次进该 tab 才会拉，避免来回点重复请求。
  Future<void> switchTab(HomeFeedTab tab) async {
    if (_currentTab == tab) return;
    _currentTab = tab;
    _safeNotify();
    await ensureLoaded(tab);
  }

  /// 没数据时拉首屏；已有数据则跳过（拉刷新走 [refresh]）。
  Future<void> ensureLoaded(HomeFeedTab tab) async {
    if (_loading[tab] == true) return;
    if (_bootstrapped.contains(tab)) return;
    await _loadInitial(tab);
  }

  /// 下拉刷新：清空游标重新拉首屏。
  Future<void> refresh(HomeFeedTab tab) async {
    if (_refreshing[tab] == true) return;
    _refreshing[tab] = true;
    _errorMessage[tab] = null;
    _safeNotify();
    try {
      await _loadInitial(tab, isRefresh: true);
      // 顺手刷新推荐关注
      unawaited(loadRecommendUsers(force: true));
    } finally {
      _refreshing[tab] = false;
      _safeNotify();
    }
  }

  /// 上拉加载更多。
  Future<void> loadMore(HomeFeedTab tab) async {
    if (_loading[tab] == true) return;
    if (_hasMore[tab] == false) return;
    final nextCursor = _cursor[tab];
    if (nextCursor == null || nextCursor.isEmpty) return;

    _loading[tab] = true;
    _safeNotify();
    final result = await _fetch(tab, cursor: nextCursor);
    if (_disposed) return;
    if (result.status == 0 && result.data != null) {
      final page = result.data!;
      _posts[tab] = [...?_posts[tab], ...page.items];
      _seedFollowFromPosts(page.items);
      _cursor[tab] = page.nextCursor;
      _hasMore[tab] = page.hasMore && page.nextCursor != null;
      _errorMessage[tab] = null;
    } else {
      _errorMessage[tab] = result.msg ?? 'load more failed';
    }
    _loading[tab] = false;
    _safeNotify();
  }

  /// 推荐关注列表。`force=true` 时即使已有数据也强制重拉。
  Future<void> loadRecommendUsers({bool force = false}) async {
    if (_recommendUsersLoading) return;
    if (!force && _recommendUsers.isNotEmpty) return;
    _recommendUsersLoading = true;
    _recommendUsersError = null;
    _safeNotify();
    final result = await _profileDomain.getRecommendedUsers(limit: 20);
    if (_disposed) return;
    if (result.status == 0 && result.data != null) {
      _recommendUsers = result.data!;
      // 用服务端权威 isFollowing 作为种子，但不会覆盖用户在本会话点过的覆盖值。
      for (final u in _recommendUsers) {
        _followOverride.putIfAbsent(u.uid, () => u.isFollowing);
      }
    } else {
      _recommendUsersError = result.msg ?? 'load recommend users failed';
    }
    _recommendUsersLoading = false;
    _safeNotify();
  }

  /// 切换关注状态。先乐观更新，失败回滚。
  Future<bool> toggleFollow(int uid) async {
    if (_currentUserUid != null && uid == _currentUserUid) return false;
    if (_followInflight.contains(uid)) return false;
    final wasFollowing = _followOverride[uid] ?? false;
    _followInflight.add(uid);
    _followOverride[uid] = !wasFollowing;
    _safeNotify();

    final result = wasFollowing
        ? await _profileDomain.unfollowUser(uid: uid)
        : await _profileDomain.followUser(uid: uid);

    if (_disposed) return false;
    _followInflight.remove(uid);
    if (result.status == 0 && result.data != null) {
      _followOverride[uid] = result.data!.isFollowing;
      eventBus.fire(
        FollowStatusChangedEvent(
          uid: uid,
          isFollowing: result.data!.isFollowing,
        ),
      );
      _safeNotify();
      return true;
    } else {
      // 失败回滚
      _followOverride[uid] = wasFollowing;
      _safeNotify();
      return false;
    }
  }

  void _onFollowStatusChanged(FollowStatusChangedEvent event) {
    _followOverride[event.uid] = event.isFollowing;
    _safeNotify();
  }

  void _onPostPublished(PostPublishedEvent _) {
    unawaited(refresh(HomeFeedTab.recommend));
    unawaited(refresh(HomeFeedTab.following));
  }

  /// 点赞 / 取消点赞。乐观更新本地点赞状态与计数，失败回滚。
  Future<bool> toggleLike(int postId) async {
    if (_likeInflight.contains(postId)) return false;
    _likeInflight.add(postId);

    final originals = <HomeFeedTab, FeedPost?>{};
    for (final tab in HomeFeedTab.values) {
      final list = _posts[tab];
      if (list == null) continue;
      final idx = list.indexWhere((p) => p.postId == postId);
      if (idx == -1) {
        originals[tab] = null;
        continue;
      }
      final original = list[idx];
      originals[tab] = original;
      list[idx] = original.copyWith(
        isLiked: !original.isLiked,
        likeCount: original.likeCount + (original.isLiked ? -1 : 1),
      );
    }
    _safeNotify();

    final isLikedNow = originals.values
        .firstWhere((p) => p != null, orElse: () => null)
        ?.isLiked;
    final result = isLikedNow == true
        ? await _feedDomain.unlikePost(postId: postId)
        : await _feedDomain.likePost(postId: postId);

    if (_disposed) return false;
    _likeInflight.remove(postId);

    if (result.status == 0 && result.data != null) {
      // 用服务端权威值校正一次点赞数（避免本地估算偏差）
      for (final tab in HomeFeedTab.values) {
        final list = _posts[tab];
        if (list == null) continue;
        final idx = list.indexWhere((p) => p.postId == postId);
        if (idx == -1) continue;
        list[idx] = list[idx].copyWith(
          isLiked: result.data!.liked,
          likeCount: result.data!.likeCount,
        );
      }
      _safeNotify();
      return true;
    } else {
      // 回滚
      for (final entry in originals.entries) {
        final original = entry.value;
        if (original == null) continue;
        final list = _posts[entry.key];
        if (list == null) continue;
        final idx = list.indexWhere((p) => p.postId == postId);
        if (idx == -1) continue;
        list[idx] = original;
      }
      _safeNotify();
      return false;
    }
  }

  // ───── internals ─────

  Future<void> _loadInitial(HomeFeedTab tab, {bool isRefresh = false}) async {
    _loading[tab] = true;
    if (!isRefresh) _errorMessage[tab] = null;
    _safeNotify();

    final result = await _fetch(tab, cursor: null);
    if (_disposed) return;
    if (result.status == 0 && result.data != null) {
      final page = result.data!;
      _posts[tab] = [...page.items];
      _seedFollowFromPosts(page.items);
      _cursor[tab] = page.nextCursor;
      _hasMore[tab] = page.hasMore && page.nextCursor != null;
      _errorMessage[tab] = null;
      _bootstrapped.add(tab);
    } else {
      // 拉刷新失败时不要清空老列表，保留旧内容 + 顶部错误提示
      if (!isRefresh) {
        _posts[tab] = const [];
      }
      _errorMessage[tab] = result.msg ?? 'load failed';
    }
    _loading[tab] = false;
    _safeNotify();
  }

  AsyncResult<FeedPage<FeedPost>> _fetch(HomeFeedTab tab,
      {String? cursor}) {
    switch (tab) {
      case HomeFeedTab.recommend:
        return _feedDomain.getRecommendFeed(cursor: cursor);
      case HomeFeedTab.following:
        return _feedDomain.getFollowFeed(cursor: cursor);
      case HomeFeedTab.hot:
        return _feedDomain.getHotFeed(cursor: cursor);
    }
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _followStatusSubscription?.cancel();
    _postPublishedSubscription?.cancel();
    super.dispose();
  }
}
