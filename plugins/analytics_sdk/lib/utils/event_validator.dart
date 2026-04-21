import 'package:analytics_sdk/manager/session_manager.dart';
import 'package:analytics_sdk/utils/device_fingerprint_util.dart';
import 'package:analytics_sdk/utils/logger.dart';

/// 事件字段校验器
///
/// 校验规则分两类：
///
/// 1. **关键字段**：校验失败直接丢弃整个事件，[validate] 返回 `null`。
/// 2. **可纠正字段**：自动截断/转换/填充，记录日志后继续上报。
class EventValidator {
  // ──────── 公共字段长度限制 ────────
  static const int _maxEventLen = 64;
  static const int _maxAppIdLen = 64;
  static const int _maxShortLen = 128;
  static const int _maxFpLen = 128;
  static const int _maxUaLen = 512;

  // ──────── timestamp 合法范围（2000-01-01 ~ 2100-01-01） ────────
  static const int _minTs = 946684800;
  static const int _maxTs = 4102444800;

  // ──────── 正则 ────────
  static final RegExp _eventPattern = RegExp(r'^[a-z0-9_]+$');
  static final RegExp _eventIdPattern = RegExp(r'^[A-Za-z0-9]{1,32}$');
  static final RegExp _keyPattern = RegExp(r'^[A-Za-z0-9_]+$');

  // ──────── payload 字段分类 ────────

  /// 关键 ID 字段：校验失败丢弃整个事件
  static const Set<String> _criticalIdFields = {
    'video_id',
    'novel_id',
    'comic_id',
    'click_item_id',
  };

  /// 普通 ID 字段：校验失败仅移除该字段
  /// 注意：ad_id / recommend_id 已在 _commaSeparatedFields 中处理，不重复列入
  static const Set<String> _normalIdFields = {
    'order_id',
    'item_id',
    'page_id',
  };

  /// 逗号分隔字段（分割 → trim → 过滤空 → 重新拼接）
  static const Set<String> _commaSeparatedFields = {
    'ad_id',
  };

  /// 名称字段，最大 128 字符
  static const Set<String> _nameFields = {
    'page_name',
    'referrer_page_name',
    'current_page_name',
    'source_page_name',
    'tab_name',
    'ad_slot_name',
    'product_name',
    'video_type_name',
    'novel_type_name',
    'comic_type_name',
    'navigation_name',
    'advertising_name',
    'video_behavior_name',
    'novel_behavior_name',
    'comic_behavior_name',
    'consume_reason_name',
    'vip_duration_name',
    'click_item_type_name',
  };

  /// 标题字段，最大 256 字符
  static const Set<String> _titleFields = {
    'video_title',
    'novel_title',
    'comic_title',
  };

  /// 关键词/评论字段，最大 500 字符
  static const Set<String> _keywordFields = {
    'keyword',
    'comment_content',
  };

  /// 百分比字段，范围 0~100
  static const Set<String> _percentageFields = {
    'play_progress',
    'read_progress',
    'click_x_percent',
    'click_y_percent',
  };

  /// 位置字段，值 ≥ 1
  static const Set<String> _positionFields = {
    'page_no',
    'click_position',
  };

  /// 非负数字字段，值 ≥ 0
  static const Set<String> _numericFields = {
    'play_duration',
    'video_duration',
    'coin_quantity',
    'coin_consume_amount',
    'coin_balance_before',
    'coin_balance_after',
    'amount',
    'search_result_count',
    'screen_width',
    'screen_height',
    'page_load_time',
    'flag',
  };

  /// 时间戳字段（范围同 client_ts）
  static const Set<String> _timestampFields = {
    'create_time',
    'vip_expiration_time',
  };

  // ─────────────────────────────────────────────────────────
  // 公开 API
  // ─────────────────────────────────────────────────────────

  /// 校验并自动纠正事件 Map。
  ///
  /// 返回纠正后的 Map；若关键字段无法修复则返回 `null`（调用方应丢弃该事件）。
  /// 本方法永远不会抛出异常。
  static Map<String, dynamic>? validate(Map<String, dynamic> event) {
    try {
      final result = Map<String, dynamic>.from(event);

      // ── 1. event ─────────────────────────────────────────
      // 必填，trim，正则 ^[a-z0-9_]+$，最大 64 字符；不符合 → 丢弃
      final rawEvent = _toStr(result['event']);
      if (rawEvent == null) {
        Logger.analyticsSdk('校验失败：event 字段缺失或类型错误，丢弃事件', level: LogLevel.warn);
        return null;
      }
      if (!_eventPattern.hasMatch(rawEvent) || rawEvent.length > _maxEventLen) {
        Logger.analyticsSdk('校验失败：event "$rawEvent" 格式不合规或超长，丢弃事件', level: LogLevel.warn);
        return null;
      }
      result['event'] = rawEvent;

      // ── 2. event_id ──────────────────────────────────────
      // 必填，trim，正则 ^[A-Za-z0-9]{1,32}$；不符合 → 丢弃
      final rawEventId = _toStr(result['event_id']);
      if (rawEventId == null || rawEventId.isEmpty) {
        Logger.analyticsSdk('校验失败：event_id 字段缺失或为空，丢弃事件', level: LogLevel.warn);
        return null;
      }
      if (!_eventIdPattern.hasMatch(rawEventId)) {
        Logger.analyticsSdk('校验失败：event_id "$rawEventId" 格式不合规，丢弃事件', level: LogLevel.warn);
        return null;
      }
      result['event_id'] = rawEventId;

      // ── 3. app_id ────────────────────────────────────────
      // 必填，不能为空，最大 64 字符；空或缺失 → 丢弃；超长 → 截断
      final rawAppId = _toStr(result['app_id']);
      if (rawAppId == null || rawAppId.isEmpty) {
        Logger.analyticsSdk('校验失败：app_id 字段缺失或为空，丢弃事件', level: LogLevel.warn);
        return null;
      }
      result['app_id'] = _trimTrunc(rawAppId, _maxAppIdLen);

      // ── 4. channel ───────────────────────────────────────
      // 可选，trim，最大 128；超长截断
      final rawChannel = _toStr(result['channel']);
      if (rawChannel != null) {
        result['channel'] = _trimTrunc(rawChannel, _maxShortLen);
      }

      // ── 5. uid ───────────────────────────────────────────
      // 可选，trim，最大 128；超长截断
      final rawUid = _toStr(result['uid']);
      if (rawUid != null) {
        result['uid'] = _trimTrunc(rawUid, _maxShortLen);
      }

      // ── 6. sid ───────────────────────────────────────────
      // 必填；空/缺失 → 自动生成；生成后仍为空 → 丢弃
      String sid = _toStr(result['sid']) ?? '';
      if (sid.isEmpty) {
        try {
          sid = SessionManager.instance.getSessionId();
          Logger.analyticsSdk('自动纠正：sid 为空，已自动生成: $sid');
        } catch (e) {
          Logger.analyticsSdk('自动纠正：sid 生成失败: $e', level: LogLevel.warn);
          sid = '';
        }
      }
      if (sid.isEmpty) {
        Logger.analyticsSdk('校验失败：sid 无法获取，丢弃事件', level: LogLevel.warn);
        return null;
      }
      result['sid'] = sid;

      // ── 7. client_ts ─────────────────────────────────────
      // 必填，整数，范围 946684800~4102444800；字符串可尝试转换；超出范围 → 丢弃
      final tsVal = _parseTs(result['client_ts']);
      if (tsVal == null) {
        Logger.analyticsSdk('校验失败：client_ts 无效或超出范围，丢弃事件', level: LogLevel.warn);
        return null;
      }
      result['client_ts'] = tsVal;

      // ── 8. device ────────────────────────────────────────
      // 仅 Android/iOS/PC；大小写自动纠正；其他值 → 丢弃；空字符串视为未设置，跳过
      final rawDevice = _toStr(result['device']);
      if (rawDevice != null && rawDevice.isNotEmpty) {
        final normalized = _normalizeDevice(rawDevice);
        if (normalized == null) {
          Logger.analyticsSdk('校验失败：device "$rawDevice" 不合规（须为 Android/iOS/PC），丢弃事件', level: LogLevel.warn);
          return null;
        }
        result['device'] = normalized;
      }

      // ── 9. device_id ─────────────────────────────────────
      // 必填，trim，1~128；空或缺失 → 丢弃；超长截断
      final rawDeviceId = _toStr(result['device_id']);
      if (rawDeviceId == null || rawDeviceId.isEmpty) {
        Logger.analyticsSdk('校验失败：device_id 字段缺失或为空，丢弃事件', level: LogLevel.warn);
        return null;
      }
      result['device_id'] = _trimTrunc(rawDeviceId, _maxShortLen);

      // ── 10. user_agent ───────────────────────────────────
      // 可选，trim，超长截断（512，规范要求）
      final rawUa = _toStr(result['user_agent']);
      if (rawUa != null) {
        result['user_agent'] = _trimTrunc(rawUa, _maxUaLen);
      }

      // ── 11. device_brand / device_model / system_name / system_version ──
      // 可选，trim，超长截断（128）
      for (final field in ['device_brand', 'device_model', 'system_name', 'system_version']) {
        final v = _toStr(result[field]);
        if (v != null) {
          result[field] = _trimTrunc(v, _maxShortLen);
        }
      }

      // ── 12. sdk_version / app_version ────────────────────
      // 可选，trim，最大 128 字符；超长截断
      for (final field in ['sdk_version', 'app_version']) {
        final v = _toStr(result[field]);
        if (v != null) {
          result[field] = _trimTrunc(v, _maxShortLen);
        }
      }

      // ── 13. device_fingerprint ───────────────────────────
      // 可选，trim，最大 128；超长截断
      final rawFp = _toStr(result['device_fingerprint']);
      if (rawFp != null) {
        result['device_fingerprint'] = _trimTrunc(rawFp, _maxFpLen);
      }

      // ── 14. fp_version ───────────────────────────────────
      // 若 device_fingerprint 非空 且 fp_version 为空 → 自动填充 DeviceFingerprintUtil.kVersion
      final fp = (result['device_fingerprint'] as String?) ?? '';
      if (fp.isNotEmpty) {
        final fpVer = _toStr(result['fp_version']) ?? '';
        if (fpVer.isEmpty) {
          result['fp_version'] = DeviceFingerprintUtil.kVersion;
          Logger.analyticsSdk('自动纠正：fp_version 为空，已填充默认版本 ${DeviceFingerprintUtil.kVersion}');
        }
      }

      // ── 15. payload ──────────────────────────────────────
      // 可为 null（补空 Map），类型错误 → 丢弃
      final rawPayload = result['payload'];
      if (rawPayload == null) {
        result['payload'] = <String, dynamic>{};
      } else if (rawPayload is! Map) {
        Logger.analyticsSdk('校验失败：payload 类型错误(${rawPayload.runtimeType})，丢弃事件', level: LogLevel.warn);
        return null;
      } else {
        final validated = _validatePayload(Map<String, dynamic>.from(rawPayload));
        if (validated == null) return null; // 关键 ID 字段校验失败
        result['payload'] = validated;
      }

      return result;
    } catch (e) {
      Logger.analyticsSdk('事件校验内部异常: $e，丢弃事件', level: LogLevel.warn);
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────
  // payload 业务字段校验
  // ─────────────────────────────────────────────────────────

  /// 校验 payload 业务字段。
  /// 返回纠正后的 Map；若关键 ID 字段不合规则返回 `null`（丢弃事件）。
  static Map<String, dynamic>? _validatePayload(Map<String, dynamic> payload) {
    final result = <String, dynamic>{};

    for (final entry in payload.entries) {
      final key = entry.key;
      final value = entry.value;

      // key 本身须符合 ^[A-Za-z0-9_]+$
      if (!_keyPattern.hasMatch(key)) {
        Logger.analyticsSdk('自动纠正：payload 字段名 "$key" 不合规，已移除', level: LogLevel.warn);
        continue;
      }

      // ── 逗号分隔字段 ─────────────────────────────────────
      if (_commaSeparatedFields.contains(key)) {
        final s = _toStr(value);
        if (s == null) {
          Logger.analyticsSdk('自动纠正：payload.$key 类型错误，已移除');
          continue;
        }
        final cleaned = _cleanComma(s);
        if (cleaned.isEmpty) {
          // 逗号分隔字段清洗后为空，视为无效字段移除
          Logger.analyticsSdk('自动纠正：payload.$key 清洗后为空，已移除');
          continue;
        }
        result[key] = cleaned;
        continue;
      }

      // ── 关键 ID 字段 ─────────────────────────────────────
      if (_criticalIdFields.contains(key)) {
        final s = _toStr(value);
        if (s == null || s.isEmpty) {
          Logger.analyticsSdk('校验失败：payload.$key（关键ID）为空或类型错误，丢弃事件', level: LogLevel.warn);
          return null;
        }
        result[key] = s;
        continue;
      }

      // ── 普通 ID 字段 ─────────────────────────────────────
      if (_normalIdFields.contains(key)) {
        final s = _toStr(value);
        if (s == null || s.isEmpty) {
          Logger.analyticsSdk('自动纠正：payload.$key（ID字段）为空或类型错误，已移除');
          continue;
        }
        result[key] = s;
        continue;
      }

      // ── 名称字段（最大 128） ──────────────────────────────
      if (_nameFields.contains(key)) {
        final s = _toStr(value);
        if (s == null) {
          Logger.analyticsSdk('自动纠正：payload.$key 类型错误，已移除');
          continue;
        }
        result[key] = _trimTrunc(s, 128);
        continue;
      }

      // ── 标题字段（最大 256） ──────────────────────────────
      if (_titleFields.contains(key)) {
        final s = _toStr(value);
        if (s == null) {
          Logger.analyticsSdk('自动纠正：payload.$key 类型错误，已移除');
          continue;
        }
        result[key] = _trimTrunc(s, 256);
        continue;
      }

      // ── 关键词字段（最大 500） ────────────────────────────
      if (_keywordFields.contains(key)) {
        final s = _toStr(value);
        if (s == null) {
          Logger.analyticsSdk('自动纠正：payload.$key 类型错误，已移除');
          continue;
        }
        result[key] = _trimTrunc(s, 500);
        continue;
      }

      // ── 百分比字段（0~100） ───────────────────────────────
      if (_percentageFields.contains(key)) {
        final n = _parseInt(value);
        if (n == null || n < 0 || n > 100) {
          Logger.analyticsSdk('自动纠正：payload.$key 百分比值无效($value)，已移除');
          continue;
        }
        result[key] = n;
        continue;
      }

      // ── 位置字段（≥ 1） ───────────────────────────────────
      if (_positionFields.contains(key)) {
        final n = _parseInt(value);
        if (n == null || n < 1) {
          Logger.analyticsSdk('自动纠正：payload.$key 位置值无效($value)，已移除');
          continue;
        }
        result[key] = n;
        continue;
      }

      // ── 数字字段（≥ 0） ───────────────────────────────────
      if (_numericFields.contains(key)) {
        final n = _parseInt(value);
        if (n == null || n < 0) {
          Logger.analyticsSdk('自动纠正：payload.$key 数字值无效($value)，已移除');
          continue;
        }
        result[key] = n;
        continue;
      }

      // ── 时间戳字段（范围校验） ─────────────────────────────
      if (_timestampFields.contains(key)) {
        final ts = _parseTs(value);
        if (ts == null) {
          Logger.analyticsSdk('自动纠正：payload.$key 时间戳无效($value)，已移除');
          continue;
        }
        result[key] = ts;
        continue;
      }

      // ── 其他字段（字符串超长截断，非字符串保留原值） ───────
      if (value is String && value.length > 500) {
        result[key] = value.substring(0, 500);
        Logger.analyticsSdk('自动纠正：payload.$key 超长，已截断至500字符');
      } else {
        result[key] = value;
      }
    }

    return result;
  }

  // ─────────────────────────────────────────────────────────
  // 工具方法
  // ─────────────────────────────────────────────────────────

  /// 将 dynamic 转为 trim 后的 String
  ///
  /// - String → trim
  /// - num / bool → toString().trim()（业务方可能传入 int 类型的 uid、channel 等）
  /// - 其他类型 → null
  static String? _toStr(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.trim();
    if (v is num || v is bool) return v.toString().trim();
    return null;
  }

  /// 截断字符串到最大长度（已是 trim 后的值）
  static String _trimTrunc(String s, int max) {
    return s.length > max ? s.substring(0, max) : s;
  }

  /// 将 device 字段大小写标准化，返回 null 表示无法识别
  static String? _normalizeDevice(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower == 'android') return 'Android';
    if (lower == 'ios') return 'iOS';
    if (lower == 'pc') return 'PC';
    return null;
  }

  /// 解析整数（支持 int 和数字字符串）
  static int? _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  /// 解析时间戳，范围须在 [_minTs, _maxTs]；支持 int / double / 数字字符串
  ///
  /// 注意：Dart Web 上 int 与 double 统一为 JS number，显式处理 double
  /// 以保证 Native 与 Web 行为一致。
  static int? _parseTs(dynamic v) {
    int? ts;
    if (v is int) {
      ts = v;
    } else if (v is double) {
      if (v.isFinite) ts = v.toInt();
    } else if (v is String) {
      ts = int.tryParse(v.trim());
    }
    if (ts == null || ts < _minTs || ts > _maxTs) return null;
    return ts;
  }

  /// 清理逗号分隔字符串：各段 trim、过滤空段、重新拼接
  static String _cleanComma(String raw) {
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(',');
  }
}
