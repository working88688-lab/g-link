/// 广告类型枚举
/// 对应埋点中的 ad_type 字段：icon、banner、feed、player、splash、text
enum AdTypeEnum {
  /// 图标广告
  icon(label: 'icon'),

  /// 横幅广告
  banner(label: 'banner'),

  /// 信息流广告
  feed(label: 'feed'),

  /// 播放器内广告
  player(label: 'player'),

  /// 开屏广告
  splash(label: 'splash'),

  /// 文字广告
  text(label: 'text'),

  ;

  /// 上报时使用的字符串值
  final String label;

  const AdTypeEnum({
    required this.label,
  });

  /// 根据字符串解析为枚举，未匹配时返回 null
  static AdTypeEnum? fromLabel(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final e in AdTypeEnum.values) {
      if (e.label == value) return e;
    }
    return null;
  }
}

