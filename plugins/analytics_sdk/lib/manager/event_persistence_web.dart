import 'dart:collection';

/// Web 平台事件持久化：内存 only，所有持久化操作为空实现。
/// Web 会话通常短暂，不需要跨页面持久化事件。
class EventPersistenceImpl {
  Future<void> init() async {}

  void bufferEvent(Map<String, dynamic> event) {}

  Future<List<Map<String, dynamic>>> loadEvents({
    required Queue<Map<String, dynamic>> queue,
    required int maxQueueSize,
    required int maxCacheLines,
    required bool Function(String) isEventTypeEnabled,
  }) async =>
      const [];

  Future<void> removeEvents(List<Map<String, dynamic>> events) async {}

  Future<void> clearCache() async {}

  void flushBuffer() {}

  Future<void> flushBufferAsync() async {}
}
