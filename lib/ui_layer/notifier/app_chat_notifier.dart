import 'package:flutter/material.dart';

enum ChatMsgType { text, image, video }

enum ChatReadStatus { unread, sent, delivered }

class ChatSession {
  const ChatSession({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.lastMsg,
    required this.time,
    required this.unreadCount,
    required this.isOnline,
    required this.isMuted,
    required this.readStatus,
    required this.isPinned,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String lastMsg;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final bool isMuted;
  final ChatReadStatus readStatus;
  final bool isPinned;

  ChatSession copyWith({
    String? lastMsg,
    String? time,
    int? unreadCount,
    bool? isMuted,
    ChatReadStatus? readStatus,
    bool? isPinned,
  }) {
    return ChatSession(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      lastMsg: lastMsg ?? this.lastMsg,
      time: time ?? this.time,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline,
      isMuted: isMuted ?? this.isMuted,
      readStatus: readStatus ?? this.readStatus,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.isMine,
    required this.time,
    this.isRead = true,
    this.duration,
    this.isTimeline = false,
  });

  final String id;
  final String content;
  final ChatMsgType type;
  final bool isMine;
  final String time;
  final bool isRead;
  final String? duration;
  final bool isTimeline;
}

class AppChatNotifier extends ChangeNotifier {
  final List<ChatSession> _sessions = [
    const ChatSession(
      id: '1',
      name: 'Haley James',
      avatarUrl: '',
      lastMsg: 'The design draft has been updated.',
      time: '10:23',
      unreadCount: 9,
      isOnline: true,
      isMuted: false,
      readStatus: ChatReadStatus.unread,
      isPinned: false,
    ),
    const ChatSession(
      id: '2',
      name: 'Mia',
      avatarUrl: '',
      lastMsg: 'I am refining the component spec.',
      time: '09:45',
      unreadCount: 2,
      isOnline: true,
      isMuted: true,
      readStatus: ChatReadStatus.sent,
      isPinned: false,
    ),
    const ChatSession(
      id: '3',
      name: 'Product Group',
      avatarUrl: '',
      lastMsg: 'This week review is scheduled on Friday.',
      time: 'Sun',
      unreadCount: 0,
      isOnline: false,
      isMuted: false,
      readStatus: ChatReadStatus.delivered,
      isPinned: false,
    ),
  ];

  final Map<String, List<ChatMessage>> _messages = {
    '1': const [
      ChatMessage(
        id: 't1',
        content: '3月12日 12:23',
        type: ChatMsgType.text,
        isMine: false,
        time: '',
        isTimeline: true,
      ),
      ChatMessage(
        id: 't2',
        content: 'Hi, are you there?',
        type: ChatMsgType.text,
        isMine: false,
        time: '12:23',
      ),
      ChatMessage(
        id: 't3',
        content: 'Yes, wait a moment, I am checking the design draft.',
        type: ChatMsgType.text,
        isMine: true,
        time: '12:24',
      ),
    ],
    '2': const [
      ChatMessage(
        id: 'm1',
        content: 'I am refining the component spec.',
        type: ChatMsgType.text,
        isMine: false,
        time: '09:45',
      ),
    ],
  };

  List<ChatSession> get sessions => List.unmodifiable(_sessions);

  int get totalUnread => _sessions.fold(0, (sum, e) => sum + e.unreadCount);

  List<ChatSession> filteredSessions(String keyword) {
    final text = keyword.trim().toLowerCase();
    if (text.isEmpty) return sessions;
    return _sessions
        .where((e) =>
            e.name.toLowerCase().contains(text) ||
            e.lastMsg.toLowerCase().contains(text))
        .toList();
  }

  List<ChatMessage> messagesOf(String sessionId) =>
      List.unmodifiable(_messages[sessionId] ?? const []);

  String ensureSession({
    required String name,
    String avatarUrl = '',
    bool isOnline = false,
  }) {
    final idx = _sessions.indexWhere((e) => e.name == name);
    if (idx >= 0) return _sessions[idx].id;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _sessions.insert(
      0,
      ChatSession(
        id: id,
        name: name,
        avatarUrl: avatarUrl,
        lastMsg: 'Start chatting.',
        time: _formatTime(DateTime.now()),
        unreadCount: 0,
        isOnline: isOnline,
        isMuted: false,
        readStatus: ChatReadStatus.delivered,
        isPinned: false,
      ),
    );
    _messages[id] = const [];
    notifyListeners();
    return id;
  }

  ChatSession? sessionById(String sessionId) {
    final idx = _sessions.indexWhere((e) => e.id == sessionId);
    if (idx < 0) return null;
    return _sessions[idx];
  }

  void markRead(String sessionId) {
    final idx = _sessions.indexWhere((e) => e.id == sessionId);
    if (idx < 0) return;
    final item = _sessions[idx];
    if (item.unreadCount == 0) return;
    _sessions[idx] =
        item.copyWith(unreadCount: 0, readStatus: ChatReadStatus.delivered);
    notifyListeners();
  }

  void toggleMute(String sessionId) {
    final idx = _sessions.indexWhere((e) => e.id == sessionId);
    if (idx < 0) return;
    _sessions[idx] = _sessions[idx].copyWith(isMuted: !_sessions[idx].isMuted);
    notifyListeners();
  }

  void togglePin(String sessionId) {
    final idx = _sessions.indexWhere((e) => e.id == sessionId);
    if (idx < 0) return;
    final item = _sessions[idx].copyWith(isPinned: !_sessions[idx].isPinned);
    _sessions.removeAt(idx);
    _sessions.insert(0, item);
    notifyListeners();
  }

  void deleteSession(String sessionId) {
    _sessions.removeWhere((e) => e.id == sessionId);
    _messages.remove(sessionId);
    notifyListeners();
  }

  void sendText(String sessionId, String text) {
    final content = text.trim();
    if (content.isEmpty) return;
    final now = _formatTime(DateTime.now());
    final list = List<ChatMessage>.from(_messages[sessionId] ?? const []);
    list.add(
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: content,
        type: ChatMsgType.text,
        isMine: true,
        time: now,
      ),
    );
    _messages[sessionId] = list;
    _refreshSessionPreview(
      sessionId: sessionId,
      lastMsg: content,
      time: now,
      unreadInc: 0,
      readStatus: ChatReadStatus.sent,
    );
  }

  void mockReply(String sessionId, String content) {
    final now = _formatTime(DateTime.now());
    final list = List<ChatMessage>.from(_messages[sessionId] ?? const []);
    list.add(
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: content,
        type: ChatMsgType.text,
        isMine: false,
        time: now,
      ),
    );
    _messages[sessionId] = list;
    _refreshSessionPreview(
      sessionId: sessionId,
      lastMsg: content,
      time: now,
      unreadInc: 1,
      readStatus: ChatReadStatus.unread,
    );
  }

  void _refreshSessionPreview({
    required String sessionId,
    required String lastMsg,
    required String time,
    required int unreadInc,
    required ChatReadStatus readStatus,
  }) {
    final idx = _sessions.indexWhere((e) => e.id == sessionId);
    if (idx < 0) return;
    final item = _sessions[idx];
    _sessions[idx] = item.copyWith(
      lastMsg: lastMsg,
      time: time,
      unreadCount: (item.unreadCount + unreadInc).clamp(0, 999),
      readStatus: readStatus,
    );
    notifyListeners();
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
