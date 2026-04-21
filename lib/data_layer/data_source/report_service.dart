import '../../../domain/type_def.dart';
import 'base_service.dart';

class ReportService extends BaseService {
  ReportService(super._dio);

  @override
  final service = 'sdk';

  /// 获取全局config接口
  AsyncJson getEncryptedConfig() => post('/event');
}