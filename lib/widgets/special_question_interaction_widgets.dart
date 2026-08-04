import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../utils/irrelevant_display_passage.dart';

const _interactionBlue = Color(0xFF2563EB);
const _interactionInk = Color(0xFF111827);
const _interactionLine = Color(0xFFD7DEE9);

class StrongPositionChoice extends StatelessWidget {
  const StrongPositionChoice({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      key: ValueKey('strong-position-$label-$selected'),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      constraints: const BoxConstraints(minWidth: 52, minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? _interactionBlue : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? const Color(0xFF1D4ED8) : _interactionLine,
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x332563EB),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (selected) ...[
            const Icon(Icons.check_rounded, size: 17, color: Colors.white),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _interactionInk,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                child: content,
              ),
      ),
    );
  }
}

class InsertionPassageView extends StatelessWidget {
  const InsertionPassageView({
    super.key,
    required this.passage,
    this.selectedPositions = const <int>{},
  });

  final String passage;
  final Set<int> selectedPositions;

  @override
  Widget build(BuildContext context) {
    const markerSpacing = r'\s\u00A0\u200B-\u200D\u202F\u2060\u3000\uFEFF';
    final markerPattern = RegExp(
      '[\\(\\uFF08]?[$markerSpacing]*'
      '([①-⑳❶-❾➀-➈])'
      '[$markerSpacing]*[\\)\\uFF09]?',
    );
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in markerPattern.allMatches(passage)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: passage.substring(cursor, match.start)));
      }
      final marker = match.group(1)!;
      final position = _insertionMarkerPosition(marker);
      if (position == null) continue;
      final selected = selectedPositions.contains(position);
      spans.add(
        TextSpan(
          text:
              '${_needsLeadingSpace(passage, match.start) ? ' ' : ''}( ${_hollowMarker(position)} ) ',
          style: TextStyle(
            color: selected ? const Color(0xFF4C1D95) : const Color(0xFF6D28D9),
            backgroundColor:
                selected ? const Color(0xFFEDE9FE) : Colors.transparent,
            decoration:
                selected ? TextDecoration.underline : TextDecoration.none,
            decorationColor: const Color(0xFF6D28D9),
            decorationThickness: 1.8,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < passage.length) {
      spans.add(TextSpan(text: passage.substring(cursor)));
    }

    return Text.rich(
      TextSpan(
        children: spans,
        style: const TextStyle(
          color: _interactionInk,
          fontSize: 15.5,
          height: 1.72,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  int? _insertionMarkerPosition(String marker) {
    final codePoint = marker.runes.single;
    if (codePoint >= 0x2460 && codePoint <= 0x2473) {
      return codePoint - 0x2460 + 1;
    }
    if (codePoint >= 0x2776 && codePoint <= 0x277E) {
      return codePoint - 0x2776 + 1;
    }
    if (codePoint >= 0x2780 && codePoint <= 0x2788) {
      return codePoint - 0x2780 + 1;
    }
    return null;
  }

  String _hollowMarker(int position) {
    return position >= 1 && position <= 20
        ? String.fromCharCode(0x2460 + position - 1)
        : '$position';
  }

  bool _needsLeadingSpace(String text, int markerStart) {
    if (markerStart == 0) return false;
    return !RegExp(r'[\s\u00A0\u202F\u3000]')
        .hasMatch(text.substring(markerStart - 1, markerStart));
  }
}

class IrrelevantPassageView extends StatefulWidget {
  const IrrelevantPassageView({
    super.key,
    required this.passage,
    this.selectedPosition,
    this.onPositionSelected,
  });

  final String passage;
  final int? selectedPosition;
  final ValueChanged<int>? onPositionSelected;

  @override
  State<IrrelevantPassageView> createState() => _IrrelevantPassageViewState();
}

class _IrrelevantPassageViewState extends State<IrrelevantPassageView> {
  static const _filledMarkers = '❶❷❸❹❺❻❼❽❾';
  final Map<int, TapGestureRecognizer> _recognizers =
      <int, TapGestureRecognizer>{};

  TapGestureRecognizer _recognizerFor(int position) {
    final recognizer = _recognizers.putIfAbsent(
      position,
      TapGestureRecognizer.new,
    );
    recognizer.onTap = widget.onPositionSelected == null
        ? null
        : () => widget.onPositionSelected!(position);
    return recognizer;
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.passage
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final spans = <InlineSpan>[];
    for (final line in lines) {
      final position = leadingIrrelevantPosition(line);
      if (position == null) {
        spans.add(TextSpan(text: '$line '));
        continue;
      }
      final selected = widget.selectedPosition == position;
      final recognizer = _recognizerFor(position);
      final background =
          selected ? const Color(0xFFE8F0FF) : Colors.transparent;
      spans.add(
        TextSpan(
          text: '${_filledMarker(position)} ',
          recognizer: recognizer,
          style: TextStyle(
            color: selected ? _interactionBlue : const Color(0xFF0F172A),
            backgroundColor: background,
            fontWeight: FontWeight.w900,
            decoration:
                selected ? TextDecoration.underline : TextDecoration.none,
            decorationColor: const Color(0xFF93C5FD),
            decorationThickness: 1.4,
          ),
        ),
      );
      spans.add(
        TextSpan(
          text: '${stripLeadingIrrelevantMarkers(line)} ',
          recognizer: recognizer,
          style: TextStyle(
            color: _interactionInk,
            backgroundColor: background,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            decoration:
                selected ? TextDecoration.underline : TextDecoration.none,
            decorationColor: const Color(0xFF93C5FD),
            decorationThickness: 1.4,
          ),
        ),
      );
    }

    return Text.rich(
      TextSpan(
        children: spans,
        style: const TextStyle(
          color: _interactionInk,
          fontSize: 15.5,
          height: 1.68,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _filledMarker(int position) {
    return position >= 1 && position <= _filledMarkers.length
        ? _filledMarkers[position - 1]
        : '$position.';
  }
}
