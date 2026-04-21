import 'package:analytics_sdk/analytics_sdk.dart';
import 'package:analytics_sdk/entity/analytics_tab.dart';
import 'package:analytics_sdk/manager/page_name_manager.dart';

/// Tab 解析与 track 分发的包内共享工具。
///
/// 供 widget 层各 analytics 包装使用，消除跨文件重复逻辑。
/// 文件名以下划线开头，表示不对外暴露。

/// 按索引解析 tab，超出范围时用 tab_N 兜底。
AnalyticsTab resolveTab(List<AnalyticsTab> tabs, int index) =>
    index < tabs.length ? tabs[index] : AnalyticsTab('tab_$index');

/// 解析 tab 展示名称，未配置时通过 PageNameMapper 自动映射。
String resolveTabName(AnalyticsTab tab) =>
    tab.name ?? PageNameMapper.getPageName(tab.key);

/// 上报事件：优先使用测试注入的 override，否则走 AnalyticsSdk.instance.track。
void trackWith(void Function(dynamic)? override, Object event) =>
    (override ?? AnalyticsSdk.instance.track)(event);
