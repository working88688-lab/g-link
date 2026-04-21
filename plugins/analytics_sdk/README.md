> **版本说明：** 本分支（`dev`）适用于 **Flutter 3.0.5 及以上**（Dart >=2.17）。
> 如使用 Flutter 1.22.5，请切换至 `compat/flutter-1.22` 分支。

# Analytics SDK

一个 Flutter 埋点 SDK，用于采集 App 内页面、点击、广告、视频、小说、漫画、搜索、推荐等行为，并提供批量上报、本地持久化、域名测速和事件类型动态配置能力。

## 目录

- [功能特性](#功能特性)
- [安装](#安装)
- [快速开始](#快速开始)
- [核心 API](#核心-api)
- [域名与事件类型管理](#域名与事件类型管理)
- [SDK 配置（可选）](#sdk-配置可选)
- [更多文档](#更多文档)
- [手动上报事件](#手动上报事件)
- [用户类型管理](#用户类型管理)
- [页面名称映射](#页面名称映射)
- [事件数据结构](#事件数据结构)
- [上报机制](#上报机制)
- [事件去重](#事件去重)
- [完整示例](#完整示例)
- [枚举类型参考](#枚举类型参考)
- [注意事项](#注意事项)
- [调试](#调试)
- [常见问题 FAQ](#常见问题-faq)
- [依赖项](#依赖项)
- [环境要求](#环境要求)

## 功能特性

- **多事件类型**：页面浏览、页面点击、导航、广告展示/点击、视频/小说/漫画行为、关键词搜索、推荐等事件
- **自动埋点**：页面生命周期（曝光/停留）、全局点击（默认开启）
- **批量上报**：队列聚合，默认每 5 秒或队列达 10 条时批量上报
- **本地持久化**：事件写入本地 JSONL 文件，重启后自动恢复（默认最多 2000 行）
- **智能重试**：指数退避重试机制，初始 2s，最大 60s，最多 5 级
- **域名测速**：从 `encryptedConfig` 解析域名列表，并发测速选最快可用节点
- **事件类型动态开关**：通过 `encryptedConfig` 下发白名单，SDK 侧统一过滤
- **会话管理**：按"冷启动 / 前后台 30 分钟 / 行为 30 分钟"规则生成 `sid`
- **用户管理**：支持用户 ID 与用户类型动态更新
- **广告展示去重**：session 级别按 adId 自动去重，防止重复上报
- **设备信息自动采集**：通过 `device_info_plus` 自动获取品牌、型号、系统名称与版本，无需外部传入
- **设备指纹**：基于设备因子生成 SHA-256 指纹；因子全空时降级为 UUID v4 持久化兜底
- **公共参数暴露**：通过 `getParams()` 获取全部或指定公共埋点参数，供服务端复用

## 安装

在宿主工程的 `pubspec.yaml` 中添加依赖（示例）：

```yaml
dependencies:
  analytics_sdk:
    path: ../analytics_sdk  # 本地导入：根据实际目录调整相对路径
```

然后执行：

```bash
flutter pub get
```

## 快速开始

### 1. 初始化 SDK

```dart
import 'package:flutter/widgets.dart';
import 'package:analytics_sdk/analytics_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 从你的服务端获取加密配置（由业务方自行实现网络请求）
  final encryptedConfig = await yourApiClient.fetchEncryptedConfig();

  await AnalyticsSdk.instance.init(
    appId: 'your_app_id',
    encryptedConfig: encryptedConfig,   // 加密配置，解密后包含域名列表和事件白名单
    channel: 'official',
    uid: 'user_123',                    // 未登录可传 null 或空字符串
    deviceId: 'device_unique_id',       // 设备唯一标识
  );

  runApp(const MyApp());
}
```

> 设备品牌、型号、系统名称和版本由 SDK 内部通过 `device_info_plus` 自动采集，无需外部传入。

### 2. 支持「先 init，后补 encryptedConfig」的场景

如果你需要先初始化 SDK，再从自己配置接口拿到加密串，可以这样用：

```dart
// 1）先初始化（此时还没有 encryptedConfig，事件会正常入队和落盘，但无法实际上报）
await AnalyticsSdk.instance.init(
  appId: 'your_app_id',
  encryptedConfig: null,    // 先传 null，SDK 会尝试读取本地缓存域名
  deviceId: 'device_unique_id',
);

// 2）等拿到配置后再传入 encryptedConfig
final encryptedConfig = await yourApiClient.fetchEncryptedConfig();
await AnalyticsSdk.instance.refreshDomainConfig(encryptedConfig: encryptedConfig);
```

`refreshDomainConfig()` 会：
- 解密 `encryptedConfig`，解析最新域名列表并并发测速，选出最快可用域名；
- 更新内部上报 URL，后续定时上报和 `flush()` 会把之前队列里的事件一并发出；
- 更新事件类型白名单配置。

### 3. 页面生命周期 & 全局点击埋点

```dart
import 'package:analytics_sdk/analytics_sdk.dart';
import 'package:analytics_sdk/widget/global_click_wrapper.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [
        AnalyticsSdk.instance.pageObserver,  // 页面自动埋点
      ],
      builder: (context, child) {
        return GlobalClickWrapper(           // 全局点击自动抓取
          child: child!,
        );
      },
      home: const HomePage(),
    );
  }
}
```

## 核心 API

### AnalyticsSdk.init

```dart
Future<void> init({
  required String appId,
  required String? encryptedConfig,
  String? channel,
  String? uid,
  required String deviceId,
  bool enableDebugBanner = false,
})
```

建议在 `main()` 中、`runApp()` 之前调用。内部流程：
- 通过 `device_info_plus` 自动采集设备品牌、型号、系统名称、版本等信息；
- 配置公共字段（appId / channel / uid / device 等）；
- 初始化 SessionManager、AppLifecycleObserver、设备指纹；
- 解密 `encryptedConfig`，解析域名列表并发测速选最快节点；
- 解析事件类型白名单；
- 如 `encryptedConfig` 为 null / 解密失败，尝试读取本地缓存域名和事件类型配置；
- 初始化事件队列、本地缓存和定时上报定时器。

**`enableDebugBanner`**：仅在非 release 包下生效，配合 `AnalyticsDebugBanner` 显示调试悬浮条。

### AnalyticsSdk.getParams

```dart
static Map<String, dynamic> getParams([List<String>? keys])
```

获取 SDK 当前全部公共参数（或按 key 过滤子集），可用于服务端事件拼装或调试：

```dart
// 获取全部公共参数
final all = AnalyticsSdk.getParams();
// { 'app_id': '...', 'channel': '...', 'uid': '...', 'user_type': '...', 'sid': '...', 'device': '...', ... }

// 只取指定参数
final partial = AnalyticsSdk.getParams(['app_id', 'uid', 'device_id']);
```

返回字段包括：`app_id`、`channel`、`uid`、`user_type`、`sid`、`device`、`device_id`、`device_brand`、`device_model`、`user_agent`、`system_name`、`system_version`、`device_fingerprint`、`fp_version`。

### AnalyticsSdk.refreshDomainConfig

```dart
Future<void> refreshDomainConfig({String? encryptedConfig})
```

使用场景：
- 先调用 `init()`，再从服务端获取 `encryptedConfig`；
- 运行中需要更新域名列表或事件类型白名单。

```dart
// 获取到最新加密配置后刷新
final newConfig = await yourApiClient.fetchEncryptedConfig();
await AnalyticsSdk.instance.refreshDomainConfig(encryptedConfig: newConfig);
```

> 传入 null 或空字符串时忽略本次刷新。本方法永远不会抛出异常。

### 事件上报相关

```dart
// 上报内置事件
void track(dynamic event)

// 立即触发上报
Future<void> flush()

// 页面生命周期观察者
NavigatorObserver get pageObserver

// 资源清理（可选）
Future<void> dispose()
```

`track()` 支持传入 SDK 内置的事件类（如 `VideoEvent`、`AdImpressionEvent` 等）或直接传 `Map<String, dynamic>`。

SDK 会自动：
- 做广告展示事件去重与过滤；
- 检查事件类型是否在白名单中；
- 校验必填字段；
- 检查单条事件大小（超过 300KB 丢弃）；
- 将事件写入队列和本地缓存；
- 在队列长度达到阈值或定时器触发时批量上报。

### 用户与会话

```dart
// 设置用户 ID 和类型（登录 / 切换账号）
static void setUserIdAndType({String userId = "", UserTypeEnum? userTypeEnum})

// 只更新用户 ID（不改变用户类型）
static void setUid(String uid)

// 更新用户类型
void updateUserType(String newType)

// 登出（清空 uid 和 userType）
static void logoutUser()

// 更新渠道标识
static void setChannel(String channel)
```

`sid`（会话 ID）由 SessionManager 自动管理，无需手动干预。

### 获取设备公共字段（服务端复用）

```dart
static Map<String, String> getDeviceCommonFields()
```

返回字段：`device`、`device_id`、`device_brand`、`device_model`、`user_agent`、`system_name`、`system_version`、`device_fingerprint`。可将这些字段传递给服务端，由服务端上报事件时附加。

## 域名与事件类型管理

### encryptedConfig 格式

`encryptedConfig` 是宿主 App 从自己服务端获取的 **Base64 编码 AES-GCM 密文**，SDK 内部解密后格式为：

```json
{
  "domainList": [
    "https://api1.example.com",
    "https://api2.example.com"
  ],
  "eventList": [
    "app_page_view",
    "page_click",
    "video_event",
    "ad_impression"
  ]
}
```

- **`domainList`**：上报域名列表，SDK 启动时会并发测速（GET 请求），选择响应最快的域名上报。
- **`eventList`**：启用的事件类型白名单。**不在列表中的事件会被静默丢弃**。传空列表时，所有事件类型均允许上报（向后兼容）。

### 测速与降级策略

1. 解密 `encryptedConfig` 成功 → 用 `domainList` 并发测速，选最快域名；
2. `encryptedConfig` 为 null 或解密失败 → 尝试从磁盘缓存（`data_plus_domains_cache.json`）读取上次保存的域名列表；
3. 缓存也为空 → 上报 URL 保持未配置，事件缓存在本地，等 `refreshDomainConfig()` 成功后自动上报。

### 验证加密配置（调试包）

```dart
final result = AnalyticsSdk.instance.validateEncryptedConfig(encryptedString);
if (result['success'] == true) {
  print('条目数量: ${result['count']}');
  print('第一条预览: ${result['preview']}');
} else {
  print('验证失败: ${result['error']}');
}
```

> 此方法仅在 debug 包可用，release 包直接返回 `{'success': false}`。

## SDK 配置（可选）

通过 `SdkConfig.configure()` 调整 SDK 参数，需在 `init()` **之前**调用：

```dart
import 'package:analytics_sdk/config/sdk_config.dart';

SdkConfig.configure(
  maxQueueSize: 5000,
  uploadInterval: const Duration(seconds: 10),
  maxCacheLines: 2000,
  connectionTimeout: const Duration(seconds: 15),
);
```

常用配置：

**队列与批量**
- `maxQueueSize`：事件队列最大容量（默认 `5000`）
- `autoUploadThreshold`：达到阈值时自动触发上报（默认 `10`）
- `maxBatchSize`：单次上报最大事件数（默认 `500`）
- `maxJsonSize`：单次请求 JSON 最大字节数（默认 `5MB`）
- `maxSingleEventSize`：单条事件最大字节数，超过则丢弃（默认 `300KB`）

**定时器**
- `uploadInterval`：定时上报间隔（默认 `5秒`）
- `clickThrottleDuration`：全局点击节流时间（默认 `300毫秒`）
- `speedTestTimeout`：域名测速超时（默认 `5秒`）

**网络超时**
- `connectionTimeout`：HTTP 连接超时（默认 `10秒`）
- `readTimeout`：HTTP 读取超时（默认 `30秒`）

**缓存相关**
- `cacheFileName`：事件缓存文件名（默认 `data_plus_events_cache.jsonl`）
- `maxCacheLines`：缓存文件最大行数（默认 `2000`）
- `maxCacheBytes`：缓存文件最大字节数（默认 `2MB`）
- `tombstoneCompactionThreshold`：tombstone 文件达到此条目数时触发主缓存压缩（默认 `200`）
- `tombstoneFileName`：tombstone 文件名（默认 `data_plus_events_tombstone.txt`）

**重试**
- `baseRetryDelay`：基础重试延迟（默认 `2秒`）
- `maxRetryDelay`：最大重试延迟（默认 `60秒`）
- `maxBackoffLevel`：最大退避级别（默认 `5`）

**广告去重**
- `maxAdImpressionCapacity`：广告去重集合最大容量，FIFO 淘汰（默认 `10000`）

恢复所有默认值：

```dart
SdkConfig.reset();
```

## 更多文档

本仓库根目录提供了更详细的开发文档：

- **SDK_USAGE_GUIDE.md**：完整使用指南，包含所有内置事件的数据结构与字段说明、会话规则、自动埋点细节、性能与容错机制说明等。

建议接入前先通读 `SDK_USAGE_GUIDE.md`，本 README 主要用于快速了解和集成。

---

## 手动上报事件

```dart
void track(dynamic event)
```

上报任意事件，传入 SDK 内置事件类即可。

### 1. App 安装事件（客户端）

> 首次安装启动时，读取剪贴板获取到 `traceId` 后上报。

```dart
AnalyticsSdk.instance.track(AppInstallEvent(
  traceId: 'landing_page_trace_id_xxx',  // 落地页点击生成的唯一 ID
));
```

### 2. 视频行为事件（客户端）

```dart
import 'package:analytics_sdk/enum/video_event_enum.dart';

AnalyticsSdk.instance.track(VideoEvent(
  videoId: 'video_123',
  videoTitle: '示例视频',
  videoTypeId: 'type_1',
  videoTypeName: '娱乐',
  videoTagKey: 'tag_1,tag_2',
  videoTagName: '热门,最新',
  videoDuration: 300,
  playDuration: 60,
  playProgress: 20,
  videoBehavior: VideoEventEnum.VIDEO_PLAY,
  mediaId: '',
));
```

### 3. 小说阅读事件（客户端）

```dart
import 'package:analytics_sdk/enum/read_behavior_enum.dart';

AnalyticsSdk.instance.track(NovelEvent(
  novelId: 'novel_123',
  novelTitle: '示例小说',
  novelTypeId: 'type_1',
  novelTypeName: '玄幻',
  novelTagKey: 'tag_1,tag_2',
  novelTagName: '玄幻,穿越',
  readProgress: 50,
  pageNo: 10,
  novelBehavior: ReadBehaviorEnum.PAGE_NEXT,
));
```

### 4. 漫画阅读事件（客户端）

```dart
AnalyticsSdk.instance.track(ComicEvent(
  comicId: 'comic_123',
  comicTitle: '示例漫画',
  comicTypeId: 'type_1',
  comicTypeName: '热血',
  comicTagKey: 'tag_1,tag_2',
  comicTagName: '热血,冒险',
  readProgress: 30,
  pageNo: 5,
  comicBehavior: ReadBehaviorEnum.VIEW,
));
```

### 5. 广告展示事件（客户端，带自动去重）

> SDK 会对 `adId` 进行 session 级别去重：同一个 `adId` 在当前 session 内只会上报一次。

```dart
import 'package:analytics_sdk/enum/ad_type_enum.dart';

AnalyticsSdk.instance.track(AdImpressionEvent(
  pageKey: PageLifecycleObserver.currentPageKey,
  pageName: PageNameMapper.getPageName(PageLifecycleObserver.currentPageKey),
  adSlotKey: 'home_banner_1',
  adSlotName: '首页顶部Banner',
  adId: 'ad_123,ad_456,ad_789',        // 多个 adId 英文逗号分隔
  creativeId: 'cr_001,cr_002,cr_003',  // 与 adId 一一对应，可传 null
  adType: AdTypeEnum.banner,
));
```

### 6. 广告点击事件（客户端）

```dart
AnalyticsSdk.instance.track(AdClickEvent(
  pageKey: PageLifecycleObserver.currentPageKey,
  pageName: PageNameMapper.getPageName(PageLifecycleObserver.currentPageKey),
  adSlotKey: 'home_banner_1',
  adSlotName: '首页顶部Banner',
  adId: 'ad_123',
  adType: AdTypeEnum.banner,
));
```

### 7. APP 广告行为事件（客户端）

> 用于上报 APP 内置活动弹窗、运营 Banner 等的展示、点击、关闭行为。

```dart
import 'package:analytics_sdk/enum/banner_event_enum.dart';

AnalyticsSdk.instance.track(AdvertisingEvent(
  eventType: BannerEventEnum.CLICK.label,  // 'click'
  advertisingKey: 'home_banner',
  advertisingName: '首页Banner',
  advertisingId: 'ad_001',
));
```

### 8. 关键词搜索事件（客户端）

```dart
AnalyticsSdk.instance.track(KeywordSearchEvent(
  keyword: '示例关键词',
  searchResultCount: 100,
));
```

### 9. 关键词搜索结果点击事件（客户端）

```dart
import 'package:analytics_sdk/enum/click_item_type_enum.dart';

AnalyticsSdk.instance.track(KeywordClickEvent(
  keyword: '示例关键词',
  clickItemId: 'video_123',
  clickItemType: ClickItemTypeEnum.VIDEO,
  clickPosition: 1,
));
```

### 10. 推荐列表展示事件（客户端）

```dart
AnalyticsSdk.instance.track(RecommendListViewEvent(
  pageKey: 'home',
  pageName: '首页',
  recommendContentType: RecommendContentTypeEnum.video,
  recommendTraceId: 'rec_trace_abc123',
  recommendId: 'vid_001,vid_002,vid_003',
));
```

### 11. 推荐列表点击事件（客户端）

```dart
AnalyticsSdk.instance.track(RecommendListClickEvent(
  pageKey: 'home',
  pageName: '首页',
  recommendTraceId: 'rec_trace_abc123',
  recommendId: 'vid_001',
));
```

### 强制立即上报

```dart
await AnalyticsSdk.instance.flush();
```

### 资源清理

建议在应用退出前调用，SDK 会先尝试上报剩余事件，再释放所有资源：

```dart
await AnalyticsSdk.instance.dispose();
```

---

## 用户类型管理

```dart
import 'package:analytics_sdk/enum/user_type_enum.dart';

// 用户登录时设置用户 ID 和类型
AnalyticsSdk.setUserIdAndType(
  userId: 'user_123',
  userTypeEnum: UserTypeEnum.vip,
);

// 只更新用户类型（升级会员等）
AnalyticsSdk.instance.updateUserType(UserTypeEnum.vip.label);

// 用户登出
AnalyticsSdk.logoutUser();
```

---

## 页面名称映射

SDK 使用路由 key（`RouteSettings.name`）作为 `pageKey`，建议在应用启动时统一注册映射：

```dart
import 'package:analytics_sdk/manager/page_name_manager.dart';

// 批量添加
PageNameMapper.addMappings({
  '/': '首页',
  '/video_detail': '视频详情页',
  '/user_center': '个人中心',
  '/search': '搜索页',
});

// 单条添加
PageNameMapper.addMapping('/settings', '设置页');

// 获取
String pageName = PageNameMapper.getPageName('/video_detail'); // '视频详情页'
```

### 动态获取当前页面信息

```dart
import 'package:analytics_sdk/observer/page_lifecycle_observer.dart';
import 'package:analytics_sdk/manager/page_name_manager.dart';

AnalyticsSdk.instance.track(AdImpressionEvent(
  pageKey: PageLifecycleObserver.currentPageKey,
  pageName: PageNameMapper.getPageName(PageLifecycleObserver.currentPageKey),
  adSlotKey: 'home_banner_1',
  adSlotName: '首页顶部Banner',
  adId: 'ad_123',
  adType: AdTypeEnum.banner,
));
```

---

## 事件数据结构

所有事件上报时都包含以下公共字段（顶层）：

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `event` | String | 事件类型，如 `video_event` |
| `channel` | String | 渠道标识 |
| `app_id` | String | 应用 ID |
| `uid` | String | 用户 ID |
| `sid` | String | 会话 ID（冷启动或后台超 30 分钟时重新生成） |
| `client_ts` | int | 事件对象**创建时**的时间戳（10位秒级） |
| `device` | String | 设备类型（SDK 自动检测） |
| `device_id` | String | 设备唯一标识（由 `init(deviceId)` 传入） |
| `device_brand` | String | 设备品牌（SDK 自动检测） |
| `device_model` | String | 设备型号（SDK 自动检测） |
| `user_agent` | String | 客户端 UA（SDK 自动检测） |
| `system_name` | String | 操作系统名称（SDK 自动检测） |
| `system_version` | String | 操作系统版本（SDK 自动检测） |
| `device_fingerprint` | String | 设备指纹（SHA-256；因子全空时降级为 UUID v4） |
| `fp_version` | String | 指纹生成规则版本号（当前为 `1`） |
| `event_id` | String | 事件去重 ID（双重 MD5） |
| `payload` | Object | 事件业务字段 |

> `device_fingerprint` 和 `fp_version` 均不参与 `event_id` 的 MD5 计算。

---

## 上报机制

### 批量上报地址

```
POST {fastestDomain}/api/eventTracking/batchReport.json?appId={appId}
Content-Type: application/json
Body: [ {...事件1}, {...事件2}, ... ]
```

### 触发条件

- 队列达到 10 条（`SdkConfig.autoUploadThreshold`）
- 定时器每 5 秒触发（`SdkConfig.uploadInterval`）
- 手动调用 `flush()`

### 本地持久化

- 事件自动保存到 `data_plus_events_cache.jsonl`（应用文档目录）
- 应用重启后自动从缓存恢复并上报；恢复时会过滤掉已通过 tombstone 标记为已上报的事件，以及当前事件类型白名单中未启用的事件类型
- 上报成功后，已上报的 `event_id` 追加写入 tombstone 文件（`data_plus_events_tombstone.txt`），避免每次上报都重写整个缓存文件；tombstone 条目达到 200 条（`SdkConfig.tombstoneCompactionThreshold`）时触发一次主缓存压缩合并

### 重试机制

失败后指数退避重试：`2s → 4s → 8s → 16s → 32s`，超过 60s 上限后不再翻倍，最多重试 5 级。

---

## 事件去重

### 通用事件去重

每个事件都有唯一的 `event_id`（基于所有字段的双重 MD5 计算），服务端可以使用 `event_id` 去重。

### 广告展示事件去重

`AdImpressionEvent` 在客户端进行额外去重：

- 基于 `adId` 去重，同一 `adId` 在当前 session 只上报一次
- 支持多个 `adId` 逗号分隔，只上报未曾上报的 ID
- 去重记录在内存中，应用重启后清空
- 容量上限默认 10000 条，超出时 FIFO 淘汰最旧记录

去重管理 API：

```dart
import 'package:analytics_sdk/manager/ad_impression_manager.dart';

// 检查广告 ID 是否已上报
bool isReported = AdImpressionManager.instance.isReported('ad_123');

// 获取多个 ID 中哪些未上报
List<String> unreported = AdImpressionManager.instance.getUnreportedAdIds('ad_123,ad_456');

// 清除已上报记录（测试用）
AdImpressionManager.instance.clear();
```

---

## 完整示例

```dart
import 'package:analytics_sdk/analytics_sdk.dart';
import 'package:analytics_sdk/config/sdk_config.dart';
import 'package:analytics_sdk/entity/video_event.dart';
import 'package:analytics_sdk/entity/ad_impression_event.dart';
import 'package:analytics_sdk/entity/advertising_event.dart';
import 'package:analytics_sdk/enum/user_type_enum.dart';
import 'package:analytics_sdk/enum/video_event_enum.dart';
import 'package:analytics_sdk/enum/ad_type_enum.dart';
import 'package:analytics_sdk/enum/banner_event_enum.dart';
import 'package:analytics_sdk/manager/page_name_manager.dart';
import 'package:analytics_sdk/observer/page_lifecycle_observer.dart';
import 'package:analytics_sdk/widget/global_click_wrapper.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 可选：调整 SDK 默认参数
  SdkConfig.configure(
    uploadInterval: const Duration(seconds: 10),
    autoUploadThreshold: 20,
  );

  // 配置页面名称映射
  PageNameMapper.addMappings({
    '/': '首页',
    '/video_detail': '视频详情页',
    '/user_center': '个人中心',
  });

  // 从自己的服务端获取加密配置
  final encryptedConfig = await yourApiClient.fetchEncryptedConfig();

  // 初始化 SDK（设备信息自动采集，无需外部传入）
  await AnalyticsSdk.instance.init(
    appId: 'your_app_id',
    encryptedConfig: encryptedConfig,
    channel: 'official',
    uid: '',   // 未登录时传空
    deviceId: 'device_unique_id',
    enableDebugBanner: true,   // 仅 debug 包生效
  );

  // 设置登录用户信息（已登录时）
  AnalyticsSdk.setUserIdAndType(
    userId: 'user_123',
    userTypeEnum: UserTypeEnum.vip,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnalyticsDebugBanner(          // 仅 debug 包显示调试悬浮条
      child: MaterialApp(
        navigatorObservers: [
          AnalyticsSdk.instance.pageObserver,  // 页面生命周期自动埋点
        ],
        builder: (context, child) {
          return GlobalClickWrapper(           // 全局点击自动抓取
            child: child!,
          );
        },
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                AnalyticsSdk.instance.track(VideoEvent(
                  videoId: 'video_123',
                  videoTitle: '示例视频',
                  videoTypeId: 'type_1',
                  videoTypeName: '娱乐',
                  videoTagKey: 'hot',
                  videoTagName: '热门',
                  videoDuration: 300,
                  playDuration: 60,
                  playProgress: 20,
                  videoBehavior: VideoEventEnum.VIDEO_PLAY,
                ));
              },
              child: const Text('上报视频播放'),
            ),
            ElevatedButton(
              onPressed: () {
                AnalyticsSdk.instance.track(AdImpressionEvent(
                  pageKey: PageLifecycleObserver.currentPageKey,
                  pageName: PageNameMapper.getPageName(PageLifecycleObserver.currentPageKey),
                  adSlotKey: 'home_banner_1',
                  adSlotName: '首页顶部Banner',
                  adId: 'ad_123,ad_456',
                  adType: AdTypeEnum.banner,
                ));
              },
              child: const Text('上报广告展示'),
            ),
            ElevatedButton(
              onPressed: () {
                AnalyticsSdk.instance.track(AdvertisingEvent(
                  eventType: BannerEventEnum.CLICK.label,
                  advertisingKey: 'home_popup',
                  advertisingName: '首页弹窗',
                  advertisingId: 'adv_001',
                ));
              },
              child: const Text('上报弹窗点击'),
            ),
            ElevatedButton(
              onPressed: () => AnalyticsSdk.instance.flush(),
              child: const Text('立即上报'),
            ),
          ],
        ),
      ),
    );
  }
}

// 应用退出时清理资源
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AnalyticsSdk.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      AnalyticsSdk.instance.dispose();
    }
  }
}
```

---

## 枚举类型参考

### UserTypeEnum

| 枚举值 | label | 说明 |
|--------|-------|------|
| `UserTypeEnum.normal` | `normal` | 普通用户 |
| `UserTypeEnum.vip` | `vip` | VIP 用户 |

### DeviceEnum

| 枚举值 | label | 说明 |
|--------|-------|------|
| `DeviceEnum.android` | `Android` | Android 设备 |
| `DeviceEnum.iOS` | `iOS` | iOS 设备 |
| `DeviceEnum.pc` | `PC` | PC 设备 |

### VideoEventEnum

| 枚举值 | key | 说明 |
|--------|-----|------|
| `VideoEventEnum.VIDEO_PLAY` | `video_play` | 播放 |
| `VideoEventEnum.VIDEO_PAUSE` | `video_pause` | 暂停 |
| `VideoEventEnum.VIDEO_SHARE` | `video_share` | 分享 |
| `VideoEventEnum.VIDEO_COMPLETE` | `video_complete` | 播放完成 |
| `VideoEventEnum.VIDEO_FORWARD` | `video_forward` | 快进 |
| `VideoEventEnum.VIDEO_REWIND` | `video_rewind` | 快退 |

### VideoContentTypeEnum

| 枚举值 | label | 说明 |
|--------|-------|------|
| `VideoContentTypeEnum.video` | `video` | 长视频 |
| `VideoContentTypeEnum.shortVideo` | `short_video` | 短视频 |

### ReadBehaviorEnum

| 枚举值 | key | 说明 |
|--------|-----|------|
| `ReadBehaviorEnum.VIEW` | `view` | 展示 |
| `ReadBehaviorEnum.PAGE_NEXT` | `page_next` | 下一页 |
| `ReadBehaviorEnum.PAGE_PREV` | `page_prev` | 上一页 |
| `ReadBehaviorEnum.COMPLETE` | `complete` | 读完 |

### AdTypeEnum

| 枚举值 | label | 说明 |
|--------|-------|------|
| `AdTypeEnum.icon` | `icon` | 图标广告 |
| `AdTypeEnum.banner` | `banner` | Banner |
| `AdTypeEnum.feed` | `feed` | 信息流 |
| `AdTypeEnum.player` | `player` | 播放器广告 |
| `AdTypeEnum.splash` | `splash` | 开屏广告 |
| `AdTypeEnum.text` | `text` | 文字广告 |

### BannerEventEnum

| 枚举值 | label | 说明 |
|--------|-------|------|
| `BannerEventEnum.CLICK` | `click` | 点击 |
| `BannerEventEnum.CLOSE` | `close` | 关闭 |
| `BannerEventEnum.SHOW` | `show` | 展示 |

### AuthTypeEnum

| 枚举值 | label | 说明 |
|--------|-------|------|
| `AuthTypeEnum.phone` | `phone` | 手机号 |
| `AuthTypeEnum.deviceid` | `deviceid` | 设备 ID |
| `AuthTypeEnum.email` | `email` | 邮箱 |
| `AuthTypeEnum.username` | `username` | 账号 |

### ClickItemTypeEnum

| 枚举值 | key | 说明 |
|--------|-----|------|
| `ClickItemTypeEnum.VIDEO` | `video` | 视频 |
| `ClickItemTypeEnum.NOVEL` | `novel` | 小说 |
| `ClickItemTypeEnum.COMIC` | `comic` | 漫画 |

### RecommendContentTypeEnum

| 枚举值 | label | 说明 |
|--------|-------|------|
| `RecommendContentTypeEnum.video` | `video` | 视频 |
| `RecommendContentTypeEnum.novel` | `novel` | 小说 |
| `RecommendContentTypeEnum.comic` | `comic` | 漫画 |

### OrderTypeEnum

| 枚举值 | label | 说明 |
|--------|-------|------|
| `OrderTypeEnum.coinPurchase` | `coin_purchase` | 金币购买 |
| `OrderTypeEnum.vipSubscription` | `vip_subscription` | VIP 订阅 |

### CurrencyEnum

| 枚举值 | label | 说明 |
|--------|-------|------|
| `CurrencyEnum.cny` | `CNY` | 人民币 |
| `CurrencyEnum.usd` | `USD` | 美元 |

### PayTypeEnum

| 枚举值 | label | 说明 |
|--------|-------|------|
| `PayTypeEnum.wechat` | `wechat` | 微信支付 |
| `PayTypeEnum.alipay` | `alipay` | 支付宝 |
| `PayTypeEnum.bankCard` | `bank_card` | 银行卡 |
| `PayTypeEnum.applePay` | `apple_pay` | Apple Pay |

### ConsumeReasonEnum

| 枚举值 | label | 说明 |
|--------|-------|------|
| `ConsumeReasonEnum.videoUnlock` | `video_unlock` | 视频解锁 |
| `ConsumeReasonEnum.giftSend` | `gift_send` | 礼物赠送 |
| `ConsumeReasonEnum.contentPurchase` | `content_purchase` | 内容购买 |

---

## 注意事项

1. **初始化时机**：建议在 `main()` 函数中、`runApp()` 之前初始化 SDK。

2. **encryptedConfig 由宿主 App 负责获取**：SDK 不自主发起配置接口请求，宿主 App 需自行从服务端获取加密配置串，再传入 `init()` 或 `refreshDomainConfig()`。

3. **设备信息自动采集**：品牌、型号、系统名称和版本由 SDK 通过 `device_info_plus` 自动读取，无需外部传入。`deviceId` 仍由宿主 App 提供（Android IMEI/OAID、iOS IDFV 等）。

4. **页面路由命名**：确保所有页面路由都有名称，SDK 才能正确追踪页面生命周期：
   ```dart
   MaterialApp(
     routes: {
       '/': (context) => HomePage(),          // ✅ 有路由名称
       '/detail': (context) => DetailPage(),
     },
   )
   ```

5. **用户信息更新**：用户登录、登出、升级会员等操作时，记得调用相应的用户管理方法。

6. **网络权限**：
   - Android：在 `AndroidManifest.xml` 中添加 `INTERNET` 权限
   - iOS：确保 `Info.plist` 中 `NSAppTransportSecurity` 配置正确

7. **资源清理**：应用退出前建议调用 `dispose()` 清理资源。

8. **事件过滤**：未在 `encryptedConfig.eventList` 中启用的事件类型会被静默丢弃，可通过日志确认。`eventList` 为空时默认允许所有事件上报。

9. **AdImpressionEvent 的 adType 需传枚举**：不能传字符串，需使用 `AdTypeEnum.banner` 等枚举值。

---

## 调试

### AnalyticsDebugBanner

在 `init()` 时设置 `enableDebugBanner: true`，并在 Widget 树根部加入 `AnalyticsDebugBanner`（仅 debug 包显示）：

```dart
import 'package:analytics_sdk/analytics_sdk.dart';

AnalyticsDebugBanner(
  child: MaterialApp(...),
)
```

悬浮条显示 7 个埋点流程步骤：①域名配置 → ②SDK初始化 → ③域名列表 → ④域名测速 → ⑤上报地址 → ⑥待上报队列 → ⑦最近上报结果。

### 通过代码获取调试信息

```dart
// 获取摘要
final info = AnalyticsSdk.instance.getDebugInfo();
print(info['inited']);       // SDK 是否初始化
print(info['queueLength']);  // 当前队列长度
print(info['reportUrl']);    // 上报 URL

// 获取详细步骤
final steps = AnalyticsSdk.instance.getDebugSteps();
for (final step in steps) {
  print('${step['name']}: ${step['status']} - ${step['detail']}');
}
```

### 控制日志输出

```dart
import 'package:analytics_sdk/utils/logger.dart';

Logger.enabled = false;  // 关闭所有日志
Logger.enabled = true;   // 开启日志（debug 包默认已开启）
```

---

## 常见问题 FAQ

**Q: 事件没有上报成功怎么办？**

A:
1. 检查网络连接和权限
2. 确认 `encryptedConfig` 是否传入且格式正确（可用 `validateEncryptedConfig()` 验证）
3. 查看控制台日志了解具体错误
4. 检查是否调用了 `flush()` 或在应用退出前调用了 `dispose()`

**Q: 如何验证 encryptedConfig 是否正确？**

A: 在 debug 包中调用：

```dart
final result = AnalyticsSdk.instance.validateEncryptedConfig(encryptedString);
print(result);
```

**Q: 事件上报延迟多久？**

A: 正常情况下：
- 队列达到 10 条时立即上报
- 每 5 秒定时上报一次
- 调用 `flush()` 立即上报

**Q: 为什么某些事件没有上报？**

A: 可能原因：
1. 事件类型不在 `encryptedConfig.eventList` 白名单中
2. 广告展示事件被 session 级别去重过滤
3. 事件单条超过 300KB 被丢弃
4. 队列满（默认上限 5000 条）
5. 上报 URL 未就绪（域名测速未完成或 encryptedConfig 未传入）

**Q: 如何动态开启/关闭某些事件的上报？**

A: 通过服务端更新 `encryptedConfig` 中的 `eventList`，然后调用：

```dart
await AnalyticsSdk.instance.refreshDomainConfig(encryptedConfig: newEncryptedConfig);
```

**Q: 如何自定义 SDK 配置参数？**

A:

```dart
import 'package:analytics_sdk/config/sdk_config.dart';

SdkConfig.configure(
  maxQueueSize: 10000,
  uploadInterval: const Duration(seconds: 30),
  connectionTimeout: const Duration(seconds: 15),
);

await AnalyticsSdk.instance.init(...);
```

**Q: 如何控制日志输出？**

A:

```dart
import 'package:analytics_sdk/utils/logger.dart';
Logger.enabled = false;
```

---

## 支持的事件类型

| 事件类型字符串 | 说明 | 上报方式 |
|--------------|------|---------|
| `app_install` | App 安装 | 客户端 |
| `navigation` | 导航事件 | **自动** |
| `app_page_view` | 应用页面展示 | **自动** |
| `page_click` | 应用页面点击 | **自动** |
| `page_lifecycle` | 页面生命周期 | **自动** |
| `advertising` | APP 广告行为（弹窗/运营 Banner） | 客户端 |
| `ad_click` | 广告点击 | 客户端 |
| `ad_impression` | 广告展示 | 客户端 |
| `video_event` | 视频行为 | 客户端 |
| `novel_event` | 小说阅读 | 客户端 |
| `comic_event` | 漫画阅读 | 客户端 |
| `keyword_search` | 关键词搜索 | 客户端 |
| `keyword_click` | 关键词搜索结果点击 | 客户端 |
| `recommend_list_view` | 推荐列表展示 | 客户端 |
| `recommend_list_click` | 推荐列表点击 | 客户端 |

---

## 依赖项

- `flutter`: Flutter SDK (>=3.3.0)
- `uuid`: UUID 生成（设备指纹因子全空时的降级兜底）
- `path_provider: ^2.1.4`: 本地文件路径获取
- `synchronized: ^3.1.0`: 并发控制锁
- `device_info_plus: ^10.0.0`: 自动采集设备品牌、型号、系统名称与版本
- `pointycastle: 3.7.3`: AES-GCM 解密
- `crypto: ^3.0.2`: SHA-256 / MD5 哈希计算

## 环境要求

- Dart SDK: `>=3.4.4 <4.0.0`
- Flutter: `>=3.3.0`
