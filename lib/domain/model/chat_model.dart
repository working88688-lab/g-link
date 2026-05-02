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
        id: (json['id'] as int?) ?? 0,
        chatId: json['chat_id'] as int,
        type: (json['type'] as int?) ?? 0,
        name: (json['name'] as String?) ?? '',
        avatarUrl: (json['avatar_url'] as String?) ?? '',
        peerUid: (json['peer_uid'] as int?) ?? 0,
        lastMsgContent: (json['last_msg_content'] as String?) ?? '',
        lastMsgTime: (json['last_msg_time'] as String?) ?? '',
        unreadCount: (json['unread_count'] as int?) ?? 0,
        isPinned: (json['is_pinned'] as bool?) ?? false,
        isMuted: (json['is_muted'] as bool?) ?? false,
      );

  ChatItem copyWith({bool? isPinned, bool? isMuted, int? unreadCount}) => ChatItem(
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

class MessageSearchContact {
  const MessageSearchContact({
    required this.uid,
    required this.nickname,
    required this.avatarUrl,
  });

  final int uid;
  final String nickname;
  final String avatarUrl;

  factory MessageSearchContact.fromJson(Map<String, dynamic> json) => MessageSearchContact(
        uid: (json['uid'] as int?) ?? 0,
        nickname: (json['nickname'] as String?) ?? '',
        avatarUrl: (json['avatar_url'] as String?) ?? '',
      );
}

class MessageSearchMsg {
  const MessageSearchMsg({
    required this.msgId,
    required this.chatId,
    required this.senderUid,
    required this.content,
    required this.createdAt,
  });

  final int msgId;
  final int chatId;
  final int senderUid;
  final String content;
  final String createdAt;

  factory MessageSearchMsg.fromJson(Map<String, dynamic> json) => MessageSearchMsg(
        msgId: (json['msg_id'] as int?) ?? 0,
        chatId: (json['chat_id'] as int?) ?? 0,
        senderUid: (json['sender_uid'] as int?) ?? 0,
        content: (json['content'] as String?) ?? '',
        createdAt: (json['created_at'] as String?) ?? '',
      );
}

typedef MessageSearchResult = ({
  List<MessageSearchContact> contacts,
  List<MessageSearchMsg> messages,
});

enum ChatMessageType {
  text(1),
  image(2),
  video(3),
  unknown(0);

  const ChatMessageType(this.value);

  final int value;

  static ChatMessageType fromValue(dynamic value) {
    final parsed = int.tryParse('$value') ?? 0;
    return ChatMessageType.values.firstWhere(
      (e) => e.value == parsed,
      orElse: () => ChatMessageType.unknown,
    );
  }
}

extension ChatMessageTypeX on ChatMessageType {
  bool get isText => this == ChatMessageType.text;

  bool get isImage => this == ChatMessageType.image;

  bool get isVideo => this == ChatMessageType.video;
}

class ChatMessageItem {
  ChatMessageItem(
      {required this.id,
      required this.chatId,
      required this.senderUid,
      required this.msgType,
      required this.content,
      required this.replyToMsgId,
      required this.status,
      required this.createdAt,
      required this.mediaUrl,
      required this.mediaMeta,
      required this.isMine});

  final int id;
  final int chatId;
  final int senderUid;
  final ChatMessageType msgType;
  final String content;
  final int? replyToMsgId;
  final String status;
  final String createdAt;
  final String mediaUrl;
  final Map<String, dynamic> mediaMeta;
  bool isMine;

  factory ChatMessageItem.fromJson(Map<String, dynamic> json) {
    final mediaMeta = json['media_meta'];
    return ChatMessageItem(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      chatId: int.tryParse('${json['chat_id'] ?? 0}') ?? 0,
      senderUid: int.tryParse('${json['sender_uid'] ?? 0}') ?? 0,
      msgType: ChatMessageType.fromValue(json['msg_type']),
      content: '${json['content'] ?? ''}',
      replyToMsgId: int.tryParse('${json['reply_to_msg_id'] ?? ''}'),
      status: '${json['status'] ?? ''}',
      createdAt: '${json['created_at'] ?? ''}',
      mediaUrl: '${json['media_url'] ?? ''}',
      mediaMeta: mediaMeta is Map<String, dynamic> ? mediaMeta : const {},
      isMine: (json['is_mine'] as bool?) ?? false,
    );
  }
}

typedef ChatMessagesResult = ({
  List<ChatMessageItem> items,
  String? nextCursor,
  bool hasMore,
});
