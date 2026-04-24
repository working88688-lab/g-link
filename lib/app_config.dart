import 'package:flutter/foundation.dart';

class BuildConfig {
  /// 业务 API 默认域名
  static const apiBaseUrl = 'https://api.zywsbgha.cc';

  //android
  static const key = kIsWeb ? 'b78ce48964cffd68' : '2f2c6c47efd3db9e';
  static const iv = kIsWeb ? 'd82e851b5811f3a7' : 'f875148e9d362d00';
  static const appKey = kIsWeb
      ? 'dd9a7cf1b8d745cc5170dfc116c76f07'
      : 'bd47b841a9866687dd13ad1fd68f31c0';
  static const ver = kIsWeb ? 'v3' : 'v2';

  static const mediaKey = 'f5d965df75336270';
  static const mediaIv = '97b60394abc2fbe1';
  static const secretKey = '0cd8091ddd83a5a8';
  static const secretIv = 'c5546fcdd6f004b2';
  static const defaultFdsKey =
      'P/D/+MulHay6Jzah0AnECON76PVOS4idWjlv/W9FmBnsXsGE+wXTI/uP4UpmvvPD';

  static const linesUrlKey = 'lines_url_v6'; // 每次换线路都要v+1！！！
  /// 备用接口线路
  static final apiLines = kIsWeb
      ? [
          'https://api1.uyagwqc.com/api.php',
          'https://api2.uyagwqc.com/api.php',
          'https://api3.uyagwqc.com/api.php',
          'https://wapi1.uyagwqc.com/api.php',
        ]
      : [
          'https://api1.usdpsit.com/api.php',
          'https://api1.uuizymnj.cc/api.php',
          'https://api1.uxhrpow.com/api.php',
        ];

  /// 备用线路
  static const githubLine =
      'https://raw.githubusercontent.com/ailiu258099-blip/master/main/haijiao.txt';

  static final fdsKeyApi = [
    'https://wvseee.jsbacjr.com/fds.txt',
    'https://gitee.com/fdsaw/ffewelmcxww/raw/master/hj.txt',
  ];

  /// 跳转webview路径
  static const webViewPathName = 'ktloadwebview';

  static const affCodeKey = 'hjsq_aff';

  static const v1ApiBase = 'https://api.zywsbgha.cc';

  static const webBundleId = 'com.pwa.hjsq';

  static const cacheKeys = (
    appBox: 'hjsqbox',
    chats: 'hjsqbox_Chats',
    videoBox: 'hjsq_video_box',
    imageBox: 'hjsqbox_ImageCache',
    imageCacheSalt: 'aQhW1oUSlY',
  );
}
