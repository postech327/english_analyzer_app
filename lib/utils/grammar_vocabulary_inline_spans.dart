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

class _InlineRange {
  const _InlineRange(this.start, this.end);

  final int start;
  final int end;
}
