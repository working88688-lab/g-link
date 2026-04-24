import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'chat_page.dart';
import '../widgets/overlay_menu_button.dart';

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
  final _openIdNotifier = ValueNotifier<String?>(null);

  static const _menuItems = [
    OverlayMenuItem(value: 'search', icon: 'icon_search2', label: '搜索用户'),
  ];

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
      readStatus: ReadStatus.sent,
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
    _openIdNotifier.dispose();
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
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
          OverlayMenuButton(items: _menuItems),
        ],
      ),
    );
  }

  // ── 搜索栏 ──────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 12.w, bottom: 5.w),
      child: Container(
        height: 46.w,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FE),
          borderRadius: BorderRadius.circular(46.r),
        ),
        child: TextField(
          controller: _searchCtrl,
          style: TextStyle(fontSize: 15.sp, color: Colors.black),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 11.w),
            prefixIcon: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset("./assets/images/icon_search.png",
                    width: 24.w, height: 24.w)
              ],
            ),
            hintText: '搜索联系人或聊天记录',
            hintStyle: TextStyle(
              fontSize: 15.sp,
              color: const Color(0xFF90A1B9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 32.w,
          ),
          Image.asset("./assets/images/empty_message.png", height: 95.w),
          SizedBox(
            height: 1.w,
          ),
          Text(
            "暂无消息",
            style: TextStyle(fontSize: 14.sp, color: Colors.black),
          ),
          SizedBox(
            height: 32.w,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "为你推荐",
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1F2C)),
              ),
              Spacer(),
              Text(
                "关闭",
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF62748E)),
              ),
            ],
          ),
          SizedBox(
            height: 15.w,
          ),
          for (int i = 0; i < 10; i++)
            Container(
              margin: EdgeInsets.only(bottom: 20.w),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40.r),
                      color: const Color(0xFFD1D1D6),
                    ),
                    child: Icon(Icons.person, size: 28.sp, color: Colors.white),
                  ),
                  SizedBox(
                    width: 12.w,
                  ),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Sarah Jenks",
                        style: TextStyle(
                            color: Color(0xFF0F172B),
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "5.4w粉丝",
                        style: TextStyle(
                            color: Color(0xFF62748E),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400),
                      )
                    ],
                  )),
                  GestureDetector(
                    child: Container(
                      height: 33.5.w,
                      width: 60.w,
                      decoration: BoxDecoration(
                        color: i % 2 == 0 ? const Color(0xFF1A1F2C) : null,
                        border: i % 2 == 0
                            ? null
                            : Border.all(
                                color: const Color(0xFFCCCCCC), width: 1.w),
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        i % 2 == 0 ? "已关注" : "关注",
                        style: TextStyle(
                          color: i % 2 == 0
                              ? const Color(0xFFF8F9FE)
                              : const Color(0xFF1A1F2C),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }

  // ── 列表 ────────────────────────────────
  Widget _buildList() {
    // return _buildEmpty();
    return ListView.builder(
      padding: EdgeInsets.only(top: 8.w),
      itemCount: _items.length,
      itemBuilder: (ctx, i) => _SwipeableTile(
        key: ValueKey(_items[i].id),
        item: _items[i],
        openIdNotifier: _openIdNotifier,
        onInteract: () {},
        onTap: () => Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => ChatPage(
              name: _items[i].name,
              avatarUrl: _items[i].avatarUrl,
              isOnline: _items[i].isOnline,
            ),
          ),
        ),
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
  final ValueNotifier<String?> openIdNotifier;
  final VoidCallback onInteract;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onMute;
  final VoidCallback onDelete;

  const _SwipeableTile({
    super.key,
    required this.item,
    required this.openIdNotifier,
    required this.onInteract,
    required this.onTap,
    required this.onPin,
    required this.onMute,
    required this.onDelete,
  });

  @override
  State<_SwipeableTile> createState() => _SwipeableTileState();
}

class _SwipeableTileState extends State<_SwipeableTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _dragOffset = 0;

  // 运行时根据 ScreenUtil 计算三个按钮的实际总宽
  double get _actionWidth => 60.w * 3;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    widget.openIdNotifier.addListener(_onOpenIdChanged);
  }

  void _onOpenIdChanged() {
    if (widget.openIdNotifier.value != widget.item.id) {
      _ctrl.animateTo(0.0);
    }
  }

  @override
  void dispose() {
    widget.openIdNotifier.removeListener(_onOpenIdChanged);
    _ctrl.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails d) {
    _dragOffset = _ctrl.value * _actionWidth;
    widget.onInteract();
    // 通知其他 tile 收起
    widget.openIdNotifier.value = widget.item.id;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    _dragOffset = (_dragOffset - d.primaryDelta!).clamp(0.0, _actionWidth);
    _ctrl.value = _dragOffset / _actionWidth;
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
                  textColor: const Color(0xFFFFFFFF),
                  color: const Color(0xFFF5A623),
                  onTap: () {
                    _close();
                    widget.onPin();
                  },
                ),
                _ActionBtn(
                  label: '静音',
                  textColor: const Color(0xFF1A1F2C),
                  color: const Color(0xFFD1D1D6),
                  onTap: () {
                    _close();
                    widget.onMute();
                  },
                ),
                _ActionBtn(
                  label: '删除',
                  textColor: const Color(0xFFFFFFFF),
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
            animation: _ctrl,
            builder: (_, child) => Transform.translate(
              offset: Offset(-_ctrl.value * _actionWidth, 0),
              child: child,
            ),
            child: GestureDetector(
              onTap: () {
                if (_ctrl.value > 0) {
                  _close();
                } else {
                  widget.onTap();
                }
              },
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
  final Color textColor;

  const _ActionBtn(
      {required this.label,
      required this.color,
      required this.onTap,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60.w,
        color: color,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 10.sp,
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
      padding: EdgeInsets.only(left: 8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatar(),
          SizedBox(width: 17.w),
          Expanded(
              child: Container(
            padding: EdgeInsets.only(
              top: 16.w,
              bottom: 16.w,
            ),
            decoration: BoxDecoration(
              border: Border(
                  bottom:
                      BorderSide(color: const Color(0xFFF8F9FE), width: 1.w)),
            ),
            child: Row(
              children: [
                Expanded(child: _buildContent()),
                SizedBox(width: 9.w),
                _buildTrailing(),
                SizedBox(
                  width: 16.w,
                )
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ── 头像 + 在线点 ──────────────────────
  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: const Color(0xFFD1D1D6),
          ),
          child: item.avatarUrl.isEmpty
              ? Icon(Icons.person, size: 28.sp, color: Colors.white)
              : null,
        ),
        if (item.isOnline)
          Positioned(
            bottom: 0.w,
            right: 0.w,
            child: Container(
              width: 9.w,
              height: 9.w,
              decoration: BoxDecoration(
                color: const Color(0xFF00C67E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.w),
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
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2024),
              ),
            ),
            if (item.isMuted) ...[
              SizedBox(width: 4.w),
              Image.asset("./assets/images/icon_volume_off.png",
                  width: 16.w, height: 16.w),
            ],
          ],
        ),
        SizedBox(height: 4.w),
        Text(
          item.lastMsg,
          style: TextStyle(
            fontSize: 12.sp,
            color: const Color(0xFF71727A),
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
            if (item.readStatus == ReadStatus.sent ||
                item.readStatus == ReadStatus.delivered)
              Image.asset(
                  "./assets/images/${(item.readStatus == ReadStatus.sent ? "icon_check" : "icon_done_all")}.png",
                  width: 14.w,
                  height: 14.w),
            SizedBox(width: 2.w),
            Container(
              width: 40.w,
              alignment: Alignment.center,
              child: Text(
                item.time,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF8E8E93),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.w),
        // 未读徽章
        if (item.unreadCount > 0)
          Container(
              width: 40.w,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    constraints: BoxConstraints(minWidth: 18.w),
                    height: 18.w,
                    decoration: BoxDecoration(
                      color: item.isMuted
                          ? const Color(0xFF90A1B9)
                          : const Color(0xFFFF2056),
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.unreadCount > 99 ? '99+' : '${item.unreadCount}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )),
      ],
    );
  }
}
