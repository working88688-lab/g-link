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
}
