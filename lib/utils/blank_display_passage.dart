import 'package:flutter/material.dart';

const visibleBlankPlaceholder = '__________';
const _visibleBlankSpanText =
    '\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0';

String blankPassageForDisplay(String raw) {
  if (raw.trim().isEmpty) return raw;
  return raw
      .replaceAll(
        RegExp(r'\[\s*(?:_{2,}\s*)?\]'),
        visibleBlankPlaceholder,
      )
      .replaceAll(RegExp(r'_{3,}'), visibleBlankPlaceholder);
}

TextSpan buildBlankPassageInlineSpans({
  required String passage,
  required TextStyle baseStyle,
  TextStyle? blankStyle,
  TextSpan Function(String text)? textSpanBuilder,
}) {
  final text = blankPassageForDisplay(passage);
  final spans = <InlineSpan>[];
  final pattern = RegExp(RegExp.escape(visibleBlankPlaceholder));
  var cursor = 0;

  for (final match in pattern.allMatches(text)) {
    if (match.start > cursor) {
      final segment = text.substring(cursor, match.start);
      spans.add(textSpanBuilder?.call(segment) ?? TextSpan(text: segment));
    }
    spans.add(
      TextSpan(
        text: _visibleBlankSpanText,
        style: blankStyle ??
            baseStyle.copyWith(
              backgroundColor: const Color(0xFFF8FAFC),
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFF334155),
              decorationThickness: 2.2,
            ),
      ),
    );
    cursor = match.end;
  }

  if (cursor < text.length) {
    final segment = text.substring(cursor);
    spans.add(textSpanBuilder?.call(segment) ?? TextSpan(text: segment));
  }
  return TextSpan(style: baseStyle, children: spans);
}
