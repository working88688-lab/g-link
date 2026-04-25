import 'package:g_link/domain/model/chat_model.dart';

abstract class ChatDomain {
  /// 会话列表（游标分页）
  Future<ChatsResult> fetchChats({int? cursor, int limit = 20});

  /// 搜索消息和联系人
  Future<MessageSearchResult> searchMessages(
      {required String q, int limit = 10});

  /// 删除会话（仅对当前用户生效）
  Future<void> deleteChat(int chatId);

  /// 切换置顶（isPinned 为当前状态，方法内判断调哪个接口）
  Future<void> togglePin(int chatId, {required bool isPinned});

  /// 切换静音（isMuted 为当前状态）
  Future<void> toggleMute(int chatId, {required bool isMuted});
}
