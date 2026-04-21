import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';

import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/notifier/home_config_notifier.dart';
import 'package:g_link/ui_layer/theme.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';

import 'package:provider/provider.dart';

import '../../domain/type_def.dart';

class MyToast {
  static showText({required String text, int? time, VoidCallback? onClose}) {
    return BotToast.showText(
      text: text,
      contentColor: Colors.white,
      textStyle: const TextStyle(
          color: Colors.black, fontSize: 14, decoration: TextDecoration.none),
      align: const Alignment(0, 0),
      duration: Duration(seconds: time ?? 2),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 45,
        vertical: 23,
      ),
      onClose: onClose,
    );
  }

  static showLoading({String text = '加载中'}) {
    BotToast.showCustomLoading(toastBuilder: (cancelFunc) {
      return Container(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(54, 54, 54, 0.8),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        height: 110,
        width: 110,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: MyTheme.jellyCyanColor103224185,
                strokeWidth: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(
                color: Color.fromRGBO(255, 255, 255, 1),
                fontSize: 14,
                overflow: TextOverflow.ellipsis,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      );
    });
  }

  static void closeAllLoading() => BotToast.closeAllLoading();
}

class XFileProgressToast extends StatefulWidget {
  const XFileProgressToast({
    super.key,
    required this.file,
    required this.response,
    required this.onCoverDataLoad,
  });

  final XFile file;
  final ValueChanged<Json?> response;
  final ValueChanged<Uint8List> onCoverDataLoad;

  @override
  State<XFileProgressToast> createState() => _XFileProgressToastState();
}

class _XFileProgressToastState extends State<XFileProgressToast> {
  late final homeConfigNotifier = context.read<HomeConfigNotifier>();
  final ValueNotifier<String> progress = ValueNotifier('scz'.tr());

  @override
  void initState() {
    super.initState();
    _upData();
  }

  final CancelToken cancelToken = CancelToken();

  _upData() async {
    final result = await Future.wait([
      loadCoverData(),
      homeConfigNotifier.uploadVideo(
        context: context,
        xFile: widget.file,
        cancelToken: cancelToken,
        progressCallback: (count, total) {
          final tmp = (count / total * 100).round();
          progress.value = "${'scz'.tr()} $tmp%";
        },
      )
    ]);
    widget.response({
      'cover': result[0],
      'video': result[1],
    });
  }

  Future<ui.Image> loadUiImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<Map<String, dynamic>?> loadCoverData() async {
    try {
      final coverData = await VideoThumbnail.thumbnailData(
        imageFormat: ImageFormat.PNG,
        video: widget.file.path,
        timeMs: 1000,
        quality: 25,
      );

      final image = await loadUiImage(coverData);

      if (cancelToken.isCancelled) {
        return null;
      }

      widget.onCoverDataLoad(coverData);

      final path = await homeConfigNotifier.uploadImageByte(
        bytes: coverData,
        cancelToken: cancelToken,
      );

      if (path?['code'] != 1) path?['msg'] = '';
      return path
        ?..addAll({
          'thumb_width': image.width.round(),
          'thumb_height': image.height.round(),
        });
    } catch (e) {
      widget.onCoverDataLoad(Uint8List(0));
      return {
        'code': 1,
        'msg': '',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color.fromRGBO(54, 54, 54, 0.8),
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          height: 110.w,
          width: 110.w,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: MyImage.asset(
                  MyImagePaths.appLoading,
                  height: 40,
                  width: 40,
                ),
              ),
              SizedBox(height: 10.w),
              RepaintBoundary(
                child: ValueListenableBuilder(
                  valueListenable: progress,
                  builder: (_, text, __) {
                    return Text(text, style: MyTheme.white255_14);
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.w),
        TextButton(
          onPressed: () {
            cancelToken.cancel();
          },
          child: Text('qx'.tr(), style: MyTheme.white15),
        ),
      ],
    );
  }
}
