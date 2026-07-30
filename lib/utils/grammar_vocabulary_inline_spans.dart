import 'package:flutter/material.dart';

const grammarVocabularyQuestionTypes = <String>{
  'grammar',
  'vocabulary',
  'grammar_vocabulary',
  'vocabulary_count',
  'grammar_correction',
  'vocabulary_correction',
};

bool isGrammarVocabularyQuestionType(String? questionType) {
  return grammarVocabularyQuestionTypes
      .contains((questionType ?? '').trim().toLowerCase());
}

bool shouldUnderlineChoiceForQuestionType(String? questionType) {
  return isGrammarVocabularyQuestionType(questionType);
}

bool containsReferenceMarkers(String passage) {
  return RegExp(r'\([a-eA-D]\)').hasMatch(passage);
}

bool containsNumberedInlineMarkers(String passage) {
  return RegExp(r'[\u2460-\u2469\u24D0-\u24D4]').hasMatch(passage);
}

bool shouldShowPositionTextInSelection(
  Map<String, dynamic> specialData,
) {
  return (specialData['interaction_type'] ?? '')
          .toString()
          .trim()
          .toLowerCase() !=
      'correction_multi';
}

Map<String, String> grammarVocabularyPositionTexts(
  Map<String, dynamic> specialData,
) {
  return _positionTexts(specialData);
}

String grammarVocabularyPositionText(
  Map<String, dynamic> specialData,
  int position,
) {
  final texts = _positionTexts(specialData);
  return texts[position.toString()] ?? texts[_positionLabel(position)] ?? '';
}

List<String> grammarVocabularyFallbackStudentOptions({
  required String questionType,
  required Iterable<int> positions,
}) {
  final normalizedType = questionType.trim().toLowerCase();
  if (normalizedType == 'vocabulary_count') {
    return const ['① 없음', '② 1개', '③ 2개', '④ 3개', '⑤ 4개'];
  }
  if (!isGrammarVocabularyQuestionType(normalizedType)) {
    return const <String>[];
  }
  const labels = '①②③④⑤⑥⑦⑧⑨';
  return positions
      .where((position) => position >= 1 && position <= labels.length)
      .map((position) => labels[position - 1])
      .toList(growable: false);
}

String grammarVocabularyInlineText(String passage) {
  return passage.replaceAll(RegExp(r'\s+'), ' ').trim();
}

TextSpan buildGrammarVocabularyInlineSpans({
  required String passage,
  required Map<String, dynamic> specialData,
  required TextStyle baseStyle,
  TextStyle? markerStyle,
  TextStyle? candidateStyle,
}) {
  final text = grammarVocabularyInlineText(passage);
  final markerPattern = RegExp(r'[①②③④⑤⑥⑦⑧⑨ⓐⓑⓒⓓⓔⓕⓖⓗⓘ]');
  final markers = markerPattern.allMatches(text).toList();
  if (markers.isEmpty) return TextSpan(text: text, style: baseStyle);

  final positionTexts = _positionTexts(specialData);
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (var markerIndex = 0; markerIndex < markers.length; markerIndex++) {
    final marker = markers[markerIndex];
    if (marker.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, marker.start)));
    }

    final label = marker.group(0)!;
    spans.add(
      TextSpan(
        text: label,
        style: markerStyle ??
            baseStyle.copyWith(
              color: const Color(0xFF7C3AED),
              fontWeight: FontWeight.w800,
            ),
      ),
    );

    final segmentEnd = markerIndex + 1 < markers.length
        ? markers[markerIndex + 1].start
        : text.length;
    final segment = text.substring(marker.end, segmentEnd);
    final preferred = positionTexts[_markerPosition(label).toString()] ??
        positionTexts[label];
    final candidateRange = _candidateRange(segment, preferred);
    if (candidateRange == null) {
      spans.add(TextSpan(text: segment));
    } else {
      if (candidateRange.start > 0) {
        spans.add(TextSpan(text: segment.substring(0, candidateRange.start)));
      }
      spans.add(
        TextSpan(
          text: segment.substring(candidateRange.start, candidateRange.end),
          style: candidateStyle ??
              baseStyle.copyWith(
                decoration: TextDecoration.underline,
                decorationThickness: 1.5,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
      if (candidateRange.end < segment.length) {
        spans.add(TextSpan(text: segment.substring(candidateRange.end)));
      }
    }
    cursor = segmentEnd;
  }

  return TextSpan(style: baseStyle, children: spans);
}

TextSpan buildReferenceMarkerInlineSpans({
  required String passage,
  required TextStyle baseStyle,
  TextStyle? markerStyle,
  TextStyle? referentStyle,
}) {
  final spans = <InlineSpan>[];
  final pattern = RegExp(r'\(([a-e])|([A-D])\)');
  final markers = pattern.allMatches(passage).toList();
  var cursor = 0;
  for (var markerIndex = 0; markerIndex < markers.length; markerIndex++) {
    final match = markers[markerIndex];
    if (match.start > cursor) {
      spans.add(TextSpan(text: passage.substring(cursor, match.start)));
    }
    spans.add(
      TextSpan(
        text: match.group(0),
        style: markerStyle ??
            baseStyle.copyWith(
              color: const Color(0xFF7C3AED),
              fontWeight: FontWeight.w900,
              backgroundColor: const Color(0xFFF3E8FF),
            ),
      ),
    );

    final segmentEnd = markerIndex + 1 < markers.length
        ? markers[markerIndex + 1].start
        : passage.length;
    final segment = passage.substring(match.end, segmentEnd);
    final isReferenceMarker = match.group(1) != null;
    if (!isReferenceMarker) {
      spans.add(TextSpan(text: segment));
      cursor = segmentEnd;
      continue;
    }
    final referentRange = _candidateRange(segment, null);
    if (referentRange == null) {
      spans.add(TextSpan(text: segment));
    } else {
      if (referentRange.start > 0) {
        spans.add(TextSpan(text: segment.substring(0, referentRange.start)));
      }
      spans.add(
        TextSpan(
          text: segment.substring(referentRange.start, referentRange.end),
          style: referentStyle ??
              baseStyle.copyWith(
                decoration: TextDecoration.underline,
                decorationThickness: 1.5,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
      if (referentRange.end < segment.length) {
        spans.add(TextSpan(text: segment.substring(referentRange.end)));
      }
    }
    cursor = segmentEnd;
  }
  if (cursor < passage.length) {
    spans.add(TextSpan(text: passage.substring(cursor)));
  }
  return TextSpan(style: baseStyle, children: spans);
}

TextSpan buildChoiceInlineSpans({
  required String text,
  required TextStyle baseStyle,
  bool underlineWhole = false,
}) {
  final arrowIndex = text.indexOf('→');
  if (arrowIndex > 0) {
    final beforeArrow = text.substring(0, arrowIndex).trimRight();
    return TextSpan(
      style: baseStyle,
      children: [
        TextSpan(
          text: beforeArrow,
          style: baseStyle.copyWith(
            decoration: TextDecoration.underline,
            decorationThickness: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextSpan(text: text.substring(beforeArrow.length)),
      ],
    );
  }
  return TextSpan(
    text: text,
    style: underlineWhole
        ? baseStyle.copyWith(
            decoration: TextDecoration.underline,
            decorationThickness: 1.4,
          )
        : baseStyle,
  );
}

Map<String, String> _positionTexts(Map<String, dynamic> specialData) {
  final raw = specialData['position_texts'];
  if (raw is! Map) return const <String, String>{};
  return <String, String>{
    for (final entry in raw.entries)
      if (entry.value.toString().trim().isNotEmpty)
        entry.key.toString(): entry.value.toString().trim(),
  };
}

_InlineRange? _candidateRange(String segment, String? preferred) {
  if (preferred != null && preferred.trim().isNotEmpty) {
    final index = segment.toLowerCase().indexOf(preferred.toLowerCase());
    if (index >= 0) return _InlineRange(index, index + preferred.length);
  }
  final fallback = RegExp(r"[A-Za-z][A-Za-z’'-]*").firstMatch(segment);
  return fallback == null ? null : _InlineRange(fallback.start, fallback.end);
}

int _markerPosition(String marker) {
  const circled = '①②③④⑤⑥⑦⑧⑨';
  const letters = 'ⓐⓑⓒⓓⓔⓕⓖⓗⓘ';
  final circledIndex = circled.indexOf(marker);
  if (circledIndex >= 0) return circledIndex + 1;
  final letterIndex = letters.indexOf(marker);
  return letterIndex >= 0 ? letterIndex + 1 : 0;
}

String _positionLabel(int position) {
  const labels = '①②③④⑤⑥⑦⑧⑨⑩';
  return position >= 1 && position <= labels.length
      ? labels[position - 1]
      : position.toString();
}

class _InlineRange {
  const _InlineRange(this.start, this.end);

  final int start;
  final int end;
}
