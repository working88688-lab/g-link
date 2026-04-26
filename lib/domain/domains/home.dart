import 'package:g_link/domain/type_def.dart';
import 'package:g_link/domain/model/ad_model.dart';

abstract class HomeDomain {
  /// 获取全局config接口
  // AsyncResult<HomeData> getHomeConfig();
  //
  /// APP点击统计
  AsyncJson reqAdClickCount({int? id, int? type});

  /// 获取当前投放中的启动页广告
  AsyncResult<SplashAd> getSplashAd();
  //
  // /// 应用商店
  // AsyncResult<AppCenterModel?> getAppCenter();
  //
  // /// 兑换
  // AsyncResult onExchange({
  //   required String cdk,
  // });
  //
  // /// 联系官方
  // AsyncResult<OfficialGroupModel> getContactList();
}
