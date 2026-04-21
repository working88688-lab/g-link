import 'package:flutter/foundation.dart';
import 'package:analytics_sdk/manager/ad_impression_manager.dart';
import 'package:analytics_sdk/utils/logger.dart';
import 'package:analytics_sdk/utils/uuid_util.dart';

/// 会话管理器：管理会话ID（sid）的生成和更新
///
/// 会话定义：用户在一次连续、自然的产品使用过程中产生的一组行为集合
///
/// **sid 说明**：sid 由客户端 SDK 自动生成，每个事件均会携带。
/// 服务端上报事件时，需通过 [AnalyticsSdk.getParams] 获取当前 sid 并一同回传，
/// 以便服务端事件与客户端事件归属同一会话。
///
/// 会话中断阈值：30 分钟无任何有效行为，生成新会话ID
///
/// APP产品定义方案，任意满足一条就重新生成会话ID：
/// 1. App 冷启动（进程首次启动）
/// 2. App 从后台切换前台，且后台停留 > 30 分钟
/// 3. 上一次行为距离当前 > 30 分钟
class SessionManager {
  static final SessionManager instance = SessionManager._internal();

  factory SessionManager() => instance;

  SessionManager._internal();

  /// 当前会话ID
  String? _currentSessionId;

  /// 会话创建时间
  DateTime? _sessionStartTime;

  /// 最后一次行为时间
  DateTime? _lastActivityTime;

  /// 应用进入后台的时间
  DateTime? _backgroundTime;

  /// 会话中断阈值（30分钟）
  static const Duration sessionTimeout = Duration(minutes: 30);

  /// 是否已初始化（用于判断冷启动）
  bool _isInitialized = false;

  /// 获取当前会话ID
  /// 如果当前没有会话或会话已过期，会自动创建新会话
  String getSessionId() {
    final now = DateTime.now();
    
    // 检查是否需要生成新会话
    // 注意：这里只检查和创建会话，不更新 _lastActivityTime
    // 调用方应通过 recordActivity() 显式记录行为时间，避免非行为调用（如 debug 面板）误延长会话
    if (_shouldCreateNewSession(now)) {
      _createNewSession(now);
    }

    // 安全检查：确保会话ID不为null（理论上不会发生，但作为保护措施）
    if (_currentSessionId == null) {
      Logger.analyticsSdk('警告：会话ID为null，强制创建新会话', level: LogLevel.warn);
      _createNewSession(now);
    }

    return _currentSessionId!;
  }

  /// 检查是否需要创建新会话
  bool _shouldCreateNewSession(DateTime now) {
    // 1. 如果还没有会话ID，需要创建
    if (_currentSessionId == null) {
      return true;
    }

    // 2. 如果还未初始化，说明是冷启动，需要创建新会话
    if (!_isInitialized) {
      return true;
    }

    // 3. 如果从后台恢复，且后台停留时间 > 30 分钟
    // 注意：这里只在超时时清空 _backgroundTime（并返回 true 触发新会话）。
    // 非超时分支不清空，保留给 onAppForeground() 统一处理，
    // 避免后台期间有代码调用 getSessionId()（如推送通知触发 track()）时
    // 提前清空导致 onAppForeground() 无法正确判断后台时长。
    if (_backgroundTime != null) {
      final backgroundDuration = now.difference(_backgroundTime!);
      if (backgroundDuration > sessionTimeout) {
        Logger.analyticsSdk('后台停留时间 ${backgroundDuration.inMinutes} 分钟，超过阈值，创建新会话');
        _backgroundTime = null;
        return true;
      }
      // 未超时：不清空 _backgroundTime，由 onAppForeground() 负责清空
    }

    // 4. 如果上一次行为距离当前 > 30 分钟
    if (_lastActivityTime != null) {
      final timeSinceLastActivity = now.difference(_lastActivityTime!);
      if (timeSinceLastActivity > sessionTimeout) {
        Logger.analyticsSdk('距离上次行为 ${timeSinceLastActivity.inMinutes} 分钟，超过阈值，创建新会话');
        return true;
      }
    }

    return false;
  }

  /// 创建新会话
  void _createNewSession(DateTime now) {
    try {
      _currentSessionId = generateUuidV4().replaceAll("-", "");
      _sessionStartTime = now;
      _lastActivityTime = now;
      _isInitialized = true;
      // 新 session 开始时重置广告去重集，使同一广告在新 session 内可再次上报
      AdImpressionManager.instance.clear();
      Logger.analyticsSdk('创建新会话ID: $_currentSessionId');
    } catch (e) {
      // UUID 生成失败时使用时间戳作为备选方案
      final timestamp = now.millisecondsSinceEpoch;
      _currentSessionId = 'session_${timestamp}_${now.microsecondsSinceEpoch}';
      _sessionStartTime = now;
      _lastActivityTime = now;
      _isInitialized = true;
      AdImpressionManager.instance.clear();
      Logger.analyticsSdk('UUID 生成失败，使用时间戳创建会话ID: $_currentSessionId');
    }
  }

  /// 初始化会话管理器
  /// 在 SDK 初始化时调用，标记为冷启动
  void initialize() {
    if (!_isInitialized) {
      final now = DateTime.now();
      _createNewSession(now);
      Logger.analyticsSdk('会话管理器初始化（冷启动），创建新会话');
    }
  }

  /// 应用进入后台
  /// 在应用生命周期变为后台时调用
  void onAppBackground() {
    _backgroundTime = DateTime.now();
    Logger.analyticsSdk('应用进入后台，记录时间: $_backgroundTime');
  }

  /// 应用从后台恢复
  /// 在应用生命周期变为前台时调用
  void onAppForeground() {
    final now = DateTime.now();
    
    // 如果从后台恢复，检查是否需要创建新会话
    if (_backgroundTime != null) {
      final backgroundDuration = now.difference(_backgroundTime!);
      if (backgroundDuration > sessionTimeout) {
        Logger.analyticsSdk('从后台恢复，后台停留 ${backgroundDuration.inMinutes} 分钟，超过阈值，创建新会话');
        _createNewSession(now);
      } else {
        Logger.analyticsSdk('从后台恢复，后台停留 ${backgroundDuration.inMinutes} 分钟，继续使用当前会话');
        // 更新最后行为时间，表示用户重新活跃
        _lastActivityTime = now;
      }
      _backgroundTime = null; // 清空后台时间
    } else {
      // 如果没有后台时间记录，直接更新最后行为时间
      _lastActivityTime = now;
    }
  }

  /// 记录用户行为
  /// 每次生成事件时调用，用于更新最后行为时间
  void recordActivity() {
    _lastActivityTime = DateTime.now();
  }

  /// 获取当前会话ID（不触发新会话创建）
  String? get currentSessionId => _currentSessionId;

  /// 获取会话开始时间
  DateTime? get sessionStartTime => _sessionStartTime;

  /// 获取最后行为时间
  DateTime? get lastActivityTime => _lastActivityTime;

  /// 仅供测试使用：获取后台时间（验证 _shouldCreateNewSession 不提前清空）
  @visibleForTesting
  DateTime? get backgroundTimeForTest => _backgroundTime;

  /// 手动重置会话（用于测试或特殊场景）
  void reset() {
    _currentSessionId = null;
    _sessionStartTime = null;
    _lastActivityTime = null;
    _backgroundTime = null;
    _isInitialized = false;
    Logger.analyticsSdk('会话已重置');
  }
}
