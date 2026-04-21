/// 支付方式枚举
/// 对应文档中的 pay_type 字段：wechat, alipay, bank_card, apple_pay 等
enum PayTypeEnum {
  /// 微信支付
  WECHAT(label: 'wechat'),

  /// 支付宝
  ALIPAY(label: 'alipay'),

  /// 银行卡
  BANK_CARD(label: 'bank_card'),

  /// Apple Pay
  APPLE_PAY(label: 'apple_pay'),

  ;

  /// 上报时使用的字符串值
  final String label;

  const PayTypeEnum({
    required this.label,
  });
}

