// lib/widgets/colored_spans_text.dart
import 'package:flutter/material.dart';
import '../models/analyzer_models.dart';

class ColoredSpansText extends StatelessWidget {
  final String text;
  final List<Span> spans;
  final TextStyle style;

  const ColoredSpansText({
    super.key,
    required this.text,
    required this.spans,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sorted = [...spans]..sort((a, b) => a.start.compareTo(b.start));

    Color bgOf(String t) {
      if (t.contains('to_inf') || t.contains('participle')) {
        return cs.tertiary.withValues(alpha: 0.18); // { }
      }
      if (t.contains('clause')) {
        return cs.primary.withValues(alpha: 0.18); // [ ]
      }
      return cs.secondary.withValues(alpha: 0.18); // ( )
    }

    final children = <TextSpan>[];
    int cursor = 0;

    for (final s in sorted) {
      final st = s.start.clamp(0, text.length);
      final ed = s.end.clamp(st, text.length);

      if (cursor < st) {
        children.add(TextSpan(
          text: text.substring(cursor, st),
          style: style,
        ));
      }

      children.add(TextSpan(
        text: text.substring(st, ed),
        style: style.copyWith(
          backgroundColor: bgOf(s.type),
          fontWeight: FontWeight.w600,
        ),
      ));

      cursor = ed;
    }

    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor), style: style));
    }

    return SelectableText.rich(TextSpan(children: children));
  }
}
