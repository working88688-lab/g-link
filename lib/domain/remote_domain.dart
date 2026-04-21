import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:g_link/domain/domains/home.dart';
import 'package:g_link/domain/enum.dart';
import 'package:g_link/domain/type_def.dart';


abstract class RemoteDomain implements HomeDomain {
  Stream<MyTokenStatus?> get tokenStatusStream;

  void initLine({
    Function? success,
    Function? failed,
    Function(List<String>)? lines,
  });

  void setBaseURL(String url);

  void setReportTraceId(String id);

  void setAffXCode(String code);

  void setInstallFlag(String flag);

  String getOAuthId();

  String getOAuthType();

  AsyncJson uploadImageBytes({
    required String baseUrl,
    required String key,
    required Uint8List bytes,
    String position = 'head',
    String? id,
    CancelToken? cancelToken,
    ProgressCallback? progressCallback,
  });

  AsyncJson uploadImage({
    required String baseUrl,
    required String key,
    required XFile xFile,
    String? id,
    String position = 'head',
    CancelToken? cancelToken,
    ProgressCallback? progressCallback,
  });

  /// 视频上传
  AsyncJson uploadVideo({
    required BuildContext context,
    required XFile xFile,
    CancelToken? cancelToken,
    ProgressCallback? progressCallback,
  });

  /// 下载apk
  Future<Response> downloadApk({
    required String urlPath,
    required String savePath,
    ProgressCallback? onReceiveProgress,
  });
}
