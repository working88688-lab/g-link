import 'dart:math' as math;

import 'package:flutter/services.dart';

/// 退格/删除选区时，`#[^\s#]+` 整体删除，与正文独立；`tags` 由正文解析即可同步。
class PublishHashtagDeleteFormatter extends TextInputFormatter {
  PublishHashtagDeleteFormatter();

  static final _tag = RegExp(r'#[^\s#]+');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    if (newValue.text.length > oldText.length) {
      return newValue;
    }

    final oldSel = oldValue.selection;
    if (!oldSel.isValid) return newValue;

    // 选区删除：若与某个话题重叠，扩成完整话题再删。
    if (!oldSel.isCollapsed) {
      final s = oldSel.start;
      final e = oldSel.end;
      var ns = s;
      var ne = e;
      for (final m in _tag.allMatches(oldText)) {
        if (m.end <= s || m.start >= e) continue;
        ns = math.min(ns, m.start);
        ne = math.max(ne, m.end);
      }
      if (ns != s || ne != e) {
        final nt = oldText.replaceRange(ns, ne, '');
        return TextEditingValue(
          text: nt,
          selection: TextSelection.collapsed(offset: ns),
        );
      }
      return newValue;
    }

    final c = oldSel.baseOffset;
    // 单字符退格
    if (newValue.text.length == oldText.length - 1 && c > 0) {
      for (final m in _tag.allMatches(oldText)) {
        if (c == m.end) {
          final nt = oldText.replaceRange(m.start, m.end, '');
          return TextEditingValue(
            text: nt,
            selection: TextSelection.collapsed(offset: m.start),
          );
        }
        if (c > m.start + 1 && c <= m.end) {
          final nt = oldText.replaceRange(m.start, m.end, '');
          return TextEditingValue(
            text: nt,
            selection: TextSelection.collapsed(offset: m.start),
          );
        }
      }
    }

    return newValue;
  }
}
