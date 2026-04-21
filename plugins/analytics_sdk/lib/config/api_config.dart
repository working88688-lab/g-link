/// API 配置管理类：统一管理所有 API 端点路径
class ApiConfig {
  ApiConfig._();

  // ==================== API 路径（固定不变）====================

  /// 上报接口路径（固定）
  static const String defaultReportPath = '/api/eventTracking/batchReport.json';

  /// 上报接口路径
  static String get reportPath => defaultReportPath;

  // ==================== 配置方法 ====================

  /// 构建完整的 URL
  /// [baseDomain] 基础域名，如 'https://api.example.com'
  /// [path] API 路径，如 '/api/analytics/report'
  /// [appId] 应用ID（可选），如果提供会作为查询参数添加到URL中
  /// 返回完整的 URL，如 'https://api.example.com/api/analytics/report?appId=xxx'
  static String buildUrl(String baseDomain, String path, {String? appId}) {
    // 确保路径以 / 开头
    final normalizedPath = _normalizePath(path);

    // 解析基础域名
    final uri = Uri.parse(baseDomain);
    final scheme = uri.scheme.isEmpty ? 'https' : uri.scheme;
    final host = uri.host.isEmpty ? baseDomain : uri.host;

    // 保留非默认端口（如 :8080），避免 IP+端口 场景下端口丢失
    final defaultPort = scheme == 'https' ? 443 : 80;
    final portSuffix =
        (uri.port > 0 && uri.port != defaultPort) ? ':${uri.port}' : '';

    // 构建完整 URL
    String url = '$scheme://$host$portSuffix$normalizedPath';

    // 如果提供了 appId，添加到查询参数
    if (appId != null && appId.isNotEmpty) {
      url = _addQueryParameter(url, 'appId', appId);
    }

    return url;
  }

  /// 规范化路径：确保路径以 / 开头
  static String _normalizePath(String path) {
    if (path.isEmpty) {
      return '/';
    }
    return path.startsWith('/') ? path : '/$path';
  }

  /// 获取上报接口 URL
  /// [baseDomain] 基础域名
  /// [appId] 应用ID（可选，如果提供会作为查询参数）
  static String getReportUrl(String baseDomain, {String? appId}) {
    return buildUrl(baseDomain, reportPath, appId: appId);
  }

  /// 添加查询参数到 URL
  /// [url] 原始 URL
  /// [key] 参数名
  /// [value] 参数值
  static String _addQueryParameter(String url, String key, String value) {
    try {
      final uri = Uri.parse(url);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      queryParams[key] = value;
      return uri.replace(queryParameters: queryParams).toString();
    } catch (e) {
      // 如果 URL 解析失败，直接拼接
      final separator = url.contains('?') ? '&' : '?';
      return '$url$separator$key=${Uri.encodeComponent(value)}';
    }
  }
}
