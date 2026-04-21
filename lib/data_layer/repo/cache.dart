part of 'repo.dart';

class _CacheManager implements CacheDomain {
  bool _isInitialized = false;

  late final ICache appBox;
  late final ICache chatBox;
  late final ICache videoBox;

  final _oauthIdKey = 'oauth_id';
  final _authTokenKey = 'wwsj_token';
  final _fdsKey = 'fds_key';
  final _githubKey = 'github_url';
  final _reportKey = 'report_url';
  final _reportAppIdKey = 'report_app_id';
  final _reportTraceIdKey = 'report_trace_id';
  final _affXCodeKey = 'aff_x_code';
  final _isBarrage = 'isBarrage';
  final _officeWebKey = 'office_web';
  final _webCachedLineKeyVersion = 'web_cached_url_line_key';
  final _adsKey = 'ads';
  final _startScreenAdsKey = 'startScreenAdsKey';
  final _installKey = 'install';

  final _searchHistoryKey = 'search_history';
  final _downloadVideoTasksKey = 'download_video_tasks';
  final _chatsKey = 'imchats';

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    const cacheKeys = BuildConfig.cacheKeys;

    await ImageCacheManager.instance
        .init(cacheKeys.imageBox, salt: cacheKeys.imageCacheSalt);
    appBox = HiveBoxCache(await Hive.openLazyBox(cacheKeys.appBox));
    chatBox = HiveBoxCache(await Hive.openLazyBox(cacheKeys.chats));
    videoBox = HiveBoxCache(await Hive.openLazyBox(cacheKeys.videoBox));

    refreshReportAppId();
    refreshInstallFlag();
  }

  void refreshReportAppId() async {
    final String? localReportAppId = await readReportAppId();
    if (localReportAppId case final String reportAppId) {
      AppGlobal.reportAppId = reportAppId;
    }
  }

  void refreshInstallFlag() async {
    final String? installFlag = await readInstallFlag();
    if (installFlag case final String install) {
      AppGlobal.installFlag = install;
    }
  }

  Future<String?> readAuthToken() async =>
      (await appBox.read(_authTokenKey))?.toString();
  Future<void> upsertAuthToken(String? token) => token == null
      ? appBox.delete(_authTokenKey)
      : appBox.upsert(_authTokenKey, token);
  Future<void> deleteAuthToken() => appBox.delete(_authTokenKey);

  Future<String?> readOauthId() async =>
      (await appBox.read(_oauthIdKey))?.toString();
  Future upsertOauthId(String value) => appBox.upsert(_oauthIdKey, value);

  Future<String?> readGithubUrl() async =>
      (await appBox.read(_githubKey))?.toString();
  Future<void> upsertGithubUrl(String url) => appBox.upsert(_githubKey, url);

  Future<String?> readReportAppId() async =>
      (await appBox.read(_reportAppIdKey))?.toString();
  Future<void> upsertReportAppId(String appid) =>
      appBox.upsert(_reportAppIdKey, appid);

  Future<String?> readInstallFlag() async =>
      (await appBox.read(_installKey))?.toString();
  Future<void> upsertInstallFlag(String installFlag) =>
      appBox.upsert(_installKey, installFlag);

  Future<String?> readReportTraceId() async =>
      (await appBox.read(_reportTraceIdKey))?.toString();
  Future<void> upsertReportTraceId(String id) =>
      appBox.upsert(_reportTraceIdKey, id);

  Future<String?> readAffXCode() async =>
      (await appBox.read(_affXCodeKey))?.toString();
  Future<void> upsertAffXCode(String code) => appBox.upsert(_affXCodeKey, code);

  @override
  Future<bool> readIsBarrage() async => await appBox.read(_isBarrage) ?? true;
  @override
  Future<void> upsertIsBarrage(bool isBarrage) async {
    return appBox.upsert(_isBarrage, isBarrage);
  }

  Future<List<String>?> readLinesUrl() async {
    if (await appBox.read(BuildConfig.linesUrlKey) case final data? when data.isNotEmpty) {
      return List<String>.from(data);
    }
    return null;
  }

  Future<void> upsertLinesUrl(List<String> lines) =>
      appBox.upsert(BuildConfig.linesUrlKey, lines);

  Future<String?> readFdsKey() async =>
      (await appBox.read(_fdsKey))?.toString();

  Future upsertFdsKey(String value) => appBox.upsert(_fdsKey, value);

  @override
  Future<AdModel?> readAds() async {
    if (await appBox.read(_adsKey) case final data?) {
      try {
        return AdModel.fromJson(Json.from(data));
      } catch (_) {}
    }
    return null;
  }

  Future<void> upsertAds(AdModel ads) => appBox.upsert(_adsKey, ads.toJson());

  @override
  Future<List<AdModel>?> readStartScreenAds() async {
    final ads = await appBox.read(_startScreenAdsKey);
    try {
      return (ads as List)
          .map((e) => AdModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('#########${e.toString()}');
    }

    return null;
  }

  Future<void> upsertStartScreenAds(List<AdModel> ads) async {
    List<Map<String, dynamic>> adsList = ads.map((e) {
      return e.toJson();
    }).toList();
    appBox.upsert(_startScreenAdsKey, adsList);
  }

  @override
  Future<String?> readOfficeWeb() async {
    if (await appBox.read(_officeWebKey) case final data?) {
      return data;
    }
    return null;
  }

  Future<void> upsertOfficeWeb(String officeWeb) =>
      appBox.upsert(_officeWebKey, officeWeb);

  @override
  Future<String?> readWebCachedLineKeyVersion() async {
    if (await appBox.read(_webCachedLineKeyVersion) case final data?) {
      return data.toString();
    }
    return null;
  }

  @override
  Future<void> upsertWebCachedLineKeyVersion(String key) =>
      appBox.upsert(_webCachedLineKeyVersion, key);

  @override
  Future<void> clearImageCacheIfNeed({bool force = false}) async {
    final cache = ImageCacheManager.instance;
    if (force || kIsWeb || cache.boxPath == null) {
      await cache.clearCache();
      return;
    }

    final file = File(cache.boxPath!);
    final size = await file.length();

    //大于500M清理磁盘
    if (size > 500 << 20) {
      await cache.clearCache();
    }
  }

  @override
  Future<List<String>> readSearchHistory() async {
    if (await appBox.read(_searchHistoryKey) case final data?) {
      return List<String>.from(data);
    }
    return [];
  }

  @override
  Future<void> upsertSearchHistory({required List<String> searchHistory}) =>
      appBox.upsert(_searchHistoryKey, searchHistory);

  @override
  Future<void> clearSearchHistory() => appBox.delete(_searchHistoryKey);

  @override
  Future<List> readDownloadVideoTasks() async {
    if (await videoBox.read(_downloadVideoTasksKey) case final data?) {
      return List.from(data);
    }
    return [];
  }

  @override
  Future<void> upsertDownloadVideoTasks({required List tasks}) =>
      videoBox.upsert(_downloadVideoTasksKey, tasks);

  @override
  Future<String> readChats() async {
    if (await chatBox.read(_chatsKey) case final data?) {
      return data;
    }
    return '';
  }

  @override
  Future<void> upsertChats({required String chats}) =>
      chatBox.upsert(_chatsKey, chats);
}
