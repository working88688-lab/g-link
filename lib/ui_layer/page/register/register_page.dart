import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/notifier/auth_notifier.dart';
import 'package:g_link/ui_layer/page/background_page.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:g_link/ui_layer/widgets/my_app_bar.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundPage(
      androidStatusBarIcon: Brightness.light,
      iosStatusBarIcon: Brightness.dark,
      systemNavigationBarColor: Color.fromRGBO(3, 7, 21, 1),
      backgroundGradient: LinearGradient(
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
            padding: EdgeInsetsGeometry.all(8.w),
            decoration: BoxDecoration(
              color: Color.fromRGBO(45, 45, 45, 0.6),
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20.w),
          Row(
            children: [
              Image.asset(
                MyImagePaths.joinGlink,
                width: 233.w,
                height: 33.w,
              ),
            ],
          ),
          SizedBox(height: 6.w),
          Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 16.w),
                child: Text(
                  'registerWorldTip'.tr(),
                  style: MyTheme.white04_12.copyWith(
                    color: Color.fromRGBO(255, 255, 255, 1),
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 26.w),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Color.fromRGBO(19, 20, 23, 0.7),
              borderRadius: BorderRadius.all(Radius.circular(12.w)),
              border: Border.all(
                color: Color.fromRGBO(34, 35, 40, 0.8),
                width: 0.8.w,
              ),
            ),
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    indicatorWeight: 3.w,
                    labelColor: Colors.white,
                    indicatorColor: Colors.white,
                    dividerColor: Colors.transparent,
                    labelStyle: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal,
                    ),
                    indicator: UnderlineTabIndicator(
                      borderRadius: BorderRadius.circular(2.w),
                      borderSide: BorderSide(width: 3.w, color: Colors.white),
                      insets: EdgeInsets.symmetric(horizontal: 10.w), // 控制长度
                    ),
                    tabs: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 13.w),
                        child: Tab(text: 'phoneRegister'.tr()),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 13.w),
                        child: Tab(text: 'emailRegister'.tr()),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 335.w,
                    child: const TabBarView(
                      children: [
                        _PhoneRegister(),
                        _EmailRegister(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 35.w),
          Text(
            '也有账号？去登陆',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.normal),
          ),
          SizedBox(height: 15.w),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 130.w,
                height: 0.8.w,
                color: MyTheme.primaryColor,
              ),
              SizedBox(width: 15.w),
              Text(
                'or',
                style: TextStyle(fontSize: 14.sp, color: Colors.white),
              ),
              SizedBox(width: 15.w),
              Container(
                width: 130.w,
                height: 0.8.w,
                color: MyTheme.primaryColor,
              ),
            ],
          ),
          SizedBox(height: 18.w),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Image.asset(
                  MyImagePaths.apple,
                  width: 40.w,
                  height: 40.w,
                ),
              ),
              SizedBox(width: 40.w),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Image.asset(
                  MyImagePaths.google,
                  width: 40.w,
                  height: 40.w,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmailRegister extends StatelessWidget {
  const _EmailRegister();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('手机号注册', style: MyTheme.white04_12),
    );
  }
}

class _PhoneRegister extends StatefulWidget {
  const _PhoneRegister();

  @override
  State<_PhoneRegister> createState() => PhoneRegisterStateState();
}

class PhoneRegisterStateState extends State<_PhoneRegister> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _pwd1Controller = TextEditingController();
  final TextEditingController _pwd2Controller = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _pwd1Controller.dispose();
    _pwd2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 25.w),
        _buildPhoneView(),
        SizedBox(height: 15.w),
        _buildCodeView(),
        SizedBox(height: 15.w),
        _buildPwd1(),
        SizedBox(height: 15.w),
        _buildPwd2(),
        SizedBox(height: 15.w),
        Selector<AuthNotifier, bool>(
          selector: (_, notifier) => notifier.checkAgreement,
          builder: (_, checkAgreement, __) {
            return Row(
              children: [
                SizedBox(width: 5.w),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    context
                        .read<AuthNotifier>()
                        .setCheckAgreement(!checkAgreement);
                  },
                  child: Image.asset(
                    checkAgreement ? MyImagePaths.check1 : MyImagePaths.uncheck,
                    width: 16.w,
                    height: 16.w,
                    color: checkAgreement ? Colors.green : Colors.white,
                  ),
                ),
                SizedBox(width: 3.w),
                Text(
                  '我已阅读并同意 《用户协议》 和 《隐私政策》',
                  style: TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 1),
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                  ),
                )
              ],
            );
          },
        ),
        SizedBox(height: 30.w),
        Selector<AuthNotifier, bool>(
            selector: (_, notifier) => notifier.loading,
            builder: (_, loading, __) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Container(
                  height: 38.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(245, 250, 250, 1),
                    borderRadius: BorderRadius.all(Radius.circular(30.w)),
                  ),
                  child: loading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            color: MyTheme.primaryColor,
                            strokeWidth: 2.w,
                          ),
                        )
                      : Text(
                          'authRegisterTab'.tr(),
                          style: MyTheme.white04_12.copyWith(
                            color: MyTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                          ),
                        ),
                ),
              );
            }),
      ],
    );
  }

  Widget _buildPhoneView() {
    return Selector<AuthNotifier, String>(
      selector: (_, notifier) => notifier.areaCode,
      builder: (_, areaCode, __) {
        return _InputView(
          leftWidget: Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: Image.asset(
              MyImagePaths.appPhone,
              width: 18.w,
              height: 18.w,
              color: Color.fromRGBO(166, 166, 166, 1),
            ),
          ),
          centerWidget: TextField(
            keyboardType: TextInputType.number,
            // 弹出数字键盘
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
            ],
            style: MyTheme.white04_12.copyWith(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
            ),
            controller: _phoneController,
            cursorColor: MyTheme.primaryColor,
            decoration: InputDecoration(
              hintText: 'phoneHint'.tr(),
              hintStyle: MyTheme.white04_12.copyWith(
                color: Color.fromRGBO(166, 166, 166, 1),
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
            ),
          ),
          rightWidget: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 20.w,
                  width: 1.w,
                  color: Color.fromRGBO(166, 166, 166, 1),
                ),
                SizedBox(width: 6.w),
                Text(
                  areaCode,
                  style: MyTheme.white04_12.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 15.sp,
                  ),
                ),
                SizedBox(width: 3.w),
                Image.asset(
                  MyImagePaths.downArrow,
                  width: 10.w,
                  height: 6.w,
                  color: Colors.white,
                ),
                SizedBox(width: 10.w),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCodeView() {
    return Selector<AuthNotifier, bool>(
      selector: (_, notifier) => notifier.loadingCode,
      builder: (_, loading, __) {
        return _InputView(
          leftWidget: Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: Image.asset(
              MyImagePaths.lock,
              width: 18.w,
              height: 18.w,
              color: Color.fromRGBO(166, 166, 166, 1),
            ),
          ),
          centerWidget: TextField(
            keyboardType: TextInputType.number,
            // 弹出数字键盘
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
            ],
            style: MyTheme.white04_12.copyWith(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
            ),
            controller: _phoneController,
            cursorColor: MyTheme.primaryColor,
            decoration: InputDecoration(
              hintText: 'authCodeHint'.tr(),
              hintStyle: MyTheme.white04_12.copyWith(
                color: Color.fromRGBO(166, 166, 166, 1),
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
            ),
          ),
          rightWidget: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Text(
                'getCode'.tr(),
                style: MyTheme.white04_12.copyWith(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPwd1() {
    return Selector<AuthNotifier, bool>(
      selector: (_, notifier) => notifier.visiPassword,
      builder: (_, visiPassword, __) {
        return _InputView(
          leftWidget: Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: Image.asset(
              MyImagePaths.lock,
              width: 18.w,
              height: 18.w,
              color: Color.fromRGBO(166, 166, 166, 1),
            ),
          ),
          centerWidget: TextField(
            keyboardType: TextInputType.number,
            // 弹出数字键盘
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
            ],
            style: MyTheme.white04_12.copyWith(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
            ),
            controller: _phoneController,
            cursorColor: MyTheme.primaryColor,
            decoration: InputDecoration(
              hintText: 'setPWD1'.tr(),
              hintStyle: MyTheme.white04_12.copyWith(
                color: Color.fromRGBO(166, 166, 166, 1),
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
            ),
          ),
          rightWidget: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Image.asset(
                visiPassword ? MyImagePaths.eye1 : MyImagePaths.eye2,
                width: 18.w,
                height: 18.w,
                color: Color.fromRGBO(166, 166, 166, 1),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPwd2() {
    return Selector<AuthNotifier, bool>(
      selector: (_, notifier) => notifier.visiPassword,
      builder: (_, visiPassword, __) {
        return _InputView(
          leftWidget: Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: Image.asset(
              MyImagePaths.lock,
              width: 18.w,
              height: 18.w,
              color: Color.fromRGBO(166, 166, 166, 1),
            ),
          ),
          centerWidget: TextField(
            keyboardType: TextInputType.number,
            // 弹出数字键盘
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
            ],
            style: MyTheme.white04_12.copyWith(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
            ),
            controller: _phoneController,
            cursorColor: MyTheme.primaryColor,
            decoration: InputDecoration(
              hintText: 'setPWD2'.tr(),
              hintStyle: MyTheme.white04_12.copyWith(
                color: Color.fromRGBO(166, 166, 166, 1),
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
            ),
          ),
          rightWidget: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Image.asset(
                visiPassword ? MyImagePaths.eye1 : MyImagePaths.eye2,
                width: 18.w,
                height: 18.w,
                color: Color.fromRGBO(166, 166, 166, 1),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InputView extends StatelessWidget {
  final Widget? leftWidget;
  final Widget? centerWidget;
  final Widget? rightWidget;

  const _InputView({
    required this.leftWidget,
    required this.centerWidget,
    required this.rightWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.w),
      decoration: BoxDecoration(
        color: Color.fromRGBO(33, 35, 49, 1),
        borderRadius: BorderRadius.all(Radius.circular(35.w)),
      ),
      child: Row(
        children: [
          if (leftWidget != null) leftWidget!,
          if (centerWidget != null) Expanded(child: centerWidget!),
          if (rightWidget != null) rightWidget!,
        ],
      ),
    );
  }
}
