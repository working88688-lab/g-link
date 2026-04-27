import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domain.dart';
import 'package:g_link/domain/domains/auth.dart';
import 'package:g_link/domain/model/auth_models.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/notifier/auth_notifier.dart';
// import 'package:g_link/ui_layer/page/common/common_webview_page.dart';
import 'package:g_link/ui_layer/page/background_page.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:g_link/ui_layer/widgets/my_app_bar.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const _termsUrl = 'https://api.zywsbgha.cc/terms';
  static const _privacyUrl = 'https://api.zywsbgha.cc/privacy';
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneCodeController = TextEditingController();
  final _emailCodeController = TextEditingController();
  final _phonePasswordController = TextEditingController();
  final _emailPasswordController = TextEditingController();
  final _phoneConfirmPasswordController = TextEditingController();
  final _emailConfirmPasswordController = TextEditingController();
  bool _agreePolicy = true;
  bool _emailPwdVisible = false;
  bool _emailConfirmPwdVisible = false;
  int _selectedCountryCodeIndex = 0;
  String? _cachedCountryCodeRequest;
  int _phoneCodeCountdown = 0;
  int _emailCodeCountdown = 0;
  Timer? _phoneCodeTimer;
  Timer? _emailCodeTimer;
  bool _countryCodesLoaded = false;

  @override
  void dispose() {
    _phoneCodeTimer?.cancel();
    _emailCodeTimer?.cancel();
    _phoneController.dispose();
    _emailController.dispose();
    _phoneCodeController.dispose();
    _emailCodeController.dispose();
    _phonePasswordController.dispose();
    _emailPasswordController.dispose();
    _phoneConfirmPasswordController.dispose();
    _emailConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authDomain = context.read<AuthDomain>();
    final appDomain = context.read<AppDomain>();
    return ChangeNotifierProvider(
      create: (_) => AuthNotifier(
        authDomain,
        deviceId: '${appDomain.info['oauth_id'] ?? ''}',
        deviceType: '${appDomain.info['oauth_type'] ?? 'ios'}',
      ),
      child: Builder(
        builder: (innerContext) {
          if (!_countryCodesLoaded) {
            _countryCodesLoaded = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _initCountryCodes(innerContext);
            });
          }
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
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
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
            body: DefaultTabController(
              length: 2,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20.w),
                          Image.asset(
                            MyImagePaths.joinGlink,
                            width: 262.w,
                            height: 33.4.w,
                          ),
                          SizedBox(height: 6.w),
                          Padding(
                            padding: EdgeInsets.only(left: 28.w),
                            child: Text(
                              'registerWorldTip'.tr(),
                              style: MyTheme.white04_12.copyWith(
                                color: const Color.fromRGBO(255, 255, 255, 1),
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                          SizedBox(height: 20.w),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 28.w),
                            padding:
                                EdgeInsets.fromLTRB(16.w, 14.w, 16.w, 16.w),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(19, 20, 23, 0.7),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12.w)),
                              border: Border.all(
                                color: const Color.fromRGBO(34, 35, 40, 0.8),
                                width: 0.8.w,
                              ),
                            ),
                            child: Column(
                              children: [
                                TabBar(
                                  indicatorColor: Colors.white,
                                  indicatorWeight: 3,
                                  labelColor: Colors.white,
                                  unselectedLabelColor: const Color(0xFF8E96A8),
                                  labelStyle: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600),
                                  indicatorSize: TabBarIndicatorSize.label,
                                  tabs: [
                                    Tab(text: 'phoneRegister'.tr()),
                                    Tab(text: 'emailRegister'.tr()),
                                  ],
                                ),
                                SizedBox(height: 16.w),
                                SizedBox(
                                  height: 370.w,
                                  child: TabBarView(
                                    children: [
                                      _buildRegisterForm(isEmail: false),
                                      _buildRegisterForm(isEmail: true),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 18.w),
                          Center(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'authAlreadyHaveAccount'.tr(),
                                  style: TextStyle(
                                    color: const Color(0xFFA6ADBC),
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => const LoginRoute().go(context),
                                  child: Text(
                                    'authGoLogin'.tr(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12.w),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 28.w),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                      height: 1,
                                      color: const Color(0xFF2E3443)),
                                ),
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.w),
                                  child: Text(
                                    'commonOr'.tr(),
                                    style: TextStyle(
                                        color: const Color(0xFFA6ADBC),
                                        fontSize: 14.sp),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                      height: 1,
                                      color: const Color(0xFF2E3443)),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.w),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _signInWithGoogle(context),
                                child: Image.asset(
                                  MyImagePaths.google,
                                  width: 34.w,
                                  height: 34.w,
                                ),
                              ),
                              SizedBox(width: 20.w),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _signInWithApple(context),
                                child: Image.asset(
                                  MyImagePaths.apple,
                                  width: 34.w,
                                  height: 34.w,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRegisterForm({required bool isEmail}) {
    if (!isEmail) {
      return _buildPhoneRegisterForm();
    }
    return _buildEmailRegisterForm();
  }

  Widget _buildPhoneRegisterForm() {
    final accountController = _phoneController;
    final codeController = _phoneCodeController;
    final passwordController = _phonePasswordController;
    return Consumer<AuthNotifier>(
      builder: (context, notifier, child) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputField(
                label: '',
                hint: 'authPhoneHint'.tr(),
                controller: accountController,
                keyboardType: TextInputType.phone,
                leftIcon: MyImagePaths.appPhone,
                rightChild: Row(
                  children: [
                    Container(
                        width: 1.w,
                        height: 22.w,
                        color: const Color(0xFF32384A)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: Text(
                        _selectedCountryCode(context).display,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showCountryCodeSelector(context),
                      behavior: HitTestBehavior.opaque,
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white, size: 18.w),
                    ),
                    SizedBox(width: 10.w),
                  ],
                ),
              ),
              SizedBox(height: 12.w),
              _buildInputField(
                label: '',
                hint: 'authCodeInputHint'.tr(),
                controller: codeController,
                keyboardType: TextInputType.number,
                leftIcon: MyImagePaths.lock,
                rightChild: _buildCodeButton(
                  notifier: notifier,
                  countdown: _phoneCodeCountdown,
                  onTap: () => _sendCode(
                    context,
                    isEmail: false,
                    account: accountController.text.trim(),
                  ),
                ),
              ),
              SizedBox(height: 12.w),
              _buildInputField(
                label: '',
                hint: 'authPasswordSetHint'.tr(),
                controller: passwordController,
                obscureText: true,
                leftIcon: MyImagePaths.lock,
                rightChild: Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Image.asset(
                    MyImagePaths.eye1,
                    width: 18.w,
                    height: 18.w,
                    color: const Color(0xFF7A8291),
                  ),
                ),
              ),
              SizedBox(height: 12.w),
              _buildInputField(
                label: '',
                hint: 'authConfirmPasswordHint'.tr(),
                controller: _phoneConfirmPasswordController,
                obscureText: true,
                leftIcon: MyImagePaths.lock,
                rightChild: Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Image.asset(
                    MyImagePaths.eye2,
                    width: 18.w,
                    height: 18.w,
                    color: const Color(0xFF7A8291),
                  ),
                ),
              ),
              SizedBox(height: 12.w),
              InkWell(
                onTap: () => setState(() => _agreePolicy = !_agreePolicy),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 2.w),
                      child: Image.asset(
                        _agreePolicy
                            ? MyImagePaths.check
                            : MyImagePaths.uncheck,
                        width: 18.w,
                        height: 18.w,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: _buildAgreementText(),
                    ),
                  ],
                ),
              ),
              if (notifier.errorMessage case final error?)
                Padding(
                  padding: EdgeInsets.only(top: 10.w),
                  child: Text(
                    error,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              SizedBox(height: 16.w),
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
                  onPressed: notifier.loading
                      ? null
                      : () => _submitRegister(
                            context,
                            isEmail: false,
                            account: accountController.text.trim(),
                            code: codeController.text.trim(),
                            password: passwordController.text.trim(),
                            confirmPassword:
                                _phoneConfirmPasswordController.text.trim(),
                          ),
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
                          'authRegisterButton'.tr(),
                          style: TextStyle(
                            color: const Color(0xFF1E2028),
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmailRegisterForm() {
    final accountController = _emailController;
    final codeController = _emailCodeController;
    final passwordController = _emailPasswordController;
    final confirmPasswordController = _emailConfirmPasswordController;
    return Consumer<AuthNotifier>(
      builder: (context, notifier, child) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPillInput(
                leading: Image.asset(
                  MyImagePaths.lock,
                  width: 18.w,
                  height: 18.w,
                  color: const Color(0xFF747C8B),
                ),
                hint: 'authEmailHint'.tr(),
                controller: accountController,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 12.w),
              _buildPillInput(
                leading: Image.asset(
                  MyImagePaths.lock,
                  width: 18.w,
                  height: 18.w,
                  color: const Color(0xFF747C8B),
                ),
                hint: 'authCodeInputHint'.tr(),
                controller: codeController,
                keyboardType: TextInputType.number,
                rightChild: _buildCodeButton(
                  notifier: notifier,
                  countdown: _emailCodeCountdown,
                  onTap: () => _sendCode(
                    context,
                    isEmail: true,
                    account: accountController.text.trim(),
                  ),
                ),
              ),
              SizedBox(height: 12.w),
              _buildPillInput(
                leading: Image.asset(
                  MyImagePaths.lock,
                  width: 18.w,
                  height: 18.w,
                  color: const Color(0xFF747C8B),
                ),
                hint: 'authPasswordSetHint'.tr(),
                controller: passwordController,
                obscureText: !_emailPwdVisible,
                rightChild: GestureDetector(
                  onTap: () {
                    setState(() {
                      _emailPwdVisible = !_emailPwdVisible;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: Image.asset(
                      _emailPwdVisible ? MyImagePaths.eye1 : MyImagePaths.eye2,
                      width: 18.w,
                      height: 18.w,
                      color: const Color(0xFF7A8291),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.w),
              _buildPillInput(
                leading: Image.asset(
                  MyImagePaths.lock,
                  width: 18.w,
                  height: 18.w,
                  color: const Color(0xFF747C8B),
                ),
                hint: 'authConfirmPasswordHint'.tr(),
                controller: confirmPasswordController,
                obscureText: !_emailConfirmPwdVisible,
                rightChild: GestureDetector(
                  onTap: () {
                    setState(() {
                      _emailConfirmPwdVisible = !_emailConfirmPwdVisible;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: Image.asset(
                      _emailConfirmPwdVisible
                          ? MyImagePaths.eye1
                          : MyImagePaths.eye2,
                      width: 18.w,
                      height: 18.w,
                      color: const Color(0xFF7A8291),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.w),
              InkWell(
                onTap: () => setState(() => _agreePolicy = !_agreePolicy),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 1.w),
                      child: Image.asset(
                        _agreePolicy
                            ? MyImagePaths.check
                            : MyImagePaths.uncheck,
                        width: 18.w,
                        height: 18.w,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _buildAgreementText(),
                    ),
                  ],
                ),
              ),
              if (notifier.errorMessage case final error?)
                Padding(
                  padding: EdgeInsets.only(top: 10.w),
                  child: Text(
                    error,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              SizedBox(height: 16.w),
              SizedBox(
                width: double.infinity,
                height: 52.w,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26.w)),
                  ),
                  onPressed: notifier.loading
                      ? null
                      : () => _submitRegister(
                            context,
                            isEmail: true,
                            account: accountController.text.trim(),
                            code: codeController.text.trim(),
                            password: passwordController.text.trim(),
                            confirmPassword:
                                confirmPasswordController.text.trim(),
                          ),
                  child: notifier.loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'authRegisterButton'.tr(),
                          style: TextStyle(
                            color: const Color(0xFF1E2028),
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPillInput({
    required Widget leading,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? rightChild,
  }) {
    return Container(
      height: 52.w,
      decoration: BoxDecoration(
        color: const Color(0xFF1D2230),
        borderRadius: BorderRadius.circular(26.w),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16.w, right: 8.w),
            child: leading,
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

  Widget _buildCodeButton({
    required AuthNotifier notifier,
    required int countdown,
    required VoidCallback onTap,
  }) {
    final disabled = notifier.loading || countdown > 0;
    return GestureDetector(
      onTap: disabled ? null : onTap,
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
              countdown > 0
                  ? 'authCodeCountdown'.tr(args: ['$countdown'])
                  : 'authGetCode'.tr(),
              style: TextStyle(
                color: disabled ? const Color(0xFF8E96A8) : Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? leftIcon,
    Widget? rightChild,
  }) {
    return Container(
      height: 52.w,
      decoration: BoxDecoration(
        color: const Color(0xFF1D2230),
        borderRadius: BorderRadius.circular(26.w),
      ),
      child: Row(
        children: [
          if (leftIcon != null)
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

  Future<void> _sendCode(
    BuildContext context, {
    required bool isEmail,
    required String account,
  }) async {
    if ((isEmail ? _emailCodeCountdown : _phoneCodeCountdown) > 0) {
      return;
    }
    if (account.isEmpty) {
      _toast(context, 'authAccountBeforeCode'.tr());
      return;
    }
    _startCodeCountdown(isEmail: isEmail);
    final success = await context.read<AuthNotifier>().sendRegisterCode(
          channel: isEmail ? 'email' : 'sms',
          countryCode: isEmail ? null : _phoneCountryCodeRequest(context),
          account: account,
        );
    if (!context.mounted) return;
    if (!success) {
      _resetCodeCountdown(isEmail: isEmail);
    }
    _toast(context, success ? 'authCodeSent'.tr() : 'authCodeSendFailed'.tr());
  }

  void _startCodeCountdown({required bool isEmail}) {
    if (isEmail) {
      _emailCodeTimer?.cancel();
      setState(() => _emailCodeCountdown = 60);
      _emailCodeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_emailCodeCountdown <= 1) {
          timer.cancel();
          setState(() => _emailCodeCountdown = 0);
          return;
        }
        setState(() => _emailCodeCountdown -= 1);
      });
      return;
    }
    _phoneCodeTimer?.cancel();
    setState(() => _phoneCodeCountdown = 60);
    _phoneCodeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_phoneCodeCountdown <= 1) {
        timer.cancel();
        setState(() => _phoneCodeCountdown = 0);
        return;
      }
      setState(() => _phoneCodeCountdown -= 1);
    });
  }

  void _resetCodeCountdown({required bool isEmail}) {
    if (isEmail) {
      _emailCodeTimer?.cancel();
      if (mounted) setState(() => _emailCodeCountdown = 0);
      return;
    }
    _phoneCodeTimer?.cancel();
    if (mounted) setState(() => _phoneCodeCountdown = 0);
  }

  Future<void> _submitRegister(
    BuildContext context, {
    required bool isEmail,
    required String account,
    required String code,
    required String password,
    required String confirmPassword,
  }) async {
    if (account.isEmpty || code.isEmpty || password.isEmpty) {
      _toast(context, 'authFillRequired'.tr());
      return;
    }
    if (isEmail && confirmPassword.isEmpty) {
      _toast(context, 'authConfirmPasswordRequired'.tr());
      return;
    }
    if (isEmail && password != confirmPassword) {
      _toast(context, 'authPasswordMismatch'.tr());
      return;
    }
    if (!_agreePolicy) {
      _toast(context, 'authAgreementRequired'.tr());
      return;
    }
    final authNotifier = context.read<AuthNotifier>();
    final appDomain = context.read<AppDomain>();
    final selectedCountryCode = _phoneCountryCodeRequest(context);
    final success = await authNotifier.register(
      type: isEmail ? 'email' : 'phone',
      account: account,
      countryCode: isEmail ? null : selectedCountryCode,
      code: code,
      password: password,
      agreementAccepted: _agreePolicy,
    );
    if (!context.mounted || !success) return;
    if (!isEmail) {
      await appDomain.cache.upsertAuthPhoneCountryCode(selectedCountryCode);
      if (!context.mounted) return;
    }
    final requireOnboarding = authNotifier.authData?.requireOnboarding ?? false;
    if (requireOnboarding) {
      const GuideRoute().go(context);
      return;
    }
    const HomeRoute().go(context);
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    // Placeholder account for future Google OAuth integration.
    const fakeGoogleAccount = {
      'provider': 'google',
      'uid': 'google_demo_10001',
      'email': 'demo.google@g-link.test',
      'displayName': 'Google Demo User',
    };
    _toast(context,
        'authGooglePlaceholder'.tr(args: ['${fakeGoogleAccount['email']}']));
  }

  Future<void> _signInWithApple(BuildContext context) async {
    // Placeholder account for future Apple Sign-In integration.
    const fakeAppleAccount = {
      'provider': 'apple',
      'uid': 'apple_demo_10002',
      'email': 'demo.apple@g-link.test',
      'displayName': 'Apple Demo User',
    };
    _toast(context,
        'authApplePlaceholder'.tr(args: ['${fakeAppleAccount['email']}']));
  }

  Widget _buildAgreementText() {
    final normalStyle = MyTheme.white04_12.copyWith(
      color: const Color(0xFF8E96A8),
      height: 1.3,
    );
    final linkStyle = normalStyle.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );
    return Wrap(
      spacing: 2.w,
      runSpacing: 2.w,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('authAgreementPrefix'.tr(), style: normalStyle),
        GestureDetector(
          onTap: () => _openAgreementWebView(
            title: 'authUserAgreementTitle'.tr(),
            url: _termsUrl,
          ),
          child: Text('authUserAgreement'.tr(), style: linkStyle),
        ),
        Text('authAgreementAnd'.tr(), style: normalStyle),
        GestureDetector(
          onTap: () => _openAgreementWebView(
            title: 'authPrivacyPolicyTitle'.tr(),
            url: _privacyUrl,
          ),
          child: Text('authPrivacyPolicy'.tr(), style: linkStyle),
        ),
      ],
    );
  }

  Future<void> _openAgreementWebView({
    required String title,
    required String url,
  }) async {
    // await Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (_) => CommonWebViewPage(title: title, url: url),
    //   ),
    // );
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

  String _phoneCountryCodeRequest(BuildContext context) =>
      _selectedCountryCode(context).request;

  Future<void> _showCountryCodeSelector(BuildContext providerContext) async {
    await showModalBottomSheet<void>(
      context: providerContext,
      backgroundColor: const Color(0xFF151A24),
      showDragHandle: true,
      builder: (sheetContext) {
        final countryCodes = providerContext.read<AuthNotifier>().countryCodes;
        if (countryCodes.isEmpty) {
          return const SizedBox.shrink();
        }
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: countryCodes.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFF2E3443)),
            itemBuilder: (_, index) {
              final item = countryCodes[index];
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
                  setState(() {
                    _selectedCountryCodeIndex = index;
                  });
                  Navigator.of(sheetContext).pop();
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _initCountryCodes(BuildContext innerContext) async {
    final appDomain = context.read<AppDomain>();
    final savedCode = await appDomain.cache.readAuthPhoneCountryCode();
    if (mounted && savedCode != null && savedCode.isNotEmpty) {
      setState(() => _cachedCountryCodeRequest = savedCode);
    }
    final notifier = innerContext.read<AuthNotifier>();
    await notifier.fetchCountryCodes();
    if (!mounted) return;
    if (!mounted || savedCode == null || savedCode.isEmpty) return;
    final idx = notifier.countryCodes.indexWhere((e) => e.request == savedCode);
    if (idx >= 0 && idx != _selectedCountryCodeIndex) {
      setState(() => _selectedCountryCodeIndex = idx);
    }
  }
}
