// 如果需要其他 UUID 生成，保留；但 eventId 现在固定，不再使用

/// 事件类型枚举：定义所有可能的事件类型
/// 每个枚举值存储固定的 event 字符串
/// 同时覆盖客户端、服务端上报的所有事件，方便统一管理
enum EventType {
  // ==================== 安装 & 用户 ====================

  /// App 安装事件（客户端）
  appInstall(event: 'app_install'),

  /// 用户注册事件（服务端）
  userRegister(event: 'user_register'),

  /// 用户登录事件（服务端）
  userLogin(event: 'user_login'),

  /// 实时在线人数（服务端）
  realtimeOnline(event: 'realtime_online'),

  // ==================== 订单 & 金币 ====================

  /// 订单创建事件（服务端）
  orderCreated(event: 'order_created'),

  /// 订单支付成功事件（服务端）
  orderPaid(event: 'order_paid'),

  /// 金币消耗事件（服务端）
  coinConsume(event: 'coin_consume'),

  /// 导航模块点击事件
  navigation(event: 'navigation'),

  /// 应用页面展示
  appPageView(event: 'app_page_view'),

  /// 应用页面点击
  pageClick(event: 'page_click'),

  /// 广告事件
  advertising(event: 'advertising'),

  /// 广告点击事件
  adClick(event: 'ad_click'),

  /// 页面存活
  pageLifecycle(event: 'page_lifecycle'),

  /// 视频事件
  videoEvent(event: 'video_event'),

  /// 广告展示
  adImpression(event: 'ad_impression'),

  /// 视频点赞事件
  videoLike(event: 'video_like'),

  /// 小说事件
  novelEvent(event: 'novel_event'),

  /// 小说点赞事件
  novelLike(event: 'novel_like'),

  /// 漫画事件
  comicEvent(event: 'comic_event'),

  /// 漫画点赞事件
  comicLike(event: 'comic_like'),

  /// 关键词搜索事件
  keywordSearch(event: 'keyword_search'),

  /// 关键词搜索结果点击事件
  keywordClick(event: 'keyword_click'),

  /// 小说收藏事件
  novelCollect(event: 'novel_collect'),

  /// 漫画收藏事件
  comicCollect(event: 'comic_collect'),

  // ==================== 推荐引擎相关 ====================

  /// 推荐列表展示事件（服务端/客户端）
  recommendListView(event: 'recommend_list_view'),

  /// 推荐列表点击事件（服务端/客户端）
  recommendListClick(event: 'recommend_list_click'),

  // ==================== 视频相关扩展事件 ====================

  /// 视频评论事件（服务端/客户端）
  videoComment(event: 'video_comment'),

  /// 视频收藏事件（服务端/客户端）
  videoCollect(event: 'video_collect'),

  /// 视频购买事件（服务端/客户端）
  videoPurchase(event: 'video_purchase'),

  /// 视频状态更改事件（服务端）
  videoStatusChange(event: 'video_status_change'),

  // ==================== 小说相关扩展事件 ====================

  /// 小说评论事件（服务端/客户端）
  novelComment(event: 'novel_comment'),

  /// 小说购买事件（服务端/客户端）
  novelPurchase(event: 'novel_purchase'),

  // ==================== 漫画相关扩展事件 ====================

  /// 漫画评论事件（服务端/客户端）
  comicComment(event: 'comic_comment'),

  /// 漫画购买事件（服务端/客户端）
  comicPurchase(event: 'comic_purchase'),
  ;

  /// 事件类型字符串
  final String event;

  const EventType({required this.event});

  /// 静态方法：根据 event 字符串获取枚举值（如果存在）
  static EventType? fromEvent(String event) {
    try {
      return EventType.values.firstWhere((e) => e.event == event);
    } catch (_) {
      return null; // 或 throw ArgumentError('Unknown event: $event')
    }
  }
}
