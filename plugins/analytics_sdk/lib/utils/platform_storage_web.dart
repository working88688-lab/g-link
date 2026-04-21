// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<String?> platformRead(String key) async =>
    html.window.localStorage[key];

Future<void> platformWrite(String key, String value) async =>
    html.window.localStorage[key] = value;

Future<bool> platformHas(String key) async =>
    html.window.localStorage.containsKey(key);

Future<void> platformDelete(String key) async =>
    html.window.localStorage.remove(key);
