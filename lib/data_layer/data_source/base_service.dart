import 'package:dio/dio.dart';
import 'package:g_link/domain/exception.dart';
import 'package:g_link/domain/type_def.dart';
import 'package:g_link/logger.dart';
import 'dart:developer' as developer;

abstract class BaseService {
  BaseService(this._dio);

  final Dio _dio;

  String get service;

  AsyncJson post(
    String path, {
    Object? data,
    bool encrypted = true,
    bool jsonBody = true,
    Options? options,
  }) async {
    logger.i('请求的路径:${'/api/$service$path'}');
    final requestOptions = (options ?? Options()).copyWith(
      contentType: options?.contentType ??
          (jsonBody
              ? Headers.jsonContentType
              : Headers.formUrlEncodedContentType),
      extra: {
        ...(options?.extra ?? const <String, dynamic>{}),
        'skipEncrypt': !encrypted,
      },
    );
    final result = (await _dio.post(
      '/api/$service$path',
      data: data,
      options: requestOptions,
    ))
        .data;
    if (result == null) {
      throw ResponseNullException();
    }
    //打印返回数据
    developer.log(
        'RequstPath: ${_dio.options.baseUrl}/api/$service$path, params: $data, \nResult: $result');
    return result;
  }

  AsyncJson get(String path,
      {Map<String, dynamic>? queryParameters, bool encrypted = true}) async {
    logger.i('请求的路径:${'/api/$service$path'}');
    final result = (await _dio.get(
      '/api/$service$path',
      queryParameters: queryParameters,
      options: Options(
        extra: {
          'skipEncrypt': !encrypted,
        },
      ),
    ))
        .data;
    if (result == null) {
      throw ResponseNullException();
    }
    developer.log(
      'RequstPath: ${_dio.options.baseUrl}/api/$service$path, params: $queryParameters, \nResult: $result',
    );
    return result;
  }

  AsyncJson put(String path,
      {Object? data, bool encrypted = true, bool jsonBody = true}) async {
    logger.i('请求的路径:${'/api/$service$path'}');
    final result = (await _dio.put(
      '/api/$service$path',
      data: data,
      options: Options(
        contentType: jsonBody
            ? Headers.jsonContentType
            : Headers.formUrlEncodedContentType,
        extra: {
          'skipEncrypt': !encrypted,
        },
      ),
    ))
        .data;
    if (result == null) {
      throw ResponseNullException();
    }
    developer.log(
      'RequstPath: ${_dio.options.baseUrl}/api/$service$path, params: $data, \nResult: $result',
    );
    return result;
  }

  AsyncJson delete(String path,
      {Object? data,
      Map<String, dynamic>? queryParameters,
      bool encrypted = true}) async {
    logger.i('请求的路径:${'/api/$service$path'}');
    final result = (await _dio.delete(
      '/api/$service$path',
      data: data,
      queryParameters: queryParameters,
      options: Options(
        extra: {
          'skipEncrypt': !encrypted,
        },
      ),
    ))
        .data;
    if (result == null) {
      throw ResponseNullException();
    }
    developer.log(
      'RequstPath: ${_dio.options.baseUrl}/api/$service$path, params: $data, \nResult: $result',
    );
    return result;
  }

  AsyncJson patch(String path,
      {Object? data, bool encrypted = true, bool jsonBody = true}) async {
    logger.i('请求的路径:${'/api/$service$path'}');
    final result = (await _dio.patch(
      '/api/$service$path',
      data: data,
      options: Options(
        contentType: jsonBody
            ? Headers.jsonContentType
            : Headers.formUrlEncodedContentType,
        extra: {
          'skipEncrypt': !encrypted,
        },
      ),
    ))
        .data;
    if (result == null) {
      throw ResponseNullException();
    }
    developer.log(
      'RequstPath: ${_dio.options.baseUrl}/api/$service$path, params: $data, \nResult: $result',
    );
    return result;
  }
}
