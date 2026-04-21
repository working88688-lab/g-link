import 'package:flutter/widgets.dart';

import 'domain/model/home_data_model.dart';

class AppGlobal {
  static String m3u8Encrypt = '0';

  static BuildContext? context;

  static int aff = 0;

  // 短视频带入的信息 list index api 等
  static Map shortVideosInfo = {'list': [], 'page': 0, 'index': 0, 'api': ''};
  static String reportAppId = '';
  static String installFlag = '';
  static ReportConfig? reportConfig;
  static String reportTraceId = '';
  static String affXCode = '';

  static String officeSite = '';
}
