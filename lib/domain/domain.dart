import 'package:g_link/domain/model/ad_model.dart';
import 'package:g_link/domain/remote_domain.dart';
import 'package:g_link/domain/type_def.dart';

abstract class AppDomain implements LocaleDomain, RemoteDomain {}

abstract class LocaleDomain {
  CacheDomain get cache;

  Json get info;
}

abstract class CacheDomain
    implements VideoDownloadCacheDomain, ChatCacheDomain {
  /// 大于500M清理磁盘
  Future<void> clearImageCacheIfNeed({bool force = false});

  /// 获取广告缓存
  Future<AdModel?> readAds();

  /// 获取广告缓存
  Future<List<AdModel>?> readStartScreenAds();

  Future<bool> readIsBarrage();

  ///获取直播弹幕开关，默认true：开
  Future<void> upsertIsBarrage(bool isBarrage);

  /// 获取官网链结缓存
  Future<String?> readOfficeWeb();

  /// 获取Web端缓存的线路key版本
  Future<String?> readWebCachedLineKeyVersion();

  /// 更新Web端缓存的线路key版本
  Future<void> upsertWebCachedLineKeyVersion(String key);

  /// 取得搜索记录
  Future<List<String>> readSearchHistory();

  /// 更新搜索记录
  Future<void> upsertSearchHistory({required List<String> searchHistory});

  /// 清除搜索记录
  Future<void> clearSearchHistory();
}

abstract class VideoDownloadCacheDomain {
  Future<List> readDownloadVideoTasks();

  Future<void> upsertDownloadVideoTasks({required List tasks});
}

abstract class ChatCacheDomain {
  Future<String> readChats();

  Future<void> upsertChats({required String chats});
}
