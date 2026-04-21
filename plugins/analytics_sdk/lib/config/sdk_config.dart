/// SDK 配置管理类：统一管理所有 SDK 相关的配置常量
class SdkConfig {
  SdkConfig._();

  // ==================== 事件队列配置 ====================

  /// 事件队列最大容量限制，防止内存无限增长
  static int maxQueueSize = 5000;

  /// 自动上报阈值：队列达到此数量时立即触发上报
  static int autoUploadThreshold = 10;

  /// 单次上报的最大事件数量限制，避免请求过大导致超时
  static int maxBatchSize = 500;

  /// JSON 编码的批次大小阈值，超过此大小使用 isolate 编码
  static int isolateEncodingThreshold = 100;

  // ==================== 定时器配置 ====================

  /// 定时上报间隔（秒）
  static Duration uploadInterval = const Duration(seconds: 5);

  /// 页面加载超时时间（秒）
  static Duration pageLoadTimeout = const Duration(seconds: 5);

  /// 点击事件节流时间（毫秒）
  static Duration clickThrottleDuration = const Duration(milliseconds: 300);

  // ==================== 网络超时配置 ====================

  /// HTTP 连接超时时间
  static Duration connectionTimeout = const Duration(seconds: 10);

  /// HTTP 读取超时时间
  static Duration readTimeout = const Duration(seconds: 30);

  /// HTTP 写入超时时间（与连接超时相同）
  static Duration get writeTimeout => connectionTimeout;

  /// 域名测速超时时间
  static Duration speedTestTimeout = const Duration(seconds: 5);

  /// 配置请求超时时间
  static Duration configRequestTimeout = const Duration(seconds: 10);

  // ==================== 加密配置 ====================

  /// AES-GCM 解密密钥（固定密钥，用于 decryptResponseAuto 等）
  static const String decryptKey = 'en1BNo0VBrN/zi+mI2LO7E9W40ehCBYwC+frBn8s3rQ';



  // ==================== 重试配置 ====================

  /// 最大退避级别
  static int maxBackoffLevel = 5;

  /// 基础延迟时间
  static Duration baseRetryDelay = const Duration(seconds: 2);

  /// 最大延迟时间
  static Duration maxRetryDelay = const Duration(seconds: 60);

  // ==================== 缓存配置 ====================

  /// 事件缓存文件名
  static String cacheFileName = 'data_plus_events_cache.jsonl';

  /// 事件类型配置缓存文件名
  static String eventTypeConfigCacheFileName =
      'analytics_event_types_config.json';

  /// 域名列表缓存文件名
  static String domainCacheFileName = 'data_plus_domains_cache.json';

  /// 最大缓存行数限制，防止文件过大导致内存问题
  /// 默认 2000 行，避免在网络不稳定时生成过大的缓存文件
  static int maxCacheLines = 2000;

  /// 缓存文件最大字节数限制，超过后从文件开头裁剪旧事件
  /// 默认 2MB
  static int maxCacheBytes = 2 * 1024 * 1024;

  /// tombstone 触发压缩的 event_id 数量阈值
  /// 默认 200：每积累 200 条已上报 ID 就压缩一次主缓存文件
  static int tombstoneCompactionThreshold = 200;

  /// tombstone 缓存文件名
  static String tombstoneFileName = 'data_plus_events_tombstone.txt';

  // ==================== 请求大小限制 ====================

  /// JSON 最大大小限制（5MB）
  static int maxJsonSize = 5 * 1024 * 1024; // 5MB

  /// 单条事件最大字节数限制，超过则丢弃（300KB）
  static int maxSingleEventSize = 300 * 1024; // 300KB

  /// 配置接口响应体最大字节数限制（1MB），防止恶意/异常服务器返回超大数据导致 OOM
  static int maxConfigResponseSize = 1 * 1024 * 1024; // 1MB

  // ==================== 容量配置 ====================

  /// 页面栈最大容量
  static int maxPageStackSize = 100;

  /// 广告去重最大容量
  static int maxAdImpressionCapacity = 10000;

  // ==================== 配置方法 ====================

  /// 配置所有 SDK 参数
  ///
  /// 示例：
  /// ```dart
  /// SdkConfig.configure(
  ///   maxQueueSize: 20000,
  ///   uploadInterval: Duration(seconds: 30),
  ///   connectionTimeout: Duration(seconds: 15),
  /// );
  /// ```
  static void configure({
    int? maxQueueSize,
    int? autoUploadThreshold,
    int? maxBatchSize,
    int? isolateEncodingThreshold,
    Duration? uploadInterval,
    Duration? pageLoadTimeout,
    Duration? clickThrottleDuration,
    Duration? connectionTimeout,
    Duration? readTimeout,
    Duration? speedTestTimeout,
    Duration? configRequestTimeout,
    int? maxBackoffLevel,
    Duration? baseRetryDelay,
    Duration? maxRetryDelay,
    String? cacheFileName,
    String? eventTypeConfigCacheFileName,
    String? domainCacheFileName,
    int? maxCacheLines,
    int? maxCacheBytes,
    int? maxJsonSize,
    int? maxSingleEventSize,
    int? maxPageStackSize,
    int? maxAdImpressionCapacity,
  }) {
    if (maxQueueSize != null && maxQueueSize > 0) {
      SdkConfig.maxQueueSize = maxQueueSize;
    }
    if (autoUploadThreshold != null && autoUploadThreshold > 0) {
      SdkConfig.autoUploadThreshold = autoUploadThreshold;
    }
    if (maxBatchSize != null && maxBatchSize > 0) {
      SdkConfig.maxBatchSize = maxBatchSize;
    }
    if (isolateEncodingThreshold != null && isolateEncodingThreshold > 0) {
      SdkConfig.isolateEncodingThreshold = isolateEncodingThreshold;
    }
    if (uploadInterval != null) {
      SdkConfig.uploadInterval = uploadInterval;
    }
    if (pageLoadTimeout != null) {
      SdkConfig.pageLoadTimeout = pageLoadTimeout;
    }
    if (clickThrottleDuration != null) {
      SdkConfig.clickThrottleDuration = clickThrottleDuration;
    }
    if (connectionTimeout != null) {
      SdkConfig.connectionTimeout = connectionTimeout;
    }
    if (readTimeout != null) {
      SdkConfig.readTimeout = readTimeout;
    }
    if (speedTestTimeout != null) {
      SdkConfig.speedTestTimeout = speedTestTimeout;
    }
    if (configRequestTimeout != null) {
      SdkConfig.configRequestTimeout = configRequestTimeout;
    }
    if (maxBackoffLevel != null && maxBackoffLevel >= 0) {
      SdkConfig.maxBackoffLevel = maxBackoffLevel;
    }
    if (baseRetryDelay != null) {
      SdkConfig.baseRetryDelay = baseRetryDelay;
    }
    if (maxRetryDelay != null) {
      SdkConfig.maxRetryDelay = maxRetryDelay;
    }
    if (cacheFileName != null && cacheFileName.isNotEmpty && !cacheFileName.contains('/') && !cacheFileName.contains('\\') && !cacheFileName.contains('..')) {
      SdkConfig.cacheFileName = cacheFileName;
    }
    if (eventTypeConfigCacheFileName != null &&
        eventTypeConfigCacheFileName.isNotEmpty && !eventTypeConfigCacheFileName.contains('/') && !eventTypeConfigCacheFileName.contains('\\') && !eventTypeConfigCacheFileName.contains('..')) {
      SdkConfig.eventTypeConfigCacheFileName = eventTypeConfigCacheFileName;
    }
    if (domainCacheFileName != null &&
        domainCacheFileName.isNotEmpty && !domainCacheFileName.contains('/') && !domainCacheFileName.contains('\\') && !domainCacheFileName.contains('..')) {
      SdkConfig.domainCacheFileName = domainCacheFileName;
    }
    if (maxCacheLines != null && maxCacheLines > 0) {
      SdkConfig.maxCacheLines = maxCacheLines;
    }
    if (maxCacheBytes != null && maxCacheBytes > 0) {
      SdkConfig.maxCacheBytes = maxCacheBytes;
    }
    if (maxJsonSize != null && maxJsonSize > 0) {
      SdkConfig.maxJsonSize = maxJsonSize;
    }
    if (maxSingleEventSize != null && maxSingleEventSize > 0) {
      SdkConfig.maxSingleEventSize = maxSingleEventSize;
    }
    if (maxPageStackSize != null && maxPageStackSize > 0) {
      SdkConfig.maxPageStackSize = maxPageStackSize;
    }
    if (maxAdImpressionCapacity != null && maxAdImpressionCapacity > 0) {
      SdkConfig.maxAdImpressionCapacity = maxAdImpressionCapacity;
    }
  }

  /// 重置所有配置为默认值
  static void reset() {
    maxQueueSize = 5000;
    autoUploadThreshold = 10;
    maxBatchSize = 500;
    isolateEncodingThreshold = 100;
    uploadInterval = const Duration(seconds: 5);
    pageLoadTimeout = const Duration(seconds: 5);
    clickThrottleDuration = const Duration(milliseconds: 300);
    connectionTimeout = const Duration(seconds: 10);
    readTimeout = const Duration(seconds: 30);
    speedTestTimeout = const Duration(seconds: 5);
    configRequestTimeout = const Duration(seconds: 10);
    maxBackoffLevel = 5;
    baseRetryDelay = const Duration(seconds: 2);
    maxRetryDelay = const Duration(seconds: 60);
    cacheFileName = 'data_plus_events_cache.jsonl';
    eventTypeConfigCacheFileName = 'analytics_event_types_config.json';
    domainCacheFileName = 'data_plus_domains_cache.json';
    maxCacheLines = 2000;
    maxCacheBytes = 2 * 1024 * 1024;
    tombstoneCompactionThreshold = 200;
    tombstoneFileName = 'data_plus_events_tombstone.txt';
    maxJsonSize = 5 * 1024 * 1024;
    maxSingleEventSize = 300 * 1024;
    maxPageStackSize = 100;
    maxAdImpressionCapacity = 10000;
  }
}
