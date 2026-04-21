import 'dart:convert';
import 'dart:io';
import 'package:app_installer/app_installer.dart';
import 'package:crypto/crypto.dart';

import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/app_global.dart';
import 'package:g_link/data_layer/repo/repo.dart';
import 'package:g_link/domain/model/home_data_model.dart';
import 'package:g_link/ui_layer/dialog/regular_dialog.dart';
import 'package:g_link/ui_layer/notifier/home_config_notifier.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../../../domain/domain.dart';
import '../../../../utils/common_utils.dart';

class DownloadApkDialog extends StatefulWidget {
  const DownloadApkDialog(
      {super.key, required this.version, required this.url, this.onTap});

  final String version;
  final String url;
  final Function? onTap;

  @override
  State<DownloadApkDialog> createState() => _DownloadApkDialogState();
}

class _DownloadApkDialogState extends State<DownloadApkDialog> {
  late final appDomain = context.read<AppDomain>();
  ValueNotifier<int> progressNotifier = ValueNotifier(0);

  Future<void> _installApk(savePath) async {
    try {
      await CommonUtils.checkRequestInstallPackages();
      await CommonUtils.checkStoragePermission();
      await AppInstaller.installApk(savePath);
    } catch (_) {}
  }

  Future<bool> md5ApkFile(File apkFile) async {
    final digest = await sha256.bind(apkFile.openRead()).first;
    VersionMsg? cf = context.read<HomeConfigNotifier>().homeData.versionMsg;
    String fileSha256 = digest.toString();
    // return false;
    return cf?.sha256 == fileSha256;
  }

  Future<void> _init() async {
    try {
      final result = await getExternalStorageDirectory();
      String savePath =
          '${result?.path}/wwsj.${DateTime.now().millisecondsSinceEpoch}.apk';
      await appDomain.downloadApk(
          urlPath: widget.url,
          savePath: savePath,
          onReceiveProgress: (int count, int total) async {
            var tmp = (count / total * 100).toInt();
            if (tmp % 1 == 0) {
              progressNotifier.value = tmp;
            }
            if (count >= total) {
              if (await md5ApkFile(File(savePath))) {
                _installApk(savePath);
              } else {
                // // //关闭升级弹窗
                // widget.onTap?.call();
                UpgradeFailHint hint =
                    context.read<HomeConfigNotifier>().homeData.upgradeFail!;
                //弹出告警提示
                BotToast.showWidget(
                    toastBuilder: (cancelFunc) => RegularDialog(
                          title: '',
                          content: Text(hint.title, style: MyTheme.gray153_14),
                          buttonText: hint.label,
                          confirmOnTap: () {
                            CommonUtils.launchUrl(hint.url);
                          },
                        ));

                //接口篡改上报
                if (AppGlobal.context != null) {
                  final apiDio = AppGlobal.context!.read<AppRepo>().apiDio;
                  final response = await apiDio.post('/api/home/config');

                  Map<String, dynamic> map = {
                    'url': response.requestOptions.baseUrl +
                        response.requestOptions.path,
                    'req_header': Map.from(response.requestOptions.headers),
                    'res_header': Map.from(response.headers.map),
                    'data': response.data,
                  };

                  //上报数据type 1 接口校验 2 APK校验
                  final res = await apiDio.post('/api/home/hijack', data: {
                    'type': 2,
                    'json': jsonEncode(map),
                  });
                  CommonUtils.log('$res');
                }
                return;
              }
            }
          });
    } catch (e) {
      BotToast.cleanAll();
      BotToast.showText(text: tr('xzsb'));
    }
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Stack(
        children: [
          Positioned(
              child: Center(
            child: SizedBox(
              width: 345.w,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                        color: Color(0xFF15152a),
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    padding: EdgeInsets.symmetric(
                        vertical: 15.5.w, horizontal: 20.w),
                    child: Column(
                      children: <Widget>[
                        Text(
                          "${tr('zzgx')} v.${widget.version}",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              decoration: TextDecoration.none,
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.left,
                        ),
                        SizedBox(
                          height: 10.w,
                        ),
                        Text(
                          tr('sjlts'),
                          style: TextStyle(
                              color: const Color(0xffffffff),
                              fontSize: 12.sp,
                              decoration: TextDecoration.none,
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.left,
                        ),
                        SizedBox(
                          height: 25.w,
                        ),
                        SizedBox(
                          width: 185.w,
                          height: 4.w,
                          child: Stack(
                            children: <Widget>[
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(2.w)),
                                child: Stack(
                                  children: <Widget>[
                                    Opacity(
                                      opacity: 0.3,
                                      child: Container(
                                        width: 185.w,
                                        height: 4.w,
                                        decoration: const BoxDecoration(
                                          color:
                                              Color.fromRGBO(236, 174, 55, 1),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(4.w)),
                                        child: AnimatedBuilder(
                                            animation: progressNotifier,
                                            builder: (context, child) {
                                              return Container(
                                                width: progressNotifier.value /
                                                    100 *
                                                    185.w,
                                                height: 4.w,
                                                decoration: const BoxDecoration(
                                                  color: Color.fromRGBO(
                                                      236, 174, 55, 1),
                                                ),
                                              );
                                            }),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 12.w,
                        ),
                        AnimatedBuilder(
                            animation: progressNotifier,
                            builder: (context, child) {
                              return Center(
                                child: Text('${progressNotifier.value}%',
                                    style: TextStyle(
                                        color: const Color.fromRGBO(
                                            236, 174, 55, 1),
                                        fontSize: 18.sp,
                                        decoration: TextDecoration.none,
                                        fontWeight: FontWeight.bold)),
                              );
                            })
                      ],
                    ),
                  )
                ],
              ),
            ),
          ))
        ],
      ),
    );
  }
}
