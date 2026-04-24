import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../image_paths.dart';
import '../../widgets/my_image.dart';
import '../../widgets/overlay_menu_button.dart';
import 'search/search_page.dart';

// ──────────────────────────────────────────
// 数据模型
// ──────────────────────────────────────────
enum MsgType { text, image, video }

class _ChatMsg {
  final String id;
  final String content;
  final MsgType type;
  final bool isMine;
  final String time;
  final bool isRead;

  // 仅 video 使用
  final String? duration;

  const _ChatMsg({
    required this.id,
    required this.content,
    required this.type,
    required this.isMine,
    required this.time,
    this.isRead = true,
    this.duration,
  });
}

// ──────────────────────────────────────────
// 页面
// ──────────────────────────────────────────
class ChatPage extends StatefulWidget {
  final String name;
  final String avatarUrl;
  final bool isOnline;

  const ChatPage({
    super.key,
    required this.name,
    this.avatarUrl = '',
    this.isOnline = false,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  bool _showPanel = false;

  final List<_ChatMsg> _msgs = [
    const _ChatMsg(
        id: '1',
        content: '3月12日 12:23',
        type: MsgType.text,
        isMine: false,
        time: '',
        isRead: false),
    const _ChatMsg(
        id: '2',
        content: 'nni你好啊，在吗，你在哪啊',
        type: MsgType.text,
        isMine: false,
        time: '12:23'),
    const _ChatMsg(
        id: '3',
        content: "It's going well. Thanks for asking!",
        type: MsgType.text,
        isMine: true,
        time: '12:24'),
    const _ChatMsg(
        id: '4',
        content: 'nni你好啊，在吗，你在哪啊',
        type: MsgType.text,
        isMine: false,
        time: '12:25'),
    const _ChatMsg(
        id: '5',
        content: '我在云南大理',
        type: MsgType.text,
        isMine: true,
        time: '12:26'),
    const _ChatMsg(
        id: '6',
        content: '',
        type: MsgType.image,
        isMine: false,
        time: '12:27'),
    const _ChatMsg(
        id: '7',
        content: '',
        type: MsgType.video,
        isMine: false,
        time: '12:28',
        duration: '09:23'),
    const _ChatMsg(
        id: '8',
        content: '你真太帅气了',
        type: MsgType.text,
        isMine: true,
        time: '12:29'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showPanel) {
        setState(() => _showPanel = false);
      }
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _msgs.add(_ChatMsg(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        type: MsgType.text,
        isMine: true,
        time: _formatTime(DateTime.now()),
      ));
      _inputCtrl.clear();
      _hasText = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildMsgList()),
            _buildInputBar(),
            _buildMorePanel(),
          ],
        ),
      ),
    );
  }

  // ── 顶部栏 ───────────────────────────────
  Widget _buildTopBar() {
    return Container(
      height: 56.w,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
            offset: const Offset(0, 1),
            blurRadius: 2,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
            offset: const Offset(0, 1),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.chevron_left,
                size: 28.sp, color: const Color(0xFF0F172B)),
          ),
          SizedBox(width: 8.w),
          _buildAvatar(size: 26.w),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              widget.name,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172B),
              ),
            ),
          ),
          // Icon(Icons.more_horiz, size: 24.sp, color: const Color(0xFF0F172B)),
          OverlayMenuButton(
            items: [
              OverlayMenuItem(
                  value: 'search',
                  icon: MyImagePaths.iconChatSearch,
                  label: '搜索',
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => const ChatSearchPage(
                              mode: SearchMode.chatRecords),
                        ),
                      )),
              const OverlayMenuItem(
                  value: 'unpin',
                  icon: MyImagePaths.iconChatUnpin,
                  label: '取消置顶'),
              const OverlayMenuItem(
                  value: 'unmute',
                  icon: MyImagePaths.iconChatUnmute,
                  label: '取消静音'),
              const OverlayMenuItem(
                  value: 'clear',
                  icon: MyImagePaths.iconChatClearRecord,
                  label: '清空聊天'),
              const OverlayMenuItem(
                  value: 'report',
                  icon: MyImagePaths.iconChatReport,
                  label: '投诉',
                  color: Color(0xFFFF2056)),
            ],
            child: MyImage.asset(
              MyImagePaths.iconChatMore,
              width: 24.w,
              height: 24.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({required double size}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size),
            color: const Color(0xFFD1D1D6),
          ),
          child: widget.avatarUrl.isEmpty
              ? Icon(Icons.person, size: size * 0.7, color: Colors.white)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(size * 0.4),
                  child: Image.network(widget.avatarUrl, fit: BoxFit.cover),
                ),
        ),
      ],
    );
  }

  // ── 消息列表 ─────────────────────────────
  Widget _buildMsgList() {
    return NotificationListener<ScrollStartNotification>(
      onNotification: (n) {
        if (n.dragDetails == null) return false; // 代码触发的滚动不处理
        FocusScope.of(context).unfocus();
        if (_showPanel) setState(() => _showPanel = false);
        return false;
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          if (_showPanel) setState(() => _showPanel = false);
        },
        child: ListView.builder(
          controller: _scrollCtrl,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.w),
          itemCount: _msgs.length,
          itemBuilder: (ctx, i) {
            final msg = _msgs[i];
            // 时间分割线（isMine=false && time 为空，用 content 当作时间标签）
            if (!msg.isMine && msg.time.isEmpty) {
              return _buildDateDivider(msg.content);
            }
            return _buildBubble(msg);
          },
        ),
      ),
    );
  }

  Widget _buildDateDivider(String label) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.w),
      child: Center(
        child: Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: const Color(0xFFAAAAAA)),
        ),
      ),
    );
  }

  Widget _buildBubble(_ChatMsg msg) {
    return Padding(
      padding: EdgeInsets.only(bottom: 18.w),
      child: Row(
        mainAxisAlignment:
            msg.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: msg.isMine
            ? [
                // _buildTimeLabel(msg),
                // SizedBox(width: 8.w),
                _buildBubbleContent(msg),
              ]
            : [
                // _buildAvatar(size: 36.w),
                // SizedBox(width: 8.w),
                _buildBubbleContent(msg),
                // SizedBox(width: 8.w),
                // _buildTimeLabel(msg),
              ],
      ),
    );
  }

  Widget _buildTimeLabel(_ChatMsg msg) {
    if (msg.time.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (msg.isMine && msg.isRead)
          Icon(Icons.done_all, size: 14.sp, color: const Color(0xFF00C67E)),
        SizedBox(height: 2.w),
        Text(
          msg.time,
          style: TextStyle(fontSize: 11.sp, color: const Color(0xFFAAAAAA)),
        ),
      ],
    );
  }

  Widget _buildBubbleContent(_ChatMsg msg) {
    switch (msg.type) {
      case MsgType.text:
        return _TextBubble(text: msg.content, isMine: msg.isMine);
      case MsgType.image:
        return _ImageBubble(isMine: msg.isMine);
      case MsgType.video:
        return _VideoBubble(duration: msg.duration ?? '', isMine: msg.isMine);
    }
  }

  // ── 底部输入栏 ───────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: const Color(0xFFF0F7E2), width: 1.w)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            offset: const Offset(0, -4),
            blurRadius: 20,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Row(
        children: [
          // 麦克风
          GestureDetector(
            onTap: () {},
            child:
                MyImage.asset(MyImagePaths.iconMic, width: 24.w, height: 24.w),
          ),
          SizedBox(width: 12.w),
          // 输入框
          Expanded(
            child: Container(
              height: 46.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FE),
                borderRadius: BorderRadius.circular(46.r),
                border:
                    Border.all(color: const Color(0xFFE3E7ED), width: 0.84.w),
              ),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _focusNode,
                style:
                    TextStyle(fontSize: 12.sp, color: const Color(0xFF0F172B)),
                onChanged: (v) =>
                    setState(() => _hasText = v.trim().isNotEmpty),
                onSubmitted: (_) {
                  _sendMessage();
                  _focusNode.requestFocus();
                },
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 15.w, vertical: 13.w),
                  hintText: '发消息',
                  hintStyle: TextStyle(
                      fontSize: 12.sp, color: const Color(0xFF90A1B9)),
                  suffixIcon: GestureDetector(
                    onTap: () {},
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: MyImage.asset(
                        MyImagePaths.iconEmoji,
                        width: 24.w,
                        height: 24.w,
                      ),
                    ),
                  ),
                  suffixIconConstraints:
                      BoxConstraints(minWidth: 0, minHeight: 0),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // 加号 / 发送
          GestureDetector(
            onTap: _hasText
                ? _sendMessage
                : () {
                    FocusScope.of(context).unfocus();
                    setState(() => _showPanel = !_showPanel);
                    if (!_showPanel) return;
                    // 等面板展开动画完成后再滚到底（maxScrollExtent 已更新）
                    Future.delayed(const Duration(milliseconds: 260), () {
                      if (_scrollCtrl.hasClients) {
                        _scrollCtrl.animateTo(
                          _scrollCtrl.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  },
            child: _hasText
                ? Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172B),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.send_rounded,
                        size: 18.sp, color: Colors.white),
                  )
                : Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFFD1D1D6), width: 1.5.w),
                      shape: BoxShape.circle,
                    ),
                    child: MyImage.asset(MyImagePaths.iconChatPlus,
                        width: 22.w, height: 22.w)),
          ),
        ],
      ),
    );
  }

  // ── 更多面板 ─────────────────────────────
  Widget _buildMorePanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      height: _showPanel ? 103.w : 0,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: SizedBox(
          height: 103.w,
          child: Container(
            color: const Color(0xFFF8F9FE),
            padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 15.w),
            child: GridView.count(
              crossAxisCount: 5,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 25.w,
              mainAxisSpacing: 25.w,
              childAspectRatio: 46 / 67,
              children: [
                _PanelItem(icon: MyImagePaths.iconChatAlbum, label: '相册'),
                _PanelItem(icon: MyImagePaths.iconChatCamera, label: '拍摄'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// 更多面板 item
// ──────────────────────────────────────────
class _PanelItem extends StatelessWidget {
  final String icon;
  final String label;

  const _PanelItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46.w,
          height: 46.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Align(
            child: MyImage.asset(icon, width: 24.w, height: 24.w),
          ),
        ),
        Spacer(),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: const Color(0xFF000000)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────
// 气泡组件
// ──────────────────────────────────────────
class _TextBubble extends StatelessWidget {
  final String text;
  final bool isMine;

  const _TextBubble({required this.text, required this.isMine});

  @override
  Widget build(BuildContext context) {
    // icon 占位宽度（图标宽 + 间距）
    final double iconPlaceholder = 14.w + 4.w;
    return Container(
      constraints: BoxConstraints(maxWidth: 240.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
      decoration: BoxDecoration(
        color: isMine ? const Color(0xFF0F172B) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
          bottomLeft: isMine ? Radius.circular(16.r) : Radius.circular(4.r),
          bottomRight: isMine ? Radius.circular(4.r) : Radius.circular(16.r),
        ),
      ),
      child: Stack(
        children: [
          // 文字末尾用透明占位撑出图标的空间
          Text(
            '$text${isMine ? " \u2003" : ""}', // 末尾两个 em-space 留位
            style: TextStyle(
              fontSize: 14.sp,
              color: isMine ? Colors.white : const Color(0xFF0F172B),
              height: 1.4,
            ),
          ),
          if (isMine)
            // 图标贴在右下角
            Positioned(
              right: 0,
              bottom: 0,
              child: MyImage.asset(
                MyImagePaths.iconDoneAll,
                width: 14.w,
                height: 14.w,
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  final bool isMine;

  const _ImageBubble({required this.isMine});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(6.r)),
      child: Container(
        width: 150.w,
        height: 200.w,
        color: const Color(0xFFD1D1D6),
        child: Icon(Icons.image_outlined, size: 48.sp, color: Colors.white),
      ),
    );
  }
}

class _VideoBubble extends StatelessWidget {
  final String duration;
  final bool isMine;

  const _VideoBubble({required this.duration, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(6.r)),
      child: Stack(
        children: [
          Container(
            width: 200.w,
            height: 150.w,
            color: const Color(0xFF2C2C2C),
          ),
          // 播放按钮
          Positioned.fill(
            child: Center(
              child: Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow_rounded,
                    size: 16.sp, color: Colors.white),
              ),
            ),
          ),
          // 时长
          Positioned(
            right: 8.w,
            bottom: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                duration,
                style: TextStyle(fontSize: 11.sp, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
