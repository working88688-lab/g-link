/// 金币消耗原因枚举
/// 对应文档中的 consume_reason_key 字段：
/// - video_unlock(视频解锁)
/// - gift_send(礼物赠送)
/// - content_purchase(内容购买)
enum ConsumeReasonEnum {
  /// 视频解锁
  VIDEO_UNLOCK(label: 'video_unlock'),

  /// 礼物赠送
  GIFT_SEND(label: 'gift_send'),

  /// 内容购买
  CONTENT_PURCHASE(label: 'content_purchase'),

  ;

  /// 上报时使用的字符串值
  final String label;

  const ConsumeReasonEnum({
    required this.label,
  });
}

