#ifndef FLUTTER_PLUGIN_analytics_sdk_PLUGIN_H_
#define FLUTTER_PLUGIN_analytics_sdk_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace analytics_sdk {

class AnalyticsSdkPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  AnalyticsSdkPlugin();

  virtual ~AnalyticsSdkPlugin();

  // Disallow copy and assign.
  AnalyticsSdkPlugin(const AnalyticsSdkPlugin&) = delete;
  AnalyticsSdkPlugin& operator=(const AnalyticsSdkPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace analytics_sdk

#endif  // FLUTTER_PLUGIN_analytics_sdk_PLUGIN_H_
