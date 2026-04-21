#include "include/analytics_sdk/analytics_sdk_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "analytics_sdk_plugin.h"

void AnalyticsSdkPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  analytics_sdk::AnalyticsSdkPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
