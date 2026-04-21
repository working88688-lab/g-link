import 'dart:async';
import 'dart:convert';

export 'widget/analytics_debug_banner.dart';
export 'entity/analytics_tab.dart';
export 'extension/tab_analytics_extension.dart';

import 'package:analytics_sdk/config/api_config.dart';
import 'package:analytics_sdk/config/sdk_config.dart';
import 'package:analytics_sdk/entity/ad_impression_event.dart';
import 'package:analytics_sdk/entity/analytics_utils.dart';
import 'package:analytics_sdk/enum/user_type_enum.dart';
import 'package:analytics_sdk/manager/ad_impression_manager.dart';
import 'package:analytics_sdk/manager/event_processor.dart';
import 'package:analytics_sdk/manager/user_manager.dart';
import 'package:analytics_sdk/manager/domain_manager.dart';
import 'package:analytics_sdk/manager/event_type_config_manager.dart';
import 'package:analytics_sdk/manager/session_manager.dart';
import 'package:analytics_sdk/observer/app_lifecycle_observer.dart';
import 'package:analytics_sdk/observer/page_lifecycle_observer.dart';
import 'package:analytics_sdk/utils/aes_gcm_util.dart';
import 'package:analytics_sdk/utils/device_fingerprint_util.dart';
import 'package:analytics_sdk/utils/device_info_util.dart';
import 'package:analytics_sdk/utils/event_validator.dart';
import 'package:analytics_sdk/utils/logger.dart';
import 'package:analytics_sdk/utils/widget_bridge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AnalyticsSdk {
  static final AnalyticsSdk instance = AnalyticsSdk._internal();

  factory AnalyticsSdk() => instance;

  AnalyticsSdk._internal();

  final EventProcessor _eventProcessor = EventProcessor();

  late final PageLifecycleObserver _pageObserver = PageLifecycleObserver(
    track: track,
    getUserType: () => AnalyticsSdk.userTypeProvider(),
    onPageExit: (pageKey) => AdImpressionManager.instance.clearPage(pageKey),
  );

  static bool _enableDebugBanner = false;

  /// 是否启用调试条（供 AnalyticsDebugBanner 读取）
  static bool get enableDebugBanner => _enableDebugBanner;

  /// 防止 init() 并发调用（异步挂起期间重复调用时直接跳过）
  bool _isInitializing = false;

  // ==================== 初始化 ====================

  /// 初始化 SDK。
  ///
  /// 本方法永远不会抛出异常，即使初始化失败也不影响应用运行。
  ///
  /// **参数说明**
  ///
  /// - [appId]：应用 ID（必填）
  /// - [channel]：渠道标识，可在初始化后通过 [setChannel] 更新
  /// - [uid]：用户 ID，未登录时可传空，登录后通过 [setUserIdAndType] 或 [setUid] 更新
  /// - [deviceId]：设备唯一标识（如 Android IMEI/OAID、iOS IDFV），不传时留空
  /// - [appVersion]：应用版本号，格式 `1.0.0`，由接入方传入，可不传
  /// - [encryptedConfig]：加密配置字符串（Base64 编码 AES 密文），解密后为
  ///   `{"domainList":["https://..."],"eventList":["event_type",...]}` 格式，可选
  ///
  /// device、deviceBrand、deviceModel、userAgent、systemName、systemVersion
  /// 由 SDK 内部通过 device_info_plus 自动检测，无需外部传入。
  Future<void> init({
    required String appId,
    required String? encryptedConfig,
    String? channel,
    String? uid,
    required String deviceId,
    String? appVersion,
    bool enableDebugBanner = false,
  }) async {
    if (_isInitializing) {
      Logger.analyticsSdk('init() 正在进行中，跳过重复调用');
      return;
    }
    _isInitializing = true;
    try {
      _enableDebugBanner = !kReleaseMode && enableDebugBanner;
      WidgetBridge.register(
        track: track,
        enableDebugBanner: _enableDebugBanner,
        getDebugSteps: getDebugSteps,
      );

      _eventProcessor.stopAutoUploadTimer();
      _eventProcessor.resetState();

      await DeviceInfoUtil.initialize();

      final device = DeviceInfoUtil.deviceType;
      final deviceBrand = DeviceInfoUtil.deviceBrand;
      final deviceModel = DeviceInfoUtil.deviceModel;
      final userAgent = DeviceInfoUtil.userAgent;
      final systemName = DeviceInfoUtil.systemName;
      final systemVersion = DeviceInfoUtil.systemVersion;

      AnalyticsUtils.configure(
        appId: appId,
        channel: channel,
        uid: uid,
        appVersion: appVersion,
        device: device,
        deviceId: deviceId,
        deviceBrand: deviceBrand,
        deviceModel: deviceModel,
        userAgent: userAgent,
        systemName: systemName,
        systemVersion: systemVersion,
      );

      Logger.analyticsSdk('响应解密已启用（使用内置密钥）');

      // re-init 时先重置会话，确保新一轮初始化生成新 session
      SessionManager.instance.reset();
      SessionManager.instance.initialize();
      AppLifecycleObserver.instance.initialize();

      // 初始化设备指纹
      await _initDeviceFingerprint(
        deviceId: deviceId,
        device: device,
        deviceBrand: deviceBrand,
        deviceModel: deviceModel,
        systemName: systemName,
        systemVersion: systemVersion,
        userAgent: userAgent,
      );

      await _applyEncryptedConfig(encryptedConfig: encryptedConfig);

      try {
        await _eventProcessor.initPersistence();
      } catch (e) {
        Logger.analyticsSdk('持久化初始化失败，继续运行: $e');
      }

      try {
        await _eventProcessor.loadCachedEvents();
      } catch (e) {
        Logger.analyticsSdk('缓存加载失败，继续运行: $e');
      }

      _eventProcessor.startAutoUploadTimer();
    } catch (e) {
      Logger.analyticsSdk('初始化异常: $e');
    } finally {
      _isInitializing = false;
    }
  }

  // ==================== UID / Channel 设置 ====================

  /// 更新用户 ID 和用户类型（登录、切换账号时调用）。
  ///
  /// [userId] 为空时表示未登录状态。
  /// 本方法永远不会抛出异常。
  static void setUserIdAndType(
      {String userId = '', UserTypeEnum? userTypeEnum}) {
    try {
      AnalyticsUtils.setUid(userId);
      UserManager.instance.updateUserType(userTypeEnum == null
          ? UserTypeEnum.normal.label
          : userTypeEnum.label);
      Logger.analyticsSdk('用户ID已更新为: $userId');
    } catch (e) {
      Logger.analyticsSdk('设置用户信息失败: $e');
    }
  }

  /// 单独更新用户 ID（不影响用户类型）。
  ///
  /// 适用于已知 userType 无变化、只需更新 uid 的场景（如静默登录）。
  /// 本方法永远不会抛出异常。
  static void setUid(String uid) {
    try {
      AnalyticsUtils.setUid(uid);
      Logger.analyticsSdk('uid 已更新为: $uid');
    } catch (e) {
      Logger.analyticsSdk('setUid 失败: $e');
    }
  }

  /// 更新渠道标识（渠道变更时调用，后续事件自动带上最新值）。
  ///
  /// 本方法永远不会抛出异常。
  static void setChannel(String channel) {
    try {
      AnalyticsUtils.setChannel(channel);
      Logger.analyticsSdk('channel 已更新为: $channel');
    } catch (e) {
      Logger.analyticsSdk('setChannel 失败: $e');
    }
  }

  /// 登出：清空 uid 和 userType。
  ///
  /// 本方法永远不会抛出异常。
  static void logoutUser() {
    try {
      AnalyticsUtils.setUid('');
      UserManager.instance.logout();
      Logger.analyticsSdk('用户已登出');
    } catch (e) {
      Logger.analyticsSdk('用户登出失败: $e');
    }
  }

  // ==================== 设备公共字段 ====================

  /// 获取当前设备公共字段（供产品方在服务端上报事件时复用）。
  ///
  /// 返回字段：device、device_id、device_brand、device_model、
  /// user_agent、system_name、system_version、device_fingerprint。
  /// 未配置的字段返回空字符串。
  ///
  /// **注意**：服务端上报事件时还需同步传入 `sid`（会话ID，由客户端生成），
  /// 可通过 `getParams(keys: ['sid'])` 单独获取。
  ///
  /// 本方法永远不会抛出异常。
  static Map<String, String> getDeviceCommonFields() {
    try {
      return AnalyticsUtils.getDeviceCommonFields();
    } catch (e) {
      Logger.analyticsSdk('getDeviceCommonFields 失败: $e');
      return {};
    }
  }

  /// 获取 SDK 当前全部公共参数，或按 [keys] 指定只返回部分参数。
  ///
  /// - 不传 [keys]（或传 null）：返回全部参数
  /// - 传入 key 列表：只返回命中的 key，不存在的 key 会被忽略
  ///
  /// 可用 key：`app_id` `channel` `uid` `user_type` `sid`
  /// `device` `device_id` `device_brand` `device_model`
  /// `user_agent` `system_name` `system_version`
  /// `device_fingerprint` `fp_version` `sdk_version` `app_version`
  ///
  /// `sid` 为客户端 SDK 自动生成的会话ID，服务端上报事件时需将其一并回传，
  /// 以确保服务端事件与客户端事件归属同一会话。
  ///
  /// 本方法永远不会抛出异常。
  static Map<String, dynamic> getParams([List<String>? keys]) {
    try {
      final all = <String, dynamic>{
        'app_id': AnalyticsUtils.appId ?? '',
        'channel': AnalyticsUtils.channel ?? '',
        'uid': AnalyticsUtils.uid ?? '',
        'user_type': UserManager.instance.userType,
        'sid': SessionManager.instance.currentSessionId ?? '',
        'sdk_version': AnalyticsUtils.kSdkVersion,
        'app_version': AnalyticsUtils.appVersion ?? AnalyticsUtils.kDefaultAppVersion,
        ...AnalyticsUtils.getDeviceCommonFields(),
      };
      if (keys == null || keys.isEmpty) return all;
      return {
        for (final k in keys)
          if (all.containsKey(k)) k: all[k]
      };
    } catch (e) {
      Logger.analyticsSdk('getParams 失败: $e');
      return {};
    }
  }

  // ==================== 上报 ====================

  NavigatorObserver get pageObserver => _pageObserver;

  /// 手动上报任意事件（事件对象必须有 toJson() 方法）。
  ///
  /// 本方法永远不会抛出异常，即使事件无效也不影响应用运行。
  void track(dynamic event) {
    try {
      if (event == null) {
        Logger.analyticsSdk('事件为 null，跳过');
        return;
      }

      final adResult = _deduplicateAdImpression(event);
      if (adResult == null) return;
      event = adResult.processedEvent;

      final json = _serializeEvent(event);
      if (json == null) return;

      final validated = _validateEvent(json);
      if (validated == null) return;

      if (!_checkEventSize(validated)) return;
      if (!_isEventTypeEnabled(validated)) return;

      final accepted = _eventProcessor.enqueueEvent(validated);

      if (accepted &&
          adResult.adsToMark != null &&
          adResult.adsToMark!.isNotEmpty) {
        try {
          AdImpressionManager.instance.markAsReportedBatch(adResult.adsToMark!, pageKey: adResult.pageKey);
        } catch (e) {
          Logger.analyticsSdk('标记广告ID为已上报失败: $e');
        }
      }
    } catch (e) {
      Logger.analyticsSdk('track() 发生异常，已安全处理: $e');
    }
  }

  /// 强制立即上报。
  ///
  /// 本方法永远不会抛出异常。
  Future<void> flush() async {
    try {
      await _eventProcessor.flush();
    } catch (e) {
      Logger.analyticsSdk('flush() 发生异常，已安全处理: $e');
    }
  }

  /// 清理 SDK 资源（先尝试上报剩余事件，再释放资源）。
  ///
  /// 本方法永远不会抛出异常。
  Future<void> dispose() async {
    try {
      try {
        await flush();
      } catch (e) {
        Logger.analyticsSdk('dispose() 时上报失败: $e');
      }

      await _eventProcessor.disposeAsync();

      try {
        DomainManager.instance.dispose();
      } catch (e) {
        Logger.analyticsSdk('销毁域名管理器失败: $e');
      }

      try {
        EventTypeConfigManager.instance.dispose();
      } catch (e) {
        Logger.analyticsSdk('销毁事件类型配置管理器失败: $e');
      }

      try {
        AppLifecycleObserver.instance.dispose();
      } catch (e) {
        Logger.analyticsSdk('销毁应用生命周期观察者失败: $e');
      }

      try {
        _pageObserver.dispose();
      } catch (e) {
        Logger.analyticsSdk('销毁页面生命周期观察者失败: $e');
      }
    } catch (e) {
      Logger.analyticsSdk('dispose() 发生异常: $e');
    }
  }

  // ==================== 调试 ====================

  /// 更新用户类型（登录、升级会员、切换账号时调用）。
  ///
  /// 本方法永远不会抛出异常。
  void updateUserType(String newType) {
    try {
      UserManager.instance.updateUserType(newType);
    } catch (e) {
      Logger.analyticsSdk('更新用户类型失败: $e');
    }
  }

  /// 在 init() 之后、需要更新配置时调用。
  ///
  /// [encryptedConfig] 格式与 init() 中的同名参数一致。
  /// 本方法永远不会抛出异常。
  Future<void> refreshDomainConfig({
    String? encryptedConfig,
  }) async {
    try {
      if (encryptedConfig == null || encryptedConfig.isEmpty) {
        Logger.analyticsSdk('refreshDomainConfig encryptedConfig 为空，忽略本次刷新',
            level: LogLevel.warn);
        return;
      }
      await _applyEncryptedConfig(encryptedConfig: encryptedConfig);
    } catch (e) {
      Logger.analyticsSdk('refreshDomainConfig 异常: $e', level: LogLevel.warn);
    }
  }

  /// 测试包用：获取埋点调试信息
  Map<String, String> getDebugInfo() {
    try {
      final steps = getDebugSteps();
      final lastStep = steps.isNotEmpty ? steps.last : <String, String>{};
      return {
        'inited': steps.isNotEmpty && steps.length >= 2
            ? steps[1]['status'] ?? '未知'
            : '未知',
        'queueLength': '${_eventProcessor.queueLength}',
        'reportUrl': _eventProcessor.debugReportUrl != null
            ? (_eventProcessor.debugReportUrl!.length > 40
                ? '${_eventProcessor.debugReportUrl!.substring(0, 40)}...'
                : _eventProcessor.debugReportUrl!)
            : '未配置',
        'lastStep': lastStep['name'] ?? '',
        'lastStatus': lastStep['status'] ?? '',
      };
    } catch (e) {
      Logger.analyticsSdk('getDebugInfo 异常，已安全处理: $e', level: LogLevel.warn);
      return {};
    }
  }

  /// 测试包用：获取埋点流程步骤
  List<Map<String, String>> getDebugSteps() {
    try {
      final dm = DomainManager.instance;
      final ep = _eventProcessor;
      final steps = <Map<String, String>>[];

      final hasDomains = dm.reportDomains.isNotEmpty;
      steps.add({
        'name': '①域名配置',
        'status': hasDomains ? '✓已配置' : '✗未配置',
        'detail': hasDomains ? '由业务方传入' : '未传入 encryptedConfig',
      });

      final appIdOk =
          AnalyticsUtils.appId != null && AnalyticsUtils.appId!.isNotEmpty;
      steps.add({
        'name': '②SDK初始化',
        'status': appIdOk ? '✓已初始化' : '✗未初始化',
        'detail': appIdOk ? 'appId已设置' : '-',
      });

      final domains = dm.reportDomains;
      steps.add({
        'name': '③域名列表',
        'status': domains.isEmpty
            ? (appIdOk ? '✗未配置或测速中' : '-')
            : '✓已配置(${domains.length}个)',
        'detail': domains.isEmpty ? '-' : domains.join(','),
      });

      final fastest = dm.fastestDomain;
      String speedStatus;
      if (fastest != null && fastest.isNotEmpty) {
        speedStatus = '✓已选';
      } else if (domains.isNotEmpty) {
        speedStatus = '✗测速失败或进行中';
      } else {
        speedStatus = '-';
      }
      steps.add({
        'name': '④域名测速',
        'status': speedStatus,
        'detail': fastest ?? '-',
      });

      final hasUrl = ep.debugReportUrl != null && ep.debugReportUrl!.isNotEmpty;
      String urlDetail = '-';
      if (hasUrl && ep.debugReportUrl != null) {
        try {
          final uri = Uri.parse(ep.debugReportUrl!);
          urlDetail = '${uri.host}${uri.path}';
        } catch (_) {
          urlDetail = '已配置';
        }
      }
      steps.add({
        'name': '⑤上报地址',
        'status': hasUrl ? '✓已就绪' : '✗未就绪',
        'detail': urlDetail,
      });

      steps.add({
        'name': '⑥待上报队列',
        'status': '${ep.queueLength}条',
        'detail': ep.queueLength > 0 ? '有事件待上报' : '空',
      });

      String uploadStatus;
      String uploadDetail = '-';
      if (ep.lastUploadTime == null) {
        uploadStatus = '未尝试';
      } else if (ep.lastUploadSuccess == true) {
        uploadStatus = '✓成功';
        uploadDetail = _formatTime(ep.lastUploadTime);
      } else {
        uploadStatus = '✗失败';
        uploadDetail = ep.lastUploadError ?? '未知';
      }
      steps.add({
        'name': '⑦最近上报',
        'status': uploadStatus,
        'detail': uploadDetail,
      });

      return steps;
    } catch (e) {
      Logger.analyticsSdk('getDebugSteps 异常，已安全处理: $e', level: LogLevel.warn);
      return [];
    }
  }

  /// 验证加密配置字符串格式（仅 debug 包可用）
  ///
  /// 支持以下解密后格式：
  /// - JSON 数组：`["https://api.example.com", ...]`（域名列表或事件类型列表）
  /// - JSON 对象含 `domainList`：`{"domainList":[...]}`
  /// - JSON 对象含 `eventList`：`{"eventList":[...]}`
  /// - JSON 对象含 `enabled_event_types`：`{"enabled_event_types":[...]}`
  Map<String, dynamic> validateEncryptedConfig(String ciphertext) {
    if (kReleaseMode) {
      return {'success': false, 'preview': null, 'error': 'release 包不可用'};
    }
    try {
      final plaintext = AesGcmUtil.decryptResponseAuto(ciphertext);
      final raw = jsonDecode(plaintext);

      // 纯 JSON 数组：域名列表或事件类型列表
      if (raw is List) {
        if (raw.isNotEmpty) {
          return {
            'success': true,
            'preview': raw[0].toString(),
            'count': raw.length,
            'error': null,
          };
        }
        final preview =
            plaintext.length > 60 ? plaintext.substring(0, 60) : plaintext;
        return {
          'success': false,
          'preview': preview,
          'error': '解密成功但列表为空（0 个元素），请检查配置',
        };
      }

      if (raw is! Map<String, dynamic>) {
        return {
          'success': false,
          'preview':
              plaintext.length > 60 ? plaintext.substring(0, 60) : plaintext,
          'error': '解密成功但格式错误：应为 JSON 数组或对象，实际为 ${raw.runtimeType}',
        };
      }

      // JSON 对象：检查已知 key
      final decoded = raw;
      List? items;
      if (decoded['domainList'] is List) {
        items = decoded['domainList'] as List;
      } else if (decoded['eventList'] is List) {
        items = decoded['eventList'] as List;
      } else if (decoded['enabled_event_types'] is List) {
        items = decoded['enabled_event_types'] as List;
      }

      if (items != null && items.isNotEmpty) {
        return {
          'success': true,
          'preview': items[0].toString(),
          'count': items.length,
          'error': null,
        };
      }

      final preview =
          plaintext.length > 60 ? plaintext.substring(0, 60) : plaintext;
      return {
        'success': false,
        'preview': preview,
        'error': '解密成功但格式无法识别（0 个元素），请检查 JSON 格式',
      };
    } catch (e) {
      return {'success': false, 'preview': null, 'error': '解密失败: $e'};
    }
  }

  // ==================== 私有方法 ====================

  static String _formatTime(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  /// 用户类型提供者
  static String Function() userTypeProvider =
      () => UserManager.instance.userType;

  /// 初始化设备指纹并写入公共字段
  Future<void> _initDeviceFingerprint({
    String deviceId = '',
    String device = '',
    String deviceBrand = '',
    String deviceModel = '',
    String systemName = '',
    String systemVersion = '',
    String userAgent = '',
  }) async {
    try {
      // 每次 init() 强制重新计算指纹，防止 re-init 时使用旧设备参数的缓存值
      DeviceFingerprintUtil.clearCache();
      final fp = await DeviceFingerprintUtil.getFingerprint(
        deviceId: deviceId,
        device: device,
        deviceBrand: deviceBrand,
        deviceModel: deviceModel,
        systemName: systemName,
        systemVersion: systemVersion,
        userAgent: userAgent,
      );
      AnalyticsUtils.configure(
        deviceFingerprint: fp,
        fingerprintVersion: DeviceFingerprintUtil.kVersion,
      );
      Logger.analyticsSdk(
          '设备指纹已初始化: ${fp.isEmpty ? "(空)" : fp}，规则版本: ${DeviceFingerprintUtil.kVersion}');
    } catch (e) {
      Logger.analyticsSdk('设备指纹初始化失败，device_fingerprint 将为空: $e');
    }
  }

  /// 解密并应用域名配置与事件类型配置（供 init() 和 refreshDomainConfig() 复用）
  ///
  /// [encryptedConfig] 解密后格式：`{"domainList":[...],"eventList":[...]}`
  Future<void> _applyEncryptedConfig({String? encryptedConfig}) async {
    final appId = AnalyticsUtils.appId ?? '';

    if (encryptedConfig != null && encryptedConfig.isNotEmpty) {
      DomainManager.instance.reset();

      // ── 阶段 1：域名配置（独立 try-catch，异常不影响阶段 2）──────────────
      List<String>? parsedEventList;
      try {
        final plaintext = AesGcmUtil.decryptResponseAuto(encryptedConfig);
        final raw = jsonDecode(plaintext);

        // 纯 JSON 数组：直接作为域名列表处理，不含 eventList
        if (raw is List) {
          final domains = (raw as List)
              .map<String>((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
          if (domains.isNotEmpty) {
            _startSpeedTest(domains, appId);
          } else {
            Logger.analyticsSdk('encryptedConfig 解析结果为空数组，尝试加载本地缓存',
                level: LogLevel.warn);
            await _applyDomainCache(appId);
          }
          // 纯数组格式不含 eventList，parsedEventList 保持 null（走缓存）
        } else if (raw is! Map<String, dynamic>) {
          Logger.analyticsSdk(
              'encryptedConfig 解析格式异常：期望 Map，实际 ${raw.runtimeType}，尝试加载本地缓存',
              level: LogLevel.warn);
          await _applyDomainCache(appId);
          // parsedEventList 保持 null，走缓存逻辑（阶段 2 处理）
        } else {
          final decoded = raw;

          // 解析 domainList
          final rawDomains = decoded['domainList'];
          final domains = rawDomains is List
              ? (rawDomains as List)
                  .map<String>((e) => e.toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
              : <String>[];

          if (domains.isNotEmpty) {
            _startSpeedTest(domains, appId);
          } else {
            Logger.analyticsSdk('domainList 解析结果为空，尝试加载本地缓存',
                level: LogLevel.warn);
            await _applyDomainCache(appId);
          }

          // 捕获 eventList 供阶段 2 使用
          final rawEvents =
              decoded['eventList'] ?? decoded['enabled_event_types'];
          if (rawEvents is List && rawEvents.isNotEmpty) {
            parsedEventList = rawEvents.map((e) => e.toString()).toList();
          }
        }
      } catch (e) {
        Logger.analyticsSdk('encryptedConfig 解密/解析失败: $e，尝试加载本地缓存',
            level: LogLevel.warn);
        await _applyDomainCache(appId);
      }

      // ── 阶段 2：事件类型配置（独立 try-catch，异常不触发第二轮测速）──────
      try {
        if (parsedEventList != null) {
          await EventTypeConfigManager.instance
              .initWithConfig(jsonEncode(parsedEventList));
        } else {
          Logger.analyticsSdk('eventList 解析结果为空，尝试加载本地缓存',
              level: LogLevel.warn);
          await EventTypeConfigManager.instance.loadCachedConfig();
        }
      } catch (e) {
        Logger.analyticsSdk('eventList 初始化失败: $e，尝试加载本地缓存',
            level: LogLevel.warn);
        await EventTypeConfigManager.instance.loadCachedConfig();
      }
    } else {
      Logger.analyticsSdk('encryptedConfig 未传入，尝试加载本地缓存', level: LogLevel.warn);
      await _applyDomainCache(appId);
      await EventTypeConfigManager.instance.loadCachedConfig();
    }
  }

  Future<void> _applyDomainCache(String appId) async {
    try {
      final cachedDomains = await DomainManager.instance.loadCachedDomains();
      if (cachedDomains.isNotEmpty) {
        Logger.analyticsSdk('使用缓存域名降级: $cachedDomains');
        _startSpeedTest(cachedDomains, appId);
      } else {
        Logger.analyticsSdk(
            '无可用域名缓存，上报 URL 保持未配置，事件将在 refreshDomainConfig() 后上报',
            level: LogLevel.warn);
      }
    } catch (e) {
      Logger.analyticsSdk('加载域名缓存失败: $e', level: LogLevel.warn);
    }
  }

  /// 设置域名测速回调并启动测速（fire-and-forget）
  void _startSpeedTest(List<String> domains, String appId) {
    DomainManager.instance.onFastestDomainChanged = (fastest) {
      try {
        if (fastest != null && fastest.isNotEmpty) {
          final url = ApiConfig.getReportUrl(fastest, appId: appId);
          _eventProcessor.updateReportUrl(url);
          Logger.analyticsSdk('域名测速完成，已更新上报URL: $url');
        }
      } catch (e) {
        Logger.analyticsSdk('_startSpeedTest 回调异常，已安全处理: $e', level: LogLevel.warn);
      }
    };
    DomainManager.instance.initWithDomains(domains);
  }

  // ==================== track() 私有辅助方法 ====================

  /// 广告展示事件去重处理。
  ///
  /// 返回 null 表示该事件全部 adId 均已上报，应跳过。
  /// 返回 [_AdDedupeResult] 时，[_AdDedupeResult.processedEvent] 为（可能经过过滤的）最终事件，
  /// [_AdDedupeResult.adsToMark] 为入队成功后需标记的 adId 字符串，非广告事件时为 null。
  _AdDedupeResult? _deduplicateAdImpression(dynamic event) {
    if (event is! AdImpressionEvent) {
      return _AdDedupeResult(event, null);
    }
    final AdImpressionEvent adEvent = event;
    try {
      final unreportedAdIds = _getUnreportedAdIds(adEvent);
      // null → _getUnreportedAdIds 内部异常，降级不去重
      // [] → 全部已上报，跳过
      if (unreportedAdIds != null && unreportedAdIds.isEmpty) {
        Logger.analyticsSdk('广告展示事件已上报，跳过: ${adEvent.adId}');
        return null;
      }
      if (unreportedAdIds != null) {
        final originalAdIdsCount = adEvent.adId
            .split(',')
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .length;
        // unreportedAdIds == null 时已降级（不去重），直接上报完整事件
        if (unreportedAdIds.length < originalAdIdsCount) {
          final filtered =
              _createAdImpressionEventWithFilteredIds(adEvent, unreportedAdIds);
          Logger.analyticsSdk(
              '广告展示事件已过滤: 原始${originalAdIdsCount}个ID，只上报${unreportedAdIds.length}个未上报的ID: ${filtered.adId}');
          return _AdDedupeResult(filtered, filtered.adId, filtered.pageKey);
        }
      }
      return _AdDedupeResult(adEvent, adEvent.adId, adEvent.pageKey);
    } catch (e) {
      Logger.analyticsSdk('广告去重检查异常，跳过去重: $e');
      return _AdDedupeResult(adEvent, adEvent.adId, adEvent.pageKey);
    }
  }

  /// 将事件对象序列化为 JSON Map。
  ///
  /// 返回 null 表示序列化失败，应丢弃事件。
  Map<String, dynamic>? _serializeEvent(dynamic event) {
    try {
      final json = event is Map<String, dynamic> ? event : event.toJson();
      if (json == null) {
        Logger.analyticsSdk('事件 toJson() 返回 null，跳过');
        return null;
      }
      return json;
    } catch (e) {
      Logger.analyticsSdk('事件序列化失败，跳过: $e');
      return null;
    }
  }

  /// 校验事件字段（关键字段异常时丢弃，非关键字段自动纠正）。
  ///
  /// 返回 null 表示校验不通过，应丢弃事件。
  Map<String, dynamic>? _validateEvent(Map<String, dynamic> json) {
    final validated = EventValidator.validate(json);
    if (validated == null) {
      Logger.analyticsSdk('事件校验不通过，已丢弃: ${json['event']}',
          level: LogLevel.warn);
    }
    return validated;
  }

  /// 检查单条事件大小，超限则丢弃。
  ///
  /// 返回 false 表示超限应丢弃，返回 true 表示通过（含检查本身异常时降级通过）。
  bool _checkEventSize(Map<String, dynamic> json) {
    try {
      final encoded = jsonEncode(json);
      final sizeBytes = utf8.encode(encoded).length;
      if (sizeBytes > SdkConfig.maxSingleEventSize) {
        final sizeKB = (sizeBytes / 1024).toStringAsFixed(1);
        final limitKB =
            (SdkConfig.maxSingleEventSize / 1024).toStringAsFixed(0);
        Logger.analyticsSdk(
            '事件过大 (${sizeKB}KB > ${limitKB}KB 限制)，丢弃。event=${json['event']}',
            level: LogLevel.warn);
        return false;
      }
      return true;
    } catch (e) {
      Logger.analyticsSdk('事件大小检查失败，继续上报: $e');
      return true;
    }
  }

  /// 检查事件类型是否在配置中启用。
  ///
  /// 返回 false 表示未启用应跳过，返回 true 表示通过（含检查本身异常时降级通过）。
  bool _isEventTypeEnabled(Map<String, dynamic> json) {
    try {
      final eventType = json['event'] as String?;
      if (eventType != null &&
          !EventTypeConfigManager.instance.isEventTypeEnabled(eventType)) {
        Logger.analyticsSdk('事件类型 $eventType 未在配置中启用，跳过上报');
        return false;
      }
      return true;
    } catch (e) {
      Logger.analyticsSdk('事件类型检查失败，继续上报: $e');
      return true;
    }
  }

  List<String>? _getUnreportedAdIds(AdImpressionEvent event) {
    try {
      if (event.adId.isEmpty) return null;
      final trimmedAdId = event.adId.trim();
      if (trimmedAdId.isEmpty) return null;
      // 直接返回 AdImpressionManager 的结果：
      //   [] → 全部已上报，外层代码会跳过事件
      //   非空列表 → 未上报的 ID，正常上报
      // null 只在异常时由 catch 返回，表示降级继续上报
      return AdImpressionManager.instance.getUnreportedAdIds(trimmedAdId, pageKey: event.pageKey);
    } catch (e) {
      Logger.analyticsSdk('广告去重检查异常，跳过: $e');
      return null;
    }
  }

  AdImpressionEvent _createAdImpressionEventWithFilteredIds(
      AdImpressionEvent originalEvent, List<String> unreportedIds) {
    try {
      final originalAdIds = originalEvent.adId
          .split(',')
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList();

      List<String>? originalCreativeIds;
      if (originalEvent.creativeId.isNotEmpty) {
        originalCreativeIds = originalEvent.creativeId
            .split(',')
            .map((id) => id.trim())
            .toList();
      }

      final filteredAdIds = <String>[];
      final filteredCreativeIds = <String>[];

      for (int i = 0; i < originalAdIds.length; i++) {
        if (unreportedIds.contains(originalAdIds[i])) {
          filteredAdIds.add(originalAdIds[i]);
          if (originalCreativeIds != null && i < originalCreativeIds.length) {
            filteredCreativeIds.add(originalCreativeIds[i]);
          } else {
            filteredCreativeIds.add('');
          }
        }
      }

      return AdImpressionEvent(
        pageKey: originalEvent.pageKey,
        pageName: originalEvent.pageName,
        adSlotKey: originalEvent.adSlotKey,
        adSlotName: originalEvent.adSlotName,
        adId: filteredAdIds.join(','),
        creativeId: originalEvent.creativeId.isNotEmpty
            ? filteredCreativeIds.join(',')
            : "",
        adType: originalEvent.adType,
      );
    } catch (e) {
      Logger.analyticsSdk('创建过滤后的广告事件失败，使用原始事件: $e');
      return originalEvent;
    }
  }
}

/// 广告展示去重结果（仅在 [AnalyticsSdk] 内部使用）
class _AdDedupeResult {
  /// 经过去重处理后的事件（可能是过滤了部分 adId 的 [AdImpressionEvent]，或原始事件）
  final dynamic processedEvent;

  /// 成功入队后需要标记为已上报的 adId 字符串；非广告展示事件时为 null
  final String? adsToMark;

  /// 广告所在页面的 pageKey，用于页面级去重；非广告事件时为空字符串
  final String pageKey;

  const _AdDedupeResult(this.processedEvent, this.adsToMark, [this.pageKey = '']);
}
