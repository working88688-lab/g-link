import 'package:g_link/domain/type_def.dart';

abstract class HomeDomain {


  /// 获取全局config接口
  // AsyncResult<HomeData> getHomeConfig();
  //
  /// APP点击统计
  AsyncJson reqAdClickCount({int? id, int? type});
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
