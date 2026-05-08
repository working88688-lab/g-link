import 'package:flutter/foundation.dart';
import 'package:g_link/domain/domains/feed.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/feed_models.dart';
import 'package:g_link/ui_layer/page/mine/user_posts_seed.dart';

/// 单个用户最新帖子列表的状态机：
/// - 入口：[load] / 下拉刷新走 [refresh] 强刷一次；
/// - 滚到底走 [loadMore]，复用接口的 cursor 翻页；
/// - 任何时刻只允许一个 in-flight 请求，避免连续触底快速触发多次。
///
/// 数据源：`GET /api/v1/users/{uid}/posts` 的富数据版本（[ProfileDomain.getUserPostsFeed]）。
class UserPostsNotifier extends ChangeNotifier {
  UserPostsNotifier({
    required this.uid,
    required ProfileDomain profileDomain,
    required FeedDomain feedDomain,
    UserPostsListSeed? listSeed,
  })  : _profileDomain = profileDomain,
        _feedDomain = feedDomain,
        _initialSeed = listSeed;

  final int uid;
  final ProfileDomain _profileDomain;
  final FeedDomain _feedDomain;
  final UserPostsListSeed? _initialSeed;

  final Set<int> _likeInflight = {};
  final Set<int> _favoriteInflight = {};

  bool _disposed = false;
  bool _loading = false;
  bool _loadingMore = false;
  bool _loaded = false;
  String? _error;

  String? _nextCursor;
  bool _hasMore = false;

  List<FeedPost> _posts = const [];

  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get loaded => _loaded;
  bool get hasMore => _hasMore;
  String? get error => _error;
  List<FeedPost> get posts => _posts;

  /// 首次加载或外部 invalidation 后的强刷。重置游标 + 列表。
  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (_loaded && !force) return;

    final seed = _initialSeed;
    if (!force && seed != null && seed.posts.isNotEmpty) {
      _posts = List<FeedPost>.from(seed.posts);
      _nextCursor = seed.nextCursor;
      _hasMore = seed.hasMore;
      _loaded = true;
      _error = null;
      _safeNotify();
      return;
    }

    _loading = true;
    _error = null;
    _safeNotify();
    final result = await _profileDomain.getUserPostsFeed(
      uid: uid,
      limit: 20,
      sort: 'new',
    );
    _loading = false;
    if (result.status == 0 && result.data != null) {
      final page = result.data!;
      _posts = page.items;
      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore;
      _loaded = true;
    } else {
      _error = result.msg ?? 'Load posts failed';
    }
    _safeNotify();
  }

  /// 用详情接口返回的完整帖替换列表中同 id 项（锚点滚动前合并富字段）。
  void replacePostById(int postId, FeedPost post) {
    final i = _posts.indexWhere((p) => p.postId == postId);
    if (i < 0) return;
    final next = List<FeedPost>.from(_posts);
    next[i] = post;
    _posts = next;
    _safeNotify();
  }

  /// 点赞 / 取消点赞：乐观更新，接口失败回滚（同首页 [HomeFeedNotifier.toggleLike]）。
  Future<bool> toggleLike(int postId) async {
    if (_likeInflight.contains(postId)) return false;
    final idx = _posts.indexWhere((p) => p.postId == postId);
    if (idx < 0) return false;
    _likeInflight.add(postId);
    final original = _posts[idx];
    final optimistic = original.copyWith(
      isLiked: !original.isLiked,
      likeCount:
          (original.likeCount + (original.isLiked ? -1 : 1)).clamp(0, 1 << 30),
    );
    final next = List<FeedPost>.from(_posts);
    next[idx] = optimistic;
    _posts = next;
    _safeNotify();

    final wasLiked = original.isLiked;
    final result = wasLiked
        ? await _feedDomain.unlikePost(postId: postId)
        : await _feedDomain.likePost(postId: postId);

    if (_disposed) return false;
    _likeInflight.remove(postId);

    final i = _posts.indexWhere((p) => p.postId == postId);
    if (i < 0) {
      _safeNotify();
      return false;
    }
    if (result.status == 0 && result.data != null) {
      final list = List<FeedPost>.from(_posts);
      list[i] = list[i].copyWith(
        isLiked: result.data!.liked,
        likeCount: result.data!.likeCount,
      );
      _posts = list;
      _safeNotify();
      return true;
    }
    final rollback = List<FeedPost>.from(_posts);
    rollback[i] = original;
    _posts = rollback;
    _safeNotify();
    return false;
  }

  /// 收藏 / 取消收藏：乐观更新，接口失败回滚。
  Future<bool> toggleFavorite(int postId) async {
    if (_favoriteInflight.contains(postId)) return false;
    final idx = _posts.indexWhere((p) => p.postId == postId);
    if (idx < 0) return false;
    _favoriteInflight.add(postId);
    final original = _posts[idx];
    final delta = original.isFavorited ? -1 : 1;
    final nextCount = (original.favoriteCount + delta).clamp(0, 1 << 30);
    final optimistic = original.copyWith(
      isFavorited: !original.isFavorited,
      favoriteCount: nextCount,
    );
    final next = List<FeedPost>.from(_posts);
    next[idx] = optimistic;
    _posts = next;
    _safeNotify();

    final wasFav = original.isFavorited;
    final result = wasFav
        ? await _feedDomain.unfavoritePost(postId: postId)
        : await _feedDomain.favoritePost(postId: postId);

    if (_disposed) return false;
    _favoriteInflight.remove(postId);

    final i = _posts.indexWhere((p) => p.postId == postId);
    if (i < 0) {
      _safeNotify();
      return false;
    }
    if (result.status == 0 && result.data != null) {
      final list = List<FeedPost>.from(_posts);
      list[i] = list[i].copyWith(
        isFavorited: result.data!.favorited,
        favoriteCount: result.data!.favoriteCount,
      );
      _posts = list;
      _safeNotify();
      return true;
    }
    final rollback = List<FeedPost>.from(_posts);
    rollback[i] = original;
    _posts = rollback;
    _safeNotify();
    return false;
  }

  /// 下拉刷新：force=true 走 [load]，并把 loaded 重置为 false 让首次/再次都能拉。
  Future<void> refresh() async {
    _loaded = false;
    _nextCursor = null;
    _hasMore = false;
    await load(force: true);
  }

  /// 滚到底加载下一页；没有更多 / 已在 inflight 直接 no-op。
  Future<void> loadMore() async {
    if (_loadingMore || _loading) return;
    if (!_hasMore || _nextCursor == null || _nextCursor!.isEmpty) return;
    _loadingMore = true;
    _safeNotify();
    final result = await _profileDomain.getUserPostsFeed(
      uid: uid,
      cursor: _nextCursor,
      limit: 20,
      sort: 'new',
    );
    _loadingMore = false;
    if (result.status == 0 && result.data != null) {
      final page = result.data!;
      _posts = [..._posts, ...page.items];
      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore;
    } else {
      _error = result.msg ?? 'Load more failed';
    }
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
