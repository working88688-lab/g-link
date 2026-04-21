import 'dart:convert';
import 'package:analytics_sdk/config/sdk_config.dart';
import 'package:analytics_sdk/utils/logger.dart';
import 'package:analytics_sdk/utils/platform_storage.dart';

/// 事件类型配置管理器：解析并缓存业务方传入的事件类型配置
class EventTypeConfigManager {
  static final EventTypeConfigManager instance =
      EventTypeConfigManager._internal();

  factory EventTypeConfigManager() => instance;

  EventTypeConfigManager._internal();

  Set<String> _enabledEventTypes = {};

  /// 获取已启用的事件类型集合
  Set<String> get enabledEventTypes => Set.unmodifiable(_enabledEventTypes);

  /// 检查某个事件类型是否被启用
  /// 如果配置为空，默认允许所有事件上报（向后兼容）
  bool isEventTypeEnabled(String eventType) {
    if (_enabledEventTypes.isEmpty) return true;
    return _enabledEventTypes.contains(eventType);
  }

  /// 传入已解密的事件类型配置 JSON 字符串，解析后写入本地缓存
  ///
  /// 支持格式：
  /// - 字符串数组：`["app_page_view", "ad_impression", ...]`
  /// - JSON 对象：`{"enabled_event_types": [...]}`
  ///
  /// 返回解析到的事件类型数量
  Future<int> initWithConfig(String decryptedJson) async {
    try {
      final eventTypes = _parseEventTypes(decryptedJson);
      if (eventTypes.isNotEmpty) {
        _enabledEventTypes = eventTypes;
        await _saveConfigToCache(eventTypes);
        Logger.eventTypeConfigManager(
            '事件类型配置已更新，共 ${eventTypes.length} 个: ${eventTypes.join(", ")}');
      } else {
        Logger.eventTypeConfigManager('解析结果为空，保持原有配置');
      }
      return eventTypes.length;
    } catch (e) {
      Logger.eventTypeConfigManager('initWithConfig 异常: $e');
      return 0;
    }
  }

  /// 从本地缓存加载配置（若无缓存则保持 allow-all 状态）
  Future<void> loadCachedConfig() async {
    try {
      await _loadCachedConfig();
    } catch (e) {
      Logger.eventTypeConfigManager('加载缓存配置异常: $e');
    }
  }

  /// 清理资源
  void dispose() {
    _enabledEventTypes.clear();
  }

  /// 解析 JSON 字符串，提取事件类型列表（供外部验证用，如 validateEncryptedConfig）
  ///
  /// 返回 List<String>，解析失败或结果为空则返回空列表，不抛出异常。
  static List<String> parseForValidation(String json) {
    try {
      dynamic decoded = jsonDecode(json);
      if (decoded is String && decoded.trim().isNotEmpty) {
        try {
          decoded = jsonDecode(decoded);
        } catch (_) {}
      }
      if (decoded is List) {
        return (decoded as List)
            .map<String>((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (decoded is Map<String, dynamic>) {
        final list = decoded['enabled_event_types'] as List? ??
            decoded['event_types'] as List? ??
            decoded['data'] as List?;
        if (list != null) {
          return list
              .map<String>((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  // ==================== 私有方法 ====================

  /// 解析 JSON 字符串，提取事件类型列表
  Set<String> _parseEventTypes(String json) {
    try {
      dynamic decoded = jsonDecode(json);
      // 兼容外层为字符串的格式："[\"event_type\", ...]"
      if (decoded is String && decoded.trim().isNotEmpty) {
        try {
          decoded = jsonDecode(decoded);
        } catch (_) {}
      }
      if (decoded is List) {
        return (decoded as List)
            .map<String>((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toSet();
      } else if (decoded is Map<String, dynamic>) {
        final list = decoded['enabled_event_types'] as List? ??
            decoded['event_types'] as List? ??
            decoded['data'] as List?;
        if (list != null) {
          return list
              .map<String>((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toSet();
        }
      }
    } catch (e) {
      Logger.eventTypeConfigManager('事件类型 JSON 解析失败: $e');
    }
    return {};
  }

  Future<void> _saveConfigToCache(Set<String> eventTypes) async {
    try {
      await PlatformStorage.write(
        SdkConfig.eventTypeConfigCacheFileName,
        jsonEncode({
          'enabled_event_types': eventTypes.toList(),
          'updated_at': DateTime.now().toIso8601String(),
        }),
      );
      Logger.eventTypeConfigManager('配置已保存到缓存');
    } catch (e) {
      Logger.eventTypeConfigManager('保存缓存失败: $e');
    }
  }

  Future<void> _loadCachedConfig() async {
    try {
      final content =
          await PlatformStorage.read(SdkConfig.eventTypeConfigCacheFileName);
      if (content == null) {
        Logger.eventTypeConfigManager('缓存文件不存在');
        return;
      }
      final json = jsonDecode(content) as Map<String, dynamic>;
      final list = json['enabled_event_types'];
      if (list is List) {
        _enabledEventTypes = (list as List)
            .map<String>((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toSet();
        Logger.eventTypeConfigManager(
            '从缓存加载 ${_enabledEventTypes.length} 个事件类型');
      }
    } catch (e) {
      Logger.eventTypeConfigManager('加载缓存失败: $e');
    }
  }
}
