part of '../repo.dart';

mixin _Chat on _BaseAppRepo implements ChatDomain {
  @override
  Future<ChatsResult> fetchChats({int? cursor, int limit = 20}) =>
      _chatService.fetchChats(cursor: cursor, limit: limit);

  @override
  Future<MessageSearchResult> searchMessages(
          {required String q, int limit = 10}) =>
      _chatService.searchMessages(q: q, limit: limit);
}
