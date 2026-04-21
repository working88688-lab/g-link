import '../../../domain/type_def.dart';
import 'base_service.dart';

class HomeService extends BaseService {
  HomeService(super._dio);

  @override
  final service = 'home';

  /// 获取全局config接口
  // AsyncJson getHomeConfig() => post('/config');
  //
  // /// APP点击统计
  AsyncJson reqAdClickCount({
    required int id,
    required int type,
  }) =>
      post('/click_report', data: {
        'id': id,
        'type': type,
      });
  //
  // /// 应用商店
  // AsyncJson getAppCenter() => post('/appCenter');
  //
  // /// 兑换
  // AsyncJson onExchange({
  //   required String cdk,
  // }) =>
  //     post('/exchange', data: {
  //       'cdk': cdk,
  //     });
  //
  // /// 联系官方
  // AsyncJson getContactList() => post('/getContactList');
}
