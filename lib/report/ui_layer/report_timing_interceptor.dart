// tracking/timing_interceptor.dart

import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../../app_global.dart';
import '../event_tracking.dart';
import 'report_timing_observer.dart';

/// Dio 拦截器：
/// - 为每个请求记录开始时间
/// - 在响应/错误时计算耗时
/// - 关联当前页面 page_key/page_name
class ReportTimingInterceptor extends Interceptor {
  static const skipKey = '__skip_timing__';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra[skipKey] == true) {
      return super.onRequest(options, handler);
    }
    //用 extra 挂一个 Stopwatch 作为本次请求的计时器
    options.extra['reqWatch'] = Stopwatch()..start();
    // 记录当前页面信息（来自 RouteStore）
    options.extra['event'] = 'app_page_view';
    options.extra['page_key'] = RouteStore.currentPageKey;
    options.extra['page_name'] = RouteStore.currentPageName;
    options.extra['current_page_key'] = RouteStore.currentPageKey;
    options.extra['current_page_name'] = RouteStore.currentPageName;
    options.extra['referrer_page_key'] = RouteStore.referrerPageKey;
    options.extra['referrer_page_name'] = RouteStore.referrerPageName;

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.extra[skipKey] != true) {
      _finish(options: response.requestOptions, success: true);
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    // TODO: implement onError
    if (err.requestOptions.extra[skipKey] != true) {
      _finish(options: err.requestOptions, success: false);
    }
    super.onError(err, handler);
  }

  void _finish({
    required RequestOptions options,
    required bool success,
  }) {
    final watch = options.extra['reqWatch'] as Stopwatch?;
    watch?.stop();
    final costMs = watch?.elapsedMilliseconds ?? 0;
    options.extra.remove("reqWatch");
    options.extra['page_load_time'] = costMs;

    // 这里就是你要的信息：当前页面 + 请求耗时

    EventTracking().reportSingle(options.extra).then((value) {
      // CommonUtils.log(value);
    });
    // if (AppGlobal.context != null) {
    //   AppGlobal.context!
    //       .read<ReportDomain>()
    //       .adReportData(params: Map<dynamic, dynamic>.from());
    // }

    // reqPageShowReport(data: Map<dynamic, dynamic>.from(options.extra));
  }
}
