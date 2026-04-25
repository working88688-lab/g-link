import 'package:dio/dio.dart';
import 'package:g_link/domain/model/chat_model.dart';

class ChatService {
  const ChatService(this._dio);

  final Dio _dio;

  Future<ChatsResult> fetchChats({int? cursor, int limit = 20}) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;

    final res = await _dio.get('/api/v1/chats', queryParameters: params);
    final data = res.data['data'] as Map<String, dynamic>;
    final items = (data['lists'] as List<dynamic>)
        .map((e) => ChatItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return (
      items: items,
      nextCursor: data['next_cursor'] as String?,
      hasMore: (data['has_more'] as bool?) ?? false,
    );
  }

  Future<MessageSearchResult> searchMessages({
    required String q,
    int limit = 10,
  }) async {
    final res = await _dio.get(
      '/api/v1/messages/search',
      queryParameters: {'q': q, 'limit': limit},
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
