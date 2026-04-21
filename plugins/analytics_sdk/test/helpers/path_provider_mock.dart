// test/helpers/path_provider_mock.dart
//
// 共享的 path_provider MethodChannel mock 工具。
//
// 用法：
//   setUp(() async {
//     tempDir = await Directory.systemTemp.createTemp('my_test_');
//     registerPathProviderMock(tempDir);
//   });
//   tearDown(() async {
//     unregisterPathProviderMock();
//     await tempDir.delete(recursive: true);
//   });

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _kChannel = MethodChannel('plugins.flutter.io/path_provider');

/// Registers a [path_provider] mock that redirects
/// `getApplicationDocumentsDirectory` to [dir].
/// All other method calls return null.
void registerPathProviderMock(Directory dir) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_kChannel, (call) async {
    if (call.method == 'getApplicationDocumentsDirectory') {
      return dir.path;
    }
    return null;
  });
}

/// Removes the path_provider mock registered by [registerPathProviderMock].
void unregisterPathProviderMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_kChannel, null);
}
