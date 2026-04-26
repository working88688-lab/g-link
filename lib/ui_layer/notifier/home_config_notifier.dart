import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:g_link/domain/model/home_data_model.dart';

import '../../domain/domain.dart';
import '../../domain/type_def.dart';

class HomeConfigNotifier extends ChangeNotifier {
  HomeConfigNotifier(this._domain);

  int _currentIndex = 0;
  bool _disposed = false;

  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    _safeNotify();
  }

  final AppDomain _domain;

  HomeData get homeData => _homeData;
  late HomeData _homeData;

  Config get config => _config;
  late Config _config;

  List<String> get searchHistory => [..._searchHistory];
  final _searchHistory = <String>[];

  Future<bool> init() async {
    return false;
  }

  Future _initSearchHistory() async {
    _searchHistory.clear();
    _searchHistory.addAll(await _domain.cache.readSearchHistory());
  }

  Future<Json?> uploadImage(XFile xFile) async {
    try {
      final result = await _domain.uploadImage(
        baseUrl: _config.imgUploadUrl,
        key: _config.uploadImgKey,
        xFile: xFile,
        position: 'upload',
      );
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<Json?> uploadImageByte({
    required Uint8List bytes,
    required CancelToken? cancelToken,
  }) async {
    try {
      final result = await _domain.uploadImageBytes(
        baseUrl: _config.imgUploadUrl,
        key: _config.uploadImgKey,
        bytes: bytes,
        position: 'upload',
        cancelToken: cancelToken,
      );
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<Json?> uploadVideo({
    required BuildContext context,
    required XFile xFile,
    required void Function(int count, int total) progressCallback,
    required CancelToken cancelToken,
  }) async {
    try {
      final result = await _domain.uploadVideo(
        context: context,
        xFile: xFile,
        progressCallback: progressCallback,
        cancelToken: cancelToken,
      );
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertSearchHistory({
    required List<String> searchHistory,
  }) async {
    await _domain.cache.upsertSearchHistory(searchHistory: searchHistory);
    _searchHistory.clear();
    _searchHistory.addAll(searchHistory);
    _safeNotify();
  }

  Future<void> clearSearchHistory() async {
    await _domain.cache.clearSearchHistory();
    _searchHistory.clear();
    _safeNotify();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
