import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/utils/common_utils.dart';

enum _ImageType { asset, network }

final Uint8List kTransparentImage = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

class MyImage extends StatelessWidget {
  const MyImage.asset(
    this.src, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
  })  : _type = _ImageType.asset,
        placeHolder = null;

  const MyImage.network(
    this.src, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.placeHolder = MyImagePaths.appFigureN,
  }) : _type = _ImageType.network;

  final String src;
  final _ImageType _type;

  final BoxFit? fit;
  final double? width;
  final double? height;
  final double? borderRadius;
  final Color? backgroundColor;
  final String? placeHolder;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = switch (_type) {
      _ImageType.asset => Image.asset(
          src,
          width: width,
          height: height,
          fit: fit,
        ),
      _ImageType.network => LayoutBuilder(builder: (context, constraints) {
          final hasBoundedWidth =
              constraints.hasBoundedWidth && constraints.maxWidth.isFinite;
          final effectiveInputWidth =
              hasBoundedWidth ? constraints.maxWidth : (width ?? height ?? 120);
          final url =
              CommonUtils.clipImageUrl(src, inputWidth: effectiveInputWidth);

          final img = FadeInImage.memoryNetwork(
            width: width,
            height: height,
            image: url,
            fit: fit,
            fadeOutDuration: const Duration(milliseconds: 300),
            fadeInDuration: const Duration(milliseconds: 500),
            placeholder: kTransparentImage,
            imageErrorBuilder: (context, error, stackTrace) {
              return Container(); //todo: 图片请求出错时可在此设置异常图片显示
            },
          );
          if (placeHolder == null) {
            return img;
          }
          if (!hasBoundedWidth) {
            final phSize = width ?? height ?? 40.0;
            final double w = phSize;
            final double h = placeHolder == MyImagePaths.appFigureN
                ? w / 117 * 40
                : (height ?? phSize);
            return Stack(
              alignment: Alignment.center,
              children: [
                placeHolder == MyImagePaths.appFigureN
                    ? Image.asset(
                        placeHolder!,
                        width: w,
                        height: h,
                      )
                    : Image.asset(
                        placeHolder!,
                        width: width,
                        height: height,
                      ),
                img,
              ],
            );
          }
          final w = constraints.maxWidth / 3;
          final h = w / 117 * 40;
          return Stack(
            fit: StackFit.expand,
            children: [
              placeHolder == MyImagePaths.appFigureN
                  ? Center(
                      child: Image.asset(
                        placeHolder!,
                        width: w,
                        height: h,
                      ),
                    )
                  : Image.asset(
                      placeHolder!,
                      width: double.infinity,
                      height: double.infinity,
                    ),
              img,
            ],
          );
        }),
    };
    if (backgroundColor case final color?) {
      imageWidget = ColoredBox(color: color, child: imageWidget);
    }

    if (borderRadius case final radius? when radius > 0) {
      imageWidget = SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          clipBehavior: Clip.hardEdge,
          borderRadius: BorderRadius.circular(radius),
          child: imageWidget,
        ),
      );
    }

    return imageWidget;
  }
}
