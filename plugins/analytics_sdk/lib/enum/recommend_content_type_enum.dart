/// 推荐列表内容类型，用于推荐列表展示/点击事件。
///
/// 可使用预定义常量，也可传入自定义字符串：
/// ```dart
/// RecommendContentTypeEnum.video
/// RecommendContentTypeEnum('podcast')
/// ```
///
/// 字段规则（debug 模式下触发 assert）：
/// - [label]：仅限字母、数字、`_`、`-`
class RecommendContentTypeEnum {
  final String label;

  const RecommendContentTypeEnum._internal(this.label);

  /// 自定义内容类型。[label] 仅限字母/数字/`_`/`-`。
  factory RecommendContentTypeEnum(String label) {
    assert(
      RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(label),
      'RecommendContentTypeEnum.label 仅支持字母、数字、_ 和 -，实际传入: "$label"',
    );
    return RecommendContentTypeEnum._internal(label);
  }

  static const VIDEO = RecommendContentTypeEnum._internal('video');
  static const NOVEL = RecommendContentTypeEnum._internal('novel');
  static const COMIC = RecommendContentTypeEnum._internal('comic');
}
