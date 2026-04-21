/// 货币类型枚举
/// 对应文档中的 currency 字段：CNY(人民币), USD(美元)
enum CurrencyEnum {
  /// 人民币
  CNY(label: 'CNY'),

  /// 美元
  USD(label: 'USD'),

  ;

  /// 上报时使用的字符串值
  final String label;

  const CurrencyEnum({
    required this.label,
  });
}

