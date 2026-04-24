import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:g_link/ui_layer/notifier/auth_notifier.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/theme/app_design.dart';
import 'package:provider/provider.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _loginAccountController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerAccountController = TextEditingController();
  final _registerCodeController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  bool _registerAgreementAccepted = true;

  @override
  void dispose() {
    _loginAccountController.dispose();
    _loginPasswordController.dispose();
    _registerAccountController.dispose();
    _registerCodeController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  bool get _registerIsEmail => _registerAccountController.text.contains('@');

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppDesign.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                Text('authTitle'.tr(), style: AppDesign.appBarTitle),
                const SizedBox(height: 8),
                Text(
                  'authSubtitle'.tr(),
                  style: const TextStyle(
                      color: AppDesign.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppDesign.brand,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppDesign.textSecondary,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: 'authLoginTab'.tr()),
                      Tab(text: 'authRegisterTab'.tr()),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildLoginTab(context),
                      _buildRegisterTab(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab(BuildContext context) {
    return Consumer<AuthNotifier>(
      builder: (context, notifier, child) {
        return ListView(
          children: [
            _buildCard(children: [
              _buildInput(
                controller: _loginAccountController,
                label: 'authAccount'.tr(),
                hint: 'authAccountHint'.tr(),
              ),
              const SizedBox(height: 12),
              _buildInput(
                controller: _loginPasswordController,
                label: 'authPassword'.tr(),
                hint: 'authPasswordHint'.tr(),
                obscure: true,
              ),
              const SizedBox(height: 8),
              if (notifier.errorMessage case final error?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    error,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed:
                      notifier.loading ? null : () => _submitLogin(context),
                  child: notifier.loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('authLoginAction'.tr()),
                ),
              ),
            ]),
          ],
        );
      },
    );
  }

  Widget _buildRegisterTab(BuildContext context) {
    return Consumer<AuthNotifier>(
      builder: (context, notifier, child) {
        return ListView(
          children: [
            _buildCard(
              children: [
                _buildInput(
                  controller: _registerAccountController,
                  label: 'authRegisterAccount'.tr(),
                  hint: 'authRegisterAccountHint'.tr(),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInput(
                        controller: _registerCodeController,
                        label: 'authCode'.tr(),
                        hint: 'authCodeHint'.tr(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 110,
                      height: 48,
                      child: OutlinedButton(
                        onPressed:
                            notifier.loading ? null : () => _sendCode(context),
                        child: Text('authSendCode'.tr()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInput(
                  controller: _registerPasswordController,
                  label: 'authPassword'.tr(),
                  hint: 'authPasswordHint'.tr(),
                  obscure: true,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _registerAgreementAccepted,
                  onChanged: (value) {
                    setState(() {
                      _registerAgreementAccepted = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    'authAgreement'.tr(),
                    style: const TextStyle(
                        fontSize: 12, color: AppDesign.textSecondary),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (notifier.errorMessage case final error?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      error,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: notifier.loading
                        ? null
                        : () => _submitRegister(context),
                    child: notifier.loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('authRegisterAction'.tr()),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscure = false,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppDesign.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF3F6FB),
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitLogin(BuildContext context) async {
    final account = _loginAccountController.text.trim();
    final password = _loginPasswordController.text.trim();
    if (account.isEmpty || password.isEmpty) {
      _toast(context, 'authFillRequired'.tr());
      return;
    }
    final success = await context.read<AuthNotifier>().login(
          account: account,
          password: password,
        );
    if (!mounted || !success) return;
    final requireOnboarding =
        context.read<AuthNotifier>().authData?.requireOnboarding ?? false;
    if (requireOnboarding) {
      const GuideRoute().go(context);
      return;
    }
    const HomeRoute().go(context);
  }

  Future<void> _sendCode(BuildContext context) async {
    final account = _registerAccountController.text.trim();
    if (account.isEmpty) {
      _toast(context, 'authAccountBeforeCode'.tr());
      return;
    }
    final isEmail = _registerIsEmail;
    final success = await context.read<AuthNotifier>().sendRegisterCode(
          channel: isEmail ? 'email' : 'phone',
          countryCode: isEmail ? null : '86',
          account: account,
        );
    if (!mounted) return;
    _toast(context, success ? 'authCodeSent'.tr() : 'authCodeSendFailed'.tr());
  }

  Future<void> _submitRegister(BuildContext context) async {
    final account = _registerAccountController.text.trim();
    final code = _registerCodeController.text.trim();
    final password = _registerPasswordController.text.trim();
    if (account.isEmpty || code.isEmpty || password.isEmpty) {
      _toast(context, 'authFillRequired'.tr());
      return;
    }
    if (!_registerAgreementAccepted) {
      _toast(context, 'authAgreementRequired'.tr());
      return;
    }
    final isEmail = _registerIsEmail;
    final success = await context.read<AuthNotifier>().register(
          type: isEmail ? 'email' : 'phone',
          account: account,
          countryCode: isEmail ? null : '86',
          code: code,
          password: password,
          agreementAccepted: _registerAgreementAccepted,
        );
    if (!mounted || !success) return;
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
}
