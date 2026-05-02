import 'dart:async';

import 'package:characters/characters.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/domain/result.dart';
import 'package:image/image.dart' as img;

class EditProfileNotifier extends ChangeNotifier {
  EditProfileNotifier(this._profileDomain);

  final ProfileDomain _profileDomain;
  bool _disposed = false;

  bool saving = false;
  bool uploadingAvatar = false;
  bool uploadingCover = false;
  String? errorMessage;
  UploadedImagePayload? uploadedAvatar;
  UploadedImagePayload? uploadedCover;

  Future<bool> submit({
    required String nickname,
    required String username,
    required String bio,
    required String location,
    required String avatarUrl,
    required String coverUrl,
  }) async {
    if (saving) return false;
    final clientError = _validateLocally(
      nickname: nickname,
      username: username,
      bio: bio,
    );
    if (clientError != null) {
      errorMessage = clientError;
      _safeNotify();
      return false;
    }
    saving = true;
    errorMessage = null;
    _safeNotify();

    final result = await _profileDomain.updateMyProfile(
      nickname: nickname.trim(),
      username: username.trim(),
      bio: bio.trim(),
      location: location.trim(),
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
    );
    saving = false;
    if (result.status != 0) {
      errorMessage = _extractServerError(result);
      _safeNotify();
      return false;
    }
    _safeNotify();
    return true;
  }

  /// 提交前的客户端校验，覆盖后端最容易拒掉的几条规则，避免空跑接口。
  /// 返回非空字符串表示有错误，调用方据此中止提交。
  String? _validateLocally({
    required String nickname,
    required String username,
    required String bio,
  }) {
    final n = nickname.trim();
    if (n.isEmpty) return '昵称不能为空';
    if (n.characters.length > 20) return '昵称最多 20 个字符';
    final u = username.trim();
    if (u.isEmpty) return '用户名不能为空';
    if (u.length < 6) return '用户名至少 6 个字符';
    if (u.length > 30) return '用户名最多 30 个字符';
    if (bio.characters.length > 100) return '个人简介最多 100 个字符';
    return null;
  }

  /// 解析后端返回的错误体；优先把 `data.errors` 里的逐字段消息拼出来，
  /// 这样用户能直接看到"用户名/头像 URL/封面 URL"具体哪条出了问题，
  /// 而不是只看到一行通用的 "Validation failed"。
  String _extractServerError(Result result) {
    final data = result.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final lines = <String>[];
        errors.forEach((field, msgs) {
          if (msgs is List && msgs.isNotEmpty) {
            lines.add('$field: ${msgs.first}');
          } else if (msgs is String && msgs.isNotEmpty) {
            lines.add('$field: $msgs');
          }
        });
        if (lines.isNotEmpty) return lines.join('\n');
      }
    }
    return result.msg ?? '保存失败';
  }

  Future<UploadedImagePayload?> uploadAvatar(XFile file) =>
      _uploadImage(file: file, scene: ImageUploadScene.avatar, isAvatar: true);

  Future<UploadedImagePayload?> uploadCover(XFile file) =>
      _uploadImage(file: file, scene: ImageUploadScene.cover, isAvatar: false);

  Future<UploadedImagePayload?> _uploadImage({
    required XFile file,
    required ImageUploadScene scene,
    required bool isAvatar,
  }) async {
    if (isAvatar && uploadingAvatar) return null;
    if (!isAvatar && uploadingCover) return null;
    if (isAvatar) {
      uploadingAvatar = true;
    } else {
      uploadingCover = true;
    }
    errorMessage = null;
    _safeNotify();

    try {
      final prepared = await _prepareUploadBytes(file, isAvatar: isAvatar);
      final result = await _profileDomain
          .uploadImageByPresign(
            bytes: prepared.bytes,
            fileExt: prepared.fileExt,
            fileSize: prepared.bytes.length,
            scene: scene,
          )
          // 避免网络栈在弱网/系统态异常下无响应导致界面一直 loading。
          .timeout(const Duration(seconds: 95));
      if (result.status == 0 && result.data != null) {
        if (isAvatar) {
          uploadedAvatar = result.data;
        } else {
          uploadedCover = result.data;
        }
        return result.data!;
      }
      errorMessage = result.msg ?? '图片上传失败';
      return null;
    } on TimeoutException {
      errorMessage = '图片上传超时，请重试';
      return null;
    } catch (err) {
      errorMessage = err.toString();
      return null;
    } finally {
      if (isAvatar) {
        uploadingAvatar = false;
      } else {
        uploadingCover = false;
      }
      _safeNotify();
    }
  }

  /// 保存接口要求 `avatar_url` 是合法 URL（不接受 object_key），所以这里
  /// 优先用 presign 返回的 `download_url`；用户没换头像时透传 fallback。
  String resolveAvatarSaveValue(String fallbackUrl) {
    return uploadedAvatar?.downloadUrl ?? fallbackUrl;
  }

  /// 同 [resolveAvatarSaveValue]，封面保存值取 `download_url`。
  String resolveCoverSaveValue(String fallbackUrl) {
    return uploadedCover?.downloadUrl ?? fallbackUrl;
  }

  String _resolveExt(XFile file) {
    final name = file.name;
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == name.length - 1) {
      return 'jpg';
    }
    final ext = name.substring(dotIndex + 1).toLowerCase();
    if (ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'webp') {
      return ext;
    }
    return 'jpg';
  }

  Future<_PreparedUpload> _prepareUploadBytes(
    XFile file, {
    required bool isAvatar,
  }) async {
    final rawBytes = await file.readAsBytes();
    final rawExt = _resolveExt(file);
    // 永远走 decode → resize → re-encode 这道工序，原因有两个：
    //  1. 用户原图常常带异常 EXIF（如 orientation=0，标准只允许 1~8），Flutter 的
    //     `Image.network`/`dart:io` 解码链对这些值容错差，常出现"浏览器能开但
    //     Flutter 加载不出来"的情况。重编码后默认不带 EXIF，绕开这个坑。
    //  2. 给一个 84×84 头像或低高度封面用 1080×2460 的源图，解码后 ARGB 约 10MB+，
    //     低端机直接 OOM 或解码超时；统一在客户端把最大边限制到合理范围。
    final compressed = await compute(
      _compressImageInIsolate,
      _CompressInput(
        bytes: rawBytes,
        fallbackExt: rawExt,
        maxDimension: isAvatar ? 1024 : 1920,
        targetMaxBytes: 2 * 1024 * 1024,
      ),
    );
    return _PreparedUpload(
      bytes: compressed.bytes,
      fileExt: compressed.fileExt,
    );
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _PreparedUpload {
  const _PreparedUpload({
    required this.bytes,
    required this.fileExt,
  });

  final Uint8List bytes;
  final String fileExt;
}

class _CompressInput {
  const _CompressInput({
    required this.bytes,
    required this.fallbackExt,
    required this.maxDimension,
    required this.targetMaxBytes,
  });

  final Uint8List bytes;
  final String fallbackExt;

  /// 长边超过该值会被等比缩放到该值；用于把头像/封面源图压到合理像素尺寸，
  /// 避免 Flutter 端解码 1080×2460 这类大图时 OOM 或卡顿。
  final int maxDimension;

  /// JPEG 重编码的目标体积上限（字节），超过会逐档压低质量再缩放。
  final int targetMaxBytes;
}

// 顶层函数，可被 compute 派发到 worker isolate 执行。
//
// 永远走 decode → 强制矫正 EXIF → 限长边 → 重编码 JPEG，三个收益：
//   - 重编码后输出是「裸 baseline JPEG」，不再带 EXIF，避免 orientation=0 这种
//     非法值让 Flutter 解码链失败（"浏览器能开但 Image.network 加载不出来"）；
//   - 长边截到 maxDimension，84px 头像不会再因为 1080×2460 解码炸内存；
//   - 体积兜底 ≤ targetMaxBytes，弱网上传更稳。
_PreparedUpload _compressImageInIsolate(_CompressInput input) {
  final decoded = img.decodeImage(input.bytes);
  if (decoded == null) {
    // image 包都解不开，只能原样上传——但起码体积保留原始字节数。
    return _PreparedUpload(
      bytes: Uint8List.fromList(input.bytes),
      fileExt: input.fallbackExt,
    );
  }

  // 把 EXIF 里 orientation 落到像素上，再清掉 EXIF；image 5.x/4.x 里
  // `bakeOrientation` 对非法值（含 0）不会抛错，等价于不旋转。
  img.Image working = img.bakeOrientation(decoded);
  working.exif.clear();

  final longestEdge =
      working.width >= working.height ? working.width : working.height;
  if (longestEdge > input.maxDimension) {
    final scale = input.maxDimension / longestEdge;
    final nextWidth = (working.width * scale).round();
    final nextHeight = (working.height * scale).round();
    working = img.copyResize(
      working,
      width: nextWidth,
      height: nextHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  Uint8List best = Uint8List.fromList(img.encodeJpg(working, quality: 88));
  if (best.length <= input.targetMaxBytes) {
    return _PreparedUpload(bytes: best, fileExt: 'jpg');
  }

  const qualitySteps = <int>[82, 76, 70, 64, 58, 52, 46, 40];
  for (final quality in qualitySteps) {
    final candidate =
        Uint8List.fromList(img.encodeJpg(working, quality: quality));
    if (candidate.length < best.length) {
      best = candidate;
    }
    if (candidate.length <= input.targetMaxBytes) {
      return _PreparedUpload(bytes: candidate, fileExt: 'jpg');
    }
  }

  while (best.length > input.targetMaxBytes &&
      working.width > 720 &&
      working.height > 720) {
    final nextWidth = (working.width * 0.85).round();
    final nextHeight = (working.height * 0.85).round();
    working = img.copyResize(
      working,
      width: nextWidth,
      height: nextHeight,
      interpolation: img.Interpolation.linear,
    );
    final candidate =
        Uint8List.fromList(img.encodeJpg(working, quality: 70));
    if (candidate.length < best.length) {
      best = candidate;
    }
    if (candidate.length <= input.targetMaxBytes) {
      return _PreparedUpload(bytes: candidate, fileExt: 'jpg');
    }
  }

  return _PreparedUpload(bytes: best, fileExt: 'jpg');
}
