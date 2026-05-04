import 'package:dio/dio.dart';
import 'package:g_link/domain/model/chat_model.dart';

class ChatService {
  const ChatService(this._dio);

  final Dio _dio;

  Future<ChatsResult> fetchChats({String? cursor, int limit = 20}) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor.isNotEmpty) params['cursor'] = cursor;

    final res = await _dio.get('/api/v1/chats', queryParameters: params);
    final data = res.data['data'] as Map<String, dynamic>;
    final items = (data['lists'] as List<dynamic>).map((e) => ChatItem.fromJson(e as Map<String, dynamic>)).toList();
    return (
      items: items,
      nextCursor: data['next_cursor'] as String?,
      hasMore: (data['has_more'] as bool?) ?? false,
    );
  }

  Future<ChatItem> createOrGetChat({required int peerUid}) async {
    final res = await _dio.post('/api/v1/chats/with/$peerUid');
    final root = res.data;
    final data = root is Map<String, dynamic> ? (root['data'] as Map<String, dynamic>? ?? root) : <String, dynamic>{};
    return ChatItem.fromJson(data);
  }

  Future<ChatMessagesResult> fetchChatMessages({
    required int chatId,
    int? cursor,
    String direction = 'before',
    int limit = 30,
  }) async {
    final params = <String, dynamic>{'limit': limit, 'direction': direction};
    if (cursor != null && cursor > 0) params['cursor'] = cursor;
    final res = await _dio.get('/api/v1/chats/$chatId/messages', queryParameters: params);
    final root = res.data;
    final data = root is Map<String, dynamic> ? (root['data'] as Map<String, dynamic>? ?? root) : <String, dynamic>{};
    final items = (data['lists'] as List<dynamic>? ?? const [])
        .map((e) => ChatMessageItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return (
      items: items,
      nextCursor: int.tryParse('${data['next_cursor'] ?? ''}'),
      hasMore: (data['has_more'] as bool?) ?? false,
    );
  }

  Future<ChatMessageItem> sendMessage({
    required int chatId,
    required ChatMessageType msgType,
    String? content,
    String? mediaUrl,
    Map<String, dynamic>? mediaMeta,
    int? replyMsgId,
    String? clientMsgId,
  }) async {
    final res = await _dio.post(
      '/api/v1/chats/$chatId/messages',
      data: {
        'msg_type': msgType.value,
        'content': content,
        'media_url': mediaUrl,
        'media_meta': mediaMeta,
        'reply_msg_id': replyMsgId,
        'client_msg_id': clientMsgId,
      },
    );
    final root = res.data;
    final data = root is Map<String, dynamic> ? (root['data'] as Map<String, dynamic>? ?? root) : <String, dynamic>{};
    return ChatMessageItem.fromJson(data);
  }

  Future<MessageSearchResult> searchMessages({required String q, int limit = 10, int? chatId = null}) async {
    final res = await _dio.get(
      '/api/v1/messages/search',
      queryParameters: {'q': q, 'limit': limit, if (chatId != null) 'chat_id': chatId},
    );
    final data = res.data['data'] as Map<String, dynamic>;
    final contacts = (data['contacts'] as List<dynamic>? ?? [])
        .map((e) => MessageSearchContact.fromJson(e as Map<String, dynamic>))
        .toList();
    final messages = (data['messages'] as List<dynamic>? ?? [])
        .map((e) => MessageSearchMsg.fromJson(e as Map<String, dynamic>))
        .toList();
    return (contacts: contacts, messages: messages);
  }

  Future<void> markChatRead(int chatId) async {
    await _dio.post('/api/v1/chats/$chatId/mark-read');
  }

  Future<void> clearChatMessages(int chatId) async {
    await _dio.delete('/api/v1/chats/$chatId/messages');
  }

  Future<void> deleteChat(int chatId) async {
    await _dio.delete('/api/v1/chats/$chatId');
  }

  /// isPinned=false → POST /pin；isPinned=true → DELETE /pin
  Future<void> togglePin(int chatId, {required bool isPinned}) async {
    if (isPinned) {
      await _dio.delete('/api/v1/chats/$chatId/pin');
    } else {
      await _dio.post('/api/v1/chats/$chatId/pin');
    }
  }

  /// isMuted=false → POST /mute；isMuted=true → DELETE /mute
  Future<void> toggleMute(int chatId, {required bool isMuted}) async {
    if (isMuted) {
      await _dio.delete('/api/v1/chats/$chatId/mute');
    } else {
      await _dio.post('/api/v1/chats/$chatId/mute');
    }
  }
}
