/// 认证/注册/登录方式枚举
/// 对应文档中的 type 字段：phone、deviceid、email、username
enum AuthTypeEnum {
  /// 手机号
  PHONE(label: 'phone'),

  /// 设备ID
  DEVICE_ID(label: 'deviceid'),

  /// 邮箱
  EMAIL(label: 'email'),

  /// 用户名/账号
  USERNAME(label: 'username'),

  ;

  /// 上报时使用的字符串值
  final String label;

  const AuthTypeEnum({
    required this.label,
  });
}

