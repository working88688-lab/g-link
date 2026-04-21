/// 订单类型枚举
/// 对应文档中的 order_type 字段：coin_purchase(金币购买), vip_subscription(VIP订阅)
enum OrderTypeEnum {
  /// 金币购买
  COIN_PURCHASE(label: 'coin_purchase'),

  /// VIP 订阅
  VIP_SUBSCRIPTION(label: 'vip_subscription'),

  ;

  /// 上报时使用的字符串值
  final String label;

  const OrderTypeEnum({
    required this.label,
  });
}

