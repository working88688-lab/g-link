import 'package:g_link/domain/type_def.dart';

import 'base_service.dart';

class AuthService extends BaseService {
  AuthService(super._dio);

  @override
  final service = 'v1';

  AsyncJson login({
    required String type,
    required String account,
    String? countryCode,
    String? phone,
    String? email,
    required String password,
    required String deviceId,
    required String deviceType,
  }) =>
      post('/auth/login',
          data: {
            'type': type,
            'account': account,
            if (countryCode != null && countryCode.isNotEmpty)
              'country_code': countryCode,
            if (phone != null && phone.isNotEmpty) 'phone': phone,
            if (email != null && email.isNotEmpty) 'email': email,
            'password': password,
            'device_id': deviceId,
            'device_type': deviceType,
          },
          encrypted: false);

  AsyncJson register({
    required String type,
    String? countryCode,
    String? phone,
    String? email,
    required String code,
    required String password,
    required bool agreementAccepted,
    required String deviceId,
    required String deviceType,
  }) =>
      post('/auth/register',
          data: {
            'type': type,
            if (countryCode != null && countryCode.isNotEmpty)
              'country_code': countryCode,
            if (phone != null && phone.isNotEmpty) 'phone': phone,
            if (email != null && email.isNotEmpty) 'email': email,
            'code': code,
            'password': password,
            'agreement_accepted': agreementAccepted,
            'device_id': deviceId,
            'device_type': deviceType,
          },
          encrypted: false);

  AsyncJson sendCode({
    required String channel,
    String? countryCode,
    String? phone,
    String? email,
    required String type,
  }) =>
      post('/auth/code/send',
          data: {
            'channel': channel,
            if (countryCode != null && countryCode.isNotEmpty)
              'country_code': countryCode,
            if (phone != null && phone.isNotEmpty) 'phone': phone,
            if (email != null && email.isNotEmpty) 'email': email,
            'type': type,
          },
          encrypted: false);

  AsyncJson resetPassword({
    required String type,
    String? countryCode,
    String? phone,
    String? email,
    required String code,
    required String password,
  }) =>
      post('/auth/reset-password',
          data: {
            'type': type,
            if (countryCode != null && countryCode.isNotEmpty)
              'country_code': countryCode,
            if (phone != null && phone.isNotEmpty) 'phone': phone,
            if (email != null && email.isNotEmpty) 'email': email,
            'code': code,
            'password': password,
          },
          encrypted: false);

  AsyncJson getCountryCodes() => get('/auth/country-codes', encrypted: false);
}
