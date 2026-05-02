import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/chat.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/chat_model.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../ui_layer/widgets/app_confirm_dialog.dart';
import '../../image_paths.dart';
import '../../widgets/my_image.dart';
import '../../widgets/overlay_menu_button.dart';

// ──────────────────────────────────────────
// 页面
// ──────────────────────────────────────────
class ChatPage extends StatefulWidget {
  final int uid;
  final String name;
  final String avatarUrl;

  const ChatPage({
    super.key,
    required this.uid,
    required this.name,
    required this.avatarUrl,
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
  bool _isLoadingSession = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _sessionError;
  ChatItem? _session;
  String? _nextCursor;
  final List<ChatMessageItem> _messages = [];
  int? _currentUserId;

  String? get nikeName => widget.name.isNotEmpty ? widget.name : _session?.name;

  String? get avatarUrl => _session?.avatarUrl.isNotEmpty == true ? _session!.avatarUrl : widget.avatarUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapCurrentUser();
      _loadSession();
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

  Future<void> _bootstrapCurrentUser() async {
    try {
      final profile = await context.read<ProfileDomain>().getMyProfile();
      if (!mounted) return;
      setState(() => _currentUserId = profile.data?.uid);
    } catch (_) {}
  }

  Future<void> _loadSession() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSession = true;
      _sessionError = null;
    });
    try {
      final session = await context.read<ChatDomain>().createOrGetChat(peerUid: widget.uid);
      if (!mounted) return;
      setState(() {
        _session = session;
        _isLoadingSession = false;
      });
      await _loadMessages(refresh: true);
      await context.read<ChatDomain>().markChatRead(session.chatId);
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _isLoadingSession = false;
        _sessionError = err.toString();
      });
    }
  }

  Future<void> _loadMessages({bool refresh = false}) async {
    final session = _session;
    if (session == null) return;
    if (_isLoadingMore) return;

    setState(() {
      if (refresh) {
        _messages.clear();
        _nextCursor = null;
        _hasMore = false;
      } else {
        _isLoadingMore = true;
      }
      _sessionError = null;
    });

    try {
      final result = await context.read<ChatDomain>().fetchChatMessages(
        chatId: session.chatId,
        cursor: refresh ? null : _nextCursor,
        direction: 'after',
        limit: 30,
      );
      if (!mounted) return;
      setState(() {
        _messages.addAll(result.items);
        _nextCursor = result.nextCursor;
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
      await _scrollToBottom();
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
        _sessionError = err.toString();
      });
    }
  }

  Future<void> _scrollToBottom() async {
    // await WidgetsBinding.instance.endOfFr if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.jumpTo(_scrollCtrl.position.minScrollExtent);
  }

  Future<UploadedImagePayload?> _uploadChatImage({required ImageSource source}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked == null) return null;

      final bytes = await picked.readAsBytes();
      final session = _session;
      if (session == null) return null;

      final ext = picked.name.contains('.') ? picked.name
          .split('.')
          .last : 'jpg';
      final payload = await context.read<ProfileDomain>().uploadImageByPresign(
        bytes: bytes,
        fileExt: ext,
        fileSize: bytes.length,
        scene: ImageUploadScene.chat,
      );
      return payload.data;
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendImageMessage(ImageSource source) async {
    final session = _session;
    if (session == null) return;
    final uploaded = await _uploadChatImage(source: source);
    if (uploaded == null || uploaded.downloadUrl.isEmpty) return;

    final draft = ChatMessageItem(
      id: DateTime
          .now()
          .microsecondsSinceEpoch,
      chatId: session.chatId,
      senderUid: _currentUserId ?? 0,
      msgType: ChatMessageType.image,
      content: '',
      replyToMsgId: null,
      status: 'sending',
      createdAt: _formatTime(DateTime.now()),
      mediaUrl: uploaded.downloadUrl,
      mediaMeta: const {},
      isMine: true,
    );

    setState(() {
      _messages.add(draft);
      _showPanel = false;
    });
    await _scrollToBottom();

    try {
      final resp = await context.read<ChatDomain>().sendMessage(
        chatId: session.chatId,
        msgType: ChatMessageType.image,
        mediaUrl: uploaded.downloadUrl,
        clientMsgId: draft.id.toString(),
      );
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((e) => e.id == draft.id.toString());
        if (idx >= 0 && resp.id != 0) {
          _messages[idx] = resp;
        }
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _sessionError = err.toString();
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    final session = _session;
    if (text.isEmpty || session == null) return;
    _inputCtrl.clear();
    setState(() => _hasText = false);

    try {
      final draft = ChatMessageItem(
        id: DateTime
            .now()
            .microsecondsSinceEpoch,
        chatId: session.chatId,
        senderUid: _currentUserId ?? 0,
        msgType: ChatMessageType.text,
        content: text,
        replyToMsgId: null,
        status: 'sending',
        createdAt: _formatTime(DateTime.now()),
        mediaUrl: '',
        mediaMeta: const {},
        isMine: true,
      );
      setState(() {
        _messages.add(draft);
      });
      await _scrollToBottom();
      await context.read<ChatDomain>().sendMessage(
        chatId: session.chatId,
        msgType: ChatMessageType.text,
        content: text,
        clientMsgId: draft.id.toString(),
      );
      if (!mounted) return;
      await _scrollToBottom();
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _sessionError = err.toString();
      });
    }
  }

  String _formatTime(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildBody()),
            _buildInputBar(),
            _buildMorePanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingSession || _currentUserId == null) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF00C67E),
        ),
      );
    }
    if (_sessionError != null) {
      return Center(
        child: Text(
          _sessionError!,
          style: TextStyle(fontSize: 14.sp, color: const Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),
      );
    }
    return _buildMsgList();
  }

  // ── 顶部栏 ───────────────────────────────
  Widget _buildTopBar() {
    final displayName = nikeName;
    final displayAvatar = avatarUrl;
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
            child: Icon(Icons.chevron_left, size: 28.sp, color: const Color(0xFF0F172B)),
          ),
          SizedBox(width: 8.w),
          _buildAvatar(size: 26.w, avatarUrl: displayAvatar),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              displayName ?? "",
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
                label: 'chatMenuSearch'.tr(),
                onTap: () => ChatRecordsSearchRoute(chatId: _session?.chatId ?? 0).push(context),
              ),
              if (_session?.isPinned == true)
                OverlayMenuItem(
                  value: 'unpin',
                  icon: MyImagePaths.iconChatUnpin,
                  label: 'chatActionUnpin'.tr(),
                ),
              if (_session?.isMuted == true)
                OverlayMenuItem(
                  value: 'unmute',
                  icon: MyImagePaths.iconChatUnmute,
                  label: 'chatActionUnmute'.tr(),
                ),
              OverlayMenuItem(
                value: 'clear',
                icon: MyImagePaths.iconChatClearRecord,
                label: 'chatMenuClearChat'.tr(),
                onTap: _session == null
                    ? null
                    : () {
                  AppConfirmDialog.show(
                    context: context,
                    title: 'chatMenuClearChat'.tr(),
                    content: 'chatClearConfirmContent'.tr(),
                    confirmText: 'commonConfirm'.tr(),
                    cancelText: 'commonCancel'.tr(),
                    onConfirm: () async {
                      if (_session == null) return;
                      await context.read<ChatDomain>().clearChatMessages(_session!.chatId);
                      if (!mounted) return;
                      setState(() {
                        _messages.clear();
                        _nextCursor = null;
                        _hasMore = false;
                      });
                    },
                  );
                },
              ),
              OverlayMenuItem(
                value: 'report',
                icon: MyImagePaths.iconChatReport,
                label: 'chatMenuReport'.tr(),
                color: const Color(0xFFFF2056),
                onTap: () => const ComplaintRoute().push(context),
              ),
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

  Widget _buildAvatar({required double size, String? avatarUrl}) {
    final url = avatarUrl ?? widget.avatarUrl;
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
          child: url.isEmpty
              ? Icon(Icons.person, size: size * 0.7, color: Colors.white)
              : ClipRRect(
            borderRadius: BorderRadius.circular(size),
            child: Image.network(url, fit: BoxFit.cover),
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
          reverse: true,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.w),
          itemCount: _messages.length + (_hasMore ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (_hasMore && i == _messages.length) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 14.w),
                child: Center(
                  child: _isLoadingMore
                      ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                      color: Color(0xFF00C67E),
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    '下拉加载更早消息',
                    style: TextStyle(fontSize: 12.sp, color: const Color(0xFF62748E)),
                  ),
                ),
              );
            }
            final msg = _messages[_messages.length - 1 - i];
            return _buildMessageBubble(msg);
          },
        ),
      ),
    );
  }

  Widget _buildDateDivider(String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 2.w, horizontal: 10.w),
          margin: EdgeInsets.only(bottom: 22.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FE),
            borderRadius: BorderRadius.circular(40.r),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFFAAAAAA)),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessageItem msg) {
    final isMine = msg.senderUid == (_currentUserId ?? -1);

    return _buildBubble(msg);
  }

  Widget _buildBubble(ChatMessageItem msg) {
    msg.isMine = msg.senderUid == (_currentUserId ?? -1);

    return Padding(
      padding: EdgeInsets.only(bottom: 18.w),
      child: Row(
        mainAxisAlignment: msg.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // _buildTimeLabel(msg),
          // SizedBox(width: 8.w),
          _buildBubbleContent(msg),
        ],
      ),
    );
  }

  Widget _buildTimeLabel(ChatMessageItem msg) {
    if (msg.createdAt.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // if (isMine && msg.) Icon(Icons.done_all, size: 14.sp, color: const Color(0xFF00C67E)),
        SizedBox(height: 2.w),
        Text(
          msg.createdAt,
          style: TextStyle(fontSize: 11.sp, color: const Color(0xFFAAAAAA)),
        ),
      ],
    );
  }

  Widget _buildBubbleContent(ChatMessageItem msg) {
    switch (msg.msgType) {
      case ChatMessageType.text:
        return _TextBubble(text: msg.content, isMine: msg.isMine);
      case ChatMessageType.image:
        return _ImageBubble(
          isMine: msg.isMine,
          imageUrl: msg.mediaUrl ?? "",
        );
      case ChatMessageType.video:
        return _VideoBubble(duration: '', isMine: msg.isMine);
      case ChatMessageType.unknown:
        return SizedBox.shrink();
    }
  }

  // ── 底部输入栏 ───────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFF0F7E2), width: 1.w)),
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
            child: MyImage.asset(MyImagePaths.iconMic, width: 24.w, height: 24.w),
          ),
          SizedBox(width: 12.w),
          // 输入框
          Expanded(
            child: Container(
              height: 46.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FE),
                borderRadius: BorderRadius.circular(46.r),
                border: Border.all(color: const Color(0xFFE3E7ED), width: 0.84.w),
              ),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _focusNode,
                style: TextStyle(fontSize: 12.sp, color: const Color(0xFF0F172B)),
                onChanged: (v) =>
                    setState(() =>
                    _hasText = v
                        .trim()
                        .isNotEmpty),
                onSubmitted: (_) {
                  _sendMessage();
                  _focusNode.requestFocus();
                },
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 13.w),
                  hintText: 'chatInputHint'.tr(),
                  hintStyle: TextStyle(fontSize: 12.sp, color: const Color(0xFF90A1B9)),
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
                  suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
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
                _scrollToBottom();
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
              child: Icon(Icons.send_rounded, size: 18.sp, color: Colors.white),
            )
                : Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD1D1D6), width: 1.5.w),
                  shape: BoxShape.circle,
                ),
                child: MyImage.asset(MyImagePaths.iconChatPlus, width: 22.w, height: 22.w)),
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
                GestureDetector(
                  onTap: () => _sendImageMessage(ImageSource.gallery),
                  child: _PanelItem(icon: MyImagePaths.iconChatAlbum, label: 'chatPanelAlbum'.tr()),
                ),
                GestureDetector(
                  onTap: () => _sendImageMessage(ImageSource.camera),
                  child: _PanelItem(icon: MyImagePaths.iconChatCamera, label: 'chatPanelCamera'.tr()),
                ),
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
  final String imageUrl;

  const _ImageBubble({required this.isMine, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(6.r)),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 150.w,
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
                child: Icon(Icons.play_arrow_rounded, size: 16.sp, color: Colors.white),
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
