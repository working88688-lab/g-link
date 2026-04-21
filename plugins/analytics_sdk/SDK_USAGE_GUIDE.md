# Analytics SDK 使用文档

## 目录

1. [概述](#1-概述)
2. [安装](#2-安装)
3. [SDK 初始化](#3-sdk-初始化)
4. [用户管理](#4-用户管理)
5. [自动埋点](#5-自动埋点)
6. [手动事件上报](#6-手动事件上报)
7. [枚举参考](#7-枚举参考)
8. [SdkConfig 全局参数](#8-sdkconfig-全局参数)
9. [上报数据格式](#9-上报数据格式)
10. [调试工具](#10-调试工具)
11. [高级用法](#11-高级用法)
12. [完整集成示例](#12-完整集成示例)
13. [桌面平台接入（macOS / Windows）](#13-桌面平台接入macos--windows)

**自动埋点子节**
- [5.1 页面生命周期自动追踪](#51-页面生命周期自动追踪pagelifecycleobserver)
- [5.2 页面名称映射](#52-页面名称映射pagenamemapper)
- [5.3 全局点击自动追踪](#53-全局点击自动追踪globalclickwrapper)
- [5.4 Tab 切换自动追踪](#54-tab-切换自动追踪)

[版本更新说明](#版本更新说明)

---

## 版本更新说明

### v1.1.0（2026-04-16）

**新增**

- **Tab 切换自动埋点**：`BottomNavigationBar` 和 `TabBar` 新增 `.withAnalytics(tabs: [...])` 链式调用，Tab 切换时自动上报，无需手动调用 `track()`。
  - `BottomNavigationBar.withAnalytics()`：切换时同时上报 `AppPageViewEvent`（含来路页面）和 `NavigationEvent`，并更新 `currentPageKey`。
  - `TabBar.withAnalytics()`：切换时仅上报轻量 `NavigationEvent`，不更新 `currentPageKey`，适合页面内分区 Tab。返回值实现 `PreferredSizeWidget`，可直接用于 `AppBar.bottom`。
  - 新增 `AnalyticsTab(String key, [String? name])` 数据类，`name` 省略时由 `PageNameMapper` 自动解析。

**稳定性**

- 内部回调（Tab 切换处理、Logger.onLog）全部加入异常兜底，任何情况下不向宿主 App 传播异常。

**接入方影响**：零改动，新 API 纯新增。

---

### v1.0.0（2026-04-15）

**新增**

- 每个事件自动携带 `sdk_version`（SDK 版本号）和 `app_version`（由 `init(appVersion: ...)` 传入）公共字段。
- `AnalyticsSdk.getParams([List<String>? keys])`：暴露全部或指定公共参数，供服务端复用或调试。
- `device_info_plus`：设备品牌、型号、系统信息改为 SDK 内部自动采集，`init()` 无需外部传入。

**接入方影响**：`init()` 新增可选参数 `appVersion`；上报 JSON 新增 `sdk_version` 和 `app_version` 字段，服务端需兼容未知字段。

---

## 1. 概述

Analytics SDK 是一个 Flutter 插件，提供：

- 自动埋点：页面浏览、页面生命周期、全局点击、导航事件（均默认开启）
- 手动埋点：视频/小说/漫画行为、广告、推荐等客户端事件
- 本地持久化缓存（JSONL 格式），断网重传
- 域名并发测速，自动选择最快上报节点
- AES-GCM 加密配置，防止配置明文泄露
- 事件类型白名单控制（服务端下发）
- 广告展示去重（页面级别）
- 设备信息自动采集（通过 `device_info_plus`，无需外部传入）
- 设备指纹自动生成
- `getParams()` 方法暴露全部或指定公共参数，供服务端复用

所有公开方法均**不会向外抛出异常**，SDK 内部失败不影响宿主应用运行。

---

## 2. 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  analytics_sdk:
    path: ../analytics_sdk  # 或 git/pub 地址
```

运行：

```bash
flutter pub get
```

---

## 3. SDK 初始化

### 3.1 最简初始化

```dart
import 'package:analytics_sdk/analytics_sdk.dart';

await AnalyticsSdk.instance.init(
  appId: 'your_app_id',
  encryptedConfig: 'Base64加密字符串',  // 服务端下发
  deviceId: 'your_device_id',           // Android IMEI/OAID、iOS IDFV 等
);
```

设备品牌、型号、系统名称、版本等信息由 SDK 内部通过 `device_info_plus` 自动采集。

### 3.2 完整参数说明

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `appId` | `String` | 是 | — | 应用 ID |
| `encryptedConfig` | `String?` | 是（可传 null） | null | 加密配置字符串，见下方格式说明 |
| `channel` | `String?` | 否 | '' | 渠道标识，可后续通过 `setChannel` 更新 |
| `uid` | `String?` | 否 | '' | 用户 ID，未登录可传空，登录后通过 `setUserIdAndType` 更新 |
| `deviceId` | `String` | 是 | — | 设备唯一标识（Android IMEI/OAID、iOS IDFV 等） |
| `appVersion` | `String?` | 否 | `'1.0.0'` | 应用版本号，需符合 `x.y.z` 格式（如 `'2.3.1'`）。格式不合规时：Debug 模式打印错误日志并忽略传入值；Release 模式静默降级为 `'1.0.0'`。未传时默认 `'1.0.0'` |
| `enableDebugBanner` | `bool` | 否 | `false` | 是否显示调试悬浮条（仅在非 release 包生效） |

> **自动采集字段**：`device`（类型）、`device_brand`、`device_model`、`system_name`、`system_version`、`user_agent` 均由 SDK 通过 `device_info_plus` 自动读取，无需传入。

### 3.3 encryptedConfig 格式说明

`encryptedConfig` 是一个 Base64 编码的 AES-GCM 密文，解密后内容为：

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

- `domainList`：上报域名列表，SDK 启动时会并发测速，选择最快的域名上报。
- `eventList`：启用的事件类型白名单。**不在列表中的事件会被静默丢弃**。传空列表或省略此字段时，所有事件类型均允许上报。

如需在调试包中验证加密串，使用 [`validateEncryptedConfig`](#validateencryptedconfig)。

### 3.4 初始化时机

建议在 `main()` 中 `runApp()` 之前调用：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 可选：在 init() 前覆盖默认参数
  SdkConfig.configure(
    uploadInterval: const Duration(seconds: 5),
    autoUploadThreshold: 10,
  );

  await AnalyticsSdk.instance.init(
    appId: 'your_app_id',
    encryptedConfig: await fetchEncryptedConfigFromServer(),
    deviceId: await getDeviceId(),
    channel: 'google_play',
    uid: currentUser?.id ?? '',
  );

  runApp(const MyApp());
}
```

---

## 4. 用户管理

### 4.1 登录 / 切换账号

```dart
AnalyticsSdk.setUserIdAndType(
  userId: '12345',
  userTypeEnum: UserTypeEnum.vip,
);
```

| 参数 | 类型 | 说明 |
|------|------|------|
| `userId` | `String` | 用户 ID，默认空字符串（未登录状态） |
| `userTypeEnum` | `UserTypeEnum?` | 用户类型，null 时默认为 `normal` |

### 4.2 仅更新 uid（不改变用户类型）

```dart
AnalyticsSdk.setUid('12345');
```

### 4.3 更新渠道

```dart
AnalyticsSdk.setChannel('huawei_store');
```

### 4.4 登出

```dart
AnalyticsSdk.logoutUser();
```

---

## 5. 自动埋点

### 5.1 页面生命周期自动追踪（PageLifecycleObserver）

```dart
MaterialApp(
  navigatorObservers: [
    AnalyticsSdk.instance.pageObserver,
  ],
)
```

注册后 SDK 会自动追踪页面进入、离开和导航事件，无需手动上报。

获取当前页面 key：

```dart
final currentPage = PageLifecycleObserver.currentPageKey;
```

### 5.2 页面名称映射（PageNameMapper）

```dart
import 'package:analytics_sdk/manager/page_name_manager.dart';

PageNameMapper.addMappings({
  'home': '首页',
  'video_detail': '视频详情页',
  'user_center': '个人中心',
  'search': '搜索页',
});

final name = PageNameMapper.getPageName('video_detail'); // '视频详情页'
```

> **注意**：`pageKey` 和映射 key 均会自动去除前导 `/`，传 `'/video_detail'` 与 `'video_detail'` 效果相同。

### 5.3 全局点击自动追踪（GlobalClickWrapper）

```dart
import 'package:analytics_sdk/widget/global_click_wrapper.dart';

MaterialApp(
  builder: (context, child) => GlobalClickWrapper(child: child!),
)
```

自动上报 `PageClickEvent`，含归一化坐标（300ms 节流）。

### 5.4 Tab 切换自动追踪

通过 `.withAnalytics(tabs: [...])` 扩展方法包装原生 Widget，Tab 切换时自动上报，无需修改现有结构。

#### BottomNavigationBar（主导航）

```dart
BottomNavigationBar(
  currentIndex: _currentIndex,
  onTap: (i) => setState(() => _currentIndex = i),
  items: const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
    BottomNavigationBarItem(icon: Icon(Icons.explore), label: '发现'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
  ],
).withAnalytics(tabs: [
  AnalyticsTab('home'),
  AnalyticsTab('discover'),
  AnalyticsTab('profile'),
])
```

切换时同时上报：
- `AppPageViewEvent`：含来路页面 key，更新 `PageLifecycleObserver.currentPageKey`
- `NavigationEvent`：导航行为记录

#### TabBar（页内分区 Tab）

```dart
TabBar(
  controller: _tabController,
  tabs: const [Tab(text: '视频'), Tab(text: '小说')],
).withAnalytics(tabs: [
  AnalyticsTab('video', '视频'),   // 第二个参数为展示名称，省略时由 PageNameMapper 解析
  AnalyticsTab('novel', '小说'),
])
```

切换时仅上报 `NavigationEvent`，**不更新** `currentPageKey`（适合页面内轻导航，不影响页面路径追踪）。

返回值实现了 `PreferredSizeWidget`，可直接用于 `AppBar.bottom`：

```dart
AppBar(
  bottom: TabBar(...).withAnalytics(tabs: [...]),
)
```

#### AnalyticsTab 参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `key` | `String` | 是 | Tab 唯一标识，用于事件上报和页面路径追踪 |
| `name` | `String?` | 否 | Tab 展示名称；省略时由 `PageNameMapper.getPageName(key)` 解析，无映射则回退到 `key` |

> **注意**：`tabs` 列表顺序须与 `items` / `tabs` 保持一致，长度可以小于实际 Tab 数（多余的 Tab 会用 `tab_<index>` 兜底，不会崩溃）。

---

## 6. 手动事件上报

所有手动事件通过 `AnalyticsSdk.instance.track(event)` 上报。

### 6.1 App 安装事件【客户端】

> **触发时机**：首次安装启动后，读取剪贴板获取到 traceId 时上报。

```dart
AnalyticsSdk.instance.track(AppInstallEvent(
  traceId: 'clipboard_trace_id',
));
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `traceId` | `String` | 落地页生成并写入剪贴板的唯一追踪 ID |

---

### 6.2 视频行为事件【客户端】

> **触发时机**：用户播放、暂停、快进、完播等操作时上报。

```dart
AnalyticsSdk.instance.track(VideoEvent(
  videoId: 'vid_001',
  videoTitle: '精彩大片',
  videoTypeId: 'action',
  videoTypeName: '动作片',
  videoTagKey: 'hot,new',
  videoTagName: '热门,最新',
  videoDuration: 7200,
  playDuration: 120,
  playProgress: 30,
  videoBehavior: VideoEventEnum.VIDEO_PLAY,
  videoContentType: VideoContentTypeEnum.video,
  recommendTraceId: 'trace_abc123',  // 未接推荐引擎传 ''
  mediaId: '',
));
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `videoId` | `String` | 是 | 视频 ID |
| `videoTitle` | `String` | 是 | 视频标题 |
| `videoTypeId` | `String` | 是 | 视频分类 ID |
| `videoTypeName` | `String` | 是 | 视频分类名称 |
| `videoTagKey` | `String` | 是 | 标签 KEY，多个用英文逗号分隔 |
| `videoTagName` | `String` | 是 | 标签名称，多个用英文逗号分隔 |
| `videoDuration` | `int` | 是 | 视频总时长（秒） |
| `playDuration` | `int` | 是 | 本次播放时长（秒） |
| `playProgress` | `int` | 是 | 播放进度百分比（0-100） |
| `videoBehavior` | `VideoEventEnum` | 是 | 视频行为，见 [VideoEventEnum](#videoeventenum) |
| `videoContentType` | `VideoContentTypeEnum?` | 是 | 内容类型：`video`(长视频) / `short_video`(短视频)，不区分时传 `null` |
| `recommendTraceId` | `String` | 否 | 推荐引擎 trace ID，未接推荐引擎传 `''`，默认 `''` |
| `mediaId` | `String` | 否 | 媒体资源 ID，默认 `''` |

---

### 6.3 小说阅读事件【客户端】

```dart
AnalyticsSdk.instance.track(NovelEvent(
  novelId: 'novel_001',
  novelTitle: '斗破苍穹',
  novelTypeId: 'fantasy',
  novelTypeName: '玄幻',
  novelTagKey: 'hot,classic',
  novelTagName: '热门,经典',
  readProgress: 45,
  pageNo: 10,
  novelBehavior: ReadBehaviorEnum.PAGE_NEXT,
  chapterId: 'ch_001',       // 无章节时传 ''
  chapterName: '第一章 陨落的天才', // 无章节时传 ''
  mediaId: '',
));
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `novelId` | `String` | 是 | 小说 ID |
| `novelTitle` | `String` | 是 | 小说标题 |
| `novelTypeId` | `String` | 是 | 分类 ID |
| `novelTypeName` | `String` | 是 | 分类名称 |
| `novelTagKey` | `String` | 是 | 标签 KEY，多个用英文逗号分隔 |
| `novelTagName` | `String` | 是 | 标签名称，多个用英文逗号分隔 |
| `readProgress` | `int` | 是 | 阅读进度百分比（0-100） |
| `pageNo` | `int` | 是 | 当前阅读第几页（从 1 开始） |
| `novelBehavior` | `ReadBehaviorEnum` | 是 | 阅读行为，见 [ReadBehaviorEnum](#readbehaviorenum) |
| `chapterId` | `String` | 否 | 章节 ID，没有章节或未对接推荐引擎时传 `''`，默认 `''` |
| `chapterName` | `String` | 否 | 章节名称，没有章节或未对接推荐引擎时传 `''`，默认 `''` |
| `recommendTraceId` | `String` | 否 | 推荐引擎 trace ID，未接推荐引擎传 `''`，默认 `''` |
| `mediaId` | `String` | 否 | 媒体资源 ID，未使用老司机库资源时传 `''` |

---

### 6.4 漫画阅读事件【客户端】

```dart
AnalyticsSdk.instance.track(ComicEvent(
  comicId: 'comic_001',
  comicTitle: '火影忍者',
  comicTypeId: 'battle',
  comicTypeName: '热血',
  comicTagKey: 'hot,classic',
  comicTagName: '热门,经典',
  readProgress: 60,
  pageNo: 5,
  comicBehavior: ReadBehaviorEnum.PAGE_NEXT,
  chapterId: 'ch_001',    // 无章节时传 ''
  chapterName: '第一话',  // 无章节时传 ''
));
```

字段与 `NovelEvent` 对称，将 `novel*` 前缀替换为 `comic*`，`novelBehavior` 替换为 `comicBehavior`。`recommendTraceId`、`chapterId`、`chapterName` 字段同样支持，默认均为 `''`。

---

### 6.5 广告展示事件【客户端】（带自动去重）

> SDK 会对 `adId` 进行页面级去重：同一页面访问内，相同 `adId` 只上报一次；页面退出后去重状态自动清除，下次进入该页面可重新上报。新 session 开始时所有页面的去重记录同步清空。

```dart
AnalyticsSdk.instance.track(AdImpressionEvent(
  pageKey: 'home',
  pageName: '首页',
  adSlotKey: 'home_banner_1',
  adSlotName: '首页顶部Banner',
  adId: 'ad_001,ad_002,ad_003',
  creativeId: 'cr_001,cr_002,cr_003',
  adType: 'banner',   // 传广告类型字符串，不传默认空字符串
));
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `pageKey` | `String` | 是 | 页面标识 |
| `pageName` | `String` | 是 | 页面名称 |
| `adSlotKey` | `String` | 是 | 广告位标识 |
| `adSlotName` | `String` | 是 | 广告位名称 |
| `adId` | `String` | 是 | 广告 ID，多个用英文逗号分隔 |
| `creativeId` | `String` | 否 | 素材 ID，多个用英文逗号分隔，与 `adId` 一一对应，默认 `''` |
| `adType` | `String` | 否 | 广告类型字符串，如 `'banner'`、`'feed'`、`'splash'`，默认 `''` |

**去重逻辑**：
- 进入 TabA 展示 20 条广告 → 上报 20 条
- 切换到 TabB 展示 20 条广告 → 上报 20 条
- 返回 TabA 上滑新加载 10 条广告 → 上报新的 10 条
- 再次下滑看到之前已展示的广告 → 全部被过滤

---

### 6.6 广告点击事件【客户端】

```dart
AnalyticsSdk.instance.track(AdClickEvent(
  pageKey: 'home',
  pageName: '首页',
  adSlotKey: 'home_banner_1',
  adSlotName: '首页顶部Banner',
  adId: 'ad_001',
  creativeId: 'cr_001',
  adType: 'banner',
));
```

字段与 `AdImpressionEvent` 相同，`adId` 为单个广告 ID。

---

### 6.7 APP 广告行为事件【客户端】（弹窗/Banner 行为）

> 用于上报 APP 内置广告（弹窗、Banner 等）的展示、点击、关闭行为。

```dart
AnalyticsSdk.instance.track(AdvertisingEvent(
  eventType: BannerEventEnum.CLICK.label,
  advertisingKey: 'home_popup',
  advertisingName: '首页弹窗',
  advertisingId: 'adv_001',
));
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `eventType` | `String` | 行为类型：`click`/`close`/`show` |
| `advertisingKey` | `String` | 广告标识 |
| `advertisingName` | `String` | 广告名称 |
| `advertisingId` | `String` | 广告 ID |

---

### 6.8 关键词搜索事件【客户端】

```dart
AnalyticsSdk.instance.track(KeywordSearchEvent(
  keyword: '火影忍者',
  searchResultCount: 42,
  searchTraceId: '',  // 未接搜索引擎时传空字符串
  searchId: '',       // 未接搜索引擎时传空字符串
));
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `keyword` | `String` | 是 | 搜索关键词 |
| `searchResultCount` | `int` | 是 | 搜索结果数量 |
| `searchTraceId` | `String` | 否 | 搜索引擎 trace ID，未接搜索引擎时传 `''` |
| `searchId` | `String` | 否 | 搜索引擎 search ID，未接搜索引擎时传 `''` |

---

### 6.9 关键词点击事件【客户端】

```dart
AnalyticsSdk.instance.track(KeywordClickEvent(
  keyword: '火影忍者',
  clickItemId: 'vid_001',
  clickItemType: ClickItemTypeEnum.VIDEO,
  clickPosition: 1,
  searchTraceId: '',  // 未接搜索引擎时传空字符串
));
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `keyword` | `String` | 是 | 搜索关键词 |
| `clickItemId` | `String` | 是 | 点击项目 ID（视频ID / 小说ID 等） |
| `clickItemType` | `ClickItemTypeEnum` | 是 | 点击项目类型：`VIDEO` / `NOVEL` / `COMIC` |
| `clickPosition` | `int` | 是 | 点击位置（搜索结果中的排序位置，从 1 开始） |
| `searchTraceId` | `String` | 否 | 搜索引擎 trace ID，未接搜索引擎时传 `''` |

---

### 6.10 推荐列表展示事件【客户端】

```dart
AnalyticsSdk.instance.track(RecommendListViewEvent(
  pageKey: 'home',
  pageName: '首页',
  recommendContentType: RecommendContentTypeEnum.video,
  recommendTraceId: 'rec_trace_abc123',
  recommendId: 'vid_001,vid_002,vid_003',
  recommendTraceInfo: '{"source":"server"}',  // 未接推荐引擎传 ''
  clientVersion: '1.2.3',                     // 未接推荐引擎传 ''
));
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `pageKey` | `String` | 是 | 页面标识 |
| `pageName` | `String` | 是 | 页面名称 |
| `recommendContentType` | `RecommendContentTypeEnum` | 是 | 推荐内容类型，见 [RecommendContentTypeEnum](#recommendcontenttypeenum) |
| `recommendTraceId` | `String` | 是 | 推荐引擎 trace ID |
| `recommendId` | `String` | 是 | 可视窗口内的内容 ID，多个用英文逗号分隔 |
| `recommendTraceInfo` | `String` | 否 | 推荐引擎 trace info，未接推荐引擎传 `''`，默认 `''` |
| `clientVersion` | `String` | 否 | 客户端版本号，如 `'1.2.3'`，默认 `''` |

---

### 6.11 推荐列表点击事件【客户端】

```dart
AnalyticsSdk.instance.track(RecommendListClickEvent(
  pageKey: 'home',
  pageName: '首页',
  recommendContentType: RecommendContentTypeEnum.video,
  recommendTraceId: 'rec_trace_abc123',
  recommendId: 'vid_001',
  recommendTraceInfo: '{"source":"server"}',  // 未接推荐引擎传 ''
  clientVersion: '1.2.3',                     // 未接推荐引擎传 ''
));
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `pageKey` | `String` | 是 | 页面标识 |
| `pageName` | `String` | 是 | 页面名称 |
| `recommendContentType` | `RecommendContentTypeEnum` | 是 | 推荐内容类型，见 [RecommendContentTypeEnum](#recommendcontenttypeenum) |
| `recommendTraceId` | `String` | 是 | 推荐引擎 trace ID |
| `recommendId` | `String` | 是 | 被点击内容的 ID |
| `recommendTraceInfo` | `String` | 否 | 推荐引擎 trace info，未接推荐引擎传 `''`，默认 `''` |
| `clientVersion` | `String` | 否 | 客户端版本号，如 `'1.2.3'`，默认 `''` |

---

### 6.12 强制立即上报

```dart
await AnalyticsSdk.instance.flush();
```

### 6.13 释放资源

```dart
await AnalyticsSdk.instance.dispose();
```

---

## 7. 枚举参考

### DeviceEnum

| 枚举值 | label | 说明 |
|--------|-------|------|
| `DeviceEnum.android` | `Android` | Android 设备 |
| `DeviceEnum.iOS` | `iOS` | iOS 设备 |
| `DeviceEnum.pc` | `PC` | PC 设备 |

### UserTypeEnum

| 枚举值 | label | 说明 |
|--------|-------|------|
| `UserTypeEnum.normal` | `normal` | 普通用户 |
| `UserTypeEnum.vip` | `vip` | VIP 用户 |

### AdTypeEnum

> **已废弃**：`adType` 字段已改为普通 `String`，直接传字符串即可，如 `'banner'`、`'feed'`、`'splash'`。无需 import 枚举类。

### VideoEventEnum

| 枚举值 | key | 说明 |
|--------|-----|------|
| `VideoEventEnum.VIDEO_VIEW` | `video_view` | 展示 |
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

### ClickItemTypeEnum

| 枚举值 | label | 说明 |
|--------|-------|------|
| `ClickItemTypeEnum.VIDEO` | `video` | 视频 |
| `ClickItemTypeEnum.NOVEL` | `novel` | 小说 |
| `ClickItemTypeEnum.COMIC` | `comic` | 漫画 |

### RecommendContentTypeEnum

| 枚举值 | label | 说明 |
|--------|-------|------|
| `RecommendContentTypeEnum.video` | `video` | 视频 |
| `RecommendContentTypeEnum.novel` | `novel` | 小说 |
| `RecommendContentTypeEnum.comic` | `comic` | 漫画 |

### BannerEventEnum

| 枚举值 | label | 说明 |
|--------|-------|------|
| `BannerEventEnum.CLICK` | `click` | 点击 |
| `BannerEventEnum.CLOSE` | `close` | 关闭 |
| `BannerEventEnum.SHOW` | `show` | 展示 |

---

## 8. SdkConfig 全局参数

在 `AnalyticsSdk.instance.init()` **之前**调用 `SdkConfig.configure(...)` 覆盖默认值：

```dart
SdkConfig.configure(
  uploadInterval: const Duration(seconds: 5),
  autoUploadThreshold: 10,
  maxBatchSize: 200,
  connectionTimeout: const Duration(seconds: 15),
);
```

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `maxQueueSize` | `5000` | 内存队列最大容量，超过后新事件丢弃 |
| `autoUploadThreshold` | `10` | 队列达到此数量时立即触发上报 |
| `maxBatchSize` | `500` | 单次上报最大事件数 |
| `uploadInterval` | `Duration(seconds: 5)` | 定时上报间隔 |
| `clickThrottleDuration` | `Duration(milliseconds: 300)` | 点击事件节流时间 |
| `connectionTimeout` | `Duration(seconds: 10)` | HTTP 连接超时 |
| `readTimeout` | `Duration(seconds: 30)` | HTTP 读取超时 |
| `speedTestTimeout` | `Duration(seconds: 5)` | 域名测速超时 |
| `maxCacheLines` | `2000` | 缓存文件最大行数 |
| `maxCacheBytes` | `2 * 1024 * 1024` (2MB) | 缓存文件最大字节数 |
| `maxSingleEventSize` | `300 * 1024` (300KB) | 单条事件最大字节数，超过丢弃 |
| `maxAdImpressionCapacity` | `10000` | 广告去重集合最大容量（FIFO 淘汰） |

恢复所有默认值：

```dart
SdkConfig.reset();
```

---

## 9. 上报数据格式

### 9.1 公共字段

每个事件上报时，顶层 JSON 自动携带以下公共字段：

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `event` | `String` | 事件类型，如 `video_event`、`ad_impression` |
| `channel` | `String` | 渠道标识 |
| `app_id` | `String` | 应用 ID |
| `uid` | `String` | 用户 ID |
| `sid` | `String` | 会话 ID，由客户端 SDK 自动生成；服务端上报事件时需通过 `getParams` 获取并回传，以归属同一会话 |
| `client_ts` | `int` | 事件创建时间戳（10位，秒） |
| `device` | `String` | 设备类型（自动采集） |
| `device_id` | `String` | 设备唯一标识 |
| `device_brand` | `String` | 设备品牌（自动采集） |
| `device_model` | `String` | 设备型号（自动采集） |
| `user_agent` | `String` | 客户端标识（自动采集） |
| `system_name` | `String` | 操作系统名称（自动采集） |
| `system_version` | `String` | 操作系统版本（自动采集） |
| `device_fingerprint` | `String` | 设备指纹（自动生成） |
| `fp_version` | `String` | 指纹版本号 |
| `sdk_version` | `String` | SDK 版本号（自动写入，当前为 `1.1.0`） |
| `app_version` | `String` | 应用版本号（由接入方在 `init()` 中传入，未传默认 `'1.0.0'`） |
| `event_id` | `String` | 事件去重 ID（MD5，SDK 自动生成；1100ms 内重复 ID 将被防抖丢弃） |
| `payload` | `Object` | 事件业务字段 |

### 9.2 上报数据格式

```json
{
  "event": "video_event",
  "channel": "google_play",
  "app_id": "your_app_id",
  "uid": "12345",
  "sid": "sess_abc123",
  "client_ts": 1704067200,
  "device": "Android",
  "device_id": "xxxx",
  "device_brand": "Samsung",
  "device_model": "SM-G991B",
  "user_agent": "...",
  "system_name": "Android",
  "system_version": "14.0",
  "device_fingerprint": "sha256-hex-xxxx",
  "fp_version": "1",
  "sdk_version": "1.0.0",
  "app_version": "2.3.1",
  "event_id": "md5-hash-for-dedup",
  "payload": {
    "video_id": "vid_001",
    ...
  }
}
```

### 9.3 字段校验规则

SDK 在事件入队前会自动校验并修正字段。**关键字段**不合规时整个事件被静默丢弃；**可纠正字段**超限时自动截断或补全，不影响上报。

关键字段包括：`event`、`event_id`、`app_id`、`sid`、`client_ts`、`device`（提供了无法识别的值时）、`device_id`、`payload`（类型错误时），以及 payload 中的核心业务 ID 字段（`video_id` / `novel_id` / `comic_id` / `click_item_id`）。

> **通用类型处理规则**
> - 所有字符串字段在校验前均会自动 `trim()`（去除首尾空格）。
> - 非字符串类型（如 `int`、`bool`、`null` 等）传入字符串字段时视为类型错误，等同于未传该字段（关键字段 → 丢弃事件；可选字段 → 移除该字段）。
> - 数字字段（百分比 / 位置 / 数量 / 时间戳类）支持 `int`、`double` 以及纯数字字符串三种类型，均可正常解析。

#### 公共字段

| 字段 | 规则 | 不合规处理 |
|------|------|-----------|
| `event` | 小写字母/数字/下划线，最大 64 字符 | 丢弃事件 |
| `event_id` | 字母/数字，1~32 字符（SDK 自动生成） | 丢弃事件 |
| `app_id` | 非空，最大 64 字符 | 空时丢弃事件；超长截断 |
| `channel` | 可选，最大 128 字符 | 超长截断 |
| `uid` | 可选，最大 128 字符 | 超长截断 |
| `sid` | 自动生成；为空时 SDK 自动填充会话 ID | 生成失败则丢弃事件 |
| `client_ts` | 整数，范围 946684800 ~ 4102444800（2000 ~ 2100 年） | 丢弃事件 |
| `device` | 仅 `Android` / `iOS` / `PC`，大小写自动纠正 | 丢弃事件 |
| `device_id` | 非空，最大 128 字符 | 空时丢弃事件；超长截断 |
| `device_fingerprint` | 可选，最大 128 字符 | 超长截断 |
| `fp_version` | 若指纹非空而版本为空，自动填充默认版本 | — |
| `sdk_version` | 可选，最大 128 字符（SDK 自动写入） | 超长截断 |
| `app_version` | 可选，最大 128 字符；传入值须符合 `x.y.z` 格式，格式非法时 Debug 打印错误并忽略，Release 降级为 `'1.0.0'` | 超长截断 |

#### payload 业务字段

| 类别 | 代表字段 | 规则 | 不合规处理 |
|------|---------|------|-----------|
| 字段名 | 所有 key | `^[A-Za-z0-9_]+$` | 移除该字段 |
| 关键 ID | `video_id` / `novel_id` / `comic_id` / `click_item_id` | 非空 | 丢弃事件 |
| 普通 ID | `ad_id` / `recommend_id` 等 | 非空 | 移除该字段 |
| 逗号分隔 | `ad_id` / `novel_tag_key` / `video_tag_name` 等 | 自动清理各段首尾空格、过滤空段；清洗后仍为空则移除该字段 | 移除该字段 |
| 可选字符串 | `creative_id` / `recommend_trace_id` 等 | 可为空 | 空字符串原样保留 |
| 名称字段 | `page_name` / `ad_name` / `video_name` 等 | 最大 128 字符 | 截断 |
| 标题字段 | `title` / `content_title` / `search_keyword` 等 | 最大 256 字符 | 截断 |
| 关键词字段 | `keywords` / `tags` / `description` | 最大 500 字符 | 截断 |
| 百分比字段 | `progress` / `completion_rate` / `view_ratio` | 整数，0 ~ 100 | 移除该字段 |
| 位置字段 | `position` / `rank` / `slot` / `index` | 整数，≥ 1 | 移除该字段 |
| 数字字段 | `duration` / `count` / `amount` 等 | 整数，≥ 0 | 移除该字段 |
| 时间戳字段 | `start_ts` / `end_ts` / `publish_ts` | 同 `client_ts` 范围 | 移除该字段 |
| 其他字段 | — | 字符串最大 500 字符；非字符串原样保留 | 截断 |

### 9.4 设备指纹（device_fingerprint / fp_version）

设备指纹由 SDK 在 `init()` 时自动生成，业务方**无需**手动传入。

#### 采集因子

| 平台 | 参与计算的因子 |
|------|--------------|
| Native（Android / iOS / 桌面） | `device_id`、`device`（类型）、`device_brand`、`device_model`、`system_name`、`system_version` |
| Web | `device`、`device_brand`、`device_model`、`system_name`、`system_version`、`user_agent`、屏幕分辨率（`WxH`）、浏览器语言、时区名称 |

#### 生成规则

1. 过滤所有空因子，将剩余因子用 `|` 拼接后做 **SHA-256**，取 64 位十六进制字符串作为指纹。
2. 若**所有因子均为空**（降级场景），改为生成随机 **UUID v4** 并持久化至本地（见缓存规则），后续从本地读取保证稳定性。

> `device_fingerprint` **不参与** `event_id` 的计算。

#### 缓存规则

- **内存缓存**：首次生成后缓存在内存中，同一应用生命周期内直接返回，不重复计算。
- **持久化缓存**（仅降级 UUID 路径）：
  - Native：写入 `applicationDocumentsDirectory/analytics_fingerprint.txt`；
  - Web：写入 `localStorage['analytics_fp']`。
- 重新 `init()` 后若设备因子发生变化，可通过内部 `clearCache()` 重新计算（一般无需手动调用）。

#### 失败兜底

任何环节发生异常，均静默返回空字符串，事件照常上报；`device_fingerprint` 为空时，`fp_version` 字段亦不写入（无指纹则无需版本号）。

#### fp_version 说明

`fp_version` 标识当前指纹生成规则的版本（当前为 `"1"`），供服务端区分不同规则生成的指纹，支持跨版本数据对比分析。生成规则（因子组合或哈希算法）变更时版本号递增。

---

## 10. 调试工具

### 10.1 AnalyticsDebugBanner（悬浮调试条）

在 `init()` 时传 `enableDebugBanner: true`，然后将 `AnalyticsDebugBanner()` 放入 widget 树顶部（通常是页面 Column 的第一个子节点或 Stack 的顶层）：

```dart
await AnalyticsSdk.instance.init(
  // ...
  enableDebugBanner: true,
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            const AnalyticsDebugBanner(),  // 无需任何参数
            Expanded(child: YourContent()),
          ],
        ),
      ),
    );
  }
}
```

调试条显示 7 个步骤：①域名配置 ②SDK初始化 ③域名列表 ④域名测速 ⑤上报地址 ⑥待上报队列 ⑦最近上报。release 包自动隐藏，无性能影响。

### 10.2 getDebugSteps / getDebugInfo

```dart
final steps = AnalyticsSdk.instance.getDebugSteps();
for (final step in steps) {
  print('${step['name']}: ${step['status']} - ${step['detail']}');
}

final info = AnalyticsSdk.instance.getDebugInfo();
print(info['inited']);
print(info['queueLength']);
print(info['reportUrl']);
```

### 10.3 validateEncryptedConfig

```dart
final result = AnalyticsSdk.instance.validateEncryptedConfig(encryptedString);
if (result['success'] == true) {
  print('域名数量: ${result['domainCount']}');
  print('事件类型数量: ${result['eventCount']}');
} else {
  print('验证失败: ${result['error']}');
}
```

仅 debug 包可用，release 包返回错误。

### 10.4 Logger

```dart
import 'package:analytics_sdk/utils/logger.dart';

Logger.enabled = false;  // 关闭所有日志
```

---

## 11. 高级用法

### 11.1 延迟传入加密配置

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AnalyticsSdk.instance.init(
    appId: 'your_app_id',
    encryptedConfig: null,     // SDK 尝试读取磁盘缓存域名
    deviceId: await getDeviceId(),
  );

  runApp(const MyApp());

  // 异步获取，不阻塞 UI 启动
  _fetchAndApplyConfig();
}

Future<void> _fetchAndApplyConfig() async {
  try {
    final config = await yourApiClient.fetchEncryptedConfig();
    await AnalyticsSdk.instance.refreshDomainConfig(encryptedConfig: config);
  } catch (_) {}
}
```

### 11.2 获取公共参数（getParams）

`getParams()` 可获取 SDK 当前全部公共参数，适合服务端拼装事件或埋点调试：

```dart
// 获取全部参数
final all = AnalyticsSdk.getParams();

// 只取指定字段
final partial = AnalyticsSdk.getParams(['app_id', 'uid', 'device_id', 'device_fingerprint']);
```

返回 `Map<String, dynamic>`，包含：`app_id`、`channel`、`uid`、`user_type`、`sid`、`sdk_version`、`app_version`、`device`、`device_id`、`device_brand`、`device_model`、`user_agent`、`system_name`、`system_version`、`device_fingerprint`、`fp_version`。

> **`sid` 说明**：`sid`（会话 ID）由客户端 SDK 自动生成，服务端上报事件时需将其一并回传，以确保服务端事件与客户端事件归属同一会话。可通过 `getParams(keys: ['sid'])` 单独获取。

如果 key 不存在，该 key 不会出现在返回 Map 中（静默忽略）。

### 11.3 服务端复用设备公共字段

```dart
final deviceFields = AnalyticsSdk.getDeviceCommonFields();
// 包含：device, device_id, device_brand, device_model,
//       user_agent, system_name, system_version, device_fingerprint
```

---

## 12. 完整集成示例

```dart
import 'package:flutter/material.dart';
import 'package:analytics_sdk/analytics_sdk.dart';
import 'package:analytics_sdk/config/sdk_config.dart';
import 'package:analytics_sdk/enum/user_type_enum.dart';
import 'package:analytics_sdk/enum/video_content_type_enum.dart';
import 'package:analytics_sdk/enum/video_event_enum.dart';
import 'package:analytics_sdk/manager/page_name_manager.dart';
import 'package:analytics_sdk/widget/global_click_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SdkConfig.configure(
    uploadInterval: const Duration(seconds: 5),
    autoUploadThreshold: 10,
  );

  PageNameMapper.addMappings({
    'home': '首页',
    'video_detail': '视频详情页',
    'user_center': '个人中心',
    'search': '搜索页',
  });

  await AnalyticsSdk.instance.init(
    appId: 'your_app_id',
    encryptedConfig: 'YOUR_BASE64_ENCRYPTED_CONFIG',
    deviceId: 'device_unique_id',
    channel: 'google_play',
    uid: '',
    enableDebugBanner: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalClickWrapper(
      child: MaterialApp(
        navigatorObservers: [
          AnalyticsSdk.instance.pageObserver,
        ],
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/video_detail': (context) => const VideoDetailPage(),
        },
      ),
    );
  }
}

// ——— 登录场景 ———
void onLoginSuccess(String userId, bool isVip) {
  AnalyticsSdk.setUserIdAndType(
    userId: userId,
    userTypeEnum: isVip ? UserTypeEnum.vip : UserTypeEnum.normal,
  );
}

// ——— 视频播放场景 ———
void onVideoPlay(String videoId, String title) {
  AnalyticsSdk.instance.track(VideoEvent(
    videoId: videoId,
    videoTitle: title,
    videoTypeId: 'action',
    videoTypeName: '动作片',
    videoTagKey: 'hot',
    videoTagName: '热门',
    videoDuration: 7200,
    playDuration: 0,
    playProgress: 0,
    videoBehavior: VideoEventEnum.VIDEO_PLAY,
    videoContentType: VideoContentTypeEnum.video,
  ));
}

// ——— 广告展示场景 ———
void onAdsRendered(List<String> adIds) {
  AnalyticsSdk.instance.track(AdImpressionEvent(
    pageKey: 'home',
    pageName: '首页',
    adSlotKey: 'home_feed_ad',
    adSlotName: '首页信息流广告',
    adId: adIds.join(','),
    adType: 'feed',
  ));
}

// ——— 应用退出场景 ———
Future<void> onAppExit() async {
  await AnalyticsSdk.instance.flush();
  await AnalyticsSdk.instance.dispose();
}
```

---

## 13. 桌面平台接入（macOS / Windows）

### 13.1 支持情况

| 平台 | Dart 层 | 本地持久化 | HTTP 上报 | 设备信息采集 |
|------|---------|-----------|----------|------------|
| macOS | ✅ | ✅ path_provider | ✅ 需配置 entitlements | ✅ device_info_plus |
| Windows | ✅ | ✅ path_provider | ✅ | ✅ device_info_plus |

### 13.2 macOS 必要配置

macOS 沙箱默认禁止出站网络连接。使用 analytics_sdk 的 macOS App **必须**在 entitlements 文件中声明出站网络权限，否则所有事件上报请求会被系统静默拦截。

**`macos/Runner/DebugProfile.entitlements` 和 `macos/Runner/Release.entitlements` 均需添加：**

```xml
<key>com.apple.security.network.client</key>
<true/>
```

完整的 `Release.entitlements` 示例：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

### 13.3 Windows 配置

Windows 无需额外配置，正常集成即可。

### 13.4 deviceId 建议

桌面平台 SDK 不会自动采集硬件 ID，`deviceId` 由业务方传入。建议：

- **macOS**：使用 `IOKit` 读取硬件 UUID，或首次启动时生成 UUID 存入 `ApplicationSupportDirectory`
- **Windows**：读取注册表 `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography\MachineGuid`，或首次启动时生成 UUID 存入 `ApplicationSupportDirectory`

若暂无硬件 ID，可传入本地生成并持久化的随机 UUID，保证同设备一致即可。
