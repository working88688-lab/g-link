import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' as fd;
import 'package:flutter/material.dart';
import 'package:g_link/app_global.dart';
import 'package:g_link/data_layer/repo/repo.dart';
import 'package:g_link/ui_layer/dialog/regular_dialog.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:provider/provider.dart';
import '../../crypto.dart';

class AutoEncryptAndDecryptInterceptor extends Interceptor {
  const AutoEncryptAndDecryptInterceptor(this._appInfo);

  final Map _appInfo;

  static bool _warnJump = false;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final Map data = {..._appInfo};
    int _req_time = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (options.data != null) {
      data.addAll(options.data);
    }
    if (AppGlobal.reportTraceId.isNotEmpty) {
      data['trace_id'] = AppGlobal.reportTraceId;
    }
    if (AppGlobal.affXCode.isNotEmpty) {
      data['aff_x_code'] = AppGlobal.affXCode;
    }
    if (options.path.contains('home/config')) {
      options.extra['clientTime'] = _req_time;
      data.addAll({'req_time': _req_time});
    }
    options.data = PlatformAwareCrypto.encryptReqParams(data);
    return super.onRequest(options, handler);
  }

  @override
  onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (response.data case final Map data when data['data'] != null) {
      Map<dynamic, dynamic> result = Map.from(response.data);
      response.data =
          await fd.compute(PlatformAwareCrypto.decryptResData, response.data);
      // response.data = await PlatformAwareCrypto.decryptResData(response.data);

      if (response.requestOptions.path.contains('home/config')) {
        String sign = result.remove("sign").toString();
        final clientTime = response.requestOptions.extra['clientTime'];
        final serverTime = result['timestamp'];
        _jumpOffice(result, sign, clientTime, serverTime, response);
      }
    }

    //打印返回数据
    CommonUtils.log('Result: ${jsonEncode(response.data)}');

    // logger.i(response.data);

    return super.onResponse(response, handler);
  }

  //警告⚠️数据被篡改 提示下载最新版本
  void _jumpOffice(
    Map<dynamic, dynamic> result,
    String sign,
    int clientTime,
    int serverTime,
    Response<dynamic> response,
  ) async {
    if (PlatformAwareCrypto.makeSign(result, appKey) != sign &&
        !_warnJump &&
        _checkTimeDiff(clientTime, serverTime) &&
        clientTime != response.data['req_time']) {
      _warnJump = true;

      String officeSite = AppGlobal.officeSite;
      //弹出告警提示
      BotToast.showWidget(
        toastBuilder: (cancelFunc) => Stack(
          children: [
            AbsorbPointer(
              child: Container(),
            ),
            RegularDialog(
              title: '',
              content: Text('sjjysb'.tr(), style: MyTheme.gray153_14),
              cancelText: 'qx'.tr(),
              cancelOnTap: () => cancelFunc(),
              buttonText: 'qr'.tr(),
              confirmOnTap: () {
                CommonUtils.launchUrl(officeSite);
              },
            ),
          ],
        ),
      );

      //接口篡改上报
      if (AppGlobal.context != null) {
        final apiDio = AppGlobal.context!.read<AppRepo>().apiDio;
        Map<String, dynamic> map = {
          'url': response.requestOptions.baseUrl + response.requestOptions.path,
          'req_header': Map.from(response.requestOptions.headers),
          'res_header': Map.from(response.headers.map),
          'data': response.data,
        };
        //上报数据type 1 接口校验 2 APK校验
        final res = await apiDio.post('/api/home/hijack', data: {
          'type': 1,
          'json': jsonEncode(map),
        });
        CommonUtils.log('$res');
      }
    }
  }

  //是否被篡改
  bool _checkTimeDiff(int clientTime, int serverTime) {
    final diff = (serverTime - clientTime).abs();
    const maxDiff = 1 * 60; // 1分钟以内
    return diff > maxDiff;
  }
}
