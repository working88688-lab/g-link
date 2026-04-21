// lib/utils/page_name_mapper.dart

/// 统一的页面 pageKey → pageName 映射管理器
/// 支持静态默认映射 + 动态添加/覆盖（业务方可在初始化时自定义）
class PageNameMapper {
  // 默认映射表（SDK 内置）
  static const Map<String, String> _defaultMap = {};

  // 可动态修改的映射表（优先级高于默认）
  static final Map<String, String> _customMap = {};

  /// 去除 pageKey 前导斜杠，结果为空时保留原值（如纯 "/" 保持为 "/"）
  static String normalizeKey(String pageKey) {
    if (!pageKey.startsWith('/')) return pageKey;
    final stripped = pageKey.substring(1);
    return stripped.isEmpty ? pageKey : stripped;
  }

  /// 获取页面名称
  static String getPageName(String pageKey) {
    final key = normalizeKey(pageKey);
    return _customMap[key] ?? _defaultMap[key] ?? key;
  }

  /// 动态添加或覆盖单个映射（业务初始化时调用）
  static void addMapping(String pageKey, String pageName) {
    _customMap[normalizeKey(pageKey)] = pageName;
  }

  /// 批量动态添加或覆盖映射
  static void addMappings(Map<String, String> mappings) {
    for (final entry in mappings.entries) {
      addMapping(entry.key, entry.value);
    }
  }

  /// 清空自定义映射（测试或重置用）
  static void clearCustom() {
    _customMap.clear();
  }
}
