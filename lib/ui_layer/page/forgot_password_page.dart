import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domain.dart';
import 'package:g_link/domain/model/auth_models.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/notifier/auth_notifier.dart';
import 'package:g_link/ui_layer/page/background_page.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/widgets/my_app_bar.dart';
import 'package:provider/provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _accountController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _pwdVisible = false;
  bool _confirmVisible = false;
  String? _confirmError;
  int _codeCountdown = 0;
  Timer? _codeTimer;
  bool _countryCodesLoaded = false;
  int _selectedCountryCodeIndex = 0;
  String? _cachedCountryCodeRequest;

  @override
  void dispose() {
    _codeTimer?.cancel();
    _accountController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_countryCodesLoaded) return;
    _countryCodesLoaded = true;
    _initCountryCodes();
  }

  Future<void> _initCountryCodes() async {
    final appDomain = context.read<AppDomain>();
    final savedCode = await appDomain.cache.readAuthPhoneCountryCode();
    if (mounted && savedCode != null && savedCode.isNotEmpty) {
      setState(() => _cachedCountryCodeRequest = savedCode);
    }
    final notifier = context.read<AuthNotifier>();
    await notifier.fetchCountryCodes();
    if (!mounted) return;
    if (!mounted || savedCode == null || savedCode.isEmpty) return;
    final idx = notifier.countryCodes.indexWhere((e) => e.request == savedCode);
    if (idx >= 0 && idx != _selectedCountryCodeIndex) {
      setState(() => _selectedCountryCodeIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundPage(
      androidStatusBarIcon: Brightness.light,
      iosStatusBarIcon: Brightness.dark,
      systemNavigationBarColor: const Color.fromRGBO(3, 7, 21, 1),
      backgroundGradient: const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color.fromRGBO(8, 37, 57, 1),
          Color.fromRGBO(17, 29, 38, 1),
          Color.fromRGBO(1, 1, 10, 1),
          Color.fromRGBO(3, 7, 21, 1),
        ],
      ),
      appBar: MyAppBar(
        leftWidget: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: EdgeInsets.only(left: 5.w, top: 3.w),
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(45, 45, 45, 0.6),
              borderRadius: BorderRadius.all(Radius.circular(30.w)),
            ),
            child: Image.asset(
              MyImagePaths.appBackIcon,
              width: 14.w,
              height: 14.w,
            ),
          ),
        ),
      ),
      body: Consumer<AuthNotifier>(
        builder: (context, notifier, _) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.w),
                Text(
                  'authResetPasswordTitle'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36.sp * 0.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 26.w),
                _buildInputRow(
                  controller: _accountController,
                  hint: 'authPhoneOrEmailHint'.tr(),
                  leftIcon: MyImagePaths.appPhone,
                  rightChild: _buildCountryCodePicker(context),
                ),
                SizedBox(height: 12.w),
                _buildInputRow(
                  controller: _codeController,
                  hint: 'authCodeInputHint'.tr(),
                  leftIcon: MyImagePaths.lock,
                  keyboardType: TextInputType.number,
                  rightChild: GestureDetector(
                    onTap: (notifier.loading || _codeCountdown > 0)
                        ? null
                        : () => _sendCode(context),
                    child: Padding(
                      padding: EdgeInsets.only(right: 14.w),
                      child: Row(
                        children: [
                          Container(
                            width: 1.w,
                            height: 22.w,
                            color: const Color(0xFF32384A),
                            margin: EdgeInsets.only(right: 12.w),
                          ),
                          Text(
                            _codeCountdown > 0
                                ? 'authCodeCountdown'
                                    .tr(args: ['$_codeCountdown'])
                                : 'authGetCode'.tr(),
                            style: TextStyle(
                              color: (_codeCountdown > 0 || notifier.loading)
                                  ? const Color(0xFF8E96A8)
                                  : Colors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.w),
                _buildInputRow(
                  controller: _passwordController,
                  hint: 'authResetNewPasswordHint'.tr(),
                  leftIcon: MyImagePaths.lock,
                  obscureText: !_pwdVisible,
                  rightChild: GestureDetector(
                    onTap: () => setState(() => _pwdVisible = !_pwdVisible),
                    child: Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: Image.asset(
                        _pwdVisible ? MyImagePaths.eye1 : MyImagePaths.eye2,
                        width: 18.w,
                        height: 18.w,
                        color: const Color(0xFF7A8291),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.w),
                _buildInputRow(
                  controller: _confirmController,
                  hint: 'authResetConfirmPasswordHint'.tr(),
                  leftIcon: MyImagePaths.lock,
                  obscureText: !_confirmVisible,
                  borderColor: _confirmError != null
                      ? const Color(0xFFFF2D78)
                      : Colors.transparent,
                  rightChild: GestureDetector(
                    onTap: () =>
                        setState(() => _confirmVisible = !_confirmVisible),
                    child: Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: Image.asset(
                        _confirmVisible ? MyImagePaths.eye1 : MyImagePaths.eye2,
                        width: 18.w,
                        height: 18.w,
                        color: const Color(0xFF7A8291),
                      ),
                    ),
                  ),
                ),
                if (_confirmError != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8.w, left: 8.w),
                    child: Text(
                      _confirmError!,
                      style: TextStyle(
                        color: const Color(0xFFFF2D78),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52.w,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26.w),
                      ),
                    ),
                    onPressed: notifier.loading ? null : () => _submit(context),
                    child: notifier.loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1E2028),
                            ),
                          )
                        : Text(
                            'commonConfirm'.tr(),
                            style: TextStyle(
                              color: const Color(0xFF1E2028),
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 18.w),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputRow({
    required TextEditingController controller,
    required String hint,
    required String leftIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? rightChild,
    Color borderColor = Colors.transparent,
  }) {
    return Container(
      height: 52.w,
      decoration: BoxDecoration(
        color: const Color(0xFF1D2230),
        borderRadius: BorderRadius.circular(26.w),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16.w, right: 8.w),
            child: Image.asset(
              leftIcon,
              width: 18.w,
              height: 18.w,
              color: const Color(0xFF747C8B),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: TextStyle(color: Colors.white, fontSize: 15.sp),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    TextStyle(color: const Color(0xFF666E7E), fontSize: 15.sp),
                border: InputBorder.none,
              ),
            ),
          ),
          if (rightChild != null) rightChild,
        ],
      ),
    );
  }

  Future<void> _sendCode(BuildContext context) async {
    if (_codeCountdown > 0) return;
    final account = _accountController.text.trim();
    if (account.isEmpty) {
      _toast(context, 'authAccountBeforeCode'.tr());
      return;
    }
    _startCodeCountdown();
    final success = await context.read<AuthNotifier>().sendResetCode(
          account: account,
          countryCode: account.contains('@')
              ? null
              : _selectedCountryCode(context).request,
        );
    if (!context.mounted) return;
    if (!success) {
      _resetCodeCountdown();
    }
    final error = context.read<AuthNotifier>().errorMessage;
    _toast(
      context,
      success ? 'authCodeSent'.tr() : (error ?? 'authCodeSendFailed'.tr()),
    );
  }

  void _startCodeCountdown() {
    _codeTimer?.cancel();
    setState(() => _codeCountdown = 60);
    _codeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_codeCountdown <= 1) {
        timer.cancel();
        setState(() => _codeCountdown = 0);
        return;
      }
      setState(() => _codeCountdown -= 1);
    });
  }

  void _resetCodeCountdown() {
    _codeTimer?.cancel();
    if (mounted) setState(() => _codeCountdown = 0);
  }

  Future<void> _submit(BuildContext context) async {
    final account = _accountController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();
    if (account.isEmpty ||
        code.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      _toast(context, 'authFillRequired'.tr());
      return;
    }
    if (password != confirm) {
      setState(() => _confirmError = 'authPasswordMismatch'.tr());
      return;
    }
    setState(() => _confirmError = null);
    final success = await context.read<AuthNotifier>().resetPassword(
          account: account,
          code: code,
          password: password,
          countryCode: account.contains('@')
              ? null
              : _selectedCountryCode(context).request,
        );
    if (!context.mounted || !success) return;
    _toast(context, 'authResetSuccess'.tr());
    const LoginRoute().go(context);
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildCountryCodePicker(BuildContext context) {
    return Consumer<AuthNotifier>(
      builder: (context, notifier, _) {
        final item = _selectedCountryCode(context);
        return Row(
          children: [
            Container(width: 1.w, height: 22.w, color: const Color(0xFF32384A)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Text(
                item.display,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () =>
                  _showCountryCodeSelector(context, notifier.countryCodes),
              behavior: HitTestBehavior.opaque,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 18.w,
              ),
            ),
            SizedBox(width: 10.w),
          ],
        );
      },
    );
  }

  AuthCountryCode _selectedCountryCode(BuildContext context) {
    final list = context.read<AuthNotifier>().countryCodes;
    if (list.isEmpty) {
      final request = _cachedCountryCodeRequest?.trim();
      if (request != null && request.isNotEmpty) {
        return AuthCountryCode(
          display: '+$request',
          request: request,
          name: '',
        );
      }
      return const AuthCountryCode(
          display: '+01', request: '1', name: 'US/Canada');
    }
    final index = _selectedCountryCodeIndex.clamp(0, list.length - 1);
    return list[index];
  }

  Future<void> _showCountryCodeSelector(
    BuildContext context,
    List<AuthCountryCode> list,
  ) async {
    if (list.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF151A24),
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: list.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFF2E3443)),
            itemBuilder: (_, index) {
              final item = list[index];
              final selected = index == _selectedCountryCodeIndex;
              return ListTile(
                leading: item.flagEmoji.isNotEmpty
                    ? Text(item.flagEmoji, style: TextStyle(fontSize: 20.sp))
                    : null,
                title: Text(
                  '${item.display}  ${item.name}',
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFFA6ADBC),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
                onTap: () {
                  setState(() => _selectedCountryCodeIndex = index);
                  Navigator.of(sheetContext).pop();
                },
              );
            },
          ),
        );
      },
    );
  }
}
