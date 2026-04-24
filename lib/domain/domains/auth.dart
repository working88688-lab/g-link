import 'package:g_link/domain/model/auth_models.dart';
import 'package:g_link/domain/type_def.dart';

abstract class AuthDomain {
  AsyncResult<AuthResultData> login({
    required String account,
    required String password,
    required String deviceId,
    required String deviceType,
  });

  AsyncResult<AuthResultData> register({
    required String type,
    String? countryCode,
    String? phone,
    String? email,
    required String code,
    required String password,
    required bool agreementAccepted,
    required String deviceId,
    required String deviceType,
  });

  AsyncResult sendCode({
    required String channel,
    String? countryCode,
    String? phone,
    String? email,
    required String type,
  });
}
