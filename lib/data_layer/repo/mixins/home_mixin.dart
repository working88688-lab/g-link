part of '../repo.dart';

mixin _Home on _BaseAppRepo implements HomeDomain {
  @override
  AsyncJson reqAdClickCount({int? id, int? type}) =>
      _homeService.reqAdClickCount(id: id ?? 0, type: type ?? 0);

  @override
  AsyncResult<SplashAd> getSplashAd() async {
    try {
      final result = (await _v1Dio.get('/api/v1/splash')).data;
      return Json.from(result)
          .deserializeJsonBy((json) => SplashAd.fromJson(Json.from(json)));
    } catch (err) {
      return Result(msg: err.toString());
    }
  }
}
