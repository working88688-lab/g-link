import 'dart:async';
import 'dart:convert';
import 'package:analytics_sdk/config/sdk_config.dart';
import 'package:analytics_sdk/utils/logger.dart';
import 'package:analytics_sdk/utils/platform_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 域名管理器：对业务方传入的域名列表进行并发测速，选择最快的上报域名
class DomainManager {
  static final DomainManager instance = DomainManager._internal();

  factory DomainManager() => instance;

  DomainManager._internal();

  List<String> _reportDomains = [];
  String? _fastestDomain;

  /// 每次 initWithDomains / reset 时递增，用于丢弃过期测速结果
  int _generation = 0;

  http.Client? _httpClient;
  http.Client get _client => _httpClient ??= http.Client();

  /// 域名更新回调，当最快域名选出后调用
  Function(String? fastestDomain)? onFastestDomainChanged;

  /// 获取最快的上报域名
  String? get fastestDomain => _fastestDomain;

  /// 获取所有上报域名
  List<String> get reportDomains => List.unmodifiable(_reportDomains);

  /// 传入已解密的域名列表，执行并发测速并选出最快域名
  ///
  /// [domains] 每项为带协议的完整域名，如 "https://api.example.com"
  ///
  /// 注意：此方法设计为 fire-and-forget，调用方无需 await，
  /// 测速完成后通过 [onFastestDomainChanged] 回调通知结果。
  Future<String?> initWithDomains(List<String> domains) async {
    // 记录本次调用的代次，测速完成后用于判断结果是否已过期
    final gen = ++_generation;
    try {
      if (domains.isEmpty) {
        Logger.domainManager('域名列表为空，跳过测速', level: LogLevel.warn);
        return null;
      }

      _reportDomains = domains;
      Logger.domainManager('开始域名测速，共 ${domains.length} 个: $domains');

      String? fastest;
      if (domains.length == 1) {
        fastest = domains.first;
        Logger.domainManager('只有一个域名，跳过测速: $fastest');
      } else if (kIsWeb) {
        // Web 端浏览器 CORS 限制会导致所有测速请求被拦截，
        // 等待超时只会延迟 SDK 初始化，直接使用第一个域名。
        fastest = domains.first;
        Logger.domainManager('Web 端跳过测速（CORS 限制），使用第一个域名: $fastest');
      } else {
        fastest = await _speedTestAndSelect(domains);
        Logger.domainManager('测速完成，最快域名: $fastest');
      }

      // 若 reset() 或新一轮 initWithDomains 已被调用，丢弃本次过期结果
      if (gen != _generation) {
        Logger.domainManager('测速结果已过期（generation 不匹配），忽略本次结果');
        return null;
      }

      _fastestDomain = fastest;
      // 测速完成后持久化域名列表（供下次 init 时解密失败时作为降级）
      _saveDomainCache();
      if (onFastestDomainChanged != null && _fastestDomain != null) {
        try {
          onFastestDomainChanged!(_fastestDomain);
        } catch (e) {
          Logger.domainManager('域名更新回调异常: $e');
        }
      }
      return _fastestDomain;
    } catch (e) {
      Logger.domainManager('域名测速失败: $e', level: LogLevel.warn);
      return null;
    }
  }

  /// 重置域名管理器状态，供 re-init 时使用
  ///
  /// 清除内存中的域名列表和最快域名，不关闭 HttpClient（复用连接池）。
  /// 不删除磁盘缓存（缓存代表最近已知可用状态，跨 init 保留）。
  void reset() {
    _generation++;          // 使所有进行中的测速结果失效
    _fastestDomain = null;
    _reportDomains = [];
    onFastestDomainChanged = null;   // 防止旧回调在新一轮测速前残留
    Logger.domainManager('域名管理器状态已重置');
  }

  /// 释放 HttpClient 资源，通常在 SDK dispose 时调用
  void dispose() {
    _httpClient?.close();
    _httpClient = null;
    Logger.domainManager('域名管理器已销毁');
  }

  /// 从磁盘加载上次缓存的域名列表
  ///
  /// 返回非空列表时可直接传入 [initWithDomains]。
  /// 无缓存文件或读取失败时返回空列表（不抛出异常）。
  Future<List<String>> loadCachedDomains() async {
    try {
      final content =
          await PlatformStorage.read(SdkConfig.domainCacheFileName);
      if (content == null) return [];
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return (decoded as List)
            .map<String>((item) => item.toString().trim())
            .where((d) => d.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      Logger.domainManager('加载域名缓存失败: $e');
      return [];
    }
  }

  // ==================== 私有方法 ====================

  /// 将当前 _reportDomains 写入磁盘缓存（fire-and-forget）
  void _saveDomainCache() {
    if (_reportDomains.isEmpty) return;
    final domainsSnapshot = List<String>.from(_reportDomains);
    Future(() async {
      try {
        await PlatformStorage.write(
          SdkConfig.domainCacheFileName,
          jsonEncode(domainsSnapshot),
        );
        Logger.domainManager('域名缓存已写入: $domainsSnapshot');
      } catch (e) {
        Logger.domainManager('写入域名缓存失败: $e');
      }
    });
  }

  /// 对所有域名进行并发测速，返回最快的域名
  Future<String?> _speedTestAndSelect(List<String> domains) async {
    if (domains.isEmpty) return null;

    final speedResults = <String, Duration>{};

    final futures = domains.map((domain) async {
      try {
        final speed = await _speedTest(domain);
        if (speed != null) {
          speedResults[domain] = speed;
          Logger.domainManager('域名 $domain 测速: ${speed.inMilliseconds}ms');
        }
      } catch (e) {
        Logger.domainManager('域名 $domain 测速失败: $e');
      }
    });

    await Future.wait(futures);

    if (speedResults.isEmpty) {
      Logger.domainManager('所有域名测速失败，回退到使用第一个域名作为上报域名',
          level: LogLevel.warn);
      return domains.first;
    }

    final fastest =
        speedResults.entries.reduce((a, b) => a.value < b.value ? a : b);

    Logger.domainManager(
        '最快域名: ${fastest.key} (${fastest.value.inMilliseconds}ms)');
    return fastest.key;
  }

  /// 测速单个域名，返回连接耗时；连接超时或网络异常返回 null
  ///
  /// 仅 HTTP 200 视为可达。
  /// 非 200（3xx 重定向、4xx 客户端错误、5xx 服务端错误）/ 连接失败 / 超时 视为不可达，返回 null。
  Future<Duration?> _speedTest(String domain) async {
    try {
      final uri = Uri.parse(domain);
      final startTime = DateTime.now();
      final response =
          await _client.get(uri).timeout(SdkConfig.speedTestTimeout);
      final elapsed = DateTime.now().difference(startTime);
      if (response.statusCode != 200) {
        Logger.domainManager(
            '域名 $domain 返回 ${response.statusCode}，视为不可达',
            level: LogLevel.warn);
        return null;
      }
      Logger.domainManager(
          '域名 $domain 可达，状态码: ${response.statusCode}');
      return elapsed;
    } catch (_) {
      return null;
    }
  }
}
