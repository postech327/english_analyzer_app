import 'package:flutter/material.dart';

import '../models/final_touch.dart';
import 'bracket_colored_text.dart';

class FinalTouchStructuredText extends StatelessWidget {
  const FinalTouchStructuredText({
    super.key,
    required this.original,
    required this.bracketed,
    required this.spans,
    this.style,
  });

  final String original;
  final String bracketed;
  final List<FinalTouchStructureSpan> spans;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final validSpans = spans
        .where((span) => span.start >= 0 && span.end <= original.length)
        .where((span) => span.start < span.end)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    if (bracketed.trim().isNotEmpty ||
        validSpans.isEmpty ||
        _hasOverlap(validSpans)) {
      return BracketColoredText(
        text: bracketed.trim().isEmpty ? original : bracketed,
        style: base,
      );
    }

    final buffer = StringBuffer();
    var cursor = 0;
    for (final span in validSpans) {
      if (cursor < span.start) {
        buffer.write(original.substring(cursor, span.start));
      }
      final brackets = _bracketsForType(span.type);
      buffer
        ..write(brackets.$1)
        ..write(original.substring(span.start, span.end))
        ..write(brackets.$2);
      cursor = span.end;
    }

    if (cursor < original.length) {
      buffer.write(original.substring(cursor));
    }

    return BracketColoredText(text: buffer.toString(), style: base);
  }

  bool _hasOverlap(List<FinalTouchStructureSpan> spans) {
    for (var index = 1; index < spans.length; index++) {
      if (spans[index].start < spans[index - 1].end) return true;
    }
    return false;
  }

  (String, String) _bracketsForType(String type) {
    if (type.endsWith('_clause')) return ('[', ']');
    if (type == 'prep_phrase' || type == 'pp') return ('(', ')');
    return ('{', '}');
  }
}

class FinalTouchStructureLegend extends StatelessWidget {
  const FinalTouchStructureLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const BracketLegend();
  }
}
