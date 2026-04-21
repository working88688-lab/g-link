/// 视频内容类型，用于视频事件。
///
/// 可使用预定义常量，也可传入自定义字符串：
/// ```dart
/// VideoContentTypeEnum.video
/// VideoContentTypeEnum('live')
/// ```
///
/// 字段规则（debug 模式下触发 assert）：
/// - [label]：仅限字母、数字、`_`、`-`
class VideoContentTypeEnum {
  final String label;

  const VideoContentTypeEnum._internal(this.label);

  /// 自定义内容类型。[label] 仅限字母/数字/`_`/`-`。
  factory VideoContentTypeEnum(String label) {
    assert(
      RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(label),
      'VideoContentTypeEnum.label 仅支持字母、数字、_ 和 -，实际传入: "$label"',
    );
    return VideoContentTypeEnum._internal(label);
  }

  /// 长视频
  static const video      = VideoContentTypeEnum._internal('video');

  /// 短视频
  static const shortVideo = VideoContentTypeEnum._internal('short_video');
}
