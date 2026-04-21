import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Analytics SDK 的 Web 平台插件入口。
///
/// Flutter Web 插件系统要求此文件存在，并实现 [registerWith]。
/// SDK 的 Web 实现（设备信息、指纹等）位于 utils/ 目录下的 web 专属文件。
class AnalyticsSdkWeb {
  static void registerWith(Registrar registrar) {
    // SDK 不使用 MethodChannel，无需注册通道。
    // Web 平台功能通过条件导入的工具类直接实现。
  }
}
