import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/notifier/auth_notifier.dart';
import 'package:g_link/ui_layer/page/background_page.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:g_link/ui_layer/widgets/my_app_bar.dart';
import 'package:provider/provider.dart';

import 'common/common_webview_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  static const _termsUrl = 'https://api.zywsbgha.cc/terms';
  static const _privacyUrl = 'https://api.zywsbgha.cc/privacy';

  final _loginAccountController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _agreePolicy = true;
  bool _loginPwdVisible = false;

  @override
  void dispose() {
    _loginAccountController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
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
          onTap: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.w),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    padding: EdgeInsets.fromLTRB(16.w, 14.w, 16.w, 20.w),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(19, 20, 23, 0.7),
                      borderRadius: BorderRadius.all(Radius.circular(16.w)),
                      border: Border.all(
                        color: const Color.fromRGBO(34, 35, 40, 0.8),
                        width: 0.8.w,
                      ),
                    ),
                    child: _buildLoginForm(context),
                  ),
                  SizedBox(height: 18.w),
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'authNoAccount'.tr(),
                          style: TextStyle(
                            color: const Color(0xFFA6ADBC),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => const RegisterRoute().push(context),
                          child: Text(
                            'authGoRegister'.tr(),
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
                              height: 1, color: const Color(0xFF2E3443)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            'commonOr'.tr(),
                            style: TextStyle(
                                color: const Color(0xFFA6ADBC),
                                fontSize: 14.sp),
                          ),
                        ),
                        Expanded(
                          child: Container(
                              height: 1, color: const Color(0xFF2E3443)),
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
                        child: Image.asset(MyImagePaths.google,
                            width: 34.w, height: 34.w),
                      ),
                      SizedBox(width: 20.w),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _signInWithApple(context),
                        child: Image.asset(MyImagePaths.apple,
                            width: 34.w, height: 34.w),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Consumer<AuthNotifier>(
      builder: (context, notifier, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'authLoginButton'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34.sp * 0.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 22.w),
            _buildInputRow(
              hint: 'authPhoneOrEmailHint'.tr(),
              controller: _loginAccountController,
              leftIcon: MyImagePaths.appPhone,
            ),
            SizedBox(height: 12.w),
            _buildInputRow(
              hint: 'authPasswordSetHint'.tr(),
              controller: _loginPasswordController,
              obscureText: !_loginPwdVisible,
              leftIcon: MyImagePaths.lock,
              rightChild: GestureDetector(
                onTap: () =>
                    setState(() => _loginPwdVisible = !_loginPwdVisible),
                child: Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Image.asset(
                    _loginPwdVisible ? MyImagePaths.eye1 : MyImagePaths.eye2,
                    width: 18.w,
                    height: 18.w,
                    color: const Color(0xFF7A8291),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.w),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => const ForgotPasswordRoute().push(context),
                child: Text(
                  'authForgotPassword'.tr(),
                  style: TextStyle(
                    color: const Color(0xFFA6ADBC),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(height: 72.w),
            InkWell(
              onTap: () => setState(() => _agreePolicy = !_agreePolicy),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 1.w),
                    child: Image.asset(
                      _agreePolicy ? MyImagePaths.check : MyImagePaths.uncheck,
                      width: 18.w,
                      height: 18.w,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(child: _buildAgreementText()),
                ],
              ),
            ),
            if (notifier.errorMessage case final error?)
              Padding(
                padding: EdgeInsets.only(top: 10.w),
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
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
                onPressed:
                    notifier.loading ? null : () => _submitLogin(context),
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
                        'authLoginButton'.tr(),
                        style: TextStyle(
                          color: const Color(0xFF1E2028),
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputRow({
    required TextEditingController controller,
    required String hint,
    required String leftIcon,
    bool obscureText = false,
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

  Future<void> _submitLogin(BuildContext context) async {
    final account = _loginAccountController.text.trim();
    final password = _loginPasswordController.text.trim();
    if (account.isEmpty || password.isEmpty) {
      _toast(context, 'authFillRequired'.tr());
      return;
    }
    if (!_agreePolicy) {
      _toast(context, 'authAgreementRequired'.tr());
      return;
    }
    final success = await context.read<AuthNotifier>().login(
          account: account,
          password: password,
        );
    if (!context.mounted || !success) return;
    final requireOnboarding =
        context.read<AuthNotifier>().authData?.requireOnboarding ?? false;
    if (requireOnboarding) {
      const GuideRoute().go(context);
      return;
    }
    const HomeRoute().go(context);
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
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
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommonWebViewPage(title: title, url: url),
      ),
    );
  }
}
