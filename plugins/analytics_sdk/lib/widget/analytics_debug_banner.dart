import 'dart:async';

import 'package:analytics_sdk/entity/analytics_utils.dart';
import 'package:analytics_sdk/utils/widget_bridge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 埋点调试条 - 展示设备信息、埋点流程 7 步，便于排查某机型上报问题
///
/// release 包自动隐藏（无性能影响）；debug 包由 WidgetBridge 内的 enableDebugBanner 控制。
class AnalyticsDebugBanner extends StatelessWidget {
  const AnalyticsDebugBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode || !WidgetBridge.enableDebugBanner) {
      return const SizedBox.shrink();
    }
    return const _AnalyticsDebugBannerContent();
  }
}

class _AnalyticsDebugBannerContent extends StatefulWidget {
  const _AnalyticsDebugBannerContent();

  @override
  State<_AnalyticsDebugBannerContent> createState() =>
      _AnalyticsDebugBannerContentState();
}

class _AnalyticsDebugBannerContentState
    extends State<_AnalyticsDebugBannerContent> {
  List<Map<String, String>> _steps = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshSteps();
    _refreshTimer = Timer.periodic(
        const Duration(seconds: 2), (_) => _refreshSteps());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _refreshSteps() {
    try {
      if (mounted) {
        setState(() {
          _steps = WidgetBridge.getDebugSteps();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {

    final brand = AnalyticsUtils.deviceBrand ?? '';
    final model = AnalyticsUtils.deviceModel ?? '';
    final deviceInfo = brand.isNotEmpty || model.isNotEmpty
        ? '$brand $model'.trim()
        : (kIsWeb
            ? 'Web'
            : defaultTargetPlatform == TargetPlatform.android
                ? 'Android'
                : defaultTargetPlatform == TargetPlatform.iOS
                    ? 'iOS'
                    : defaultTargetPlatform.name);
    final deviceId = AnalyticsUtils.deviceId ?? '';
    final channel = AnalyticsUtils.channel ?? '';

    return IgnorePointer(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          border: const Border(
              bottom: BorderSide(color: Colors.white, width: 2)),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '【埋点测试包】',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        color: Colors.black,
                        offset: Offset(1, 1),
                        blurRadius: 2),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '设备: $deviceInfo',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
              Text(
                'deviceId: ${deviceId.isEmpty ? "未获取" : "${deviceId.length > 16 ? deviceId.substring(0, 16) : deviceId}..."}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
              Text(
                '渠道: ${channel.isEmpty ? "未获取" : channel}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              const Text(
                '埋点流程（卡在某步=该机型问题）',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.yellow),
              ),
              ..._steps.map((s) {
                final status = s['status'] ?? '';
                final isOk = status.startsWith('✓');
                final isFail = status.startsWith('✗');
                var detail = s['detail'] ?? '';
                if (detail.toString().length > 35) {
                  detail = '${detail.toString().substring(0, 35)}...';
                }
                final detailStr =
                    detail.isNotEmpty && detail != '-' ? ' ($detail)' : '';
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${s['name']}: $status$detailStr',
                    style: TextStyle(
                      fontSize: 10,
                      color: isOk
                          ? Colors.greenAccent
                          : isFail
                              ? Colors.orange
                              : Colors.white70,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
