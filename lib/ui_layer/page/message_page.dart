import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ──────────────────────────────────────────
// 数据模型
// ──────────────────────────────────────────
enum ReadStatus { unread, sent, delivered }

class _MsgItem {
  final String id;
  final String name;
  final String avatarUrl;
  final String lastMsg;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final bool isMuted;
  final ReadStatus readStatus;
  final bool isPinned;

  const _MsgItem({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.lastMsg,
    required this.time,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isMuted = false,
    this.readStatus = ReadStatus.unread,
    this.isPinned = false,
  });

  _MsgItem copyWith({
    bool? isMuted,
    bool? isPinned,
    int? unreadCount,
  }) =>
      _MsgItem(
        id: id,
        name: name,
        avatarUrl: avatarUrl,
        lastMsg: lastMsg,
        time: time,
        unreadCount: unreadCount ?? this.unreadCount,
        isOnline: isOnline,
        isMuted: isMuted ?? this.isMuted,
        readStatus: readStatus,
        isPinned: isPinned ?? this.isPinned,
      );
}

// ──────────────────────────────────────────
// 页面
// ──────────────────────────────────────────
class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final _searchCtrl = TextEditingController();

  final List<_MsgItem> _items = [
    const _MsgItem(
      id: '1',
      name: 'Haley James',
      avatarUrl: '',
      lastMsg: '设计稿已同步更新，请查看。',
      time: '10:23',
      unreadCount: 9,
      isOnline: true,
    ),
    const _MsgItem(
      id: '2',
      name: 'Haley James',
      avatarUrl: '',
      lastMsg: '设计稿已同步更新，请查看。设计稿已同步更新，请查看。',
      time: '10:23',
      unreadCount: 9,
      isOnline: true,
      isMuted: true,
      readStatus: ReadStatus.delivered,
    ),
    const _MsgItem(
      id: '3',
      name: 'Haley James',
      avatarUrl: '',
      lastMsg: '设计稿已同步更新，请查看。',
      time: '10:23',
      isOnline: true,
      readStatus: ReadStatus.delivered,
    ),
    const _MsgItem(
      id: '4',
      name: 'Haley James',
      avatarUrl: '',
      lastMsg: '设计稿已同步更新，请查看。请速度',
      time: '周日',
      isOnline: true,
    ),
    const _MsgItem(
      id: '5',
      name: 'Haley James',
      avatarUrl: '',
      lastMsg: '设计稿已同步更新，请查看。',
      time: '10:23',
      isOnline: true,
    ),
    const _MsgItem(
      id: '6',
      name: 'Haley James',
      avatarUrl: '',
      lastMsg: '设计稿已同步更新，请查看。',
      time: '10:23',
      isOnline: true,
    ),
  ];

  void _pin(String id) {
    setState(() {
      final idx = _items.indexWhere((e) => e.id == id);
      if (idx < 0) return;
      final item = _items[idx].copyWith(isPinned: !_items[idx].isPinned);
      _items.removeAt(idx);
      _items.insert(0, item);
    });
  }

  void _mute(String id) {
    setState(() {
      final idx = _items.indexWhere((e) => e.id == id);
      if (idx < 0) return;
      _items[idx] = _items[idx].copyWith(isMuted: !_items[idx].isMuted);
    });
  }

  void _delete(String id) {
    setState(() => _items.removeWhere((e) => e.id == id));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  // ── 顶部标题栏 ──────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
      //     box-shadow: 0px 1px 2px -1px #E2E8F080;
      //
      // box-shadow: 0px 1px 3px 0px #E2E8F080;

        boxShadow: [
            BoxShadow(
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
              offset: const Offset(0, 1),
              blurRadius: 3,
              spreadRadius: -1,
            ),
          ],
      ),
      child: Row(
        children: [
          Text(
            '消息 (${_items.fold(0, (sum, e) => sum + e.unreadCount)})',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D293D),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172B),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Icon(Icons.add, color: Colors.white, size: 22.sp),
            ),
          ),
        ],
      ),
    );
  }

  // ── 搜索栏 ──────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Container(
        height: 40.h,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: TextField(
          controller: _searchCtrl,
          style: TextStyle(fontSize: 15.sp, color: const Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 10.h),
            prefixIcon: Icon(
              Icons.search,
              color: const Color(0xFF8E8E93),
              size: 20.sp,
            ),
            hintText: '搜索联系人或聊天记录',
            hintStyle: TextStyle(
              fontSize: 15.sp,
              color: const Color(0xFF8E8E93),
            ),
          ),
        ),
      ),
    );
  }

  // ── 列表 ────────────────────────────────
  Widget _buildList() {
    return ListView.builder(
      padding: EdgeInsets.only(top: 8.h),
      itemCount: _items.length,
      itemBuilder: (ctx, i) => _SwipeableTile(
        key: ValueKey(_items[i].id),
        item: _items[i],
        onPin: () => _pin(_items[i].id),
        onMute: () => _mute(_items[i].id),
        onDelete: () => _delete(_items[i].id),
      ),
    );
  }
}

// ──────────────────────────────────────────
// 可滑动的消息行
// ──────────────────────────────────────────
class _SwipeableTile extends StatefulWidget {
  final _MsgItem item;
  final VoidCallback onPin;
  final VoidCallback onMute;
  final VoidCallback onDelete;

  const _SwipeableTile({
    super.key,
    required this.item,
    required this.onPin,
    required this.onMute,
    required this.onDelete,
  });

  @override
  State<_SwipeableTile> createState() => _SwipeableTileState();
}

class _SwipeableTileState extends State<_SwipeableTile>
    with SingleTickerProviderStateMixin {
  static const double _actionWidth = 240.0; // 三个按钮总宽（逻辑像素）
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  double _dragStart = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _anim = Tween<double>(begin: 0, end: -_actionWidth)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails d) {
    _dragStart = _ctrl.value * _actionWidth;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    final newVal =
        ((_dragStart - d.primaryDelta!) / _actionWidth).clamp(0.0, 1.0);
    _ctrl.value = newVal;
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    if (_ctrl.value > 0.3) {
      _ctrl.animateTo(1.0);
    } else {
      _ctrl.animateTo(0.0);
    }
  }

  void _close() => _ctrl.animateTo(0.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        children: [
          // ── 背景操作按钮 ──
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionBtn(
                  label: '置顶',
                  color: const Color(0xFFF5A623),
                  onTap: () {
                    _close();
                    widget.onPin();
                  },
                ),
                _ActionBtn(
                  label: '静音',
                  color: const Color(0xFFD1D1D6),
                  onTap: () {
                    _close();
                    widget.onMute();
                  },
                ),
                _ActionBtn(
                  label: '删除',
                  color: const Color(0xFFFF2D55),
                  onTap: () {
                    _close();
                    widget.onDelete();
                  },
                ),
              ],
            ),
          ),
          // ── 前景内容 ──
          AnimatedBuilder(
            animation: _anim,
            builder: (_, child) => Transform.translate(
              offset: Offset(_anim.value, 0),
              child: child,
            ),
            child: GestureDetector(
              onTap: _close,
              child: _MsgTile(item: widget.item),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// 操作按钮
// ──────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80.w,
        color: color,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// 消息行内容
// ──────────────────────────────────────────
class _MsgTile extends StatelessWidget {
  final _MsgItem item;

  const _MsgTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          SizedBox(width: 12.w),
          Expanded(child: _buildContent()),
          SizedBox(width: 8.w),
          _buildTrailing(),
        ],
      ),
    );
  }

  // ── 头像 + 在线点 ──────────────────────
  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 26.r,
          backgroundColor: const Color(0xFFD1D1D6),
          backgroundImage:
              item.avatarUrl.isNotEmpty ? NetworkImage(item.avatarUrl) : null,
          child: item.avatarUrl.isEmpty
              ? Icon(Icons.person, size: 28.sp, color: Colors.white)
              : null,
        ),
        if (item.isOnline)
          Positioned(
            bottom: 1.h,
            right: 1.w,
            child: Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: const Color(0xFF34C759),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  // ── 名称 + 消息预览 ────────────────────
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              item.name,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            if (item.isMuted) ...[
              SizedBox(width: 4.w),
              Icon(
                Icons.volume_off,
                size: 14.sp,
                color: const Color(0xFF8E8E93),
              ),
            ],
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          item.lastMsg,
          style: TextStyle(
            fontSize: 13.sp,
            color: const Color(0xFF8E8E93),
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── 时间 + 未读徽章 ────────────────────
  Widget _buildTrailing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 已读状态图标 + 时间
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.readStatus == ReadStatus.sent)
              Icon(Icons.check, size: 14.sp, color: const Color(0xFF34C759)),
            if (item.readStatus == ReadStatus.delivered)
              Icon(Icons.done_all, size: 14.sp,
                  color: const Color(0xFF34C759)),
            SizedBox(width: 2.w),
            Text(
              item.time,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        // 未读徽章
        if (item.unreadCount > 0)
          Container(
            constraints: BoxConstraints(minWidth: 20.w),
            height: 20.h,
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFF2D55),
              borderRadius: BorderRadius.circular(10.r),
            ),
            alignment: Alignment.center,
            child: Text(
              item.unreadCount > 99 ? '99+' : '${item.unreadCount}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

