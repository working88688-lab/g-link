/// 点击项目类型。
///
/// 可直接使用预定义常量，也可传入自定义字符串：
/// ```dart
/// ClickItemTypeEnum.video                    // 预定义
/// ClickItemTypeEnum('manga', '漫画类')        // 自定义
/// ```
///
/// 字段规则（debug 模式下触发 assert）：
/// - [key]：仅限字母、数字、`_`、`-`
/// - [name]：字母、数字、`_`、`-`、中文
class ClickItemTypeEnum {
  final String key;
  final String name;

  const ClickItemTypeEnum._internal(this.key, this.name);

  /// 自定义类型。[key] 仅限字母/数字/`_`/`-`；[name] 允许中文。
  factory ClickItemTypeEnum(String key, String name) {
    assert(
      RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(key),
      'ClickItemTypeEnum.key 仅支持字母、数字、_ 和 -，实际传入: "$key"',
    );
    assert(
      RegExp(r'^[\u4e00-\u9fa5A-Za-z0-9_-]+$').hasMatch(name),
      'ClickItemTypeEnum.name 仅支持字母、数字、_、- 和中文，实际传入: "$name"',
    );
    return ClickItemTypeEnum._internal(key, name);
  }

  static const VIDEO = ClickItemTypeEnum._internal('video', '视频');
  static const NOVEL = ClickItemTypeEnum._internal('novel', '小说');
  static const COMIC = ClickItemTypeEnum._internal('comic', '漫画');
}
