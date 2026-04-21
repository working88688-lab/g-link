import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String?> platformRead(String key) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$key');
    if (!await file.exists()) return null;
    return await file.readAsString();
  } catch (_) {
    return null;
  }
}

Future<void> platformWrite(String key, String value) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/$key').writeAsString(value);
  } catch (_) {}
}

Future<bool> platformHas(String key) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$key').existsSync();
  } catch (_) {
    return false;
  }
}

Future<void> platformDelete(String key) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$key');
    if (await file.exists()) await file.delete();
  } catch (_) {}
}
