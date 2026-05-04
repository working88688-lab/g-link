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
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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

enum _AnchorDirection { top, bottom }

class _Anchor {
  final int messageId;
  final double alignment;

  const _Anchor({required this.messageId, required this.alignment});
}

class _ChatPageState extends State<ChatPage> {
  final _inputCtrl = TextEditingController();
  final ItemScrollController _itemScrollCtrl = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final _focusNode = FocusNode();
  bool _hasText = false;
  bool _showPanel = false;
  bool _isLoadingSession = true;
  bool _isLoadingOlder = false;
  bool _isLoadingNewer = false;
  bool _hasMoreOlder = false;
  bool _hasMoreNewer = false;
  int? _olderCursor;
  int? _newerCursor;
  String? _sessionError;
  ChatItem? _session;
  final List<ChatMessageItem> _messages = [];
  int? _currentUserId;

  String? get displayName => widget.name.isNotEmpty ? widget.name : _session?.name;

  String? get displayAvatarUrl => _session?.avatarUrl.isNotEmpty == true ? _session!.avatarUrl : widget.avatarUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapCurrentUser();
      _loadSession();
    });
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showPanel) {
        setState(() => _showPanel = false);
      }
    });
    _itemPositionsListener.itemPositions.addListener(_handleScrollPosition);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_handleScrollPosition);
    _inputCtrl.dispose();
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
    if (session == null || _isLoadingOlder || _isLoadingNewer) return;

    _setOlderLoading(true);
    if (refresh) {
      _resetPagination();
    }
    _clearSessionError();

    try {
      final result = await context.read<ChatDomain>().fetchChatMessages(
            chatId: session.chatId,
            cursor: null,
            direction: 'before',
            limit: 30,
          );
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(result.items);
        _olderCursor = result.nextCursor;
        _hasMoreOlder = result.hasMore;
        _newerCursor = _messages.isNotEmpty ? _messages.first.id : null;
        _hasMoreNewer = false;
      });
    } catch (err) {
      _setSessionError(err);
    } finally {
      _setOlderLoading(false);
    }
  }

  void _handleScrollPosition() {
    if (_isLoadingOlder || _isLoadingNewer) return;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty || _messages.isEmpty) return;

    final minIndex = positions.map((e) => e.index).reduce((a, b) => a < b ? a : b);
    final maxIndex = positions.map((e) => e.index).reduce((a, b) => a > b ? a : b);
    if (_hasMoreOlder && maxIndex >= _messages.length - 2) {
      _loadOlderMessages();
    }
    if (_hasMoreNewer && minIndex <= 1) {
      _loadNewerMessages();
    }
  }

  void _scrollToBottom() {
    if (_messages.isEmpty || !_itemScrollCtrl.isAttached) return;
    _itemScrollCtrl.jumpTo(
      index: 0,
      alignment: 0,
    );
  }

  Future<void> _jumpToMessageAndRefresh(int msgId) async {
    final session = _session;
    if (session == null) return;

    final exists = _messages.any((m) => m.id == msgId);
    if (exists) {
      await _scrollToMessage(msgId);
      return;
    }

    final anchor = _captureBottomAnchor();
    try {
      final result = await context.read<ChatDomain>().fetchChatMessages(
            chatId: session.chatId,
            cursor: msgId,
            direction: 'before',
            limit: 30,
          );
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(result.items);
        _olderCursor = result.nextCursor;
        _hasMoreOlder = result.hasMore;
        _newerCursor = _messages.isNotEmpty ? _messages.first.id : msgId;
        _hasMoreNewer = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreAnchor(anchor, animate: false);
        if (_itemScrollCtrl.isAttached) {
          _itemScrollCtrl.jumpTo(index: _messages.indexWhere((m) => m.id == msgId), alignment: 0.5);
        }
      });
    } catch (err) {
      _setSessionError(err);
    }
  }

  Future<void> _scrollToMessage(int msgId) async {
    if (!_itemScrollCtrl.isAttached) return;
    final idx = _messages.indexWhere((m) => m.id == msgId);
    if (idx < 0) return;
    await _itemScrollCtrl.scrollTo(
      index: idx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: 0.5,
    );
  }

  Future<void> _loadOlderMessages() async {
    final session = _session;
    if (session == null || _isLoadingOlder || !_hasMoreOlder || _olderCursor == null) return;

    final anchor = _captureTopAnchor();
    _setOlderLoading(true);
    try {
      final result = await context.read<ChatDomain>().fetchChatMessages(
            chatId: session.chatId,
            cursor: _olderCursor,
            direction: 'before',
            limit: 30,
          );
      if (!mounted) return;
      final incoming = result.items.toList();
      setState(() {
        _messages.addAll(incoming);
        _olderCursor = result.nextCursor;
        _hasMoreOlder = result.hasMore;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreAnchor(anchor, animate: false));
    } catch (err) {
      _setSessionError(err);
    } finally {
      _setOlderLoading(false);
    }
  }

  _Anchor? _captureTopAnchor() {
    return _captureAnchor(direction: _AnchorDirection.top);
  }

  _Anchor? _captureBottomAnchor() {
    return _captureAnchor(direction: _AnchorDirection.bottom);
  }

  _Anchor? _captureAnchor({required _AnchorDirection direction}) {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty || _messages.isEmpty) return null;
    final visible = positions.where((p) => p.itemTrailingEdge > 0 && p.itemLeadingEdge < 1).toList();
    if (visible.isEmpty) return null;

    visible.sort((a, b) {
      return switch (direction) {
        _AnchorDirection.top => a.itemLeadingEdge.compareTo(b.itemLeadingEdge),
        _AnchorDirection.bottom => b.itemTrailingEdge.compareTo(a.itemTrailingEdge),
      };
    });

    final pos = visible.first;
    final idx = pos.index.clamp(0, _messages.length - 1);
    return _Anchor(
      messageId: _messages[idx].id,
      alignment: switch (direction) {
        _AnchorDirection.top => pos.itemLeadingEdge.clamp(0.0, 1.0),
        _AnchorDirection.bottom => (1.0 - pos.itemTrailingEdge).clamp(0.0, 1.0),
      },
    );
  }

  void _restoreAnchor(_Anchor? anchor, {required bool animate}) {
    if (anchor == null || !_itemScrollCtrl.isAttached) return;
    final newIndex = _messages.indexWhere((m) => m.id == anchor.messageId);
    if (newIndex < 0) return;
    if (animate) {
      _itemScrollCtrl.scrollTo(
        index: newIndex,
        alignment: anchor.alignment,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else {
      _itemScrollCtrl.jumpTo(index: newIndex, alignment: anchor.alignment);
    }
  }

  void _resetPagination() {
    _messages.clear();
    _olderCursor = null;
    _newerCursor = null;
    _hasMoreOlder = false;
    _hasMoreNewer = false;
  }

  void _setOlderLoading(bool value) {
    if (!mounted) return;
    setState(() => _isLoadingOlder = value);
  }

  void _setNewerLoading(bool value) {
    if (!mounted) return;
    setState(() => _isLoadingNewer = value);
  }

  void _clearSessionError() {
    if (!mounted) return;
    if (_sessionError == null) return;
    setState(() => _sessionError = null);
  }

  void _setSessionError(Object err) {
    if (!mounted) return;
    setState(() {
      _sessionError = err.toString();
    });
  }

  Future<void> _loadNewerMessages() async {
    final session = _session;
    if (session == null || _isLoadingNewer || !_hasMoreNewer || _newerCursor == null) return;

    final anchor = _captureBottomAnchor();
    _setNewerLoading(true);
    try {
      final result = await context.read<ChatDomain>().fetchChatMessages(
            chatId: session.chatId,
            cursor: _newerCursor,
            direction: 'after',
            limit: 30,
          );
      if (!mounted) return;
      final incoming = result.items.toList();
      setState(() {
        _messages.insertAll(0, incoming);
        _newerCursor = result.nextCursor;
        _hasMoreNewer = result.hasMore;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreAnchor(anchor, animate: false));
    } catch (err) {
      _setSessionError(err);
    } finally {
      _setNewerLoading(false);
    }
  }

  Future<UploadedImagePayload?> _uploadChatImage({required ImageSource source}) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked == null) return null;

      final session = _session;
      if (session == null) return null;

      final bytes = await picked.readAsBytes();
      final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
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

    final draft = _buildSendingDraft(
      chatId: session.chatId,
      msgType: ChatMessageType.image,
      content: '',
      mediaUrl: uploaded.downloadUrl,
    );

    setState(() {
      _messages.insert(0, draft);
      _showPanel = false;
    });
    _scrollToBottom();

    try {
      final resp = await context.read<ChatDomain>().sendMessage(
            chatId: session.chatId,
            msgType: ChatMessageType.image,
            mediaUrl: uploaded.downloadUrl,
            clientMsgId: draft.id.toString(),
          );
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((e) => e.id == draft.id);
        if (idx >= 0 && resp.id != 0) {
          _messages[idx] = resp;
        }
      });
    } catch (err) {
      _setSessionError(err);
    }
  }

  Future<void> _sendMessage() async {
    final session = _session;
    final text = _inputCtrl.text.trim();
    if (session == null || text.isEmpty) return;

    _inputCtrl.clear();
    if (mounted) {
      setState(() => _hasText = false);
    }

    final draft = _buildSendingDraft(
      chatId: session.chatId,
      msgType: ChatMessageType.text,
      content: text,
    );

    setState(() {
      _messages.insert(0, draft);
    });
    _scrollToBottom();

    try {
      await context.read<ChatDomain>().sendMessage(
            chatId: session.chatId,
            msgType: ChatMessageType.text,
            content: text,
            clientMsgId: draft.id.toString(),
          );
      if (!mounted) return;
      _scrollToBottom();
    } catch (err) {
      _setSessionError(err);
    }
  }

  ChatMessageItem _buildSendingDraft({
    required int chatId,
    required ChatMessageType msgType,
    required String content,
    String? mediaUrl,
  }) {
    return ChatMessageItem(
      id: DateTime.now().microsecondsSinceEpoch,
      chatId: chatId,
      senderUid: _currentUserId ?? 0,
      msgType: msgType,
      content: content,
      replyToMsgId: null,
      status: 'sending',
      createdAt: _formatTime(DateTime.now()),
      mediaUrl: mediaUrl ?? '',
      mediaMeta: const {},
      isMine: true,
    );
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

  void _dismissKeyboardAndPanel() {
    FocusScope.of(context).unfocus();
    if (_showPanel) {
      setState(() => _showPanel = false);
    }
  }

  // ── 顶部栏 ───────────────────────────────
  Widget _buildTopBar() {
    final displayName = this.displayName;
    final displayAvatar = displayAvatarUrl;
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
                onTap: () async {
                  final chatId = _session?.chatId ?? 0;
                  if (chatId == 0) return;
                  final msgId = await ChatRecordsSearchRoute(chatId: chatId).push<int>(context);
                  if (!mounted || msgId == null || msgId <= 0) return;
                  await _jumpToMessageAndRefresh(msgId);
                },
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
                            final session = _session;
                            if (session == null) return;
                            await context.read<ChatDomain>().clearChatMessages(session.chatId);
                            if (!mounted) return;
                            setState(() {
                              _resetPagination();
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
    return GestureDetector(
      onTap: _dismissKeyboardAndPanel,
      child: ScrollablePositionedList.builder(
        reverse: true,
        itemScrollController: _itemScrollCtrl,
        itemPositionsListener: _itemPositionsListener,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.w),
        itemCount: _messages.length,
        itemBuilder: (ctx, i) => _buildMessageBubble(_messages[i]),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageItem msg) {
    final isMine = msg.senderUid == (_currentUserId ?? -1);
    return Padding(
      padding: EdgeInsets.only(bottom: 18.w),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildBubbleContent(msg, isMine: isMine),
        ],
      ),
    );
  }

  Widget _buildBubbleContent(ChatMessageItem msg, {required bool isMine}) {
    switch (msg.msgType) {
      case ChatMessageType.text:
        return _TextBubble(text: msg.content, isMine: isMine);
      case ChatMessageType.image:
        return _ImageBubble(
          isMine: isMine,
          imageUrl: msg.mediaUrl ?? "",
        );
      case ChatMessageType.video:
        return _VideoBubble(duration: '', isMine: isMine);
      case ChatMessageType.unknown:
        return const SizedBox.shrink();
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
                onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
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
        SizedBox(height: 6.w),
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
          Text(
            '$text${isMine ? " \u2003" : ""}',
            style: TextStyle(
              fontSize: 14.sp,
              color: isMine ? Colors.white : const Color(0xFF0F172B),
              height: 1.4,
            ),
          ),
          if (isMine)
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
