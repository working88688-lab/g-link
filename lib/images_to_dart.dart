import 'dart:io';

void main() async {
  final dir = Directory('assets/images/');
  final List<File> files =
      (await dir.list(recursive: true).toList()).whereType<File>().toList();
  String iconDart = '''class MyImagePaths {\n''';
  for (var file in files) {
    final fileName = file.uri.pathSegments.last;
    final splitted = fileName.split('.');
    final name = splitted.first;
    final varName = name.camelCase;
    final ext = splitted.last;
    if (name == '') continue;

    final output = './assets/images/$name.$ext';

    iconDart += "  static const $varName = '$output';\n";
  }
  iconDart += '}';

  final file = File('lib/ui_layer/image_paths.dart');
  await file.writeAsString(iconDart);
}

class ReCase {
  final RegExp _upperAlphaRegex = RegExp(r'[A-Z]');

  final symbolSet = {' ', '.', '/', '_', '\\', '-'};

  late String originalText;
  late List<String> _words;

  ReCase(String text) {
    originalText = text;
    _words = _groupIntoWords(text);
  }

  List<String> _groupIntoWords(String text) {
    StringBuffer sb = StringBuffer();
    List<String> words = [];
    bool isAllCaps = text.toUpperCase() == text;

    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      String? nextChar = i + 1 == text.length ? null : text[i + 1];

      if (symbolSet.contains(char)) {
        continue;
      }

      sb.write(char);

      bool isEndOfWord = nextChar == null ||
          (_upperAlphaRegex.hasMatch(nextChar) && !isAllCaps) ||
          symbolSet.contains(nextChar);

      if (isEndOfWord) {
        words.add(sb.toString());
        sb.clear();
      }
    }

    return words;
  }

  /// camelCase
  String get camelCase => _getCamelCase();

  String _getCamelCase({String separator = ''}) {
    List<String> words = _words.map(_upperCaseFirstLetter).toList();
    if (_words.isNotEmpty) {
      words[0] = words[0].toLowerCase();
    }

    return words.join(separator);
  }

  String _upperCaseFirstLetter(String word) {
    return '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}';
  }
}

extension StringReCase on String {
  String get camelCase => ReCase(this).camelCase;
}
