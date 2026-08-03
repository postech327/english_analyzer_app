import 'package:flutter/material.dart';

typedef OriginalUnderlineSegmentBuilder = TextSpan Function(
  String text,
  TextStyle style,
);

bool shouldRenderOriginalUnderline(String questionType) =>
    questionType.trim().toLowerCase() == 'implication';

TextSpan buildQuestionOriginalUnderlineInlineSpans({
  required String questionType,
  required String passage,
  required Map<String, dynamic> specialData,
  required TextStyle baseStyle,
}) {
  if (!shouldRenderOriginalUnderline(questionType)) {
    return TextSpan(text: passage, style: baseStyle);
  }
  return buildOriginalUnderlineInlineSpans(
    passage: passage,
    specialData: specialData,
    baseStyle: baseStyle,
  );
}

TextSpan buildOriginalUnderlineInlineSpans({
  required String passage,
  required Map<String, dynamic> specialData,
  required TextStyle baseStyle,
  TextStyle? underlineStyle,
  OriginalUnderlineSegmentBuilder? segmentBuilder,
}) {
  final ranges = originalUnderlineRanges(passage, specialData);
  final effectiveUnderlineStyle = underlineStyle ??
      baseStyle.copyWith(
        decoration: TextDecoration.underline,
        decorationColor: baseStyle.color ?? const Color(0xFF111827),
        decorationThickness: 1.7,
      );
  final children = <InlineSpan>[];
  var cursor = 0;

  void addSegment(String text, TextStyle style) {
    if (text.isEmpty) return;
    children.add(
      segmentBuilder?.call(text, style) ?? TextSpan(text: text, style: style),
    );
  }

  for (final range in ranges) {
    addSegment(passage.substring(cursor, range.start), baseStyle);
    addSegment(
      passage.substring(range.start, range.end),
      effectiveUnderlineStyle,
    );
    cursor = range.end;
  }
  addSegment(passage.substring(cursor), baseStyle);
  return TextSpan(style: baseStyle, children: children);
}

List<OriginalUnderlineRange> originalUnderlineRanges(
  String passage,
  Map<String, dynamic> specialData,
) {
  final rawRanges = specialData['underline_ranges'];
  if (rawRanges is! List) return const <OriginalUnderlineRange>[];
  final result = <OriginalUnderlineRange>[];
  for (final raw in rawRanges) {
    if (raw is! Map) continue;
    final storedText = raw['text']?.toString() ?? '';
    var start = _asInt(raw['start']);
    var end = _asInt(raw['end']);
    final offsetsAreValid = start != null &&
        end != null &&
        start >= 0 &&
        end > start &&
        end <= passage.length &&
        (storedText.isEmpty || passage.substring(start, end) == storedText);
    if (!offsetsAreValid && storedText.isNotEmpty) {
      start = passage.indexOf(storedText);
      end = start < 0 ? null : start + storedText.length;
    }
    if (start == null || end == null || start < 0 || end > passage.length) {
      continue;
    }
    result.add(OriginalUnderlineRange(start: start, end: end));
  }
  result.sort((left, right) => left.start.compareTo(right.start));
  final nonOverlapping = <OriginalUnderlineRange>[];
  for (final range in result) {
    if (nonOverlapping.isEmpty || range.start >= nonOverlapping.last.end) {
      nonOverlapping.add(range);
    }
  }
  return nonOverlapping;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

class OriginalUnderlineRange {
  const OriginalUnderlineRange({required this.start, required this.end});

  final int start;
  final int end;
}
