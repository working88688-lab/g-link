import 'dart:convert';
import 'dart:io';

import 'package:analytics_sdk/config/sdk_config.dart';
import 'package:analytics_sdk/manager/domain_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/path_provider_mock.dart';

/// DomainManager 磁盘缓存测试
///
/// 使用 MethodChannel mock 将 path_provider 重定向到系统临时目录，
/// 测试缓存读写逻辑而无需真实设备文件系统。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dm_cache_test_');
    registerPathProviderMock(tempDir);
    // 重置单例缓存路径（确保每个 test 都从全新状态开始）
    DomainManager.instance.reset();
  });

  tearDown(() async {
    unregisterPathProviderMock();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('DomainManager 磁盘缓存', () {
    test('缓存文件不存在时 loadCachedDomains() 返回空列表', () async {
      final result = await DomainManager.instance.loadCachedDomains();
      expect(result, isEmpty);
    });

    test('写入缓存后 loadCachedDomains() 返回正确域名列表', () async {
      final domains = ['https://api.example.com', 'https://api2.example.com'];
      // 直接写入缓存文件模拟之前 initWithDomains 写入的结果
      final cacheFile =
          File('${tempDir.path}/${SdkConfig.domainCacheFileName}');
      await cacheFile.writeAsString(jsonEncode(domains));

      final result = await DomainManager.instance.loadCachedDomains();
      expect(result, equals(domains));
    });

    test('缓存文件 JSON 格式损坏时 loadCachedDomains() 返回空列表（不抛异常）', () async {
      final cacheFile =
          File('${tempDir.path}/${SdkConfig.domainCacheFileName}');
      await cacheFile.writeAsString('not valid json {{{');

      expect(
        () async => await DomainManager.instance.loadCachedDomains(),
        returnsNormally,
      );
      final result = await DomainManager.instance.loadCachedDomains();
      expect(result, isEmpty);
    });

    test('空字符串或空格不被解析为有效域名', () async {
      final cacheFile =
          File('${tempDir.path}/${SdkConfig.domainCacheFileName}');
      await cacheFile.writeAsString(jsonEncode(['  ', '', 'https://ok.com']));

      final result = await DomainManager.instance.loadCachedDomains();
      expect(result, equals(['https://ok.com']));
    });
  });

  group('DomainManager.reset()', () {
    test('reset() 后 fastestDomain 和 reportDomains 均为空', () async {
      // 先通过缓存文件让 loadCachedDomains 有数据
      final cacheFile =
          File('${tempDir.path}/${SdkConfig.domainCacheFileName}');
      await cacheFile.writeAsString(jsonEncode(['https://api.example.com']));

      // reset() 只清内存状态，不删文件
      DomainManager.instance.reset();
      expect(DomainManager.instance.fastestDomain, isNull);
      expect(DomainManager.instance.reportDomains, isEmpty);

      // 缓存文件应仍然存在
      expect(cacheFile.existsSync(), isTrue);
    });
  });
}
