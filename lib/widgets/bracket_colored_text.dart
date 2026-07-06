import 'package:flutter/material.dart';

class BracketColoredText extends StatelessWidget {
  const BracketColoredText({
    super.key,
    required this.text,
    this.style,
  });

  static const clauseColor = Color(0xFF2563EB);
  static const phraseColor = Color(0xFF0F766E);
  static const nonFiniteColor = Color(0xFFEA580C);

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
        return const Color(0xFFF2F7FF);
      case '(':
        return const Color(0xFFF0FBF9);
      case '{':
        return const Color(0xFFFFF7EF);
      default:
        return Colors.transparent;
    }
  }

  String? _matchingOpen(String bracket) {
    switch (bracket) {
      case ']':
        return '[';
      case ')':
        return '(';
      case '}':
        return '{';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final children = <TextSpan>[];
    final stack = <String>[];
    final buffer = StringBuffer();

    void flushBuffer() {
      if (buffer.isEmpty) return;
      final bracket = stack.isEmpty ? null : stack.last;
      children.add(
        TextSpan(
          text: buffer.toString(),
          style: bracket == null
              ? base
              : base.copyWith(backgroundColor: _backgroundFor(bracket)),
        ),
      );
      buffer.clear();
    }

    for (var index = 0; index < text.length; index++) {
      final character = text[index];

      if (character == '[' || character == '(' || character == '{') {
        flushBuffer();
        stack.add(character);
        children.add(
          TextSpan(
            text: character,
            style: base.copyWith(
              color: _colorFor(character),
              fontWeight: FontWeight.w800,
            ),
          ),
        );
        continue;
      }

      final openBracket = _matchingOpen(character);
      if (openBracket != null) {
        flushBuffer();
        if (stack.isNotEmpty && stack.last == openBracket) {
          stack.removeLast();
        } else if (stack.contains(openBracket)) {
          while (stack.isNotEmpty && stack.last != openBracket) {
            stack.removeLast();
          }
          if (stack.isNotEmpty) stack.removeLast();
        }
        children.add(
          TextSpan(
            text: character,
            style: base.copyWith(
              color: _colorFor(openBracket),
              fontWeight: FontWeight.w800,
            ),
          ),
        );
        continue;
      }

      buffer.write(character);
    }

    flushBuffer();

    // TODO: Use backend span metadata when nested grammar highlighting expands.
    return SelectableText.rich(TextSpan(children: children, style: base));
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
          label: '{ } 구·준동사구',
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
