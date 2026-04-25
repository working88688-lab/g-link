import 'package:g_link/domain/model/chat_model.dart';

abstract class ChatDomain {
  /// 会话列表（游标分页）
  Future<ChatsResult> fetchChats({int? cursor, int limit = 20});

  /// 搜索消息和联系人
  Future<MessageSearchResult> searchMessages(
      {required String q, int limit = 10});
}
