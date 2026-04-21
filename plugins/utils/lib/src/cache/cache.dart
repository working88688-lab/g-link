import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' hide Key;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart' hide Key;
import 'dart:ui' as ui;
import 'utils/image_load_async.dart'
    if (dart.library.html) 'utils/image_load_async_web.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
part 'cache.g.dart';

///Define interface to uncoupling cache package
abstract class ICache<K, V> {
  bool containsKey(K key);
  Future<void> upsert(K key, V value);
  Future<V?> read(K key);
  Future<void> delete(K key);
  Future<void> clearAll();
}

abstract class ImageCacheManager {
  factory ImageCacheManager() => instance;
  static final ImageCacheManager instance = _imageCacheManager;

  Future<void> clearCache();

  String? get boxPath;

  ICache<String, Uint8List> get cache;

  Future<void> init(String boxKey, {String? salt});
}
