import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

/// 发布描述里 `#话题词` 蓝色高亮（与正文 `#111111` 区分）。
class PublishHashtagSpanBuilder extends RegExpSpecialTextSpanBuilder {
  PublishHashtagSpanBuilder();

  final _hashtag = _HashtagMatch();

  @override
  List<RegExpSpecialText> get regExps => [_hashtag];
}

class _HashtagMatch extends RegExpSpecialText {
  static final _re = RegExp(r'#[^\s#]+');

  @override
  RegExp get regExp => _re;

  @override
  InlineSpan finishText(
    int start,
    Match match, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
  }) {
    final base = textStyle ?? const TextStyle(fontSize: 16);
    return TextSpan(
      text: match[0],
      style: base.copyWith(
        color: const Color(0xFF1677FF),
      ),
    );
  }
}
