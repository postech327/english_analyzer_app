import '../models/final_touch_import_draft.dart';

FinalTouchImportResult parseFinalTouchImportDrafts(String rawText) {
  final blocks = _splitPassageBlocks(rawText);
  final drafts = <FinalTouchImportDraft>[
    for (var index = 0; index < blocks.length; index++)
      _parseSingleDraft(
        blocks[index].text,
        index: index,
        unitLabel: blocks[index].unitLabel,
      ),
  ];
  return FinalTouchImportResult(
    rawText: rawText,
    drafts: drafts,
    globalWarnings: [
      if (drafts.length > 1) '한 파일에서 ${drafts.length}개 지문 후보를 찾았습니다.',
    ],
  );
}

FinalTouchImportDraft parseFinalTouchImportText(String rawText) {
  return _parseSingleDraft(rawText, index: 0, unitLabel: '');
}

FinalTouchImportDraft _parseSingleDraft(
  String rawText, {
  required int index,
  required String unitLabel,
}) {
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

  var bracketed = value('passage');
  if (bracketed.isEmpty) {
    bracketed = _inferPassage(rawText);
  }
  final passage = stripFinalTouchBrackets(bracketed);
  var translationText = value('translation');
  if (translationText.isEmpty) {
    translationText = _inferTranslation(rawText, bracketed);
  }
  final translations = _contentLines(translationText);
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
    index: index,
    unitLabel: unitLabel,
    source: value('source').isEmpty ? unitLabel : value('source'),
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

List<({String unitLabel, String text})> _splitPassageBlocks(String rawText) {
  final lines = rawText.replaceAll('\r\n', '\n').split('\n');
  final explicitStarts = <int>[];
  for (var index = 0; index < lines.length; index++) {
    if (_explicitUnitLabel(lines[index]) != null) explicitStarts.add(index);
  }
  if (explicitStarts.length >= 2) {
    return _blocksFromStarts(lines, explicitStarts);
  }

  final sourceStarts = <int>[];
  for (var index = 0; index < lines.length; index++) {
    if (_isSourceHeading(lines[index])) sourceStarts.add(index);
  }
  if (sourceStarts.length >= 2) {
    return _blocksFromStarts(lines, sourceStarts);
  }

  final numericStarts = <int>[];
  for (var index = 0; index < lines.length; index++) {
    if (!RegExp(r'^\s*\d{1,2}\s*$').hasMatch(lines[index])) continue;
    final lookAhead = lines.skip(index + 1).take(20).join('\n');
    if (_containsAnalysisHeading(lookAhead) &&
        (_englishRatio(lookAhead) >= 0.25 ||
            RegExp(r'\[\s*영어\s*지문\s*\]').hasMatch(lookAhead))) {
      numericStarts.add(index);
    }
  }
  if (numericStarts.length >= 2) {
    return _blocksFromStarts(lines, numericStarts);
  }

  final label = explicitStarts.isEmpty
      ? ''
      : _explicitUnitLabel(lines[explicitStarts.first]) ?? '';
  return [(unitLabel: label, text: rawText.trim())];
}

List<({String unitLabel, String text})> _blocksFromStarts(
  List<String> lines,
  List<int> starts,
) {
  final blocks = <({String unitLabel, String text})>[];
  for (var index = 0; index < starts.length; index++) {
    final start = starts[index];
    final end = index + 1 < starts.length ? starts[index + 1] : lines.length;
    final label = _explicitUnitLabel(lines[start]) ??
        (RegExp(r'^\s*\d{1,2}\s*$').hasMatch(lines[start])
            ? lines[start].trim().padLeft(2, '0')
            : '');
    final prefix = index == 0 && start > 0 ? lines.take(start).join('\n') : '';
    final body = [
      if (prefix.trim().isNotEmpty) prefix,
      lines.sublist(start, end).join('\n'),
    ].join('\n');
    if (body.trim().isNotEmpty) {
      blocks.add((unitLabel: label, text: body.trim()));
    }
  }
  return blocks;
}

String? _explicitUnitLabel(String line) {
  final normalized = line
      .replaceAll(RegExp(r'^[\s□☐✓•·]+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final patterns = [
    RegExp(r'^Unit\s+\d+\s+No\.?\s*\d+$', caseSensitive: false),
    RegExp(r'^Unit\s+\d+\s+Gateway(?:\s+\d+)?$', caseSensitive: false),
    RegExp(r'^Gateway(?:\s+\d+)?$', caseSensitive: false),
    RegExp(r'^\d+\s*강\s*\d+\s*번$'),
    RegExp(r'^(?:Chapter|Lesson)\s+\d+\s+No\.?\s*\d+$', caseSensitive: false),
  ];
  return patterns.any((pattern) => pattern.hasMatch(normalized))
      ? normalized
      : null;
}

bool _isSourceHeading(String line) {
  return RegExp(r'^\s*(?:\[\s*출처\s*\]|출처\s*:)', caseSensitive: false)
      .hasMatch(line);
}

bool _containsAnalysisHeading(String text) {
  return RegExp(
    r'(?:제목|주제|요지|글의\s*흐름|영어\s*지문|한글\s*해석|해석)\s*(?:\]|:)',
  ).hasMatch(text);
}

String stripFinalTouchBrackets(String text) {
  return text
      .replaceAll(RegExp(r'[\[\]\{\}\(\)]'), '')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r' *\n *'), '\n')
      .trim();
}

(String, String)? _headingKey(String line) {
  final bracketMatch = RegExp(
    r'^\[\s*(출처|제목|주제|요지|소재|글의\s*흐름|영어\s*지문|한글\s*해석|해석|Summary|Topic|Title|Main\s*Idea)\s*\]\s*:?\s*(.*)$',
    caseSensitive: false,
  ).firstMatch(line);
  final colonMatch = RegExp(
    r'^(?:\d+\.\s*)?(출처|제목|주제|요지|소재|글의\s*흐름|영어\s*지문|한글\s*해석|해석|Summary|Topic|Title|Main\s*Idea)\s*:\s*(.*)$',
    caseSensitive: false,
  ).firstMatch(line);
  final match = bracketMatch ?? colonMatch;
  if (match == null) return null;
  final label = match.group(1)!.replaceAll(' ', '').toLowerCase();
  final key = switch (label) {
    '출처' => 'source',
    '제목' => 'title',
    'title' => 'title',
    '주제' || '소재' || 'topic' => 'topic',
    '요지' || 'summary' || 'mainidea' => 'gist',
    '글의흐름' => 'flow',
    '영어지문' => 'passage',
    _ => 'translation',
  };
  return (key, match.group(2)?.trim() ?? '');
}

String _inferPassage(String rawText) {
  final groups = <List<String>>[];
  var current = <String>[];
  var section = '';
  void flush() {
    if (current.isNotEmpty) groups.add(current);
    current = <String>[];
  }

  for (final rawLine in rawText.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    final heading = _headingKey(line);
    if (heading != null) {
      flush();
      section = heading.$1;
      continue;
    }
    if (_explicitUnitLabel(line) != null || line.isEmpty) {
      flush();
      continue;
    }
    if (section == 'title' ||
        section == 'topic' ||
        section == 'gist' ||
        section == 'flow' ||
        section == 'translation') {
      flush();
      continue;
    }
    if (_isEnglishPassageLine(line)) {
      current.add(_stripLeadingNumber(line));
    } else {
      flush();
    }
  }
  flush();
  if (groups.isEmpty) return '';
  groups.sort(
      (left, right) => right.join(' ').length.compareTo(left.join(' ').length));
  return groups.first.join('\n');
}

String _inferTranslation(String rawText, String passage) {
  final passageLines =
      _contentLines(passage).map(stripFinalTouchBrackets).toSet();
  final groups = <List<String>>[];
  var current = <String>[];
  var section = '';
  void flush() {
    if (current.isNotEmpty) groups.add(current);
    current = <String>[];
  }

  for (final rawLine in rawText.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    final heading = _headingKey(line);
    if (heading != null) {
      flush();
      section = heading.$1;
      continue;
    }
    if (_explicitUnitLabel(line) != null || line.isEmpty) {
      flush();
      continue;
    }
    if (section == 'title' ||
        section == 'topic' ||
        section == 'gist' ||
        section == 'flow' ||
        section == 'passage') {
      flush();
      continue;
    }
    if (_isKoreanSentenceLine(line) &&
        !passageLines.contains(stripFinalTouchBrackets(line))) {
      current.add(_stripLeadingNumber(line));
    } else {
      flush();
    }
  }
  flush();
  if (groups.isEmpty) return '';
  groups.sort(
      (left, right) => right.join(' ').length.compareTo(left.join(' ').length));
  return groups.first.join('\n');
}

bool _isEnglishPassageLine(String line) {
  if (line.length < 20) return false;
  final letters = RegExp(r'[A-Za-z]').allMatches(line).length;
  final korean = RegExp(r'[가-힣]').allMatches(line).length;
  final words = RegExp(r"[A-Za-z]+(?:'[A-Za-z]+)?").allMatches(line).length;
  return letters >= 12 && words >= 4 && letters > korean * 2;
}

bool _isKoreanSentenceLine(String line) {
  if (line.length < 8) return false;
  final korean = RegExp(r'[가-힣]').allMatches(line).length;
  final letters = RegExp(r'[A-Za-z]').allMatches(line).length;
  return korean >= 5 && korean > letters;
}

double _englishRatio(String text) {
  final letters = RegExp(r'[A-Za-z]').allMatches(text).length;
  final meaningful = RegExp(r'[A-Za-z가-힣]').allMatches(text).length;
  return meaningful == 0 ? 0 : letters / meaningful;
}

String _stripLeadingNumber(String line) {
  return line
      .replaceFirst(
        RegExp(r'^\s*(?:[①②③④⑤⑥⑦⑧⑨⑩]|\d+[.)]?)\s*'),
        '',
      )
      .trim();
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
