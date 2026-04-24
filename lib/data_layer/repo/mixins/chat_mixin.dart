part of '../repo.dart';

mixin _Chat on _BaseAppRepo implements ChatDomain {
  @override
  Future<ChatsResult> fetchChats({int? cursor, int limit = 20}) =>
      _chatService.fetchChats(cursor: cursor, limit: limit);
}
