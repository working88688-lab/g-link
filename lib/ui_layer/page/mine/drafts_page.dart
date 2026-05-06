import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/feed.dart';
import 'package:g_link/domain/model/feed_models.dart';
import 'package:g_link/ui_layer/notifier/drafts_notifier.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:provider/provider.dart';

/// 草稿箱列表管理页：`帖子` / `短视频` 两个 tab，右上角「管理」进入多选删除模式。
///
/// 数据来源：`GET /api/v1/drafts?type=post|video`（首屏 50 条）；删除走
/// `DELETE /api/v1/drafts/{id}`，删除成功后页面 pop 返回 `true`，提示上层
/// 个人主页强制刷新对应 tab 的 `postDraft`/`videoDraft`。
class DraftsPage extends StatefulWidget {
  const DraftsPage({super.key, this.initialTab = 0});

  /// 0 = 帖子；1 = 短视频。
  final int initialTab;

  @override
  State<DraftsPage> createState() => _DraftsPageState();
}

class _DraftsPageState extends State<DraftsPage> {
  static const Color _accent = Color(0xFFFE2C55);
  static const Color _selectionFill = Color(0xFF1AAEFF);
  static const Color _badgeBg = Color(0x99000000);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DraftsNotifier>(
      create: (ctx) =>
          DraftsNotifier(ctx.read<FeedDomain>(), initialTab: widget.initialTab)
            ..load(),
      child: Consumer<DraftsNotifier>(
        builder: (context, n, _) {
          // 用 PopScope 把「删除过任意一条」的事实带回上一页：上一页（个人主页）
          // 借此判断是否要 force reload 当前 tab，避免置顶 draft cell 显示已删的项。
          return PopScope<Object?>(
            canPop: true,
            onPopInvokedWithResult: (_, __) {},
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: _buildAppBar(context, n),
              body: SafeArea(
                top: false,
                child: Column(
                  children: [
                    _buildTabBar(n),
                    Expanded(child: _buildBody(n)),
                  ],
                ),
              ),
              bottomNavigationBar: _buildDeleteBar(context, n),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, DraftsNotifier n) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      title: Text(
        '${'mineDraftBoxBadge'.tr()} (${n.currentCount})',
        style: TextStyle(
          color: Colors.black,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 28),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        TextButton(
          onPressed: n.deleting
              ? null
              : () {
                  if (n.manageMode) {
                    n.exitManageMode();
                  } else {
                    if (n.currentList.isEmpty) return;
                    n.enterManageMode();
                  }
                },
          child: Text(
            n.manageMode ? 'mineDraftCancel'.tr() : 'mineDraftManage'.tr(),
            style: TextStyle(
              color: Colors.black,
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(DraftsNotifier n) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tab(label: 'mineDraftTabPost'.tr(), index: 0, n: n),
          SizedBox(width: 24.w),
          _tab(label: 'mineDraftTabVideo'.tr(), index: 1, n: n),
        ],
      ),
    );
  }

  Widget _tab({
    required String label,
    required int index,
    required DraftsNotifier n,
  }) {
    final selected = n.tabIndex == index;
    return InkWell(
      onTap: () => n.changeTab(index),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : const Color(0xFF8C95A4),
                fontSize: selected ? 16.sp : 14.sp,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            SizedBox(height: 4.w),
            Container(
              width: 18.w,
              height: 3.w,
              decoration: BoxDecoration(
                color: selected ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(DraftsNotifier n) {
    if (n.currentLoading && n.currentList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (n.currentList.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.w),
          child: Text(
            'mineDraftEmpty'.tr(),
            style:
                TextStyle(color: const Color(0xFF8C95A4), fontSize: 13.sp),
          ),
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(2.w, 2.w, 2.w, 12.w),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.74,
      ),
      itemCount: n.currentList.length,
      itemBuilder: (_, i) {
        final draft = n.currentList[i];
        return _draftCell(context, n, draft);
      },
    );
  }

  Widget _draftCell(BuildContext context, DraftsNotifier n, DraftItem draft) {
    final selected = n.isSelected(draft.draftId);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (n.manageMode) {
          n.toggleSelected(draft.draftId);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (draft.coverUrl.isNotEmpty)
            MyImage.network(draft.coverUrl,
                fit: BoxFit.cover, placeHolder: null)
          else
            Container(color: const Color(0xFFE5E7ED)),
          Positioned(
            left: 5.w,
            top: 5.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.w),
              decoration: BoxDecoration(
                color: _badgeBg,
                borderRadius: BorderRadius.circular(3.w),
              ),
              child: Text(
                _formatUpdatedAt(draft.updatedAt),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (n.manageMode)
            Positioned(
              right: 6.w,
              top: 6.w,
              child: _selectionDot(selected),
            ),
        ],
      ),
    );
  }

  Widget _selectionDot(bool selected) {
    final size = 20.w;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? _selectionFill : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? _selectionFill : Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: selected
          ? Icon(Icons.check, color: Colors.white, size: 14.w)
          : null,
    );
  }

  Widget? _buildDeleteBar(BuildContext context, DraftsNotifier n) {
    if (!n.manageMode) return null;
    final hasSelection = n.selectedIds.isNotEmpty;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 8.w, 20.w, 12.w),
        child: SizedBox(
          width: double.infinity,
          height: 48.w,
          child: FilledButton(
            onPressed: (!hasSelection || n.deleting)
                ? null
                : () => _confirmAndDelete(context, n),
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _accent.withValues(alpha: 0.5),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: n.deleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    hasSelection
                        ? '${'mineDraftDelete'.tr()}(${n.selectedIds.length})'
                        : 'mineDraftDelete'.tr(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(
      BuildContext context, DraftsNotifier n) async {
    // 提前抓 messenger，避免在 await 之后再用 BuildContext 触发 lint。
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('mineDraftDeleteConfirmTitle'.tr()),
        content: Text(
          'mineDraftDeleteConfirmContent'
              .tr(args: ['${n.selectedIds.length}']),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('mineDraftCancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: _accent),
            child: Text('mineDraftDelete'.tr()),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await n.deleteSelected();
    if (!mounted) return;
    if (res.failed > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'mineDraftDeletePartial'.tr(
              args: ['${res.deleted}', '${res.failed}'],
            ),
          ),
        ),
      );
    } else if (res.deleted > 0) {
      messenger.showSnackBar(
        SnackBar(content: Text('mineDraftDeleteSuccess'.tr())),
      );
    }
  }

  /// `2026-04-18T10:25:00+00:00` → `4月18日`；解析失败时退化为原字符串。
  String _formatUpdatedAt(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw;
    return '${dt.month}月${dt.day}日';
  }
}
