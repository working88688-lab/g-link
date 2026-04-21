import 'dart:convert';

import 'package:analytics_sdk/utils/device_fingerprint_util.dart';
import 'package:analytics_sdk/utils/logger.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:analytics_sdk/manager/session_manager.dart';

/// 公共工具类：提供 event_id 计算、公共字段管理等
class AnalyticsUtils {
  /// SDK 版本号（写死，与 pubspec.yaml 保持一致）
  static const String kSdkVersion = '1.3.0';

  /// appVersion 公共字段默认值。
  /// 接入方未传 `appVersion`、或 release 模式下传入非法值时均使用该值，
  /// 保证事件 payload 与 `AnalyticsSdk.getParams()` 返回值保持一致。
  static const String kDefaultAppVersion = '1.0.0';

  static String? _appId;
  static String? _channel;
  static String? _uid;
  static String? _appVersion;
  static String? _device;
  static String? _deviceId;
  static String? _deviceBrand;
  static String? _deviceModel;
  static String? _userAgent;
  static String? _systemName;
  static String? _systemVersion;
  static String? _deviceFingerprint;
  static String _fingerprintVersion = DeviceFingerprintUtil.kVersion;

  /// 配置公共字段
  ///
  /// 所有参数均为可选，非 null 值才会覆盖现有值。
  /// 通常在 [AnalyticsSdk.init] 中调用，也可在 init 之后按需更新。
  static void configure({
    String? appId,
    String? channel,
    String? uid,
    String? appVersion,
    String? device,
    String? deviceId,
    String? deviceBrand,
    String? deviceModel,
    String? userAgent,
    String? systemName,
    String? systemVersion,
    String? deviceFingerprint,
    String? fingerprintVersion,
  }) {
    if (appId != null) _appId = appId;
    if (channel != null) _channel = channel;
    if (uid != null) _uid = uid;
    if (appVersion != null) {
      if (RegExp(r'^\d+\.\d+\.\d+$').hasMatch(appVersion)) {
        _appVersion = appVersion;
      } else if (kDebugMode) {
        Logger.analyticsSdk(
            'appVersion 格式不正确，应为 x.y.z，当前值：$appVersion，已忽略',
            level: LogLevel.error);
      } else {
        _appVersion = kDefaultAppVersion;
      }
    }
    if (device != null) _device = device;
    if (deviceId != null) _deviceId = deviceId;
    if (deviceBrand != null) _deviceBrand = deviceBrand;
    if (deviceModel != null) _deviceModel = deviceModel;
    if (userAgent != null) _userAgent = userAgent;
    if (systemName != null) _systemName = systemName;
    if (systemVersion != null) _systemVersion = systemVersion;
    if (deviceFingerprint != null) _deviceFingerprint = deviceFingerprint;
    if (fingerprintVersion != null) _fingerprintVersion = fingerprintVersion;
  }

  /// 更新用户 ID（登录或切换账号时调用）
  static void setUid(String newUid) {
    _uid = newUid;
  }

  /// 更新渠道（渠道变更时调用）
  static void setChannel(String channel) {
    _channel = channel;
  }

  /// 重置所有公共字段为 null（SDK 重新初始化时使用）
  ///
  /// 与 [configure] 不同，此方法会将所有字段清为 null，
  /// 而 configure 中传 null 表示"不修改"。
  static void reset() {
    _appId = null;
    _channel = null;
    _uid = null;
    _appVersion = null;
    _device = null;
    _deviceId = null;
    _deviceBrand = null;
    _deviceModel = null;
    _userAgent = null;
    _systemName = null;
    _systemVersion = null;
    _deviceFingerprint = null;
    _fingerprintVersion = DeviceFingerprintUtil.kVersion;
  }

  // ──────── Getters（调试 / 外部复用） ────────────────────────────────────

  static String? get appId => _appId;
  static String? get channel => _channel;
  static String? get uid => _uid;
  static String? get appVersion => _appVersion;
  static String? get deviceId => _deviceId;
  static String? get deviceBrand => _deviceBrand;
  static String? get deviceModel => _deviceModel;

  /// 获取设备公共字段（供产品方在服务端上报事件时复用）
  ///
  /// 返回的 Map 包含：device、device_id、device_brand、device_model、
  /// user_agent、system_name、system_version、device_fingerprint、fp_version。
  /// 未配置的字段返回空字符串。
  static Map<String, String> getDeviceCommonFields() {
    return {
      'device': _device ?? '',
      'device_id': _deviceId ?? '',
      'device_brand': _deviceBrand ?? '',
      'device_model': _deviceModel ?? '',
      'user_agent': _userAgent ?? '',
      'system_name': _systemName ?? '',
      'system_version': _systemVersion ?? '',
      'device_fingerprint': _deviceFingerprint ?? '',
      'fp_version': _fingerprintVersion,
    };
  }

  /// 生成公共字段 Map
  ///
  /// 包含所有客户端事件上报所需的公共字段：
  /// event、channel、app_id、uid、sid、client_ts、
  /// device、device_id、device_brand、device_model、
  /// user_agent、system_name、system_version、
  /// device_fingerprint、fp_version、sdk_version、app_version。
  ///
  /// sdk_version 由 SDK 自动写入，无需外部传入。
  /// app_version 由接入方在 init() 中传入，可为空。
  /// device_fingerprint 和 fp_version 由 SDK 自动生成并注入，
  /// 产品方无需手动传入。
  ///
  /// 本方法永远不会抛出异常。
  static Map<String, dynamic> generateCommonFields(String event) {
    final now = DateTime.now();
    final clientTs = now.millisecondsSinceEpoch ~/ 1000;

    String sid;
    try {
      final sessionManager = SessionManager.instance;
      sid = sessionManager.getSessionId();
      sessionManager.recordActivity();
    } catch (_) {
      sid = 'fallback_${now.millisecondsSinceEpoch}';
    }

    return {
      'event': event,
      'channel': _channel ?? '',
      'app_id': _appId ?? '',
      'uid': _uid ?? '',
      'sid': sid,
      'client_ts': clientTs,
      'device': _device ?? '',
      'device_id': _deviceId ?? '',
      'device_brand': _deviceBrand ?? '',
      'device_model': _deviceModel ?? '',
      'user_agent': _userAgent ?? '',
      'system_name': _systemName ?? '',
      'system_version': _systemVersion ?? '',
      'device_fingerprint': _deviceFingerprint ?? '',
      'fp_version': _fingerprintVersion,
      'sdk_version': kSdkVersion,
      'app_version': _appVersion ?? kDefaultAppVersion,
    };
  }

  /// 根据字段列表生成 event_id
  ///
  /// 计算规则：
  /// 1. 对每个字段值单独做 MD5
  /// 2. 将所有 MD5 用 `|` 拼接
  /// 3. 对拼接结果再做一次 MD5，作为最终 event_id
  ///
  /// **注意**：`device_fingerprint` 不参与 event_id 计算。
  /// 本方法永远不会抛出异常，失败时返回基于时间戳的备选 ID。
  static String generateEventId(List<String> fields) {
    try {
      final fieldDigests = <String>[];
      for (final value in fields) {
        final v = value;
        final bytes = utf8.encode(v);
        final digest = md5.convert(bytes);
        fieldDigests.add(digest.toString());
      }

      final joined = fieldDigests.join('|');
      final finalDigest = md5.convert(utf8.encode(joined));
      return finalDigest.toString();
    } catch (e) {
      try {
        final content = fields.join('|');
        // 用 32 位掩码确保非负整数（兼容 Web/JS 的 2^53 整数精度限制），
        // toRadixString(16) 保证符合 ^[A-Za-z0-9]{1,32}$
        return 'h${(content.hashCode & 0x7FFFFFFF).toRadixString(16)}';
      } catch (_) {
        // 去掉下划线，保证符合 ^[A-Za-z0-9]{1,32}$
        return 't${DateTime.now().millisecondsSinceEpoch}';
      }
    }
  }

  /// 从公共字段 Map 和业务特有字段列表生成 event_id。
  ///
  /// 自动从 [commonFields] 中提取固定的基础字段
  /// （event、app_id、channel、uid、device、device_id、device_brand、
  /// device_model、client_ts、sid），再拼接 [extraFields] 后计算最终 event_id。
  ///
  /// 本方法永远不会抛出异常。
  static String generateEventIdFromCommonFields(
      Map<String, dynamic> commonFields, List<String> extraFields) {
    return generateEventId([
      commonFields['event'] as String? ?? '',
      commonFields['app_id'] as String? ?? '',
      commonFields['channel'] as String? ?? '',
      commonFields['uid'] as String? ?? '',
      commonFields['device'] as String? ?? '',
      commonFields['device_id'] as String? ?? '',
      commonFields['device_brand'] as String? ?? '',
      commonFields['device_model'] as String? ?? '',
      (commonFields['client_ts'] ?? '').toString(),
      commonFields['sid'] as String? ?? '',
      ...extraFields,
    ]);
  }
}
