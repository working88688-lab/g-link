import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../../utils/my_toast.dart';

class PopScopeWrapper extends StatefulWidget {
  const PopScopeWrapper({super.key, required this.child});
  final Widget child;

  @override
  State<PopScopeWrapper> createState() => _PopScopeWrapperState();
}

class _PopScopeWrapperState extends State<PopScopeWrapper> {
  Widget get child => widget.child;
  DateTime? lastPopTime;

  void _onWillPopHandler(bool didPop) {
    late final bool shouldPop;
    if (lastPopTime == null ||
        DateTime.now().difference(lastPopTime!) > const Duration(seconds: 2)) {
      lastPopTime = DateTime.now();
      MyToast.showText(text: 'zatck'.tr(context: context));
      shouldPop = false;
    } else {
      lastPopTime = DateTime.now();
      shouldPop = true;
    }
    if (shouldPop) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: _onWillPopHandler,
      child: child,
    );
  }
}
