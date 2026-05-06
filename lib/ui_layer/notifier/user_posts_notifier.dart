import 'package:flutter/foundation.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/feed_models.dart';

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
  }) : _profileDomain = profileDomain;

  final int uid;
  final ProfileDomain _profileDomain;

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
