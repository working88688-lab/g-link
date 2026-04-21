import 'package:analytics_sdk/analytics_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:g_link/app_global.dart';
import 'package:g_link/data_layer/repo/repo.dart';
import 'package:g_link/domain/domains/report.dart';
import 'package:g_link/domain/model/member_model.dart';
import 'package:g_link/report/analytics/analytic_page_mapper.dart';
import 'package:g_link/ui_layer/notifier/user_notifier.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:provider/provider.dart';

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

Future<void> initAnalyticsSdk(BuildContext? context,
    {String oauthId = ''}) async {
  if (context == null) {
    final appId =
        AppGlobal.reportAppId.isNotEmpty ? AppGlobal.reportAppId : 'DX-002';
    await AnalyticsSdk.instance.init(
      appId: appId,
      encryptedConfig: null,
      deviceId: oauthId,
      enableDebugBanner: kDebugMode,
    );
  } else {
    AppGlobal.context = context;
    final user = await _getUserInfo();
    final appId =
        AppGlobal.reportAppId.isNotEmpty ? AppGlobal.reportAppId : 'DX-002';
    await AnalyticsSdk.instance.init(
      appId: appId,
      encryptedConfig: null,
      deviceId: _getDeviceId(),
      channel: (user?.channel == 'self' ? '' : user?.channel),
      uid: user?.aff?.toString(),
      enableDebugBanner: kDebugMode,
    );
  }

  initPage();
}

Future<void> fetchAndApplyConfig() async {
  try {
    final reportDomain = AppGlobal.context?.read<ReportDomain>();
    final res = await reportDomain?.getEncryptedConfig();
    // 根据实际的API响应格式提取config
    if (res != null && res.status == 1) {
      if (res.data case final encryptedConfig) {
        CommonUtils.log('encryptedConfig:$encryptedConfig');
        await AnalyticsSdk.instance.refreshDomainConfig(
          encryptedConfig: encryptedConfig,
        );
      }
    }
  } catch (e) {
    CommonUtils.log('获取加密config失败: $e');
  }
}
