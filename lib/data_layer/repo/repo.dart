import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:g_link/data_layer/repo/http_interceptor.dart';
import 'package:g_link/data_layer/repo/utils.dart';
import 'package:g_link/domain/domains/report.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/domains/auth.dart';
import 'package:g_link/domain/result.dart';
import 'package:g_link/report/ui_layer/report_timing_interceptor.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:utils/utils.dart';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import 'package:http_parser/http_parser.dart';

import 'package:g_link/app_config.dart';
import 'package:g_link/app_global.dart';
import 'package:g_link/domain/model/ad_model.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/domain/model/auth_models.dart';
import 'package:g_link/data_layer/repo/r2_uploader.dart';

import 'package:g_link/data_layer/data_source/home_service.dart';
import 'package:g_link/data_layer/data_source/profile_service.dart';
import 'package:g_link/data_layer/data_source/report_service.dart';
import 'package:g_link/data_layer/data_source/auth_service.dart';

import 'package:g_link/domain/domain.dart';
import 'package:g_link/domain/enum.dart';
import 'package:g_link/domain/type_def.dart';

import 'package:g_link/domain/domains/home.dart';

part 'cache.dart';

part 'mixins/home_mixin.dart';
part 'mixins/report_mixin.dart';
part 'mixins/profile_mixin.dart';
part 'mixins/auth_mixin.dart';

class AppRepo extends _BaseAppRepo with _Home, _Report, _Profile, _Auth {}

abstract class _BaseAppRepo implements AppDomain {
  late final _homeService = HomeService(_apiDio);
  late final _reportService = ReportService(_apiDio);
  late final _profileService = ProfileService(_apiDio);
  late final _authService = AuthService(_apiDio);

  final _cacheManager = _CacheManager();
  final _tokenValidStreamController = StreamController<MyTokenStatus?>();

  @override
  late final tokenStatusStream =
      _tokenValidStreamController.stream.asBroadcastStream();

  late final _apiDio = Dio(
    BaseOptions(
      baseUrl: BuildConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      contentType: Headers.formUrlEncodedContentType,
    ),
  );

  Dio get apiDio => _apiDio;

  /// 未加密网路服务/上传资源
  late final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 300),
    ),
  );

  bool _isInitialized = false;
  Json _appInfo = {};

  @override
  Json get info => _appInfo;

  @override
  CacheDomain get cache => _cacheManager;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _cacheManager.init();
    _appInfo = await _getAppInfo();

    _apiDio.interceptors.add(AutoEncryptAndDecryptInterceptor(_appInfo));
    _apiDio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) async {
          if (response.data case final Map data when data['msg'] == 'token无效') {
            await _cleanToken();
            _tokenValidStreamController.sink.add(MyTokenStatus.invalid);
          }
          return handler.next(response);
        },
      ),
    );
    _apiDio.interceptors.add(ReportTimingInterceptor());
  }

  Future _cleanToken() async {
    try {
      if (_appInfo.token != null) {
        _appInfo.removeToken();
        await _cacheManager.deleteAuthToken();
      }
    } catch (_) {}
  }

  void _updateToken(String token) {
    _appInfo.token = token;
    _cacheManager.upsertAuthToken(token);
    _tokenValidStreamController.sink.add(MyTokenStatus.valid);
  }

  Future<Json> _getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();

    final info = kIsWeb
        ? {
            'bundleId': BuildConfig.webBundleId,
            'version': packageInfo.version,
            'language': 'zh',
            'via': 'pwa',
          }
        : {
            'bundleId': packageInfo.packageName,
            'version': packageInfo.version,
            // "build_affcode": "cweZ2",
          };

    info.addAll({
      'oauth_id': await _getOAuthId(),
      'oauth_type': getOAuthType(),
    });

    final token = await _cacheManager.readAuthToken();

    if (token != null) {
      info.token = token;
      _tokenValidStreamController.sink.add(MyTokenStatus.valid);
    } else {
      _tokenValidStreamController.sink.add(null);
    }

    return info;
  }

  Future<String> _getOAuthId() async {
    String? deviceId;
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        const androidIdPlugin = AndroidId();
        final androidId = await androidIdPlugin.getId();
        deviceId = androidId;
      } else if (Platform.isIOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
      }
    }

    deviceId ??= await _cacheManager.readOauthId();

    if (deviceId == null) {
      deviceId =
          '${RepoUtils.randomId(16)}_${DateTime.now().millisecondsSinceEpoch}';
      await _cacheManager.upsertOauthId(deviceId);
    }
    return RepoUtils.gvMD5(deviceId);
  }

  @override
  void initLine({
    Function? success,
    Function? failed,
    Function(List<String>)? lines,
  }) async {}

  @override
  void setBaseURL(String url) async {
    if (url.isEmpty) {
      return;
    }
    _apiDio.options.baseUrl = url;
  }

  @override
  void setInstallFlag(String flag) {}

  @override
  void setReportTraceId(String id) async {}

  @override
  void setAffXCode(String code) async {}

  @override
  String getOAuthId() => '';

  @override
  String getOAuthType() {
    if (kIsWeb) {
      return 'web';
    }
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    return 'web';
  }

  @override
  AsyncJson uploadImageBytes({
    required String baseUrl,
    required String key,
    required Uint8List bytes,
    String position = 'head',
    String? id,
    CancelToken? cancelToken,
    ProgressCallback? progressCallback,
  }) async {
    final id0 = id ?? '${DateTime.now().millisecondsSinceEpoch}';
    final newKey = 'id=$id0&position=$position${key.replaceFirst('head', '')}';
    final tmpSha256 = _gvSha256(newKey);
    final sign = _gvMD5(tmpSha256);
    final imageName = _gvMD5(id0);

    final formData = FormData.fromMap({
      'id': id0,
      'position': position,
      'sign': sign,
      'cover': MultipartFile.fromBytes(
        bytes,
        filename: '$imageName.png',
        contentType: MediaType.parse('image/png'),
      ),
    });

    final response = await _dio.post(
      baseUrl,
      data: formData,
      cancelToken: cancelToken,
      onSendProgress: progressCallback,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    return jsonDecode(response.data);
  }

  @override
  AsyncJson uploadImage({
    required XFile xFile,
    required String baseUrl,
    required String key,
    String position = 'head',
    String? id,
    CancelToken? cancelToken,
    ProgressCallback? progressCallback,
  }) async {
    final id0 = id ?? '${DateTime.now().millisecondsSinceEpoch}';
    final newKey = 'id=$id0&position=$position${key.replaceFirst('head', '')}';
    final tmpSha256 = _gvSha256(newKey);
    final sign = _gvMD5(tmpSha256);
    final imageName = _gvMD5(id0);
    final ext = xFile.name.split('.').last;

    final formData = FormData.fromMap({
      'id': id0,
      'position': position,
      'sign': sign,
      'cover': MultipartFile.fromBytes(
        await xFile.readAsBytes(),
        filename: '$imageName.$ext',
        contentType: MediaType.parse('image/$ext'),
      ),
    });

    final response = await _dio.post(
      baseUrl,
      data: formData,
      cancelToken: cancelToken,
      onSendProgress: progressCallback,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    return jsonDecode(response.data);
  }

  @override
  AsyncJson uploadVideo({
    required BuildContext context,
    required XFile xFile,
    CancelToken? cancelToken,
    ProgressCallback? progressCallback,
  }) async {
    final result =
        await R2UploaderUtil(context: context, cancelToken: cancelToken).upload(
      xFile: xFile,
      progressCallback: progressCallback,
    );
    return result;
  }

  @override
  Future<Response> downloadApk({
    required String urlPath,
    required String savePath,
    ProgressCallback? onReceiveProgress,
  }) =>
      _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
      );
}

extension _MapHelper on Map {
  String get _tokenKey => 'token';

  void removeToken() => remove(_tokenKey);

  String? get token => this[_tokenKey];
  set token(String? value) {
    if (value == null) {
      remove(_tokenKey);
    } else {
      this[_tokenKey] = value;
    }
  }
}

extension _Guard<T> on AsyncResult<T> {
  AsyncResult<T> get guard async {
    try {
      return await this;
    } catch (err, stack) {
      CommonUtils.log(err);
      CommonUtils.log(stack);
      return Result(msg: err.toString() + stack.toString());
    }
  }
}

String _gvMD5(String data) {
  var content = const Utf8Encoder().convert(data);
  var digest = md5.convert(content);
  var text = hex.encode(digest.bytes);
  return text;
}

String _gvSha256(String data) {
  var content = const Utf8Encoder().convert(data);
  var digest = sha256.convert(content);
  var text = hex.encode(digest.bytes);
  return text;
}
