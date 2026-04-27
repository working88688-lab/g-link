import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:g_link/data_layer/data_source/chat_service.dart';
import 'package:g_link/data_layer/repo/http_interceptor.dart';
import 'package:g_link/domain/domains/chat.dart';
import 'package:g_link/domain/model/chat_model.dart';
import 'package:g_link/data_layer/repo/utils.dart';
import 'package:g_link/domain/domains/report.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/domains/auth.dart';
import 'package:g_link/domain/result.dart';
import 'package:g_link/report/ui_layer/report_timing_interceptor.dart';
import 'package:g_link/ui_layer/router/paths.dart';
import 'package:g_link/ui_layer/router/router.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:g_link/utils/my_toast.dart';
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
import 'package:g_link/domain/model/search_models.dart';
import 'package:g_link/data_layer/repo/r2_uploader.dart';

import 'package:g_link/data_layer/data_source/home_service.dart';
import 'package:g_link/data_layer/data_source/profile_service.dart';
import 'package:g_link/data_layer/data_source/report_service.dart';
import 'package:g_link/data_layer/data_source/auth_service.dart';
import 'package:g_link/data_layer/data_source/search_service.dart';
import 'package:g_link/data_layer/data_source/user_report_service.dart';

import 'package:g_link/domain/domain.dart';
import 'package:g_link/domain/enum.dart';
import 'package:g_link/domain/type_def.dart';

import 'package:g_link/domain/domains/home.dart';
import 'package:g_link/domain/domains/search.dart';

part 'cache.dart';

part 'mixins/chat_mixin.dart';
part 'mixins/home_mixin.dart';
part 'mixins/report_mixin.dart';
part 'mixins/profile_mixin.dart';
part 'mixins/auth_mixin.dart';
part 'mixins/search_mixin.dart';

class AppRepo extends _BaseAppRepo
    with _Home, _Report, _Profile, _Auth, _Chat, _Search {}

abstract class _BaseAppRepo implements AppDomain {
  late final _homeService = HomeService(_apiDio);
  late final _reportService = ReportService(_apiDio);
  late final _userReportService = UserReportService(_apiDio);
  late final _profileService = ProfileService(_apiDio);
  late final _authService = AuthService(_apiDio);
  late final _chatService = ChatService(_v1Dio);
  late final _searchService = SearchService(_apiDio);

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

  /// v1 REST API（Bearer 认证，非加密）
  late final _v1Dio = Dio(
    BaseOptions(
      baseUrl: BuildConfig.v1ApiBase,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _applyCommonHeaders(options);
          final token = _appInfo.token?.trim();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          _printCurl(options);
          return handler.next(options);
        },
      ),
    );

  /// 未加密网路服务/上传资源
  late final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 300),
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _applyCommonHeaders(options);
          _printCurl(options);
          return handler.next(options);
        },
      ),
    );

  bool _isInitialized = false;
  bool _authRedirecting = false;
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
        onRequest: (options, handler) {
          _applyCommonHeaders(options);
          final token = _appInfo.token?.trim();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          _printCurl(options);
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          if (_isAuthRequiredResponse(response.data)) {
            await _handleAuthRequired();
          }
          return handler.next(response);
        },
        onError: (err, handler) async {
          final statusCode = err.response?.statusCode;
          if (statusCode == 401 || statusCode == 403) {
            await _handleAuthRequired();
          }
          return handler.next(err);
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

  bool _isAuthRequiredResponse(dynamic data) {
    if (data is! Map) return false;
    final msg = '${data['msg'] ?? data['message'] ?? ''}'.toLowerCase();
    final code = int.tryParse('${data['code'] ?? data['status'] ?? ''}') ?? 0;
    if (msg.contains('token无效') ||
        msg.contains('未登录') ||
        msg.contains('需要登录') ||
        msg.contains('invalid token') ||
        msg.contains('token has expired') ||
        msg.contains('please login again')) {
      return true;
    }
    return code == 401 || code == 403 || code == -401;
  }

  Future<void> _handleAuthRequired() async {
    if (_authRedirecting) return;
    _authRedirecting = true;
    await _cleanToken();
    _tokenValidStreamController.sink.add(MyTokenStatus.invalid);
    MyToast.showText(text: '需要登录');
    try {
      AppRouter.router.go(AppRouterPaths.login);
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      _authRedirecting = false;
    }
  }

  void _applyCommonHeaders(RequestOptions options) {
    options.headers['Accept'] = Headers.jsonContentType;
    options.headers['X-Device-Id'] = '${_appInfo['oauth_id'] ?? ''}';
    options.headers['X-App-Version'] = '${_appInfo['version'] ?? ''}';
    options.headers['X-Platform'] = _platformHeaderValue();

    final isUpload = options.data is FormData;
    if (!isUpload) {
      options.headers['Content-Type'] = Headers.jsonContentType;
    }
  }

  String _platformHeaderValue() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'web';
  }

  void _printCurl(RequestOptions options) {
    final url = options.uri.toString();
    final buffer =
        StringBuffer("curl -X ${options.method.toUpperCase()} '$url'");

    options.headers.forEach((key, value) {
      if (value == null) return;
      final headerValue = value.toString().replaceAll("'", r"'\''");
      buffer.write(" -H '$key: $headerValue'");
    });

    final data = options.data;
    if (data != null) {
      if (data is FormData) {
        for (final field in data.fields) {
          final fieldValue = field.value.replaceAll("'", r"'\''");
          buffer.write(" -F '${field.key}=$fieldValue'");
        }
        for (final file in data.files) {
          buffer.write(" -F '${file.key}=@<file>'");
        }
      } else {
        final body = data is String ? data : jsonEncode(data);
        final escapedBody = body.replaceAll("'", r"'\''");
        buffer.write(" --data-raw '$escapedBody'");
      }
    }

    debugPrint('[cURL] ${buffer.toString()}');
  }

  void _updateToken(String token, String refreshToken) {
    _appInfo.token = token;
    _appInfo.refreshToken = refreshToken;
    _cacheManager.upsertAuthToken(token);
    _cacheManager.upsertRefreshToken(refreshToken);
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

    final token = (await _cacheManager.readAuthToken())?.trim();

    if (token != null && token.isNotEmpty) {
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

  String get _refreshTokenKey => 'refresh_token';

  void removeRefreshToken() => remove(_refreshTokenKey);

  String? get refreshToken => this[_refreshTokenKey];
  set refreshToken(String? value) {
    if (value == null) {
      remove(_refreshTokenKey);
    } else {
      this[_refreshTokenKey] = value;
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
