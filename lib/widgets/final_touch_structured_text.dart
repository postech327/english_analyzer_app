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

  static const nounColor = Color(0xFF7E22CE);
  static const adjectiveColor = Color(0xFF2563EB);
  static const adverbColor = Color(0xFFEA580C);
  static const prepositionalColor = Color(0xFF0F766E);

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

    if (validSpans.isEmpty || _hasOverlap(validSpans)) {
      return BracketColoredText(
        text: bracketed.trim().isEmpty ? original : bracketed,
        style: base,
      );
    }

    final children = <TextSpan>[];
    var cursor = 0;
    for (final span in validSpans) {
      if (cursor < span.start) {
        children.add(TextSpan(text: original.substring(cursor, span.start)));
      }

      final color = _colorForRole(span.role, span.type);
      final brackets = _bracketsForType(span.type);
      children.add(
        TextSpan(
          text: brackets.$1,
          style: base.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      children.add(
        TextSpan(
          text: original.substring(span.start, span.end),
          style: base.copyWith(
            backgroundColor: _backgroundForRole(span.role, span.type),
          ),
        ),
      );
      children.add(
        TextSpan(
          text: brackets.$2,
          style: base.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      cursor = span.end;
    }

    if (cursor < original.length) {
      children.add(TextSpan(text: original.substring(cursor)));
    }

    return SelectableText.rich(TextSpan(style: base, children: children));
  }

  bool _hasOverlap(List<FinalTouchStructureSpan> spans) {
    for (var index = 1; index < spans.length; index++) {
      if (spans[index].start < spans[index - 1].end) return true;
    }
    return false;
  }

  Color _colorForRole(String role, String type) {
    switch (role) {
      case 'noun':
        return nounColor;
      case 'adjective':
        return adjectiveColor;
      case 'adverb':
        return adverbColor;
      case 'prepositional':
        return prepositionalColor;
    }

    if (type == 'noun_clause' ||
        type == 'noun_phrase' ||
        type == 'gerund_phrase') {
      return nounColor;
    }
    if (type == 'adj_clause' ||
        type == 'adj_phrase' ||
        type == 'participle_phrase') {
      return adjectiveColor;
    }
    if (type == 'prep_phrase' || type == 'pp') {
      return prepositionalColor;
    }
    return adverbColor;
  }

  Color _backgroundForRole(String role, String type) {
    switch (role) {
      case 'noun':
        return const Color(0xFFF8F2FF);
      case 'adjective':
        return const Color(0xFFF2F7FF);
      case 'adverb':
        return const Color(0xFFFFF7EF);
      case 'prepositional':
        return const Color(0xFFF0FBF9);
    }

    if (type == 'noun_clause' ||
        type == 'noun_phrase' ||
        type == 'gerund_phrase') {
      return const Color(0xFFF8F2FF);
    }
    if (type == 'adj_clause' ||
        type == 'adj_phrase' ||
        type == 'participle_phrase') {
      return const Color(0xFFF2F7FF);
    }
    if (type == 'prep_phrase' || type == 'pp') {
      return const Color(0xFFF0FBF9);
    }
    return const Color(0xFFFFF7EF);
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
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _LegendChip(label: '명사 역할', color: FinalTouchStructuredText.nounColor),
        _LegendChip(
          label: '형용사 역할',
          color: FinalTouchStructuredText.adjectiveColor,
        ),
        _LegendChip(
          label: '부사 역할',
          color: FinalTouchStructuredText.adverbColor,
        ),
        _LegendChip(
          label: '전치사구',
          color: FinalTouchStructuredText.prepositionalColor,
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
