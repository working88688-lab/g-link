part of '../repo.dart';

mixin _Auth on _BaseAppRepo implements AuthDomain {
  @override
  AsyncResult<AuthResultData> login({
    required String account,
    required String password,
    required String deviceId,
    required String deviceType,
  }) async {
    final parsed = await _authService
        .login(
          account: account,
          password: password,
          deviceId: deviceId,
          deviceType: deviceType,
        )
        .deserializeJsonBy(AuthResultData.fromJson)
        .guard;
    if (parsed.data case final data?) {
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
    if (parsed.data case final data?) {
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
}
