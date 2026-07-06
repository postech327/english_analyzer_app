import '../models/final_touch_import_draft.dart';

FinalTouchImportDraft parseFinalTouchImportText(String rawText) {
  final sections = <String, List<String>>{};
  String? current;
  for (final rawLine in rawText.replaceAll('\r\n', '\n').split('\n')) {
    final line = rawLine.trim();
    final heading = _headingKey(line);
    if (heading != null) {
      current = heading.$1;
      sections.putIfAbsent(current, () => []);
      if (heading.$2.isNotEmpty) sections[current]!.add(heading.$2);
      continue;
    }
    if (current != null) sections[current]!.add(rawLine.trim());
  }

  String value(String key) => (sections[key] ?? const <String>[])
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  final bracketed = value('passage');
  final passage = bracketed
      .replaceAll(RegExp(r'[\[\]\{\}\(\)]'), '')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r' *\n *'), '\n')
      .trim();
  final translations = _contentLines(value('translation'));
  final bracketedSentences = _contentLines(bracketed);
  final plainSentences = _contentLines(passage);
  final sentenceCount = plainSentences.length;
  final sentenceDetails = <Map<String, dynamic>>[
    for (var index = 0; index < sentenceCount; index++)
      {
        'sentence_no': index + 1,
        'original': plainSentences[index],
        'bracketed': index < bracketedSentences.length
            ? bracketedSentences[index]
            : plainSentences[index],
        'translation': index < translations.length ? translations[index] : '',
        'translation_bracketed':
            index < translations.length ? translations[index] : '',
        'spans': const [],
        'sentence_role': '',
        'role_highlight_type': 'none',
        'is_blank_candidate': false,
        'highlights': const [],
        'grammar_points': const [],
        'question_point': '',
      },
  ];
  final outline = _parseOutline(value('flow'));
  final warnings = <String>[
    if (value('source').isEmpty) '출처가 없습니다.',
    if (value('title').isEmpty) '제목이 없습니다.',
    if (value('topic').isEmpty) '주제가 없습니다.',
    if (value('gist').isEmpty) '요지가 없습니다.',
    if (passage.isEmpty) '영어 지문이 없습니다.',
    if (translations.isEmpty) '한글 해석이 없습니다.',
    if (!RegExp(r'[\[\]\{\}\(\)]').hasMatch(bracketed)) '괄호 구조가 없습니다.',
    if (translations.isNotEmpty && translations.length != sentenceCount)
      '영어 문장과 한글 해석 개수가 다릅니다.',
  ];

  return FinalTouchImportDraft(
    source: value('source'),
    title: value('title'),
    topic: value('topic'),
    gist: value('gist'),
    outline: outline,
    passage: passage,
    passageBracketed: bracketed.isEmpty ? passage : bracketed,
    sentenceDetails: sentenceDetails,
    rawText: rawText,
    warnings: warnings,
  );
}

(String, String)? _headingKey(String line) {
  final match = RegExp(
    r'^\[?\s*(출처|제목|주제|요지|글의\s*흐름|영어\s*지문|한글\s*해석|해석)\s*\]?\s*:?\s*(.*)$',
    caseSensitive: false,
  ).firstMatch(line);
  if (match == null) return null;
  final label = match.group(1)!.replaceAll(' ', '');
  final key = switch (label) {
    '출처' => 'source',
    '제목' => 'title',
    '주제' => 'topic',
    '요지' => 'gist',
    '글의흐름' => 'flow',
    '영어지문' => 'passage',
    _ => 'translation',
  };
  return (key, match.group(2)?.trim() ?? '');
}

Map<String, String> _parseOutline(String text) {
  final result = {'intro': '', 'body': '', 'conclusion': ''};
  final matches = RegExp(
    r'(서론|본론|결론)\s*:\s*(.*?)(?=(?:서론|본론|결론)\s*:|$)',
    dotAll: true,
  ).allMatches(text);
  for (final match in matches) {
    final key = switch (match.group(1)) {
      '서론' => 'intro',
      '본론' => 'body',
      _ => 'conclusion',
    };
    result[key] = match.group(2)?.trim() ?? '';
  }
  if (matches.isEmpty && text.trim().isNotEmpty) result['body'] = text.trim();
  return result;
}

List<String> _contentLines(String text) {
  final lines = text
      .split(RegExp(r'\n+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.length != 1) return lines;
  return text
      .trim()
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}
