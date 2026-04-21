import 'dart:convert';
import 'package:archive/archive.dart';
import 'dart:math';
import 'dart:typed_data';

import 'package:analytics_sdk/config/sdk_config.dart';
import 'package:pointycastle/export.dart';

/// AES-GCM 加密工具类
/// 提供 AES-256-GCM 加密/解密、GZIP 压缩/解压功能
class AesGcmUtil {
  // AES-256 密钥长度
  static const int keySize = 32;

  // GCM IV 长度（12 字节）
  static const int gcmIvLength = 12;

  // GCM Tag 长度（128 位 = 16 字节）
  static const int gcmTagLength = 16;

  // 随机数生成器
  static final Random _random = Random.secure();

  /// 生成唯一的密钥（Base64 字符串，无填充）
  /// 返回 32 字节的 AES-256 密钥的 Base64 编码
  static String generateKey() {
    final keyBytes = Uint8List(keySize);
    for (int i = 0; i < keySize; i++) {
      keyBytes[i] = _random.nextInt(256);
    }
    return base64Encode(keyBytes).replaceAll('=', '').replaceAll('+', '-').replaceAll('/', '_');
  }

  /// 加密：Object → String（Base64）
  /// [keyBase64] Base64 编码的密钥
  /// [data] 要加密的数据（任意对象，会被转换为 JSON）
  /// 返回 Base64 编码的加密数据（IV + 密文）
  static String encrypt(String keyBase64, dynamic data) {
    try {
      // 解码密钥
      final key = _decodeKey(keyBase64);

      // 将数据转换为 JSON 字符串
      final json = jsonEncode(data);
      final input = utf8.encode(json);

      // 生成随机 IV（12 字节）
      final iv = Uint8List(gcmIvLength);
      for (int i = 0; i < gcmIvLength; i++) {
        iv[i] = _random.nextInt(256);
      }

      // 执行 AES-GCM 加密
      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(
        KeyParameter(key),
        gcmTagLength * 8, // Tag 长度（位）
        iv,
        Uint8List(0), // 无附加认证数据（AAD）
      );
      cipher.init(true, params);

      final cipherText = cipher.process(input);

      // 组合 IV + 密文
      final output = Uint8List(iv.length + cipherText.length);
      output.setRange(0, iv.length, iv);
      output.setRange(iv.length, output.length, cipherText);

      // Base64 编码（无填充）
      return base64Encode(output).replaceAll('=', '').replaceAll('+', '-').replaceAll('/', '_');
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// 加密（带 GZIP 压缩）：先压缩再加密
  /// [keyBase64] Base64 编码的密钥
  /// [data] 要加密的数据（任意对象，会被转换为 JSON）
  /// 返回 Base64 编码的加密数据
  static String encryptGzip(String keyBase64, dynamic data) {
    try {
      // 解码密钥
      final key = _decodeKey(keyBase64);

      // 将数据转换为 JSON 字符串
      final json = jsonEncode(data);

      // ① 先 GZIP 压缩并转 Base64
      final gzipBase64 = gzipToBase64(json);

      // ② AES-GCM 加密这个 Base64 字符串
      final input = utf8.encode(gzipBase64);

      // 生成随机 IV（12 字节）
      final iv = Uint8List(gcmIvLength);
      for (int i = 0; i < gcmIvLength; i++) {
        iv[i] = _random.nextInt(256);
      }

      // 执行 AES-GCM 加密
      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(
        KeyParameter(key),
        gcmTagLength * 8, // Tag 长度（位）
        iv,
        Uint8List(0), // 无附加认证数据（AAD）
      );
      cipher.init(true, params);

      final cipherText = cipher.process(input);

      // 组合 IV + 密文
      final output = Uint8List(iv.length + cipherText.length);
      output.setRange(0, iv.length, iv);
      output.setRange(iv.length, output.length, cipherText);

      // Base64 编码（无填充）
      return base64Encode(output).replaceAll('=', '').replaceAll('+', '-').replaceAll('/', '_');
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// 解密：返回明文 JSON 字符串
  /// [keyBase64] Base64 编码的密钥
  /// [encryptedBase64] Base64 编码的加密数据（IV + 密文）
  /// 返回解密后的 JSON 字符串
  static String decryptToString(String keyBase64, String encryptedBase64) {
    try {
      // 解码 Base64（处理 URL 安全格式）
      String normalizedBase64 = encryptedBase64.replaceAll('-', '+').replaceAll('_', '/');
      while (normalizedBase64.length % 4 != 0) {
        normalizedBase64 += '=';
      }
      final data = base64Decode(normalizedBase64);
      return decryptFromCipherBytes(keyBase64, Uint8List.fromList(data));
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// 解密：从原始字节（IV + 密文）解密为明文字符串
  /// [keyBase64] Base64 编码的密钥
  /// [cipherBytes] 密文字节：前 12 字节为 IV，后续为 AES-GCM 密文
  /// 返回解密后的 UTF-8 字符串
  ///
  /// 若抛出 [InvalidCipherTextException]（或 "Decryption failed: InvalidCipherTextException"），
  /// 常见原因：① 密钥与加密端不一致 ② 服务端密文格式不是「前 12 字节 IV + 密文」
  /// （如 IV 单独返回或顺序不同，需先自行截取再传入）
  static String decryptFromCipherBytes(String keyBase64, Uint8List cipherBytes) {
    try {
      final key = _decodeKey(keyBase64);
      if (cipherBytes.length < gcmIvLength) {
        throw ArgumentError('Invalid ciphertext: too short (need at least $gcmIvLength bytes for IV)');
      }
      final iv = cipherBytes.sublist(0, gcmIvLength);
      final cipherText = cipherBytes.sublist(gcmIvLength);
      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(
        KeyParameter(key),
        gcmTagLength * 8,
        iv,
        Uint8List(0),
      );
      cipher.init(false, params);
      final plainText = cipher.process(cipherText);
      return utf8.decode(plainText);
    } on InvalidCipherTextException catch (e) {
      throw Exception(
        'Decryption failed: GCM 校验失败（密钥错误、IV/密文格式不符或数据被篡改）。'
        ' 请确认：① 密钥与加密端一致 ② 密文为「前 12 字节 IV + 密文」。原始: $e',
      );
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// 解密：从 "[169, 246, 173, ...]" 格式的字节列表字符串解密
  /// 适用于接口返回的密文是「数字列表字符串」而非 Base64 的情况
  /// [keyBase64] Base64 编码的密钥，传 null 则使用 SdkConfig.decryptKey
  /// [byteListString] 形如 "[169, 246, 173, 197, ...]" 的字符串（前 12 字节为 IV，后续为密文）
  /// 返回解密后的 UTF-8 字符串
  static String decryptFromByteListString(String byteListString, {String? keyBase64}) {
    final key = keyBase64 ?? _defaultKey;
    final cipherBytes = _parseByteListString(byteListString);
    return decryptFromCipherBytes(key, cipherBytes);
  }

  /// 将 "[169, 246, ...]" 格式的字符串解析为 Uint8List
  static Uint8List _parseByteListString(String byteListString) {
    final list = byteListString
        .replaceAll(RegExp(r'[\[\]\s]+'), ' ')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => int.parse(s))
        .toList();
    for (final b in list) {
      if (b < 0 || b > 255) throw ArgumentError('Byte value out of range: $b');
    }
    return Uint8List.fromList(list);
  }

  /// 解码 Base64 密钥
  static Uint8List _decodeKey(String keyBase64) {
    // 处理 URL 安全格式
    String normalizedBase64 = keyBase64.replaceAll('-', '+').replaceAll('_', '/');
    // 添加填充
    while (normalizedBase64.length % 4 != 0) {
      normalizedBase64 += '=';
    }

    final keyBytes = base64Decode(normalizedBase64);
    if (keyBytes.length != keySize) {
      throw ArgumentError('Key must be 32 bytes for AES-256');
    }
    return keyBytes;
  }

  /// GZIP 压缩字节数组
  static Uint8List gzip(Uint8List data) {
    return gzipEncode(data);
  }

  /// GZIP 压缩字符串并转 Base64
  static String gzipToBase64(String str) {
    if (str.isEmpty) return str;
    try {
      final compressed = gzipEncode(utf8.encode(str));
      return base64Encode(compressed);
    } catch (e) {
      throw Exception('Gzip 压缩失败: $e');
    }
  }

  /// GZIP 解压字节数组
  static Uint8List gunzip(Uint8List data) {
    return gzipDecode(data);
  }

  /// 从 Base64 解压 GZIP
  static String gunzipFromBase64(String base64) {
    if (base64.isEmpty) return base64;
    try {
      final compressed = base64Decode(base64);
      final decompressed = gzipDecode(compressed);
      return utf8.decode(decompressed);
    } catch (e) {
      throw Exception('Gzip 解压失败: $e');
    }
  }

  /// GZIP 编码（使用 package:archive，兼容 Web）
  static Uint8List gzipEncode(List<int> data) {
    final encoder = GZipEncoder();
    final compressed = encoder.encode(data) ?? <int>[];
    return Uint8List.fromList(compressed);
  }

  /// GZIP 解码（使用 package:archive，兼容 Web）
  static Uint8List gzipDecode(List<int> data) {
    final decoder = GZipDecoder();
    final decompressed = decoder.decodeBytes(data);
    return Uint8List.fromList(decompressed);
  }

  /// 解密接口响应（使用 SDK 默认密钥）
  ///
  /// 接口直接返回加密字符串，整段解密后返回明文。
  ///
  /// [responseBody] 接口返回的加密字符串
  /// [useGzip] 是否对解密结果再做 GZIP 解压（默认：false）
  static String decryptResponseAuto(String responseBody, {bool useGzip = false}) {
    return decryptResponse(_defaultKey, responseBody, useGzip: useGzip);
  }

  /// 默认密钥（从 SdkConfig 获取）
  static String get _defaultKey => SdkConfig.decryptKey;

  /// 解密接口响应
  ///
  /// 接口直接返回加密字符串，整段解密后返回明文。
  ///
  /// [keyBase64] Base64 编码的密钥
  /// [responseBody] 接口返回的加密字符串
  /// [useGzip] 是否对解密结果再做 GZIP 解压（默认：false）
  static String decryptResponse(String keyBase64, String responseBody, {bool useGzip = false}) {
    try {
      final decrypted = decryptToString(keyBase64, responseBody.trim());
      if (useGzip) return gunzipFromBase64(decrypted);
      return decrypted;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('解密响应失败: $e');
    }
  }

  /// 解密接口响应并解析为 Map
  /// 接口直接返回加密字符串，解密后再按 JSON 解析为 Map。
  /// [keyBase64] Base64 编码的密钥
  /// [responseBody] 接口返回的加密字符串
  /// [useGzip] 是否对解密结果再做 GZIP 解压（默认：false）
  static Map<String, dynamic> decryptResponseToMap(
    String keyBase64,
    String responseBody, {
    bool useGzip = false,
  }) {
    final decryptedJson = decryptResponse(keyBase64, responseBody, useGzip: useGzip);
    return jsonDecode(decryptedJson) as Map<String, dynamic>;
  }

  /// 解密接口响应并解析为指定类型
  /// 接口直接返回加密字符串，解密后再按 JSON 解析并转为 T。
  /// [keyBase64] Base64 编码的密钥
  /// [responseBody] 接口返回的加密字符串
  /// [fromJson] JSON 解析函数
  /// [useGzip] 是否对解密结果再做 GZIP 解压（默认：false）
  static T decryptResponseToObject<T>(
    String keyBase64,
    String responseBody,
    T Function(Map<String, dynamic>) fromJson, {
    bool useGzip = false,
  }) {
    final decryptedMap = decryptResponseToMap(keyBase64, responseBody, useGzip: useGzip);
    return fromJson(decryptedMap);
  }
}
