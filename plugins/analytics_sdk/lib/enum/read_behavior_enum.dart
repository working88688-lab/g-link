/// 阅读行为类型，用于小说和漫画事件。
///
/// 可使用预定义常量，也可传入自定义字符串：
/// ```dart
/// ReadBehaviorEnum.view
/// ReadBehaviorEnum('custom_key', '自定义行为')
/// ```
///
/// 字段规则（debug 模式下触发 assert）：
/// - [key]：仅限字母、数字、`_`、`-`
/// - [name]：字母、数字、`_`、`-`、中文
class ReadBehaviorEnum {
  final String key;
  final String name;

  const ReadBehaviorEnum._internal(this.key, this.name);

  /// 自定义行为类型。[key] 仅限字母/数字/`_`/`-`；[name] 允许中文。
  factory ReadBehaviorEnum(String key, String name) {
    assert(
      RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(key),
      'ReadBehaviorEnum.key 仅支持字母、数字、_ 和 -，实际传入: "$key"',
    );
    assert(
      RegExp(r'^[\u4e00-\u9fa5A-Za-z0-9_-]+$').hasMatch(name),
      'ReadBehaviorEnum.name 仅支持字母、数字、_、- 和中文，实际传入: "$name"',
    );
    return ReadBehaviorEnum._internal(key, name);
  }

  static const VIEW      = ReadBehaviorEnum._internal('view',      '展示');
  static const PAGE_NEXT = ReadBehaviorEnum._internal('page_next', '下一页');
  static const PAGE_PREV = ReadBehaviorEnum._internal('page_prev', '上一页');
  static const COMPLETE  = ReadBehaviorEnum._internal('complete',  '读完');
}
