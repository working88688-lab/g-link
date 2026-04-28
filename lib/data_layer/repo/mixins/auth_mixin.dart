part of '../repo.dart';

mixin _Auth on _BaseAppRepo implements AuthDomain {
  @override
  AsyncResult<AuthResultData> login({
    required String type,
    required String account,
    String? countryCode,
    String? phone,
    String? email,
    required String password,
    required String deviceId,
    required String deviceType,
  }) async {
    final parsed = await _authService
        .login(
          type: type,
          account: account,
          countryCode: countryCode,
          phone: phone,
          email: email,
          password: password,
          deviceId: deviceId,
          deviceType: deviceType,
        )
        .deserializeJsonBy(AuthResultData.fromJson)
        .guard;
    final data = parsed.data;
    if (parsed.status == 0 &&
        data != null &&
        data.tokens.accessToken.isNotEmpty &&
        data.tokens.refreshToken.isNotEmpty) {
      _updateToken(data.tokens.accessToken, data.tokens.refreshToken);
    }
    return parsed;
  }

  @override
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
  }) async {
    final parsed = await _authService
        .register(
          type: type,
          countryCode: countryCode,
          phone: phone,
          email: email,
          code: code,
          password: password,
          agreementAccepted: agreementAccepted,
          deviceId: deviceId,
          deviceType: deviceType,
        )
        .deserializeJsonBy(AuthResultData.fromJson)
        .guard;
    final data = parsed.data;
    if (parsed.status == 0 &&
        data != null &&
        data.tokens.accessToken.isNotEmpty &&
        data.tokens.refreshToken.isNotEmpty) {
      _updateToken(data.tokens.accessToken, data.tokens.refreshToken);
    }
    return parsed;
  }

  @override
  AsyncResult sendCode({
    required String channel,
    String? countryCode,
    String? phone,
    String? email,
    required String type,
  }) async {
    return _authService
        .sendCode(
          channel: channel,
          countryCode: countryCode,
          phone: phone,
          email: email,
          type: type,
        )
        .deserialize()
        .guard;
  }

  @override
  AsyncResult resetPassword({
    required String type,
    String? countryCode,
    String? phone,
    String? email,
    required String code,
    required String password,
  }) async {
    return _authService
        .resetPassword(
          type: type,
          countryCode: countryCode,
          phone: phone,
          email: email,
          code: code,
          password: password,
        )
        .deserialize()
        .guard;
  }

  @override
  AsyncResult<List<AuthCountryCode>> getCountryCodes() =>
      _authService.getCountryCodes().deserializeJsonBy(
        (json) {
          // deserializeJsonBy already passes response.data here.
          final list = json['list'] ??
              json['country_codes'] ??
              json['items'] ??
              (json['data'] is Map
                  ? ((json['data'] as Map)['list'] ??
                      (json['data'] as Map)['country_codes'] ??
                      (json['data'] as Map)['items'])
                  : json['data']);
          if (list is! List) return <AuthCountryCode>[];
          return list
              .whereType<Map>()
              .map((e) => AuthCountryCode.fromJson(Json.from(e)))
              .toList();
        },
      ).guard;
}
