import 'package:g_link/domain/model/chat_model.dart';

abstract class ChatDomain {
  /// 会话列表（游标分页）
  /// [cursor] 上一页最后一条记录 id，首页不传
  /// [limit]  每页条数 1-50，默认 20
  Future<ChatsResult> fetchChats({int? cursor, int limit = 20});
}
