import 'dart:convert';

import 'package:analytics_sdk/analytics_sdk.dart';
import 'package:analytics_sdk/config/sdk_config.dart';
import 'package:analytics_sdk/utils/aes_gcm_util.dart';
import 'package:flutter_test/flutter_test.dart';

/// GCM 解密固定测试 + validateEncryptedConfig 覆盖
///
/// 目的：
/// 1. 保护 SdkConfig.decryptKey + AesGcmUtil pipeline 的完整性。
/// 2. 覆盖 validateEncryptedConfig() 的所有逻辑分支，
///    确保上线前格式校验工具本身是可靠的。
void main() {
  const key = SdkConfig.decryptKey;

  group('AesGcmUtil GCM 加解密', () {
    test('域名列表：加密后可正确解密还原', () {
      final domains = ['https://api.example.com', 'https://api2.example.com'];
      final ciphertext = AesGcmUtil.encrypt(key, domains);
      final plaintext = AesGcmUtil.decryptResponseAuto(ciphertext);
      final decoded = jsonDecode(plaintext);
      expect(decoded, isA<List>());
      expect(List<String>.from(decoded), equals(domains));
    });

    test('事件类型列表：加密后可正确解密还原', () {
      final eventTypes = ['app_page_view', 'ad_impression', 'app_click'];
      final ciphertext = AesGcmUtil.encrypt(key, eventTypes);
      final plaintext = AesGcmUtil.decryptResponseAuto(ciphertext);
      final decoded = jsonDecode(plaintext);
      expect(decoded, isA<List>());
      expect(List<String>.from(decoded), equals(eventTypes));
    });

    test('decryptResponseAuto 与 decryptToString 结果一致', () {
      final data = ['https://api.example.com'];
      final ciphertext = AesGcmUtil.encrypt(key, data);
      final auto = AesGcmUtil.decryptResponseAuto(ciphertext);
      final explicit = AesGcmUtil.decryptToString(key, ciphertext);
      expect(auto, equals(explicit));
    });

    test('错误密文抛出异常而非静默失败', () {
      expect(
        () => AesGcmUtil.decryptResponseAuto('not-a-valid-ciphertext'),
        throwsException,
      );
    });
  });

  group('AnalyticsSdk.validateEncryptedConfig()', () {
    test('域名列表加密串 → success=true, preview=第一个域名', () {
      final domains = ['https://api.example.com', 'https://api2.example.com'];
      final encrypted = AesGcmUtil.encrypt(key, domains);
      final result = AnalyticsSdk.instance.validateEncryptedConfig(encrypted);
      expect(result['success'], isTrue);
      expect(result['preview'], equals('https://api.example.com'));
      expect(result['error'], isNull);
    });

    test('事件类型列表加密串 → success=true, preview=第一个事件类型', () {
      final eventTypes = ['app_page_view', 'ad_impression'];
      final encrypted = AesGcmUtil.encrypt(key, eventTypes);
      final result = AnalyticsSdk.instance.validateEncryptedConfig(encrypted);
      expect(result['success'], isTrue);
      expect(result['preview'], equals('app_page_view'));
      expect(result['error'], isNull);
    });

    test('enabled_event_types 格式 → success=true', () {
      final payload = {'enabled_event_types': ['app_click', 'ad_impression']};
      final encrypted = AesGcmUtil.encrypt(key, payload);
      final result = AnalyticsSdk.instance.validateEncryptedConfig(encrypted);
      expect(result['success'], isTrue);
      expect(result['preview'], equals('app_click'));
    });

    test('解密成功但无法识别格式 → success=false, preview=前60字符', () {
      // 加密一个 Map，其中没有已知 key
      final unrecognized = {'unknown_key': 'some_value'};
      final encrypted = AesGcmUtil.encrypt(key, unrecognized);
      final result = AnalyticsSdk.instance.validateEncryptedConfig(encrypted);
      expect(result['success'], isFalse);
      expect(result['preview'], isNotNull);
      expect((result['preview'] as String).length, lessThanOrEqualTo(60));
      expect(result['error'], contains('0 个元素'));
    });

    test('无效密文 → success=false, error 包含"解密失败"', () {
      final result = AnalyticsSdk.instance.validateEncryptedConfig('not-valid-ciphertext');
      expect(result['success'], isFalse);
      expect(result['error'], contains('解密失败'));
      expect(result['preview'], isNull);
    });

    test('空列表加密串 → success=false, error 包含"0 个元素"', () {
      final encrypted = AesGcmUtil.encrypt(key, <String>[]);
      final result = AnalyticsSdk.instance.validateEncryptedConfig(encrypted);
      expect(result['success'], isFalse);
      expect(result['error'], contains('0 个元素'));
    });
  });
}
