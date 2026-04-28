import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';

import '../../image_paths.dart';
import '../../widgets/app_confirm_dialog.dart';

// ──────────────────────────────────────────
// 数据模型（UI 骨架）
// ──────────────────────────────────────────
class _CacheItem {
  final String id;
  final String title;
  final String author;
  final String size;
  final String duration;
  final String coverUrl;

  const _CacheItem({
    required this.id,
    required this.title,
    required this.author,
    required this.size,
    required this.duration,
    required this.coverUrl,
  });
}

// ──────────────────────────────────────────
// 页面
// ──────────────────────────────────────────
class OfflineCachePage extends StatefulWidget {
  const OfflineCachePage({super.key});

  @override
  State<OfflineCachePage> createState() => _OfflineCachePageState();
}

class _OfflineCachePageState extends State<OfflineCachePage> {
  final _items = List.generate(
    4,
    (i) => _CacheItem(
      id: '$i',
      title: '标题你那么帅标题你那么帅标题你那么帅标题你那么帅',
      author: 'Haley James',
      size: '32.3M',
      duration: '09:23',
      coverUrl: '',
    ),
  );

  static const String _totalSize = '232.2M';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: _items.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding:
                        EdgeInsets.symmetric(vertical: 6.w, horizontal: 6.w),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => SizedBox(
                      height: 6.w,
                    ),
                    itemBuilder: (_, i) => _CacheItemTile(
                      item: _items[i],
                      onDelete: () => _removeItem(_items[i].id),
                    ),
                  ),
          ),
          if (_items.isNotEmpty) _buildFooter(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20.w,
          color: const Color(0xFF1D293D),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'mineDrawerOfflineCache'.tr(),
        style: TextStyle(
          color: const Color(0xFF1D293D),
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: _clearAll,
          child: Text(
            'historyClear'.tr(),
            style: TextStyle(
              color: const Color(0xFF45556C),
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        'messageEmpty'.tr(),
        style: TextStyle(color: const Color(0xFF8C95A4), fontSize: 14.sp),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'offlineCacheTotalSize'.tr(namedArgs: {'size': _totalSize}),
            style: TextStyle(
              color: const Color(0xFF314158),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  void _removeItem(String id) {
    setState(() => _items.removeWhere((e) => e.id == id));
  }

  void _clearAll() {
    AppConfirmDialog.show(
      context: context,
      title: '全部清空？',
      content: '清空后，所有的帖子和短视频离线缓存将全部消失',
      onConfirm: () {
        /* 执行操作 */
      },
    );
  }
}

// ──────────────────────────────────────────
// 缓存列表项
// ──────────────────────────────────────────
class _CacheItemTile extends StatelessWidget {
  const _CacheItemTile({required this.item, required this.onDelete});

  final _CacheItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          // 封面
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6.w),
                child: item.coverUrl.isNotEmpty
                    ? MyImage.network(
                        item.coverUrl,
                        width: 120.w,
                        height: 119.w,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 120.w,
                        height: 119.w,
                        color: const Color(0xFFD9D9D9),
                      ),
              ),
              // 时长
              Positioned(
                right: 4.w,
                bottom: 4.w,
                child: Container(
                  padding: EdgeInsets.only(
                      left: 2.w, top: 3.w, right: 4.w, bottom: 3.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Row(
                    children: [
                      MyImage.asset(
                        MyImagePaths.iconPlay,
                        width: 14.w,
                      ),
                      SizedBox(
                        width: 1.w,
                      ),
                      Text(
                        item.duration,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 9.w),
          // 信息
          Expanded(
            child: Container(
              height: 119.w,
              padding: EdgeInsets.symmetric(vertical: 8.w, horizontal: 7.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.title,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF1A1F2C),
                      fontSize: 12.sp,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 24.w,
                        height: 24.w,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(24.w),
                        ),
                      ),
                      SizedBox(
                        width: 6.w,
                      ),
                      Text(
                        item.author,
                        style: TextStyle(
                          color: const Color(0xFF45556C),
                          fontSize: 12.sp,
                        ),
                      ),
                      Spacer(),
                      Text(
                        item.size,
                        style: TextStyle(
                          color: const Color(0xFF45556C),
                          fontSize: 12.sp,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
