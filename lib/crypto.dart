import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' as fd;
import 'package:webcrypto/webcrypto.dart';

import 'app_config.dart';

final key = Key.fromUtf8(BuildConfig.key);
final iv = IV.fromUtf8(BuildConfig.iv);
const appKey = BuildConfig.appKey;
final mediaKey = Key.fromUtf8(BuildConfig.mediaKey);
final mediaIv = IV.fromUtf8(BuildConfig.mediaIv);

String getSign(Map obj) {
  final keyValues = [];
  keyValues.add("_ver=${obj['_ver']}");
  keyValues.add("client=${obj['client']}");
  keyValues.add("data=${obj['data']}");
  keyValues.add("timestamp=${obj['timestamp']}");
  final text = '${keyValues.join('&')}$appKey';
  final digest = sha256.convert(utf8.encode(text));
  final md5Text = md5.convert(utf8.encode(digest.toString())).toString();
  return md5Text;
}

String getReportSign(Map obj, {String signKey = ''}) {
  final keyValues = [];
  keyValues.add("client=${obj['client']}");
  keyValues.add("data=${obj['data']}");
  keyValues.add("timestamp=${obj['timestamp']}");

  final text = '${keyValues.join('&')}$signKey';
  final digest = sha256.convert(utf8.encode(text));
  final md5Text = md5.convert(utf8.encode(digest.toString())).toString();
  return md5Text;
}

class PlatformAwareCrypto {
  static dynamic encryptReqParams(Object value) {
    final word = jsonEncode(value);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encryptBytes(utf8.encode(word), iv: iv);
    final data = utf8.decode(encrypted.base64.codeUnits);
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final sign = getSign({
      '_ver': BuildConfig.ver,
      'client': fd.kIsWeb ? 'pwa' : 'android',
      'data': data,
      'timestamp': timestamp,
    });
    return '_ver=${BuildConfig.ver}&client=${fd.kIsWeb ? 'pwa' : 'android'}&timestamp=$timestamp&data=$data&sign=$sign';
  }

  static dynamic decryptResData(dynamic data) async {
    // final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    // final encrypted = Encrypted.fromBase64(data['data']);
    // final decrypted = encrypter.decrypt(encrypted, iv: iv);

    final k = await AesCbcSecretKey.importRawKey(utf8.encode(BuildConfig.key));

    final raw = await k.decryptBytes(
        base64Decode(data['data']), utf8.encode(BuildConfig.iv));

    return jsonDecode(utf8.decode(raw));
  }

  static dynamic encryptReportParams(Object value,
      {String keyString = '', String ivString = '', String signKey = ''}) {
    final word = jsonEncode(value);
    final encrypter =
        Encrypter(AES(Key.fromUtf8(keyString), mode: AESMode.cbc));
    final encrypted =
        encrypter.encryptBytes(utf8.encode(word), iv: IV.fromUtf8(ivString));
    final data = utf8.decode(encrypted.base64.codeUnits);
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final sign = getReportSign(
        {'client': 'pwa', 'data': data, 'timestamp': timestamp},
        signKey: signKey);
    return 'client=pwa&timestamp=$timestamp&data=$data&sign=$sign';
  }

  //获取小说
  static FutureOr<String> decryptNovel(String? base64) async {
    if (base64 != null) {
      final decrypted = decryptImage(base64);
      if (decrypted != '' && decrypted != null) {
        final rawData = base64Decode(decrypted);
        return utf8.decode(rawData);
      }
    }
    return '';
  }

  static String? decryptImage(data) {
    try {
      final encrypter = Encrypter(AES(mediaKey, mode: AESMode.cbc));
      final encrypted = Encrypted.fromBase64(data);
      final decrypted = encrypter.decryptBytes(encrypted, iv: mediaIv);
      return base64Encode(decrypted);
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> imageDecrypt(Uint8List data) async {
    Encrypter encrypter = Encrypter(AES(mediaKey, mode: AESMode.cbc));
    Encrypted encrypted = Encrypted.fromBase64(base64Encode(data));
    List<int> decrypted = encrypter.decryptBytes(encrypted, iv: mediaIv);
    return Uint8List.fromList(decrypted);
  }

  static dynamic decryptM3U8(data) {
    try {
      final encrypter = Encrypter(AES(mediaKey, mode: AESMode.cbc));
      final encrypted = Encrypted.fromBase64(data);
      final decrypted = encrypter.decrypt(encrypted, iv: mediaIv);
      return decrypted;
    } catch (err) {
      return null;
    }
  }

  static String encry(plainText) {
    try {
      final encrypter = Encrypter(AES(mediaKey, mode: AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: mediaIv);
      return encrypted.base16;
    } catch (err) {
      return plainText;
    }
  }

  static String decry(encrypted) {
    try {
      final encrypter = Encrypter(AES(mediaKey, mode: AESMode.cbc));
      final decrypted = encrypter.decrypt16(encrypted, iv: mediaIv);
      return decrypted;
    } catch (err) {
      return encrypted;
    }
  }

  static String decryptSecret(String data) {
    final encrypter =
        Encrypter(AES(Key.fromUtf8(BuildConfig.secretKey), mode: AESMode.cbc));
    final encrypted = Encrypted.fromBase64(data);
    final decrypted =
        encrypter.decrypt(encrypted, iv: IV.fromUtf8(BuildConfig.secretIv));
    return decrypted;
  }

  static String encryptSecret(String key) {
    final serect = key.split('_').first;
    final interval = int.tryParse(key.split('_').last) ?? 3600;
    final ct =
        (DateTime.now().millisecondsSinceEpoch / 1000 / interval).floor();
    final cal = (sha1.convert(utf8.encode(serect + ct.toString()))).toString();
    final sha = sha1.convert(utf8.encode(serect + cal));
    final str = md5.convert(utf8.encode(sha.toString())).toString();
    return str.substring(0, 16);
  }

  static String secretValue({
    String fdsKey = '',
  }) {
    final key = PlatformAwareCrypto.decryptSecret(
        fdsKey.isEmpty ? BuildConfig.defaultFdsKey : fdsKey);
    final value = PlatformAwareCrypto.encryptSecret(key);
    return value;
  }

  //IM加密专用
  static FutureOr<String> encryptReqParamsWithKey(
      String word, String key, String iv) async {
    final encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));
    final encrypted =
        encrypter.encryptBytes(utf8.encode(word), iv: IV.fromUtf8(iv));
    final data = utf8.decode(encrypted.base64.codeUnits);
    return data;
  }

  //IM解密专用
  static FutureOr<String> decryptResDataWithKey(
    dynamic data,
    String key,
    String iv,
  ) async {
    final dataStr = data['data'] ?? '';
    // if (data_str.length % 4 > 0) {
    //   data_str += '=' * (4 - data_str.length % 4); // as suggested by Albert221
    // }
    final encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));
    final encrypted = Encrypted.fromBase64(dataStr);
    final decrypted = encrypter.decrypt(encrypted, iv: IV.fromUtf8(iv));
    return decrypted;
  }

  //验证签名
  static String makeSign(Map<dynamic, dynamic>? params, String signKey) {
    if (params == null || params.isEmpty) {
      return '';
    }
    // 1. ksort（按 key 排序）
    final sortedKeys = params.keys.toList()..sort();
    // 2. 拼接 key=value
    final List<String> arrTemp = [];
    for (final key in sortedKeys) {
      var value = params[key]?.toString() ?? '';
      if (key == 'data') {
        value = value.replaceAll(' ', '+');
      }
      arrTemp.add('$key=$value');
    }
    // 3. 用 & 连接
    final string = arrTemp.join('&') + signKey;
    // 4. 先 sha256，再 md5
    final sha256Str = sha256.convert(utf8.encode(string)).toString();
    final md5Str = md5.convert(utf8.encode(sha256Str)).toString();

    return md5Str;
  }
}
