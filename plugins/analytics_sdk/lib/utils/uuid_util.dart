import 'dart:math';

/// 生成符合 RFC 4122 的 UUID v4 字符串
/// 替代 uuid 包，消除跨 Dart 版本的依赖约束冲突
String generateUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1
  String toHex(int b) => b.toRadixString(16).padLeft(2, '0');
  return '${toHex(bytes[0])}${toHex(bytes[1])}${toHex(bytes[2])}${toHex(bytes[3])}-'
      '${toHex(bytes[4])}${toHex(bytes[5])}-${toHex(bytes[6])}${toHex(bytes[7])}-'
      '${toHex(bytes[8])}${toHex(bytes[9])}-'
      '${toHex(bytes[10])}${toHex(bytes[11])}${toHex(bytes[12])}${toHex(bytes[13])}${toHex(bytes[14])}${toHex(bytes[15])}';
}
