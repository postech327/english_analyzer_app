const singleInsertionDisplayPrompt = '글의 흐름으로 보아, 주어진 문장이 들어가기에 가장 적절한 곳은?';
const multipleInsertionDisplayPrompt = '글의 흐름으로 보아, 주어진 문장들이 들어가기에 가장 적절한 곳은?';

String insertionDisplayPromptForMode(Object? mode) {
  final normalized = (mode ?? '').toString().trim().toLowerCase();
  return normalized == 'multiple'
      ? multipleInsertionDisplayPrompt
      : singleInsertionDisplayPrompt;
}

const _insertionPositionLabels = <String>[
  '\u2460',
  '\u2461',
  '\u2462',
  '\u2463',
  '\u2464',
  '\u2465',
  '\u2466',
  '\u2467',
  '\u2468',
];

String insertionPositionLabel(int position) {
  return position >= 1 && position <= _insertionPositionLabels.length
      ? _insertionPositionLabels[position - 1]
      : '$position';
}

List<String> insertionPositionLabels(Iterable<int> positions) {
  return positions.map(insertionPositionLabel).toList(growable: false);
}

String insertionPassageForDisplay(String passage) {
  var cleaned = passage.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  if (cleaned.isEmpty) return '';

  final noteLine = RegExp(r'^\s*\*{1,3}[A-Za-z]');
  final keptLines = <String>[];
  for (final line in cleaned.split('\n')) {
    if (noteLine.hasMatch(line)) break;
    keptLines.add(line);
  }
  cleaned = keptLines.join('\n').trim();

  cleaned =
      cleaned.replaceFirst(RegExp(r'\s+\*{1,3}[A-Za-z][\s\S]*$'), '').trim();

  // Circled numbers in insertion passages identify inline gaps, not sentences.
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'\s*\(?\s*([\u2460-\u2468])\s*\)?\s*'),
    (match) => ' (${match.group(1)}) ',
  );

  return cleaned
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n[ \t]+'), '\n')
      .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
