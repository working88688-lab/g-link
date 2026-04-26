import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:g_link/domain/domains/auth.dart';
import 'package:g_link/domain/model/auth_models.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._authDomain,
      {required this.deviceId, required this.deviceType});

  final AuthDomain _authDomain;
  final String deviceId;
  final String deviceType;
  bool _disposed = false;

  bool loading = false;
  String? errorMessage;
  AuthResultData? authData;

  Future<bool> login({
    required String account,
    required String password,
  }) async {
    loading = true;
    errorMessage = null;
    _safeNotify();
    final result = await _authDomain.login(
      account: account,
      password: password,
      deviceId: deviceId,
      deviceType: deviceType,
    );
    loading = false;
    if (result.data case final data?) {
      authData = data;
      _safeNotify();
      return true;
    }
    errorMessage = result.msg ?? 'Login failed';
    _safeNotify();
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
    _safeNotify();
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
      _safeNotify();
      return true;
    }
    errorMessage = result.msg ?? 'Register failed';
    _safeNotify();
    return false;
  }

  Future<bool> sendRegisterCode({
    required String channel,
    String? countryCode,
    String? account,
  }) async {
    final normalizedChannel = channel == 'phone' ? 'sms' : channel;
    final result = await _authDomain.sendCode(
      channel: normalizedChannel,
      countryCode: countryCode,
      phone: normalizedChannel == 'sms' ? account : null,
      email: normalizedChannel == 'email' ? account : null,
      type: 'register',
    );
    if (result.status == 0) {
      return true;
    }
    errorMessage = result.msg ?? 'Send code failed';
    _safeNotify();
    return false;
  }

  Future<bool> sendResetCode({
    required String account,
  }) async {
    final isEmail = account.contains('@');
    final phoneInput = _parsePhoneInput(account);
    if (!isEmail && phoneInput == null) {
      errorMessage = 'authPhoneFormatInvalid'.tr();
      _safeNotify();
      return false;
    }
    final result = await _authDomain.sendCode(
      channel: isEmail ? 'email' : 'sms',
      countryCode: isEmail ? null : phoneInput!.countryCode,
      phone: isEmail ? null : phoneInput!.phone,
      email: isEmail ? account : null,
      type: 'reset_password',
    );
    if (result.status == 0) {
      return true;
    }
    errorMessage = result.msg ?? 'Send code failed';
    _safeNotify();
    return false;
  }

  Future<bool> resetPassword({
    required String account,
    required String code,
    required String password,
  }) async {
    loading = true;
    errorMessage = null;
    _safeNotify();
    final isEmail = account.contains('@');
    final phoneInput = _parsePhoneInput(account);
    if (!isEmail && phoneInput == null) {
      loading = false;
      errorMessage = 'authPhoneFormatInvalid'.tr();
      _safeNotify();
      return false;
    }
    final result = await _authDomain.resetPassword(
      type: isEmail ? 'email' : 'phone',
      countryCode: isEmail ? null : phoneInput!.countryCode,
      phone: isEmail ? null : phoneInput!.phone,
      email: isEmail ? account : null,
      code: code,
      password: password,
    );
    loading = false;
    if (result.status == 0) {
      _safeNotify();
      return true;
    }
    errorMessage = result.msg ?? 'Reset password failed';
    _safeNotify();
    return false;
  }

  ({String countryCode, String phone})? _parsePhoneInput(String raw) {
    final value = raw.trim().replaceAll(RegExp(r'[\s-]'), '');
    final plusReg = RegExp(r'^\+(\d{1,4})(\d{4,15})$');
    final plusMatch = plusReg.firstMatch(value);
    if (plusMatch != null) {
      return (
        countryCode: plusMatch.group(1) ?? '86',
        phone: plusMatch.group(2) ?? value,
      );
    }
    final localReg = RegExp(r'^\d{4,15}$');
    if (localReg.hasMatch(value)) {
      return (countryCode: '86', phone: value);
    }
    return null;
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
