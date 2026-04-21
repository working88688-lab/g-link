/// 用户类型，用于上报用户身份信息。
///
/// 可使用预定义常量，也可传入自定义字符串：
/// ```dart
/// UserTypeEnum.normal
/// UserTypeEnum.vip
/// UserTypeEnum('svip')
/// ```
///
/// 字段规则（debug 模式下触发 assert）：
/// - [label]：仅限字母、数字、`_`、`-`
class UserTypeEnum {
  final String label;

  const UserTypeEnum._internal(this.label);

  /// 自定义用户类型。[label] 仅限字母/数字/`_`/`-`。
  factory UserTypeEnum(String label) {
    assert(
      RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(label),
      'UserTypeEnum.label 仅支持字母、数字、_ 和 -，实际传入: "$label"',
    );
    return UserTypeEnum._internal(label);
  }

  static const normal = UserTypeEnum._internal('normal');
  static const vip    = UserTypeEnum._internal('vip');
}
