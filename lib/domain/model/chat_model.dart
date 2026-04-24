class ChatItem {
  final int id;
  final int chatId;
  final int type;
  final String name;
  final String avatarUrl;
  final int peerUid;
  final String lastMsgContent;
  final String lastMsgTime;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;

  const ChatItem({
    required this.id,
    required this.chatId,
    required this.type,
    required this.name,
    required this.avatarUrl,
    required this.peerUid,
    required this.lastMsgContent,
    required this.lastMsgTime,
    required this.unreadCount,
    required this.isPinned,
    required this.isMuted,
  });

  factory ChatItem.fromJson(Map<String, dynamic> json) => ChatItem(
        id: json['id'] as int,
        chatId: json['chat_id'] as int,
        type: (json['type'] as int?) ?? 0,
        name: (json['name'] as String?) ?? '',
        avatarUrl: (json['avatar_url'] as String?) ?? '',
        peerUid: json['peer_uid'] as int,
        lastMsgContent: (json['last_msg_content'] as String?) ?? '',
        lastMsgTime: (json['last_msg_time'] as String?) ?? '',
        unreadCount: (json['unread_count'] as int?) ?? 0,
        isPinned: (json['is_pinned'] as bool?) ?? false,
        isMuted: (json['is_muted'] as bool?) ?? false,
      );

  ChatItem copyWith({bool? isPinned, bool? isMuted, int? unreadCount}) =>
      ChatItem(
        id: id,
        chatId: chatId,
        type: type,
        name: name,
        avatarUrl: avatarUrl,
        peerUid: peerUid,
        lastMsgContent: lastMsgContent,
        lastMsgTime: lastMsgTime,
        unreadCount: unreadCount ?? this.unreadCount,
        isPinned: isPinned ?? this.isPinned,
        isMuted: isMuted ?? this.isMuted,
      );
}

typedef ChatsResult = ({
  List<ChatItem> items,
  String? nextCursor,
  bool hasMore,
});
