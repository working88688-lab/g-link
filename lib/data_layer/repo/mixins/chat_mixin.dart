part of '../repo.dart';

mixin _Chat on _BaseAppRepo implements ChatDomain {
  @override
  Future<ChatsResult> fetchChats({String? cursor, int limit = 20}) =>
      _chatService.fetchChats(cursor: cursor, limit: limit);

  @override
  Future<ChatItem> createOrGetChat({required int peerUid}) => _chatService.createOrGetChat(peerUid: peerUid);

  @override
  Future<ChatMessagesResult> fetchChatMessages({
    required int chatId,
    int? cursor,
    String direction = 'before',
    int limit = 30,
  }) =>
      _chatService.fetchChatMessages(
        chatId: chatId,
        cursor: cursor,
        direction: direction,
        limit: limit,
      );

  @override
  Future<ChatMessageItem> sendMessage({
    required int chatId,
    required ChatMessageType msgType,
    String? content,
    String? mediaUrl,
    Map<String, dynamic>? mediaMeta,
    int? replyMsgId,
    String? clientMsgId,
  }) =>
      _chatService.sendMessage(
        chatId: chatId,
        msgType: msgType,
        content: content,
        mediaUrl: mediaUrl,
        mediaMeta: mediaMeta,
        replyMsgId: replyMsgId,
        clientMsgId: clientMsgId,
      );

  @override
  Future<MessageSearchResult> searchMessages({required String q, int limit = 10, int? chatId = null}) =>
      _chatService.searchMessages(q: q, limit: limit,chatId: chatId);

  @override
  Future<void> markChatRead(int chatId) => _chatService.markChatRead(chatId);

  @override
  Future<void> clearChatMessages(int chatId) => _chatService.clearChatMessages(chatId);

  @override
  Future<void> deleteChat(int chatId) => _chatService.deleteChat(chatId);

  @override
  Future<void> togglePin(int chatId, {required bool isPinned}) => _chatService.togglePin(chatId, isPinned: isPinned);

  @override
  Future<void> toggleMute(int chatId, {required bool isMuted}) => _chatService.toggleMute(chatId, isMuted: isMuted);
}
