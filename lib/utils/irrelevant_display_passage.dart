const _irrelevantCircledMarkers = '①②③④⑤⑥⑦⑧⑨';
const _irrelevantFilledMarkers = '❶❷❸❹❺❻❼❽❾';
const _irrelevantMarkerTokenPattern =
    r'(?:[\(（]\s*(?:[①②③④⑤⑥⑦⑧⑨❶❷❸❹❺❻❼❽❾]|[1-9])\s*[\)）]|[①②③④⑤⑥⑦⑧⑨❶❷❸❹❺❻❼❽❾]|[1-9][\).])';

final RegExp _leadingIrrelevantMarker = RegExp(
  r'^\s*(?:(?:[\(（]\s*)?([①②③④⑤⑥⑦⑧⑨❶❷❸❹❺❻❼❽❾])(?:\s*[\)）])?|[\(（]\s*([1-9])\s*[\)）]|([1-9])[\).])\s*',
);
final RegExp _adjacentIrrelevantMarkers = RegExp(
  '($_irrelevantMarkerTokenPattern)\\s*($_irrelevantMarkerTokenPattern)',
);

int? leadingIrrelevantPosition(String text) {
  final match = _leadingIrrelevantMarker.firstMatch(text);
  if (match == null) return null;
  final circled = match.group(1);
  if (circled != null) {
    final hollowIndex = _irrelevantCircledMarkers.indexOf(circled);
    if (hollowIndex >= 0) return hollowIndex + 1;
    final filledIndex = _irrelevantFilledMarkers.indexOf(circled);
    return filledIndex < 0 ? null : filledIndex + 1;
  }
  return int.tryParse(match.group(2) ?? match.group(3) ?? '');
}

String stripLeadingIrrelevantMarkers(String text) {
  var cleaned = text.trim();
  for (var count = 0; count < 4; count++) {
    final match = _leadingIrrelevantMarker.firstMatch(cleaned);
    if (match == null || match.end == 0) break;
    cleaned = cleaned.substring(match.end).trimLeft();
  }
  return cleaned.trim();
}

String irrelevantSentenceWithMarker(int position, String text) {
  final marker = position >= 1 && position <= _irrelevantCircledMarkers.length
      ? _irrelevantCircledMarkers[position - 1]
      : '$position)';
  final cleaned = stripLeadingIrrelevantMarkers(text);
  return cleaned.isEmpty ? marker : '$marker $cleaned';
}

String irrelevantPassageForDisplay(
  Map<String, dynamic> specialData, {
  String fallbackPassage = '',
}) {
  final passageWithNumbers =
      (specialData['passage_with_numbers'] ?? '').toString().trim();
  if (passageWithNumbers.isNotEmpty) {
    return cleanupIrrelevantDisplayPassage(passageWithNumbers);
  }

  final numbered = specialData['numbered_sentences'];
  if (numbered is List) {
    final sentenceTexts = <String>[];
    for (final item in numbered) {
      if (item is! Map) continue;
      final text = (item['text'] ?? '').toString().trim();
      if (text.isEmpty || _isIrrelevantAnnotationLine(text)) continue;
      sentenceTexts.add(text);
    }
    if (sentenceTexts.isNotEmpty) {
      return cleanupIrrelevantDisplayPassage(sentenceTexts.join('\n'));
    }
  }

  return cleanupIrrelevantDisplayPassage(fallbackPassage);
}

String cleanupIrrelevantDisplayPassage(String passage) {
  final normalized = passage.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final outputLines = <String>[];
  for (final rawLine in normalized.split('\n')) {
    final line = stripDuplicateIrrelevantMarkers(rawLine.trim());
    if (line.isEmpty || _isIrrelevantAnnotationLine(line)) continue;
    final continuation = _stripParadoxContinuationMarker(line);
    if (continuation != null && outputLines.isNotEmpty) {
      outputLines[outputLines.length - 1] =
          '${outputLines.last.trimRight()} ${continuation.trimLeft()}';
      continue;
    }
    outputLines.add(line);
  }
  return _putIrrelevantMarkersOnOwnLines(outputLines.join('\n')).trim();
}

String stripDuplicateIrrelevantMarkers(String passage) {
  var cleaned = passage;
  for (var pass = 0; pass < 8; pass++) {
    var changed = false;
    cleaned = cleaned.replaceAllMapped(_adjacentIrrelevantMarkers, (match) {
      final right = match.group(2)!;
      changed = true;
      return right;
    });
    if (!changed) break;
  }
  return cleaned;
}

String? _stripParadoxContinuationMarker(String line) {
  final markerMatch = _leadingIrrelevantMarker.firstMatch(line);
  if (markerMatch == null) return null;
  final withoutMarker = line.substring(markerMatch.end).trimLeft();
  return RegExp(
    r'^The\s+paradox\s+of\s+enrichment\s+reveals\b',
    caseSensitive: false,
  ).hasMatch(withoutMarker)
      ? withoutMarker
      : null;
}

String _putIrrelevantMarkersOnOwnLines(String passage) {
  final inlineMarker = RegExp(
    '([^\\n])\\s+($_irrelevantMarkerTokenPattern)(?=\\s+\\S)',
  );
  var formatted = passage;
  for (var pass = 0; pass < 9; pass++) {
    final next = formatted.replaceAllMapped(
      inlineMarker,
      (match) => '${match.group(1)}\n${match.group(2)}',
    );
    if (next == formatted) break;
    formatted = next;
  }
  return formatted;
}

bool _isIrrelevantAnnotationLine(String line) {
  final withoutMarkers = stripLeadingIrrelevantMarkers(line);
  final lower = withoutMarkers.toLowerCase();
  if (withoutMarkers.startsWith('*')) return true;
  if (RegExp(
    r'^\s*(?:glance|counterintuitive|instability|align\s+with)\b',
    caseSensitive: false,
  ).hasMatch(withoutMarkers)) {
    return true;
  }
  return RegExp(
    r'^\s*\[?\s*(?:\uC5B4\uD718|\uD574\uC124|\uD574\uC11D|\uC815\uB2F5|vocabulary|explanation|answer)\s*\]?',
    caseSensitive: false,
  ).hasMatch(lower);
}
