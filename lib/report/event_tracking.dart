import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:g_link/data_layer/repo/utils.dart';
import 'package:g_link/domain/model/member_model.dart';
import 'package:g_link/ui_layer/notifier/user_notifier.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;

import '../app_global.dart';
import '../crypto.dart';
import '../data_layer/repo/repo.dart';
import '../domain/model/home_data_model.dart';

/// 埋点数据上报工具类（Dio版本）
class EventTracking {
  static final EventTracking _instance = EventTracking._internal();
  factory EventTracking() => _instance;

  EventTracking._internal() {
    _startTimer();
  }

  /// 上报地址
  static String reportUrl = '';

  /// Dio实例
  Dio? _dio;

  /// 本地缓存队列
  final List<Map<String, dynamic>> _eventQueue = [];

  /// 是否正在上报中
  bool _isReporting = false;

  /// 最大重试次数
  static const int _maxRetries = 3;

  /// 批量上报阈值
  static const int _batchThreshold = 10;

  /// 定时器上报间隔（秒）
  static const int _timerIntervalSeconds = 10;

  /// 定时器实例
  Timer? _batchTimer;

  /// 启动定时器
  void _startTimer() {
    // 每10秒检查一次
    _batchTimer = Timer.periodic(
      const Duration(seconds: _timerIntervalSeconds),
      (timer) {
        if (_eventQueue.isNotEmpty && !_isReporting) {
          CommonUtils.log('定时器触发上报，队列长度: ${_eventQueue.length}');
          unawaited(_batchReport());
        }
      },
    );
  }

  /// 停止定时器
  void _stopTimer() {
    _batchTimer?.cancel();
    _batchTimer = null;
  }

  /// 重新启动定时器
  void _restartTimer() {
    _stopTimer();
    _startTimer();
  }

  /// 初始化Dio
  void _initDio() {
    if (_dio == null && reportUrl.isNotEmpty) {
      try {
        ReportConfig reportConfig = AppGlobal.reportConfig!;
        final uri = Uri.parse(reportUrl);
        final baseUrl =
            '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';

        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
          ),
        );

        if (reportConfig.isEncryption == 1) {
          final secretValue = PlatformAwareCrypto.encryptSecret(
              '${reportConfig.authenticationKey}_${reportConfig.authenticationTime}');
          _dio?.options.headers = {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Cf-Ray-Xf': secretValue
          };

          _dio?.interceptors.add(
            InterceptorsWrapper(onRequest: (options, handler) {
              if (options.data != null) {
                final dynamic data = options.data;
                CommonUtils.log('上报 加密前 参数 = ${options.data}');

                options.data = PlatformAwareCrypto.encryptReportParams(data,
                    keyString: reportConfig.encryptionKey,
                    ivString: reportConfig.encryptionIv,
                    signKey: reportConfig.signKey);

                // CommonUtils.log('options.data = ${options.data}');
                CommonUtils.log('options.headers = ${options.headers}');
              }
              handler.next(options);
            }),
          );
        }

        // 添加拦截器
        _dio?.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              CommonUtils.log(
                  '埋点上报请求: ${options.method} ${options.baseUrl}${options.path}');
              return handler.next(options);
            },
            onResponse: (response, handler) {
              CommonUtils.log('埋点上报响应: ${response.statusCode}');
              return handler.next(response);
            },
            onError: (DioException e, handler) {
              CommonUtils.log('埋点上报错误: ${e.type} - ${e.message}');
              return handler.next(e);
            },
          ),
        );

        CommonUtils.log('Dio初始化成功，baseUrl: $baseUrl');
      } catch (e) {
        CommonUtils.log('Dio初始化失败: $e');
      }
    }
  }

  /// 获取设备信息
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        final userAgent = html.window.navigator.userAgent;

        String browser = webInfo.browserName.name;
        String deviceModel = "Unknown";

        if (userAgent.contains("Mobile")) {
          if (userAgent.contains("iPhone")) {
            deviceModel = "iPhone";
          } else if (userAgent.contains("Android")) {
            deviceModel = "Android Mobile";
          }
        }

        return {
          "device": "iOS",
          "deviceBrand": "Apple",
          "deviceModel": "$browser - $deviceModel",
          "user_agent": userAgent,
          "platformVersion": webInfo.appVersion ?? "",
        };
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          "device": "android",
          "deviceBrand": androidInfo.brand,
          "deviceModel": androidInfo.model,
          "user_agent": "",
          "platformVersion": androidInfo.version.release,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          "device": "ios",
          "deviceBrand": "Apple",
          "deviceModel": iosInfo.model,
          "user_agent": "",
          "platformVersion": iosInfo.systemVersion,
        };
      }
    } catch (e) {
      CommonUtils.log('获取设备信息失败: $e');
    }

    return {
      "device": "unknown",
      "deviceBrand": "unknown",
      "deviceModel": "unknown",
      "user_agent": "",
      "platformVersion": "",
    };
  }

  /// 获取设备ID（从AppGlobal）
  String _getDeviceId() {
    try {
      final info = AppGlobal.context!.read<AppRepo>().info;
      final deviceId = info['oauth_id'];
      return deviceId?.toString() ?? "unknown_device";
    } catch (e) {
      CommonUtils.log('获取设备ID失败: $e');
      return "unknown_device";
    }
  }

  /// 生成事件ID
  String _generateEventId() {
    try {
      final deviceId = _getDeviceId();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomStr = _generateRandomString(8);
      final eventId = "${deviceId}_${timestamp}_$randomStr";
      return RepoUtils.gvMD5(eventId);
    } catch (e) {
      CommonUtils.log('生成事件ID失败: $e');
      return 'fallback_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
    }
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  /// 获取用户信息（安全版本）
  Future<Member?> _getUserInfo() async {
    try {
      if (AppGlobal.context == null) {
        CommonUtils.log('AppGlobal.context 为 null');
        return null;
      }

      return AppGlobal.context!.read<UserNotifier>().member;
    } catch (e) {
      CommonUtils.log('获取用户信息失败: $e');
      return null;
    }
  }

  /// 构建事件数据
  Future<Map<String, dynamic>> _buildEventData(
      Map<dynamic, dynamic> originalPayload) async {
    try {
      // 安全地获取用户信息
      final user = await _getUserInfo();

      // 获取设备信息
      final deviceInfo = await _getDeviceInfo();

      // 提取 event 字段
      final eventValue = originalPayload['event'];
      final payload = Map<String, dynamic>.from(originalPayload);
      payload.remove('event');

      // 构建最终事件数据
      return {
        'app_id': AppGlobal.reportAppId ?? 'unknown_app',
        'trace_id': AppGlobal.reportTraceId,
        'channel': (user?.channel == 'self' ? '' : user?.channel) ?? '',
        'client_ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'device': deviceInfo['device'] ?? 'unknown',
        'deviceBrand': deviceInfo['deviceBrand'] ?? 'unknown',
        'deviceModel': deviceInfo['deviceModel'] ?? 'unknown',
        'device_id': _getDeviceId(),
        'event_id': _generateEventId(),
        'event': eventValue?.toString() ?? 'unknown_event',
        'payload': payload,
        'uid': user?.aff ?? '',
        'sid': user?.uuid ?? '',
        'user_agent': deviceInfo['user_agent'] ?? '',
        'user_type': (user?.vipLevel ?? 0) > 0 ? 'vip' : 'normal',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'event_time': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      CommonUtils.log('构建事件数据失败: $e');
      // 返回最小化的事件数据
      return {
        'app_id': AppGlobal.reportAppId ?? 'unknown_app',
        'client_ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'event_id': _generateEventId(),
        'event': originalPayload['event']?.toString() ?? 'unknown_event',
        'payload': {'error': 'build_failed'},
        'device_id': _getDeviceId(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  bool _eventCanPass(Map<dynamic, dynamic> payload) {
    if (AppGlobal.reportConfig case ReportConfig reportConfig) {
      final eventKey = 'is_report_${payload['event']}'; // is_report_xxx
      return reportConfig.toJson()[eventKey] == 1;
    }
    return false;
  }

  /// 上报单条埋点事件
  Future<void> reportSingle(Map<dynamic, dynamic> payload) async {
    try {
      // 判断是否需要上报
      if (!_eventCanPass(payload)) {
        return;
      }
      // 判断uid，有值才上报
      final userInfo = await _getUserInfo();
      if (userInfo?.uid == null) return;

      if (userInfo?.uid is int && (userInfo?.uid ?? 0) > 0) {
        // 构建事件数据
        final eventData = await _buildEventData(payload);

        // 添加事件到队列
        _addToQueue(eventData);

        CommonUtils.log(
            '事件添加到队列: ${eventData['event']}, 队列长度: ${_eventQueue.length}');

        // 如果队列达到阈值，触发批量上报
        if (_eventQueue.length >= _batchThreshold) {
          CommonUtils.log('队列达到阈值 $_batchThreshold，触发上报');
          await _batchReport();
        }
      }
    } catch (e) {
      CommonUtils.log('埋点上报失败: $e');
    }
  }

  /// 批量上报埋点事件
  Future<void> reportBatch(List<Map<String, dynamic>> eventList) async {
    try {
      final List<Map<String, dynamic>> eventDataList = [];

      for (final payload in eventList) {
        final eventData = await _buildEventData(payload);
        eventDataList.add(eventData);
      }

      _eventQueue.addAll(eventDataList);
      CommonUtils.log(
          '批量添加 ${eventList.length} 条事件到队列，总长度: ${_eventQueue.length}');

      await _batchReport();
    } catch (e) {
      CommonUtils.log('批量埋点上报失败: $e');
    }
  }

  /// 将事件添加到队列
  void _addToQueue(Map<String, dynamic> eventData) {
    _eventQueue.add(eventData);

    // 限制队列大小，避免内存溢出
    const maxQueueSize = 1000;
    if (_eventQueue.length > maxQueueSize) {
      final removedCount = _eventQueue.length - maxQueueSize;
      _eventQueue.removeRange(0, removedCount);
      CommonUtils.log('队列超过 $maxQueueSize 条，移除 $removedCount 条旧数据');
    }
  }

  /// 执行批量上报
  Future<void> _batchReport() async {
    if (_isReporting || _eventQueue.isEmpty) {
      return;
    }

    _isReporting = true;

    try {
      // 复制当前队列
      final List<Map<String, dynamic>> eventsToReport = List.from(_eventQueue);

      if (eventsToReport.isEmpty) {
        return;
      }

      CommonUtils.log('开始批量上报埋点事件，共 ${eventsToReport.length} 条');

      bool success = false;
      int retryCount = 0;

      while (!success && retryCount < _maxRetries) {
        try {
          success = await _sendReportWithDio(eventsToReport);
          if (success) {
            // 上报成功，从队列中移除已上报的事件
            for (final event in eventsToReport) {
              _eventQueue.remove(event);
            }
            CommonUtils.log(
                '埋点上报成功，移除 ${eventsToReport.length} 条记录。剩余${_eventQueue.length} 条记录');
            break;
          }
          retryCount++;
        } catch (e) {
          CommonUtils.log('第 ${retryCount + 1} 次重试失败: $e');
          retryCount++;
          if (retryCount < _maxRetries) {
            // 指数退避策略
            await Future.delayed(Duration(seconds: 1 << retryCount));
          }
        }
      }

      if (!success) {
        CommonUtils.log('上报失败次数过多，从队列中移除上报失败的事件');
        // 上报失败次数过多，从队列中移除上报失败的事件
        for (final event in eventsToReport) {
          _eventQueue.remove(event);
        }
      }
    } catch (e) {
      CommonUtils.log('批量上报异常: $e');
    } finally {
      _isReporting = false;
    }
  }

  /// 使用Dio发送HTTP请求
  Future<bool> _sendReportWithDio(List<Map<String, dynamic>> events) async {
    if (events.isEmpty) {
      return false;
    }

    if (reportUrl.isEmpty) {
      CommonUtils.log('上报URL未设置');
      return false;
    }

    try {
      if (_dio == null) {
        _initDio();
      }

      if (_dio == null) {
        CommonUtils.log('Dio初始化失败');
        return false;
      }

      // 提取API路径
      final uri = Uri.parse(reportUrl);
      final path = uri.path;

      // 记录要上报的数据
      CommonUtils.log('上报数据: ${events.length} 条');

      final response = await _dio!.post(
        path,
        data: events,
      );

      if (response.statusCode == 200) {
        dynamic result;
        if (response.data is String) {
          try {
            result = jsonDecode(response.data as String);
          } catch (e) {
            result = {'success': true};
          }
        } else {
          result = response.data;
        }

        // 判断成功条件
        final bool isSuccess = result is Map &&
            ((result['code'] != null && result['code'] == 0) ||
                (result['success'] != null && result['success'] == true) ||
                (result['status'] != null && result['status'] == 1));

        if (isSuccess) {
          CommonUtils.log('埋点上报成功: ${events.length} 条数据');
        } else {
          CommonUtils.log(
              '埋点上报业务失败: ${result['msg'] ?? result['message'] ?? result}');
        }

        return isSuccess;
      } else {
        CommonUtils.log('HTTP错误: ${response.statusCode} - ${response.data}');
        return false;
      }
    } on DioException catch (e) {
      CommonUtils.log('Dio异常: ${e.type} - ${e.message}');

      if (e.response != null) {
        CommonUtils.log('响应数据: ${e.response?.data}');
      }

      return false;
    } catch (e) {
      CommonUtils.log('其他异常: $e');
      return false;
    }
  }

  /// 手动触发上报（例如在应用退出时）
  Future<void> flush() async {
    if (_eventQueue.isNotEmpty && !_isReporting) {
      CommonUtils.log('手动触发埋点上报，队列长度: ${_eventQueue.length}');
      await _batchReport();
    }
  }

  /// 添加网络状态监听，网络恢复时自动上报
  void setupNetworkListener() {
    // 这里可以使用 connectivity_plus 包监听网络状态变化
    // 当网络恢复时自动上报缓存的数据
  }

  /// 清空队列（测试用）
  void clearQueue() {
    _eventQueue.clear();
    CommonUtils.log('清空事件队列');
  }

  /// 获取队列长度（测试用）
  int get queueLength => _eventQueue.length;

  /// 获取Dio实例（用于自定义配置）
  Dio? get dio => _dio;

  /// 更新Dio配置
  void updateDioConfig(BaseOptions options) {
    if (_dio == null) return;

    _dio!.options = _dio!.options.copyWith(
      baseUrl: options.baseUrl,
      connectTimeout: options.connectTimeout,
      receiveTimeout: options.receiveTimeout,
      headers: options.headers,
    );
  }

  /// 销毁资源
  void dispose() {
    _stopTimer();
    // 尝试上报剩余事件
    unawaited(flush());
  }
}
