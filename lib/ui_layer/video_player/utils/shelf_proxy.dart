// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import '../../../../../crypto.dart';

/// A handler that proxies requests to [url].
///
/// To generate the proxy request, this concatenates [url] and [Request.url].
/// This means that if the handler mounted under `/documentation` and [url] is
/// `http://example.com/docs`, a request to `/documentation/tutorials`
/// will be proxied to `http://example.com/docs/tutorials`.
///
/// [url] must be a [String] or [Uri].
///
/// [client] is used internally to make HTTP requests. It defaults to a
/// `dart:io`-based client.
///
/// [proxyName] is used in headers to identify this proxy. It should be a valid
/// HTTP token or a hostname. It defaults to `shelf_proxy`.

List<Map<String, int>> servers = [];
int current_port = 8888;
int static_port = 9999;

String proxy_host = '127.0.0.1';
String seg_str = '&hls_seg&';
String md5_salt = 'wyll123456';
String cache_folder = 'VideoCache';

Future createServer(String url, int isShort) async {
  RegExp domainReg = RegExp(r'(http|https):\/\/[^\/]*');
  String domainStr = domainReg.stringMatch(url) ?? '';
  int port = 8888;
  bool flag = servers.any((element) {
    if (element.keys.first == domainStr) {
      port = element.values.first;
      return true;
    }
    return false;
  });
  if (domainStr.isEmpty) {
    // 如果解密的key为空字符串则不创建代理服务器，域名原封不动，不作替换
    return {'origin': domainStr, 'localproxy': domainStr};
  } else {
    if (!flag) {
      // 创建服务器
      var server = await shelf_io.serve(
          proxyHandler(domainStr), '127.0.0.1', current_port,
          shared: true);
      servers.add({domainStr: current_port});
      current_port++;
      return {
        'origin': domainStr,
        'localproxy': 'http://127.0.0.1:${current_port - 1}'
      };
    } else {
      return {'origin': domainStr, 'localproxy': 'http://127.0.0.1:$port'};
    }
  }
}

Future createStaticServer(String url) async {
  List<String> urls = url.split('/');
  String fileName = urls[urls.length - 1];
  int port = 8888;
  bool flag = servers.any((element) {
    if (element.keys.first == fileName) {
      port = element.values.first;
      return true;
    }
    return false;
  });
  Future createServer() async {
    try {
      var handler = createStaticHandler(
        url.substring(0, url.lastIndexOf('/')),
        defaultDocument: fileName,
      );
      HttpServer server;
      server = await shelf_io.serve(handler, '127.0.0.1', static_port);
      servers.add({fileName: static_port});
      static_port++;
      return 'http://${server.address.host}:${server.port}/$fileName';
    } catch (e) {
      static_port++;
      return createServer();
    }
  }

  String localUrl;
  if (!flag) {
    localUrl = await createServer();
    return localUrl;
  } else {
    return 'http://127.0.0.1:$port/$fileName';
  }
}

Handler proxyHandler(url, {http.Client? client, String? proxyName}) {
  Uri uri;
  if (url is String) {
    uri = Uri.parse(url);
  } else if (url is Uri) {
    uri = url;
  } else {
    throw ArgumentError.value(url, 'url', 'url must be a String or Uri.');
  }
  final nonNullClient = client ?? http.Client();
  proxyName ??= 'shelf_proxy';

  return (serverRequest) async {
    // TODO(nweiz): Support WebSocket requests.

    // TODO(nweiz): Handle TRACE requests correctly. See
    // http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.8
    final requestUrl = uri.resolve(serverRequest.url.toString());
    final clientRequest = http.StreamedRequest(serverRequest.method, requestUrl)
      ..followRedirects = false
      ..headers.addAll(serverRequest.headers)
      ..headers['Host'] = uri.authority;

    // Add a Via header. See
    // http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.45

    unawaited(serverRequest
        .read()
        .forEach(clientRequest.sink.add)
        .catchError(clientRequest.sink.addError)
        .whenComplete(clientRequest.sink.close));
    final clientResponse = await nonNullClient.send(clientRequest);
    // Add a Via header. See
    // http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.45

    // Remove the transfer-encoding since the body has already been decoded by
    // [client].
    clientResponse.headers.remove('transfer-encoding');

    // If the original response was gzipped, it will be decoded by [client]
    // and we'll have no way of knowing its actual content-length.
    if (clientResponse.headers['content-encoding'] == 'gzip') {
      clientResponse.headers.remove('content-encoding');
      clientResponse.headers.remove('content-length');

      // Add a Warning header. See
      // http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html#sec13.5.2
      _addHeader(
          clientResponse.headers, 'warning', '214 $proxyName "GZIP decoded"');
    }

    // Make sure the Location header is pointing to the proxy server rather
    // than the destination server, if possible.
    if (clientResponse.isRedirect &&
        clientResponse.headers.containsKey('location')) {
      final location = requestUrl
          .resolve(clientResponse.headers['location'] ?? '')
          .toString();
      if (p.url.isWithin(uri.toString(), location)) {
        clientResponse.headers['location'] =
            '/${p.url.relative(location, from: uri.toString())}';
      } else {
        clientResponse.headers['location'] = location;
      }
    }

    if (requestUrl.toString().contains('.m3u8') == true) {
      var encryptData = await clientResponse.stream.bytesToString();
      var decryptData = PlatformAwareCrypto.decryptM3U8(encryptData);
      var str = await _parseM3U8(decryptData, requestUrl.toString());
      return Response(clientResponse.statusCode,
          body: str, headers: clientResponse.headers);
    } else {
      return Response(clientResponse.statusCode,
          body: clientResponse.stream, headers: clientResponse.headers);
    }
  };
}

// 处理请求
Future<Response?> preDealRequest(
    StringBuffer urlStrBuffer, StringBuffer localFilePathBuffer) async {
  String urlStr = urlStrBuffer.toString();
  String localFilePath = '';

  if (urlStr.contains('.m3u8')) {
    // String folderName = getFolderName(urlStr);
    // String fileName = stringByHashEncode(urlStr.substring(
    //     urlStr.lastIndexOf('/') + 1, urlStr.indexOf('.m3u8')));
    // localFilePath = await getCachePath(folderName) + '$fileName.m3u8';

    // File file = File(localFilePath);
    // final stat = file.statSync();
    // if (stat.size > 0) {
    //   String contents = await file.readAsString();
    //   final headers = {
    //     HttpHeaders.lastModifiedHeader: formatHttpDate(stat.modified),
    //     HttpHeaders.contentLengthHeader: '${stat.size}',
    //     HttpHeaders.contentTypeHeader: 'text/plain; charset=utf-8',
    //   };
    //   return Response.ok(contents, headers: headers);
    // } else {
    //   localFilePathBuffer.write(localFilePath);
    // }
  } else {
    try {
      String decodeStr = stringByBase64Decode(urlStr);
      if (decodeStr.contains(seg_str)) {
        List<String> urlArr = decodeStr.split(seg_str);
        if (urlArr.length < 3) return null;
        urlStr = urlArr[0];
        String folderName = urlArr[1];
        String fileName = urlArr[2];
        localFilePath = await getCachePath(folderName) + fileName;

        File file = File(localFilePath);
        final stat = file.statSync();
        if (stat.size > 0) {
          Stream<List<int>> contents = file.openRead();
          final headers = {
            HttpHeaders.lastModifiedHeader: formatHttpDate(stat.modified),
            HttpHeaders.acceptRangesHeader: 'bytes',
            HttpHeaders.contentLengthHeader: '${stat.size}',
          };
          return Response.ok(contents, headers: headers);
        } else {
          urlStrBuffer.clear();
          urlStrBuffer.write(urlStr);
          localFilePathBuffer.write(localFilePath);
        }
      }
    } catch (e) {
      CommonUtils.log('读取预加载、边下边播缓存报错：$e');
      return null;
    }
  }
  return null;
}

// 处理m3u8索引文件（原处理逻辑）
Future<String> parseM3U8(String str, String m3u8Url, int isShort) async {
  RegExp domainReg = RegExp(r"(http|https):\/\/[^\/]*");
  // hls返回的片段域名不同
  List<String> tsArr = str.split('\n');
  List<String> domainStrArr = [];
  for (var tsStr in tsArr) {
    String domainStr = domainReg.stringMatch(tsStr) ?? "";
    if (domainStr.isNotEmpty) {
      if (!domainStrArr.contains(domainStr)) {
        domainStrArr.add(domainStr);
      }
    }
  }
  String resultStr = str;
  if (domainStrArr.isNotEmpty) {
    // 如果ts自带域名则建立新的代理服务器
    for (var domainStr in domainStrArr) {
      Map config = await createServer(domainStr, isShort);
      resultStr = resultStr.replaceAll(domainStr, config['localproxy']);
    }
    // 边下边播改造
    String folderName = getFolderName(m3u8Url);
    resultStr = processingM3U8IndexFile(resultStr, folderName);
  }
  return resultStr;
}

// 处理m3u8索引文件（边下边播改造）
String processingM3U8IndexFile(String m3u8FileStr, String folderName) {
  List<String> tsArr = m3u8FileStr.split('\n');
  var newTsArr = tsArr.map((element) {
    // 1.ts片链接处理
    if ((element.contains('http') || element.contains('https')) &&
        element.contains('.ts') &&
        !element.contains('EXT-X-KEY')) {
      // 1.1根据原文件名，生成一个新hash字符串，作为本地缓存的文件名
      String itemName = element.substring(
          element.lastIndexOf('/') + 1, element.indexOf('.ts'));
      String hashString = stringByHashEncode(itemName);
      // 1.2拼接数据，得到完整本地分片链
      element += '$seg_str$folderName$seg_str$hashString.ts';
      // 1.3 origin后部分base64编码处理
      String origin = '${getUrlOrigin(element)}/';
      String encodeStr = stringByBase64Encode(element.replaceAll(origin, ''));
      // 1.4生成全新的ts分片
      element = origin + encodeStr;
    } // 2.其他链接处理
    else if ((element.contains('http') || element.contains('https')) &&
        (element.contains('.key') || element.contains('EXT-X-KEY'))) {
      String suffix = element.contains('.ts') ? '.ts' : '.key';
      // 2.1根据原文件名，生成一个新hash字符串，作为本地缓存的文件名
      String itemName = element.substring(
          element.lastIndexOf('/') + 1, element.indexOf(suffix));
      String hashString = stringByHashEncode(itemName);
      // 2.2截取数据，拿到该行中的url
      String mainUrl =
          element.substring(element.indexOf('"') + 1, element.lastIndexOf('"'));
      String newMainUrl =
          mainUrl + seg_str + folderName + seg_str + hashString + suffix;
      // 2.3 origin后部分base64编码处理
      String origin = '${getUrlOrigin(newMainUrl)}/';
      String encodeStr =
          stringByBase64Encode(newMainUrl.replaceAll(origin, ''));
      // 2.4 替换为新生成的url
      newMainUrl = origin + encodeStr;
      element = element.replaceAll(mainUrl, newMainUrl);
    }
    return element;
  }).toList();
  return newTsArr.join('\n');
}

// 缓存m3u8索引文件
Future cacheIndexFile(String savePath, String content) async {
  if (savePath.isEmpty) return;

  double remainMemory = await CommonUtils.getRemainMemory();
  if (remainMemory < 5 * 1000.0 * 1000.0 * 1000.0 && remainMemory >= 0.0) {
    return;
  }

  try {
    await File(savePath).writeAsString(content);
  } on FileSystemException catch (e) {
    CommonUtils.log(e);
  }
}

// 缓存m3u8文件中的分片
Future cacheExcerptFile(String savePath, Stream<List<int>> content) async {
  if (savePath.isEmpty) return;

  double remainMemory = await CommonUtils.getRemainMemory();
  if (remainMemory < 5 * 1000.0 * 1000.0 * 1000.0 && remainMemory > 0.0) return;

  final file = await File(savePath).create();
  final IOSink sink = file.openWrite();
  // 订阅Stream
  StreamSubscription<List<int>> subscription;
  subscription = content.listen(
    (data) {
      try {
        sink.add(data);
      } catch (e) {
        CommonUtils.log('保存分片文件错误:$e');
      }
    },
    onError: (error) async {
      // 错误处理
      await sink.close();
      await file.delete();
    },
    cancelOnError: true, // 如果为true，则遇到错误时会自动取消订阅
  );
  subscription.onDone(() async {
    // 完成处理
    await subscription.cancel();
    await sink.close();
  });
}

// 获取链接的origin
String getUrlOrigin(String url) {
  Uri uri = Uri.parse(url);
  return uri.origin;
}

// 字符串base64编码
String stringByBase64Encode(String string) {
  List<int> bytes = utf8.encode(string);
  String encodeStr = base64Encode(bytes);
  return encodeStr;
}

// 字符串base64解码
String stringByBase64Decode(String encodeStr) {
  List<int> bytes = base64Decode(encodeStr);
  String decodeStr = String.fromCharCodes(bytes);
  return decodeStr;
}

// 字符串哈希编码
String stringByHashEncode(String string) {
  String saltedPassword = '$string$md5_salt';

  //UTF8编码
  List<int> bytes = utf8.encode(saltedPassword);
  //MD5哈希处理
  Digest md5Hash = md5.convert(bytes);
  //将结果转换为十六进制字符串
  String hexHash = md5Hash.toString();

  return hexHash;
}

// 哈希编码校验
bool isPassedHashEncode(String originString, String hashString) {
  String hashEncodeString = stringByHashEncode(originString);
  return hashEncodeString == hashString ? true : false;
}

// 生成缓存的本地文件夹名
String getFolderName(String m3u8Url) {
  String origin = '${getUrlOrigin(m3u8Url)}/';
  String folderName = stringByHashEncode(m3u8Url.substring(
      m3u8Url.indexOf(origin) + origin.length, m3u8Url.indexOf('.m3u8')));
  return folderName;
}

// 获取视频缓存文件夹路径
Future<String> getCachePath(String folderName) async {
  Directory? documents;
  if (Platform.isAndroid) {
    documents = await getExternalStorageDirectory();
  } else {
    documents = await getApplicationDocumentsDirectory();
  }

  // 获取Documents文件目录
  String documentsDirectory = documents!.path;
  // 拼接文件夹名称，生成视频缓存文件夹路径
  String cachePath = '$documentsDirectory/$cache_folder/$folderName/';
  // 判断是否含有缓存文件夹路径
  Directory directory = Directory(cachePath);
  bool isExists = await directory.exists();
  if (!isExists) {
    // 如果没有，则创建
    await directory.create(recursive: true);
  }
  return cachePath;
}

// 判断本地端口是否可用，不可用则+1递归调用，直到拿到可用端口
Future<int> isPortUsed(int port) async {
  try {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
    await server.close();
    return port;
  } on SocketException catch (_) {
    int availPort = await isPortUsed(port + 1);
    return availPort;
  }
}

Future _parseM3U8(String str, String m3u8_url) async {
  RegExp domainReg = RegExp(r'(http|https):\/\/[^\/]*');
  String domainStr = domainReg.stringMatch(str) ?? '';
  String resultStr = '';
  if (domainStr.isNotEmpty) {
    // 如果ts自带域名则建立新的代理服务器
    Map config = await createServer(domainStr, 1);
    resultStr = str.replaceAll(domainStr, config['localproxy']);
  } else {
    // 如果ts不带域名则使用m3u8的域名作为代理服务器，ts列表字符串不做处理
    resultStr = str;
  }
  return resultStr;
}

void _addHeader(Map<String, String> headers, String name, String value) {
  final existing = headers[name];
  headers[name] = existing == null ? value : '$existing, $value';
}

String randomId(int len) {
  String str = '';
  int range = len;
  int pos;
  List<String> arr = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];
  for (var i = 0; i < range; i++) {
    pos = Random().nextInt(arr.length - 1);
    str += arr[pos];
  }
  return str;
}
