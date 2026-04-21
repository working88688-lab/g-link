/// 视频行为类型，用于视频事件。
///
/// 可使用预定义常量，也可传入自定义字符串：
/// ```dart
/// VideoEventEnum.play
/// VideoEventEnum('custom_key', '自定义行为')
/// ```
///
/// 字段规则（debug 模式下触发 assert）：
/// - [key]：仅限字母、数字、`_`、`-`
/// - [name]：字母、数字、`_`、`-`、中文
class VideoEventEnum {
  final String key;
  final String name;

  const VideoEventEnum._internal(this.key, this.name);

  /// 自定义行为类型。[key] 仅限字母/数字/`_`/`-`；[name] 允许中文。
  factory VideoEventEnum(String key, String name) {
    assert(
      RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(key),
      'VideoEventEnum.key 仅支持字母、数字、_ 和 -，实际传入: "$key"',
    );
    assert(
      RegExp(r'^[\u4e00-\u9fa5A-Za-z0-9_-]+$').hasMatch(name),
      'VideoEventEnum.name 仅支持字母、数字、_、- 和中文，实际传入: "$name"',
    );
    return VideoEventEnum._internal(key, name);
  }

  static const VIDEO_VIEW     = VideoEventEnum._internal('video_view',     '视频展示');
  static const VIDEO_PLAY     = VideoEventEnum._internal('video_play',     '视频播放');
  static const VIDEO_PAUSE    = VideoEventEnum._internal('video_pause',    '暂停');
  static const VIDEO_SHARE    = VideoEventEnum._internal('video_share',    '分享');
  static const VIDEO_COMPLETE = VideoEventEnum._internal('video_complete', '播放完成');
  static const VIDEO_FORWARD  = VideoEventEnum._internal('video_forward',  '快进');
  static const VIDEO_REWIND   = VideoEventEnum._internal('video_rewind',   '快退');
}
