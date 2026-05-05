import 'package:flutter/foundation.dart';
import 'package:g_link/domain/domains/feed.dart';
import 'package:g_link/domain/model/feed_models.dart';

/// 草稿箱列表管理页状态：`帖子`/`短视频` 两个 tab + 编辑（多选删除）模式。
///
/// 使用流程：构造时传入 [FeedDomain] 并设置初始 tab，调用 [load] 触发首屏加载；
/// 切 tab 走 [changeTab]；进入「管理」模式走 [enterManageMode]；
/// 单选走 [toggleSelected]；点底部删除走 [deleteSelected]。
class DraftsNotifier extends ChangeNotifier {
  DraftsNotifier(this._feedDomain, {int initialTab = 0})
      : tabIndex = initialTab.clamp(0, 1);

  final FeedDomain _feedDomain;

  /// 0 = 帖子（type=post）；1 = 短视频（type=video）。
  int tabIndex;

  bool loadingPost = false;
  bool loadingVideo = false;
  bool postLoaded = false;
  bool videoLoaded = false;
  String? errorMessage;

  List<DraftItem> postDrafts = const [];
  List<DraftItem> videoDrafts = const [];

  /// 当前是否处于多选管理模式。退出时自动清空 [_selectedIds]。
  bool manageMode = false;

  /// 当前 tab 已选中的 draft id（按 tab 维度互不影响：切 tab 会清空）。
  final Set<int> _selectedIds = <int>{};
  Set<int> get selectedIds => _selectedIds;

  /// 当前 tab 是否在删除中（底部按钮 loading）。
  bool deleting = false;

  bool _disposed = false;

  bool get isPostTab => tabIndex == 0;
  String get _typeForCurrentTab => isPostTab ? 'post' : 'video';
  List<DraftItem> get currentList => isPostTab ? postDrafts : videoDrafts;
  bool get currentLoading => isPostTab ? loadingPost : loadingVideo;
  bool get currentLoaded => isPostTab ? postLoaded : videoLoaded;

  bool isSelected(int draftId) => _selectedIds.contains(draftId);

  /// 用于头部 `草稿箱 (N)` 文案：取当前 tab 已加载的条数。
  int get currentCount => currentList.length;

  Future<void> load({bool force = false}) {
    return _loadType(_typeForCurrentTab, force: force);
  }

  Future<void> _loadType(String type, {bool force = false}) async {
    final isPost = type == 'post';
    if (!force && (isPost ? postLoaded : videoLoaded)) return;
    if (isPost) {
      loadingPost = true;
    } else {
      loadingVideo = true;
    }
    errorMessage = null;
    _safeNotify();
    final result = await _feedDomain.getDrafts(type: type, limit: 50);
    if (_disposed) return;
    if (result.status == 0 && result.data != null) {
      if (isPost) {
        postDrafts = result.data!;
        postLoaded = true;
      } else {
        videoDrafts = result.data!;
        videoLoaded = true;
      }
    } else {
      errorMessage = result.msg;
    }
    if (isPost) {
      loadingPost = false;
    } else {
      loadingVideo = false;
    }
    _safeNotify();
  }

  /// 切 tab：跨 tab 多选意义不大，这里直接清空选择 + 退出管理模式。
  void changeTab(int index) {
    if (tabIndex == index) return;
    tabIndex = index.clamp(0, 1);
    _selectedIds.clear();
    manageMode = false;
    _safeNotify();
    load();
  }

  void enterManageMode() {
    if (manageMode) return;
    manageMode = true;
    _selectedIds.clear();
    _safeNotify();
  }

  void exitManageMode() {
    if (!manageMode) return;
    manageMode = false;
    _selectedIds.clear();
    _safeNotify();
  }

  void toggleSelected(int draftId) {
    if (!manageMode) return;
    if (!_selectedIds.add(draftId)) {
      _selectedIds.remove(draftId);
    }
    _safeNotify();
  }

  /// 串行调用 `DELETE /drafts/{id}` 删除多选项；任一失败仍尝试其它，
  /// 最终把已成功删除的 id 从本地列表移除并退出管理模式。
  /// 返回 `(deleted, failed)` 计数，便于上层 toast。
  Future<({int deleted, int failed})> deleteSelected() async {
    if (deleting || _selectedIds.isEmpty) {
      return (deleted: 0, failed: 0);
    }
    deleting = true;
    _safeNotify();
    final ids = List<int>.from(_selectedIds);
    var deleted = 0;
    var failed = 0;
    for (final id in ids) {
      final r = await _feedDomain.deleteDraft(draftId: id);
      if (r.status == 0) {
        deleted++;
      } else {
        failed++;
      }
    }
    if (_disposed) return (deleted: deleted, failed: failed);
    if (isPostTab) {
      postDrafts =
          postDrafts.where((d) => !_selectedIds.contains(d.draftId)).toList();
    } else {
      videoDrafts =
          videoDrafts.where((d) => !_selectedIds.contains(d.draftId)).toList();
    }
    _selectedIds.clear();
    manageMode = false;
    deleting = false;
    _safeNotify();
    return (deleted: deleted, failed: failed);
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
