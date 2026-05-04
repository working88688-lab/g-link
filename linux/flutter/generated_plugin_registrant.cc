//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <analytics_sdk/analytics_sdk_plugin.h>
#include <file_selector_linux/file_selector_plugin.h>
#include <url_launcher_linux/url_launcher_plugin.h>
#include <volume_controller/volume_controller_plugin.h>
#include <webcrypto/webcrypto_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) analytics_sdk_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "AnalyticsSdkPlugin");
  analytics_sdk_plugin_register_with_registrar(analytics_sdk_registrar);
  g_autoptr(FlPluginRegistrar) file_selector_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FileSelectorPlugin");
  file_selector_plugin_register_with_registrar(file_selector_linux_registrar);
  g_autoptr(FlPluginRegistrar) url_launcher_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "UrlLauncherPlugin");
  url_launcher_plugin_register_with_registrar(url_launcher_linux_registrar);
  g_autoptr(FlPluginRegistrar) volume_controller_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "VolumeControllerPlugin");
  volume_controller_plugin_register_with_registrar(volume_controller_registrar);
  g_autoptr(FlPluginRegistrar) webcrypto_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "WebcryptoPlugin");
  webcrypto_plugin_register_with_registrar(webcrypto_registrar);
}
