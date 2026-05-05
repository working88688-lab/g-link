import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_swiper_null_safety_flutter3/flutter_swiper_null_safety_flutter3.dart';
import 'package:g_link/app_global.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/notifier/home_config_notifier.dart';
import 'package:g_link/ui_layer/notifier/user_notifier.dart';
import 'package:g_link/ui_layer/router/paths.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:g_link/ui_layer/theme/app_design.dart';
import 'package:g_link/ui_layer/theme/theme_manager.dart';
import 'package:g_link/ui_layer/widgets/custom_bottom_nav_bar.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:g_link/ui_layer/widgets/pop_scope_wrapper.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/domain.dart';
import '../../domain/enum.dart';
import '../../domain/model/home_data_model.dart';

class BottomNaviBar extends StatefulWidget {
  const BottomNaviBar({
    required this.navigationShell,
    super.key = const ValueKey<String>('ScaffoldWithNavBar'),
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<BottomNaviBar> createState() => _BottomNaviBarState();
}

class _BottomNaviBarState extends State<BottomNaviBar> {
  late final _userNotifier = context.read<UserNotifier>();
  late final homeConfigNotifier = context.read<HomeConfigNotifier>();
  late final targetVersion = homeConfigNotifier.homeData.versionMsg;
  late final domain = context.read<AppDomain>();
  late final cache = domain.cache;
  MyTokenStatus? currentTokenStatus;

  bool get openLive => homeConfigNotifier.config.openLive == 1 ? true : false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  late final appDomain = context.read<AppDomain>();

  @override
  Widget build(BuildContext context) {
    AppGlobal.context = context;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: ThemeManager.statusBarIconBrightness(
          context,
        ),
        statusBarBrightness: ThemeManager.getBrightness(context),
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: MyTheme.bgColor,
        systemNavigationBarIconBrightness: ThemeManager.statusBarIconBrightness(
          context,
        ),
        systemNavigationBarDividerColor: MyTheme.bgColor,
        systemNavigationBarContrastEnforced: false,
      ),
      child: PopScopeWrapper(
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: AppDesign.bg,
              body: widget.navigationShell,
              bottomNavigationBar: DecoratedBox(
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 2.0,
                      spreadRadius: 1.5,
                      offset: Offset(0.0, -0.5),
                      color: Color.fromRGBO(240, 240, 240, 1),
                    ),
                  ],
                ),
                child: Selector<HomeConfigNotifier, int>(
                  selector: (_, homeConfigNotifier) =>
                      homeConfigNotifier.currentIndex,
                  builder: (_, currentIndex, __) {
                    return CustomBottomNavBar(
                      currentIndex: currentIndex,
                      onTap: (index) {
                        if (index == 2) {
                          context.push(AppRouterPaths.publish);
                          return;
                        }
                        homeConfigNotifier.setCurrentIndex(index);
                        _goBranch(index);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goBranch(int index) {
    final shellIndex = index < 2 ? index : index - 1;
    widget.navigationShell.goBranch(
      shellIndex,
      initialLocation: shellIndex == widget.navigationShell.currentIndex,
    );
  }
}

//悬浮广告view
class TopADWidget extends StatefulWidget {
  const TopADWidget({super.key, required this.toADs});

  final List<AdModel> toADs;

  @override
  State<StatefulWidget> createState() => _TopADWidgetState();
}

class _TopADWidgetState extends State<TopADWidget> {
  bool offstage = false;

  @override
  Widget build(BuildContext context) {
    return widget.toADs.isEmpty ? Container() : _buildButton();
  }

  Widget _buildButton() {
    return Offstage(
      offstage: offstage,
      child: SizedBox(
        width: 120.w,
        height: 120.w,
        child: Stack(
          children: [
            Positioned.fill(
                child: Container(
              alignment: Alignment.center,
              margin: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                  // color: Colors.red,
                  borderRadius: BorderRadius.all(Radius.circular(5.w))),
              child: Swiper(
                autoplay: widget.toADs.length > 1,
                loop: widget.toADs.length > 1,
                itemBuilder: (BuildContext context, int index) {
                  double w = 80.w;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      // CommonUtils.openRoute(
                      //   context,
                      //   widget.toADs[index].toJson(),
                      // );
                    },
                    child: SizedBox(
                      width: w,
                      height: w,
                      child: MyImage.network(
                        CommonUtils.getThumb(widget.toADs[index].toJson()),
                        borderRadius: 5.w,
                      ),
                    ),
                  );
                },
                itemCount: widget.toADs.length,
                pagination: widget.toADs.length > 1
                    ? SwiperPagination(
                        margin: EdgeInsets.only(bottom: 5.w),
                        builder: SwiperCustomPagination(
                          builder: (context, config) {
                            int count = widget.toADs.length;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(count, (index) {
                                return config.activeIndex == index
                                    ? Container(
                                        width: 4.w,
                                        height: 4.w,
                                        margin: EdgeInsets.only(right: 4.w),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(2.w)),
                                        ),
                                      )
                                    : Container(
                                        width: 4.w,
                                        height: 4.w,
                                        margin: EdgeInsets.only(right: 4.w),
                                        decoration: BoxDecoration(
                                          color: MyTheme.grayColor150,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(2.w)),
                                        ),
                                      );
                              }),
                            );
                          },
                        ),
                      )
                    : null,
              ),
            )),
            Positioned(
              right: 0,
              top: 0,
              width: 20.w,
              height: 20.w,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    offstage = true;
                  });
                },
                child: const MyImage.asset(MyImagePaths.appDialogClose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
