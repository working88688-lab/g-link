import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/page/publish/publish_composer_page.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';

import '../../widgets/app_bottom_sheet.dart';

class PublishPage extends StatefulWidget {
  const PublishPage({super.key});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  String? _errorText;
  String? _lastCapturedLabel;
  String? _capturedPhotoPath;
  CameraState? _currentCameraState;
  int _publishModeIndex = 0;
  bool _flashBusy = false;
  bool _showSpecialEffectsPanel = true;
  int _selectedEffectIndex = 0;

  Future<void> _openAlbum() async {
    final result = await const PublishAlbumRoute().push<Map<String, Object?>>(context);
    if (!mounted || result == null) return;
    setState(() {
      _capturedPhotoPath = result['path']?.toString();
      _showSpecialEffectsPanel = true;
    });
    final draft = PublishMediaDraft(
      mediaType: result['type']?.toString() ?? 'image',
      title: result['name']?.toString(),
      coverLabel: '编辑封面',
      sourceLabel: '相册选择',
    );
    PublishDraftRegistry.set(draft);
    _currentCameraState?.setState(CaptureMode.preview);
  }

  void _openComposer() {
    // const PublishComposerPage().push(context);
  }

  Future<void> _toggleFlash(CameraState cameraState) async {
    if (_flashBusy) return;
    setState(() => _flashBusy = true);
    try {
      await Future<void>.microtask(() => cameraState.sensorConfig.switchCameraFlash());
    } finally {
      if (mounted) {
        setState(() => _flashBusy = false);
      }
    }
  }

  void _showCaptureResult(String label) {
    if (!mounted) return;
    setState(() => _lastCapturedLabel = label);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }

  Future<void> _handleCapture(CameraState cameraState) async {
    if (_publishModeIndex == 0) {
      await cameraState.when(
        onPhotoMode: (state) async {
          await state.takePhoto(
            onPhoto: (request) {
              final path = request.when(
                single: (single) => single.file?.path,
                multiple: (multiple) => multiple.fileBySensor.values.firstOrNull?.path,
              );
              if (path != null && mounted) {
                setState(() {
                  _capturedPhotoPath = path;
                  _showSpecialEffectsPanel = false;
                });
              }
            },
          );
          if (!mounted) return;
          state.setState(CaptureMode.preview);
        },
        onVideoMode: (state) => state.startRecording(),
        onVideoRecordingMode: (state) => state.stopRecording(),
        onPreviewMode: (_) async {},
        onPreparingCamera: (_) async {},
        onAnalysisOnlyMode: (_) async {},
      );
      return;
    }

    await cameraState.when(
      onPhotoMode: (state) => state.takePhoto(),
      onVideoMode: (state) => state.startRecording(),
      onVideoRecordingMode: (state) => state.stopRecording(),
      onPreviewMode: (_) async {},
      onPreparingCamera: (_) async {},
      onAnalysisOnlyMode: (_) async {},
    );
    _showCaptureResult('已执行拍摄动作');
  }

  Future<bool> _handleWillPop() async {
    if (_capturedPhotoPath != null) {
      setState(() {
        _capturedPhotoPath = null;
      });
      _currentCameraState?.setState(CaptureMode.photo);
      return false;
    }
    return true;
  }

  Widget _buildCameraPage() {
    return PopScope(
        canPop: _capturedPhotoPath == null,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _handleWillPop();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              CameraAwesomeBuilder.custom(
                saveConfig: SaveConfig.photoAndVideo(),
                enablePhysicalButton: false,
                builder: (cameraState, preview) {
                  _currentCameraState = cameraState;
                  if (_capturedPhotoPath != null) {
                    return _buildCapturedPreviewOverlay(cameraState: cameraState);
                  }
                  return cameraState.when(
                    onPreparingCamera: (_) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    onPhotoMode: (state) => _buildLivePreviewOverlay(
                      cameraState: state,
                    ),
                    onVideoMode: (state) => _buildLivePreviewOverlay(
                      cameraState: state,
                    ),
                    onVideoRecordingMode: (state) => _buildLivePreviewOverlay(
                      cameraState: state,
                    ),
                    onPreviewMode: (state) => _buildCapturedPreviewOverlay(
                      cameraState: state,
                    ),
                    onAnalysisOnlyMode: (state) => _buildLivePreviewOverlay(
                      cameraState: state,
                    ),
                  );
                },
              ),
              if (_errorText != null)
                Positioned(
                  left: 16,
                  right: 16,
                  top: 48,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorText!,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ));
  }

  Widget _buildLivePreviewOverlay({
    required CameraState cameraState,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildGradientOverlay(),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 19.w),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_capturedPhotoPath != null) {
                          setState(() => _capturedPhotoPath = null);
                          _currentCameraState?.setState(CaptureMode.photo);
                          return;
                        }
                        Navigator.of(context).maybePop();
                      },
                      child: MyImage.asset(
                        MyImagePaths.iconPublishClose,
                        width: 24.w,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _publishModeIndex = 0),
                      child: Text(
                        '发布帖子',
                        style: TextStyle(
                          color: _publishModeIndex == 0 ? Colors.white : const Color(0xFF9D9D9D),
                          fontSize: 16.sp,
                          fontWeight: _publishModeIndex == 0 ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _publishModeIndex = 1),
                      child: Text(
                        '发布短视频',
                        style: TextStyle(
                          color: _publishModeIndex == 1 ? Colors.white : const Color(0xFF9D9D9D),
                          fontSize: 16.sp,
                          fontWeight: _publishModeIndex == 1 ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 24.w,
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 22.w),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    children: [
                      _CameraActionButton(
                        icon: MyImagePaths.iconPublishReverse,
                        label: '翻转',
                        onTap: () => cameraState.switchCameraSensor(),
                      ),
                      SizedBox(height: 23.w),
                      _CameraActionButton(
                        icon: MyImagePaths.iconPublishFlashlight,
                        label: '闪光灯',
                        onTap: () => _toggleFlash(cameraState),
                      ),
                      SizedBox(height: 23.w),
                      _CameraActionButton(
                        icon: MyImagePaths.iconPublishBeauty,
                        label: '美颜',
                        onTap: _onBeauty,
                      ),
                      SizedBox(height: 23.w),
                      _CameraActionButton(
                        icon: MyImagePaths.iconPublishFilter,
                        label: '滤镜',
                        onTap: _onFilter,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BottomActionTile(
                    icon: MyImagePaths.iconPublishSpecialEffects1,
                    iconWidget: _showSpecialEffectsPanel
                        ? Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: const Color(0x66636B80),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Align(
                              child: MyImage.asset(
                                MyImagePaths.iconPublishClose,
                                width: 20.w,
                              ),
                            ),
                          )
                        : null,
                    label: '特效',
                    onTap: () => setState(() => _showSpecialEffectsPanel = !_showSpecialEffectsPanel),
                    badgeText: _lastCapturedLabel,
                  ),
                  SizedBox(
                    width: 42.w,
                  ),
                  GestureDetector(
                    onTap: () => _handleCapture(cameraState),
                    child: Container(
                      width: 72.w,
                      height: 72.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.w),
                      ),
                      child: Center(
                        child: Container(
                          width: 60.w,
                          height: 60.w,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 42.w,
                  ),
                  _BottomActionTile(
                    icon: MyImagePaths.iconPublishAlbum,
                    label: '相册',
                    onTap: _openAlbum,
                  ),
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: _showSpecialEffectsPanel
                    ? _buildSpecialEffectsList(key: const ValueKey('effectsPanel'))
                    : SizedBox.shrink(
                        key: ValueKey('effectsHidden'),
                      ),
              ),
              SizedBox(
                height: 26.w,
              ),
              //
              // SizedBox(
              //   height: 48.w,
              // )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialEffectsList({Key? key}) {
    return Column(
      key: key,
      children: [
        SizedBox(
          height: 25.w,
        ),
        SizedBox(
          height: 46.w,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            itemCount: 8,
            separatorBuilder: (_, __) => SizedBox(width: 6.w),
            itemBuilder: (context, index) {
              final selected = _selectedEffectIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedEffectIndex = index),
                child: Container(
                  width: 44.w,
                  height: 44.w,
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.r),
                    border: selected
                        ? Border.all(
                            color: selected ? const Color(0xFFF8F9FE) : const Color(0xFF4C4C4C),
                            width: 1.w,
                          )
                        : null,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0x805D5D5D),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: index == 0
                        ? Align(
                            child: MyImage.asset(
                              MyImagePaths.iconPublishNone,
                              width: 24.w,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildCapturedPreviewOverlay({
    required CameraState cameraState,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: _capturedPhotoPath == null
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black,
                  child: Image.file(
                    File(_capturedPhotoPath!),
                    fit: BoxFit.contain,
                  ),
                ),
        ),
        _buildGradientOverlay(),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 19.w),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        cameraState.setState(CaptureMode.photo);
                        setState(() => _capturedPhotoPath = null);
                      },
                      child: MyImage.asset(
                        MyImagePaths.iconPublishBack,
                        width: 24.w,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 22.w),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    children: [
                      _CameraActionButton(
                        icon: MyImagePaths.iconPublishText,
                        label: '文字',
                        onTap: () => _toggleFlash(cameraState),
                      ),
                      SizedBox(height: 23.w),
                      _CameraActionButton(
                        icon: MyImagePaths.iconPublishBeauty,
                        label: '美颜',
                        onTap: _onBeauty,
                      ),
                      SizedBox(height: 23.w),
                      _CameraActionButton(
                        icon: MyImagePaths.iconPublishFilter,
                        label: '滤镜',
                        onTap: _onFilter,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              IntrinsicWidth(
                  child: GestureDetector(
                onTap: () => setState(() => _showSpecialEffectsPanel = !_showSpecialEffectsPanel),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 7.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MyImage.asset(
                        MyImagePaths.iconPublishSpecialEffects,
                        width: 20.w,
                      ),
                      SizedBox(
                        width: 6.w,
                      ),
                      Text(
                        "选择特效",
                        style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600),
                      )
                    ],
                  ),
                ),
              )),
              SizedBox(height: 14.w),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _currentCameraState?.setState(CaptureMode.photo);
                          setState(() => _capturedPhotoPath = null);
                        },
                        child: Container(
                          height: 43.w,
                          decoration: BoxDecoration(
                            color: const Color(0x1A494949),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: const Color(0xFF4C4C4C), width: 1.w),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '重拍',
                            style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 13.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: _openComposer,
                        child: Container(
                          height: 43.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FE),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '下一步',
                            style:
                                TextStyle(color: const Color(0xFF1A1F2C), fontSize: 14.sp, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: _showSpecialEffectsPanel
                    ? _buildSpecialEffectsList(key: const ValueKey('effectsPanel'))
                    : SizedBox.shrink(
                        key: ValueKey('effectsHidden'),
                      ),
              ),
              SizedBox(height: 24.w),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xAA000000), Colors.transparent, Colors.transparent, Color(0xCC000000)],
          stops: [0.0, 0.18, 0.76, 1.0],
        ),
      ),
    );
  }

  void _onBeauty() {
    AppBottomSheet.show(
        context: context,
        blurSigma: 22.1,
        showHandle: false,
        decoration: BoxDecoration(
            color: const Color(0xE51B1C1F), borderRadius: BorderRadius.vertical(top: Radius.circular(16.w))),
        child: StatefulBuilder(
            builder: (_, setModalState) => Padding(padding: EdgeInsets.all(16.w), child: Column(children: []))));
  }

  void _onFilter() {
    AppBottomSheet.show(
        context: context,
        blurSigma: 22.1,
        showHandle: false,
        decoration: BoxDecoration(
            color: const Color(0xE51B1C1F), borderRadius: BorderRadius.vertical(top: Radius.circular(16.w))),
        child: StatefulBuilder(
            builder: (_, setModalState) => Padding(padding: EdgeInsets.all(16.w), child: Column(children: []))));
  }

  @override
  Widget build(BuildContext context) {
    return _buildCameraPage();
  }
}

class _CameraActionButton extends StatelessWidget {
  const _CameraActionButton({required this.icon, required this.label, required this.onTap});

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          MyImage.asset(
            icon,
            width: 24.w,
          ),
          SizedBox(height: 4.w),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 12.sp)),
        ],
      ),
    );
  }
}

class _BottomActionTile extends StatelessWidget {
  const _BottomActionTile(
      {required this.icon, required this.label, required this.onTap, this.iconWidget, this.badgeText});

  final String icon;
  final String label;
  final VoidCallback onTap;
  final String? badgeText;
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget ??
              MyImage.asset(
                icon,
                width: 40.w,
              ),
          SizedBox(height: 6.w),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
