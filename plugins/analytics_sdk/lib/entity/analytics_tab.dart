/// Tab 页面的 analytics 配置。
///
/// [key] 为 pageKey，必填。
/// [name] 为 pageName，可选；为 null 时由 PageNameMapper 自动解析。
class AnalyticsTab {
  final String key;
  final String? name;

  const AnalyticsTab(this.key, [this.name]);
}
