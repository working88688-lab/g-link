import 'dart:async';
import 'dart:typed_data';
import 'package:webcrypto/webcrypto.dart';

const List<int> enviedkeymediaKey = [
  462343192,
  39960075,
  574656748,
  515183369,
  2805397049,
  916179334,
  1432446718,
  4166792892,
  3365588019,
  3377585432,
  1798887723,
  2526932618,
  221804018,
  2884505460,
  1802778660,
  1311141143
];
const List<int> envieddatamediaKey = [
  462343294,
  39960126,
  574656648,
  515183408,
  2805397007,
  916179379,
  1432446618,
  4166792922,
  3365587972,
  3377585453,
  1798887704,
  2526932665,
  221803972,
  2884505414,
  1802778643,
  1311141159
];
final mediaKey =
    List.generate(envieddatamediaKey.length, (i) => i, growable: false)
        .map((i) => envieddatamediaKey[i] ^ enviedkeymediaKey[i])
        .toList(growable: false);

const List<int> enviedkeymediaIv = [
  3482495231,
  859839061,
  851527260,
  1328534717,
  1107431274,
  3316824835,
  728896161,
  2314953931,
  3801261676,
  686136315,
  640130935,
  2924619451,
  1989694632,
  851358879,
  541634310,
  1237323994
];
const List<int> envieddatamediaIv = [
  3482495174,
  859839074,
  851527230,
  1328534667,
  1107431258,
  3316824880,
  728896152,
  2314953983,
  3801261581,
  686136217,
  640130836,
  2924619401,
  1989694670,
  851358973,
  541634403,
  1237324011
];
final mediaIv =
    List.generate(envieddatamediaIv.length, (i) => i, growable: false)
        .map((i) => envieddatamediaIv[i] ^ enviedkeymediaIv[i])
        .toList(growable: false);

FutureOr<Uint8List> imageDecrypt(Uint8List data) async {
  // 历史实现里默认所有图片图床都是 AES-CBC 密文，需要客户端解密后再交给 Skia。
  // 但新链路（如头像/封面走 S3 presign 直传）下发的就是裸图字节，
  // 强行 AES 解密会撞到 WRONG_FINAL_BLOCK_LENGTH。
  // 这里用 magic bytes 嗅探：识别得出来的明文格式直接透传，识别不出来的
  // 才走老的 AES 解密分支。这样新旧两条图床并存。
  if (_isPlainImage(data)) {
    return data;
  }
  final key = await AesCbcSecretKey.importRawKey(mediaKey);
  final decrypted = await key.decryptBytes(data, mediaIv);
  return decrypted;
}

bool _isPlainImage(Uint8List data) {
  if (data.length < 4) return false;
  // JPEG: FF D8 FF
  if (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF) return true;
  // PNG: 89 50 4E 47 0D 0A 1A 0A
  if (data.length >= 8 &&
      data[0] == 0x89 &&
      data[1] == 0x50 &&
      data[2] == 0x4E &&
      data[3] == 0x47 &&
      data[4] == 0x0D &&
      data[5] == 0x0A &&
      data[6] == 0x1A &&
      data[7] == 0x0A) {
    return true;
  }
  // GIF87a / GIF89a: 47 49 46 38 (37|39) 61
  if (data.length >= 6 &&
      data[0] == 0x47 &&
      data[1] == 0x49 &&
      data[2] == 0x46 &&
      data[3] == 0x38 &&
      (data[4] == 0x37 || data[4] == 0x39) &&
      data[5] == 0x61) {
    return true;
  }
  // WebP: 52 49 46 46 ?? ?? ?? ?? 57 45 42 50
  if (data.length >= 12 &&
      data[0] == 0x52 &&
      data[1] == 0x49 &&
      data[2] == 0x46 &&
      data[3] == 0x46 &&
      data[8] == 0x57 &&
      data[9] == 0x45 &&
      data[10] == 0x42 &&
      data[11] == 0x50) {
    return true;
  }
  // BMP: 42 4D
  if (data[0] == 0x42 && data[1] == 0x4D) return true;
  // HEIC/HEIF: 00 00 00 ?? 66 74 79 70 (ftyp box)
  if (data.length >= 12 &&
      data[0] == 0x00 &&
      data[1] == 0x00 &&
      data[2] == 0x00 &&
      data[4] == 0x66 &&
      data[5] == 0x74 &&
      data[6] == 0x79 &&
      data[7] == 0x70) {
    return true;
  }
  return false;
}
