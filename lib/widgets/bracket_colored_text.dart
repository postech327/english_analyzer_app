import 'package:flutter/material.dart';

class BracketColoredText extends StatelessWidget {
  const BracketColoredText({
    super.key,
    required this.text,
    this.style,
  });

  static const clauseColor = Color(0xFF3B6FE0);
  static const phraseColor = Color(0xFF3BAA5C);
  static const nonFiniteColor = Color(0xFFE08A3B);

  final String text;
  final TextStyle? style;

  Color _colorFor(String bracket) {
    switch (bracket) {
      case '[':
        return clauseColor;
      case '(':
        return phraseColor;
      case '{':
        return nonFiniteColor;
      default:
        return const Color(0xFF172033);
    }
  }

  Color _backgroundFor(String bracket) {
    switch (bracket) {
      case '[':
        return const Color(0x0F3B6FE0);
      case '(':
        return const Color(0x0F3BAA5C);
      case '{':
        return const Color(0x0FE08A3B);
      default:
        return Colors.transparent;
    }
  }

  String? _matchingClose(String bracket) {
    switch (bracket) {
      case '[':
        return ']';
      case '(':
        return ')';
      case '{':
        return '}';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final spans = <InlineSpan>[];
    var index = 0;

    while (index < text.length) {
      final character = text[index];
      final close = _matchingClose(character);
      if (close != null) {
        final end = _findMatchingClose(text, index, character, close);
        if (end > index) {
          spans.add(
            _chipSpan(
              text: text.substring(index, end + 1),
              bracket: character,
              base: base,
            ),
          );
          index = end + 1;
          continue;
        }
      }

      final nextOpen = _nextOpenIndex(text, index + 1);
      final end = nextOpen == -1 ? text.length : nextOpen;
      spans.add(TextSpan(text: text.substring(index, end), style: base));
      index = end;
    }

    return SelectableText.rich(TextSpan(children: spans, style: base));
  }

  int _nextOpenIndex(String value, int start) {
    final indexes = ['[', '(', '{']
        .map((char) => value.indexOf(char, start))
        .where((found) => found >= 0)
        .toList();
    if (indexes.isEmpty) return -1;
    indexes.sort();
    return indexes.first;
  }

  int _findMatchingClose(
    String value,
    int openIndex,
    String open,
    String close,
  ) {
    var depth = 0;
    for (var i = openIndex; i < value.length; i++) {
      if (value[i] == open) depth++;
      if (value[i] == close) {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }

  InlineSpan _chipSpan({
    required String text,
    required String bracket,
    required TextStyle base,
  }) {
    final color = _colorFor(bracket);
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0.8, vertical: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: _backgroundFor(bracket),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: color.withValues(alpha: 0.62),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: base.copyWith(
            color: color,
            fontWeight: FontWeight.w400,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

class BracketLegend extends StatelessWidget {
  const BracketLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _BracketLegendChip(
          label: '[ ] 절',
          color: BracketColoredText.clauseColor,
        ),
        _BracketLegendChip(
          label: '{ } 구 / 준동사구',
          color: BracketColoredText.nonFiniteColor,
        ),
        _BracketLegendChip(
          label: '( ) 전치사구',
          color: BracketColoredText.phraseColor,
        ),
      ],
    );
  }
}

class _BracketLegendChip extends StatelessWidget {
  const _BracketLegendChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
