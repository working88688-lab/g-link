import 'platform_storage_native.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'platform_storage_web.dart';

/// 跨平台 key-value 存储。
/// Native：文件存储（path_provider）；Web：localStorage。
/// key 即文件名（native）或 localStorage key（web），不含路径。
class PlatformStorage {
  static Future<String?> read(String key) => platformRead(key);
  static Future<void> write(String key, String value) =>
      platformWrite(key, value);
  static Future<bool> has(String key) => platformHas(key);
  static Future<void> delete(String key) => platformDelete(key);
}
