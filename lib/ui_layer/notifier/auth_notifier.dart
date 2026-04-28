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
  List<AuthCountryCode> countryCodes = const [];

  Future<bool> login({
    required String account,
    String? countryCode,
    required String password,
  }) async {
    loading = true;
    errorMessage = null;
    _safeNotify();
    final isEmail = account.contains('@');
    final phone = isEmail ? null : account.trim();
    final result = await _authDomain.login(
      type: isEmail ? 'email' : 'phone',
      account: account,
      countryCode: isEmail ? null : countryCode,
      phone: phone,
      email: isEmail ? account : null,
      password: password,
      deviceId: deviceId,
      deviceType: deviceType,
    );
    loading = false;
    final data = result.data;
    if (result.status == 0 &&
        data != null &&
        data.tokens.accessToken.isNotEmpty &&
        data.tokens.refreshToken.isNotEmpty) {
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
    final data = result.data;
    if (result.status == 0 &&
        data != null &&
        data.tokens.accessToken.isNotEmpty &&
        data.tokens.refreshToken.isNotEmpty) {
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
    String? countryCode,
  }) async {
    final isEmail = account.contains('@');
    final phone = account.trim();
    final localReg = RegExp(r'^\d{4,15}$');
    if (!isEmail && !localReg.hasMatch(phone)) {
      errorMessage = 'authPhoneFormatInvalid'.tr();
      _safeNotify();
      return false;
    }
    final result = await _authDomain.sendCode(
      channel: isEmail ? 'email' : 'sms',
      countryCode: isEmail ? null : countryCode,
      phone: isEmail ? null : phone,
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
    String? countryCode,
  }) async {
    loading = true;
    errorMessage = null;
    _safeNotify();
    final isEmail = account.contains('@');
    final phone = account.trim();
    final localReg = RegExp(r'^\d{4,15}$');
    if (!isEmail && !localReg.hasMatch(phone)) {
      loading = false;
      errorMessage = 'authPhoneFormatInvalid'.tr();
      _safeNotify();
      return false;
    }
    final result = await _authDomain.resetPassword(
      type: isEmail ? 'email' : 'phone',
      countryCode: isEmail ? null : countryCode,
      phone: isEmail ? null : phone,
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

  Future<void> fetchCountryCodes() async {
    final result = await _authDomain.getCountryCodes();
    if (result.status == 0 && result.data != null && result.data!.isNotEmpty) {
      countryCodes = result.data!;
      final preview = countryCodes
          .take(5)
          .map((e) =>
              '${e.flagEmoji.isNotEmpty ? "${e.flagEmoji} " : ""}${e.display}/${e.request}/${e.name}${e.iso2.isNotEmpty ? "/${e.iso2}" : ""}')
          .join(', ');
      debugPrint(
        '[CountryCodes] loaded ${countryCodes.length} items: $preview',
      );
      _safeNotify();
      return;
    }
    debugPrint(
      '[CountryCodes] load failed status=${result.status} msg=${result.msg}',
    );
    if (countryCodes.isEmpty) {
      countryCodes = const [
        AuthCountryCode(display: '+01', request: '1', name: 'US/Canada'),
        AuthCountryCode(display: '+86', request: '86', name: 'China'),
      ];
      debugPrint(
          '[CountryCodes] fallback to local defaults: ${countryCodes.length}');
      _safeNotify();
    }
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
