import 'dart:convert';
import 'dart:math';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

class RepoUtils {
  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  static final _rnd = Random();

  static String randomId(int length) => String.fromCharCodes(Iterable.generate(
        length,
        (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
      ));

  static String gvMD5(String data) {
    var content = const Utf8Encoder().convert(data);
    var digest = md5.convert(content);
    var text = hex.encode(digest.bytes);
    return text;
  }

  static String gvSha256(String data) {
    var content = const Utf8Encoder().convert(data);
    var digest = sha256.convert(content);
    var text = hex.encode(digest.bytes);
    return text;
  }
}
