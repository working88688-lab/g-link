
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart' as models;
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:provider/provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _tabIndex = 0;

  static const _tabs = ['系统通知', '互动通知', '新增粉丝'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _buildTabContent(key: ValueKey(_tabIndex)),
            ),
          ),
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
        '通知',
        style: TextStyle(
          color: const Color(0xFF1D293D),
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: _markAllRead,
          child: Text(
            '全部已读',
            style: TextStyle(
              color: const Color(0xFF45556C),
              fontSize: 14.sp,
            ),
          ),
        ),
        SizedBox(width: 6.w),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFEDF0F5)),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 18.w, 16.w, 10.w),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final selected = index == _tabIndex;
          return Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = index),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 30.w,
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF1A1F2C) : const Color(0xFFF8F9FE),
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      _tabs[index],
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF38475B),
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      right: -8.w,
                      top: -7.w,
                      child: Container(
                        width: 18.w,
                        height: 18.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF2056),
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.5)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '9',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent({Key? key}) {
    return IndexedStack(
      index: _tabIndex,
      children: const [
        _SystemNotificationList(key: PageStorageKey('notification-system')),
        _InteractionNotificationList(key: PageStorageKey('notification-interaction')),
        _FanNotificationList(key: PageStorageKey('notification-follower')),
      ],
    );
  }

  Future<void> _markAllRead() async {
    await context.read<ProfileDomain>().markAllNotificationsRead();
  }
}

class _NotificationsPagedList extends StatefulWidget {
  const _NotificationsPagedList({
    required this.category,
    required this.itemBuilder,
    super.key,
  });

  final String category;
  final Widget Function(BuildContext context, models.NotificationItem item) itemBuilder;

  @override
  State<_NotificationsPagedList> createState() => _NotificationsPagedListState();
}

class _NotificationsPagedListState extends State<_NotificationsPagedList>
    with AutomaticKeepAliveClientMixin {
  static const int _pageSize = 20;

  final List<models.NotificationItem> _items = [];
  final ScrollController _controller = ScrollController();

  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _cursor;
  Object? _error;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadFirstPage();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _onScroll() {
    if (!_controller.hasClients || _loading || _loadingMore || !_hasMore) return;
    final position = _controller.position;
    if (position.maxScrollExtent - position.pixels <= 240) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _cursor = null;
      _hasMore = true;
      _items.clear();
    });
    try {
      final result = await context.read<ProfileDomain>().getNotifications(
            category: widget.category,
            limit: _pageSize,
          );
      if (!mounted) return;
      final nextPage = result.data;
      final pageItems = nextPage?.items ?? const [];
      setState(() {
        _items.addAll(pageItems);
        _cursor = nextPage?.nextCursor ?? _nextCursor(pageItems);
        _hasMore = nextPage?.hasMore ?? pageItems.length >= _pageSize;
        _initialized = true;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err;
        _initialized = true;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = await context.read<ProfileDomain>().getNotifications(
            category: widget.category,
            cursor: _cursor,
            limit: _pageSize,
          );
      if (!mounted) return;
      final nextPage = result.data;
      final nextItems = nextPage?.items ?? const [];
      if (nextItems.isEmpty) {
        setState(() => _hasMore = false);
      } else {
        setState(() {
          _items.addAll(nextItems);
          _cursor = nextPage?.nextCursor ?? _nextCursor(nextItems);
          _hasMore = nextPage?.hasMore ?? nextItems.length >= _pageSize;
        });
      }
    } catch (err) {
      if (!mounted) return;
      setState(() => _error = err);
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  String? _nextCursor(List<models.NotificationItem> items) {
    if (items.isEmpty) return null;
    return items.last.id.toString();
  }

  Future<void> _refresh() => _loadFirstPage();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_initialized && _loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return _EmptyState(
        message: '加载失败，请下拉重试',
        onRetry: _loadFirstPage,
      );
    }

    if (_initialized && _items.isEmpty) {
      return _EmptyState(
        message: '暂无通知',
        onRetry: _loadFirstPage,
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: const Color(0xFF1A1F2C),
      child: ListView.separated(
        key: widget.key,
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(8.w, 5.w, 8.w, 16.w),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.w),
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return widget.itemBuilder(context, _items[index]);
        },
        separatorBuilder: (_, __) => Container(
          height: 1.w,
          margin: EdgeInsets.only(left: 72.w),
          color: const Color(0xFFF8F9FE),
        ),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
      ),
    );
  }
}

class _SystemNotificationList extends StatelessWidget {
  const _SystemNotificationList({super.key});

  @override
  Widget build(BuildContext context) {
    return _NotificationsPagedList(
      category: 'system',
      itemBuilder: (context, item) => _SystemNotificationTile(item: item),
    );
  }
}

class _InteractionNotificationList extends StatelessWidget {
  const _InteractionNotificationList({super.key});

  @override
  Widget build(BuildContext context) {
    return _NotificationsPagedList(
      category: 'interaction',
      itemBuilder: (context, item) => _InteractionNotificationTile(item: item),
    );
  }
}

class _FanNotificationList extends StatelessWidget {
  const _FanNotificationList({super.key});

  @override
  Widget build(BuildContext context) {
    return _NotificationsPagedList(
      category: 'follower',
      itemBuilder: (context, item) => _FanNotificationTile(item: item),
    );
  }
}

class _SystemNotificationTile extends StatelessWidget {
  const _SystemNotificationTile({required this.item});

  final models.NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        SystemNotificationDetailRoute(title: item.detailContent ?? item.desc).push(context);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (item.unread)
                  Padding(
                    padding: EdgeInsets.only(right: 7.w),
                    child: Container(
                      width: 9.w,
                      height: 9.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2056),
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.w)),
                      ),
                    ),
                  )
                else
                  SizedBox(width: 16.w),
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBFD0FF).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(Icons.notifications_active_rounded, color: const Color(0xFFBFD0FF).withValues(alpha: 0.95), size: 28.w),
                ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(color: const Color(0xFF1A1F2C), fontSize: 14.sp, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        item.time,
                        style: TextStyle(
                          color: const Color(0xFF71727A),
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.w),
                  Text(
                    item.desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF71727A),
                      fontSize: 12.sp,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractionNotificationTile extends StatelessWidget {
  const _InteractionNotificationTile({required this.item});

  final models.NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, top: 8.w, right: 6.w, bottom: 8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAB67B).withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(Icons.person, color: const Color(0xFFEAB67B), size: 24.w),
              ),
              Positioned(
                right: -5.w,
                bottom: 0.w,
                child: MyImage.asset(
                  _interactionIcon(item),
                  width: 17.w,
                ),
              )
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${item.title}  ',
                                  style: TextStyle(
                                      color: const Color(0xFF1A1F2C), fontSize: 14.sp, fontWeight: FontWeight.w600),
                                ),
                                TextSpan(
                                  text: ' ${item.desc}',
                                  style: TextStyle(
                                      color: const Color(0xFF314158), fontSize: 12.sp, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          if ((item.detailContent ?? '').isNotEmpty) ...[
                            SizedBox(height: 4.w),
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                item.detailContent ?? item.desc,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFF314158),
                                  fontSize: 12.sp,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: 4.w),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.time,
                                style: TextStyle(
                                  color: const Color(0xFF314158),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    SizedBox(width: 11.w),
                    const _ThumbPreview(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _interactionIcon(models.NotificationItem item) {
    final category = item.category.toLowerCase();
    if (category.contains('comment') || category.contains('reply')) {
      return MyImagePaths.iconNoticeComment;
    }
    if (category.contains('mention')) {
      return MyImagePaths.iconNoticeMention;
    }
    return MyImagePaths.iconNoticeLike;
  }
}

class _FanNotificationTile extends StatelessWidget {
  const _FanNotificationTile({required this.item});

  final models.NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            color: const Color(0xFFF0E7D8),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(Icons.person, color: const Color(0xFFC2B091), size: 28.w),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: const Color(0xFF0F172B),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '关注了你',
                    style: TextStyle(color: const Color(0xFF314158), fontSize: 12.sp, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Text(
                item.time,
                style: TextStyle(
                  color: const Color(0xFF62748E),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 10.w),
        _FollowButton(selected: item.unread, label: item.unread ? '回关' : '已互关'),
      ],
    );
  }
}

class _ThumbPreview extends StatelessWidget {
  const _ThumbPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58.w,
      height: 76.w,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Container(color: const Color(0xFFB8B8B8)),
          ),
          Container(
            width: 22.w,
            height: 22.w,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16.w),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.w),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFF2056) : const Color(0xFF0F172B),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFFF8F9FE),
          fontSize: 10.sp,
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.selected, required this.label});

  final bool selected;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60.w,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 7.w),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1A1F2C) : Colors.transparent,
        borderRadius: BorderRadius.circular(999.r),
        border: !selected ? Border.all(color: const Color(0xFFCCCCCC)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF1A1F2C),
          fontSize: 13.sp,
          height: 0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: TextStyle(color: const Color(0xFF62748E), fontSize: 14.sp),
          ),
          SizedBox(height: 12.w),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
