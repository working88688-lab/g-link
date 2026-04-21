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
  final key = await AesCbcSecretKey.importRawKey(mediaKey);
  final decrypted = await key.decryptBytes(data, mediaIv);

  return decrypted;

  // Encrypter encrypter =
  //     Encrypter(AES(Key.fromUtf8("f5d965df75336270"), mode: AESMode.cbc));
  // Encrypted encrypted = Encrypted.fromBase64(base64Encode(data));
  // List<int> decrypted =
  //     encrypter.decryptBytes(encrypted, iv: IV.fromUtf8("97b60394abc2fbe1"));
  // return Uint8List.fromList(decrypted);
}
