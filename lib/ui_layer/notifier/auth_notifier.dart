import 'package:flutter/foundation.dart';
import 'package:g_link/domain/domains/auth.dart';
import 'package:g_link/domain/model/auth_models.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._authDomain,
      {required this.deviceId, required this.deviceType});

  final AuthDomain _authDomain;
  final String deviceId;
  final String deviceType;

  bool loading = false;
  String? errorMessage;
  AuthResultData? authData;

  Future<bool> login({
    required String account,
    required String password,
  }) async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    final result = await _authDomain.login(
      account: account,
      password: password,
      deviceId: deviceId,
      deviceType: deviceType,
    );
    loading = false;
    if (result.data case final data?) {
      authData = data;
      notifyListeners();
      return true;
    }
    errorMessage = result.msg ?? 'Login failed';
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String type,
    String? account,
    String? countryCode,
    String? phone,
    String? email,
    required String code,
    required String password,
    required bool agreementAccepted,
  }) async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    final registerPhone = type == 'phone' ? (phone ?? account ?? '') : null;
    final registerEmail = type == 'email' ? (email ?? account ?? '') : null;
    final result = await _authDomain.register(
      type: type,
      countryCode: countryCode,
      phone: registerPhone,
      email: registerEmail,
      code: code,
      password: password,
      agreementAccepted: agreementAccepted,
      deviceId: deviceId,
      deviceType: deviceType,
    );
    loading = false;
    if (result.data case final data?) {
      authData = data;
      notifyListeners();
      return true;
    }
    errorMessage = result.msg ?? 'Register failed';
    notifyListeners();
    return false;
  }

  Future<bool> sendRegisterCode({
    required String channel,
    String? countryCode,
    String? account,
  }) async {
    final result = await _authDomain.sendCode(
      channel: channel,
      countryCode: countryCode,
      phone: channel == 'phone' ? account : null,
      email: channel == 'email' ? account : null,
      type: 'register',
    );
    if (result.status == 0) {
      return true;
    }
    errorMessage = result.msg ?? 'Send code failed';
    notifyListeners();
    return false;
  }
}
