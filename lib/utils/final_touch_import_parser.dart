import '../models/final_touch_import_draft.dart';

FinalTouchImportResult parseFinalTouchImportDrafts(String rawText) {
  final blocks = _mergeCompanionBlocks(_splitPassageBlocks(rawText));
  final drafts = <FinalTouchImportDraft>[];
  for (final block in blocks) {
    final draft = _parseSingleDraft(
      block.text,
      index: drafts.length,
      unitLabel: block.unitLabel,
    );
    if (draft.passage.trim().isNotEmpty) drafts.add(draft);
  }
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
    if (_passageBoundaryLabel(line) != null) continue;
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
  final mappedTranslations = _mapTranslationsToSentences(
    translationText,
    translations,
    sentenceCount,
  );
  final effectiveSource =
      value('source').isEmpty ? unitLabel.trim() : value('source');
  final sentenceDetails = <Map<String, dynamic>>[
    for (var index = 0; index < sentenceCount; index++)
      {
        'sentence_no': index + 1,
        'original': plainSentences[index],
        'bracketed': index < bracketedSentences.length
            ? bracketedSentences[index]
            : plainSentences[index],
        'translation': mappedTranslations[index],
        'translation_bracketed': mappedTranslations[index],
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
    if (effectiveSource.isEmpty) '출처가 없습니다.',
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
    source: effectiveSource,
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
    if (_passageBoundaryLabel(lines[index]) != null) explicitStarts.add(index);
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
      : _passageBoundaryLabel(lines[explicitStarts.first]) ?? '';
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
    final label = _passageBoundaryLabel(lines[start]) ??
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

List<({String unitLabel, String text})> _mergeCompanionBlocks(
  List<({String unitLabel, String text})> blocks,
) {
  final merged = <({String unitLabel, String text})>[];
  for (final block in blocks) {
    final hasPassage = _blockHasEnglishPassage(block.text);
    final hasSupplement = _hasTranslationOrExplanationHeading(block.text);
    if (!hasPassage && hasSupplement && merged.isNotEmpty) {
      final key = _canonicalPassageKey(block.unitLabel);
      var targetIndex = -1;
      if (key.isNotEmpty) {
        for (var index = merged.length - 1; index >= 0; index--) {
          if (_canonicalPassageKey(merged[index].unitLabel) == key) {
            targetIndex = index;
            break;
          }
        }
      }
      if (targetIndex < 0) targetIndex = merged.length - 1;
      final target = merged[targetIndex];
      merged[targetIndex] = (
        unitLabel: target.unitLabel,
        text: '${target.text.trim()}\n\n${block.text.trim()}',
      );
      continue;
    }
    merged.add(block);
  }
  return merged;
}

bool _blockHasEnglishPassage(String text) {
  final sections = <String, List<String>>{};
  String? current;
  for (final rawLine in text.replaceAll('\r\n', '\n').split('\n')) {
    final line = rawLine.trim();
    final heading = _headingKey(line);
    if (heading != null) {
      current = heading.$1;
      sections.putIfAbsent(current, () => []);
      if (heading.$2.isNotEmpty) sections[current]!.add(heading.$2);
      continue;
    }
    if (_passageBoundaryLabel(line) != null) continue;
    if (current != null) sections[current]!.add(line);
  }
  final explicitPassage =
      (sections['passage'] ?? const <String>[]).join('\n').trim();
  return explicitPassage.isNotEmpty || _inferPassage(text).trim().isNotEmpty;
}

bool _hasTranslationOrExplanationHeading(String text) {
  const translation = '\uD574\uC11D';
  const koreanTranslation = '\uD55C\uAE00\\s*\uD574\uC11D';
  const explanation = '\uD574\uC124';
  const solution = '\uD480\uC774';
  const vocabulary = '\uC5B4\uD718';
  const answer = '\uC815\uB2F5';
  const material = '\uC18C\uC7AC';
  return RegExp(
    '(?:\\[\\s*(?:$koreanTranslation|$translation)\\s*\\]|'
    '(?:$koreanTranslation|$translation)\\s*:|'
    '\\[\\s*(?:$explanation|$solution|$vocabulary|$answer|$material)\\s*\\]|'
    '(?:$explanation|$solution|$vocabulary|$answer|$material)\\s*:)',
    caseSensitive: false,
  ).hasMatch(text);
}

String _canonicalPassageKey(String label) {
  final normalized = label
      .replaceAll(RegExp(r'^[\s\[\]#\-:]+|[\s\[\]#\-:]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .toLowerCase();
  if (normalized.isEmpty) return '';
  final gateway =
      RegExp(r'gateway(?:\s+(\d+))?$', caseSensitive: false).firstMatch(
    normalized,
  );
  if (gateway != null) {
    final number = gateway.group(1);
    return number == null ? 'gateway' : 'gateway_$number';
  }
  final unitNo = RegExp(r'unit\s+\d+\s+no\.?\s*(\d+)', caseSensitive: false)
      .firstMatch(normalized);
  if (unitNo != null) return 'no_${int.parse(unitNo.group(1)!)}';
  final noOnly =
      RegExp(r'^no\.?\s*(\d+)$', caseSensitive: false).firstMatch(normalized);
  if (noOnly != null) return 'no_${int.parse(noOnly.group(1)!)}';
  final digits = RegExp(r'^\d{1,2}$').firstMatch(normalized);
  if (digits != null) return 'no_${int.parse(normalized)}';
  return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

String? _passageBoundaryLabel(String line) {
  final normalized = line
      .replaceAll(RegExp(r'^[\s#\-:]+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final patterns = [
    RegExp(r'^Unit\s+\d+\s+No\.?\s*\d+$', caseSensitive: false),
    RegExp(r'^Unit\s+\d+\s+Gateway(?:\s+\d+)?$', caseSensitive: false),
    RegExp(r'^Gateway(?:\s+\d+)?$', caseSensitive: false),
    RegExp(r'^No\.?\s*\d+$', caseSensitive: false),
    RegExp(r'^\d{1,2}$'),
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
  const title = '\uC81C\uBAA9';
  const topic = '\uC8FC\uC81C';
  const gist = '\uC694\uC9C0';
  const material = '\uC18C\uC7AC';
  const flow = '\uAE00\uC758\\s*\uD750\uB984';
  const passage = '\uC601\uC5B4\\s*\uC9C0\uBB38';
  const translation = '(?:\uD55C\uAE00\\s*)?\uD574\uC11D';
  const explanation = '\uD574\uC124';
  const solution = '\uD480\uC774';
  const vocabulary = '\uC5B4\uD718';
  const answer = '\uC815\uB2F5';
  if (RegExp(
    '(?:$title|$topic|$gist|$material|$flow|$passage|$translation|$explanation|$solution|$vocabulary|$answer)\\s*(?:\\]|:)',
  ).hasMatch(text)) {
    return true;
  }
  return false;
}

String stripFinalTouchBrackets(String text) {
  return text
      .replaceAll(RegExp(r'[\[\]\{\}\(\)]'), '')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r' *\n *'), '\n')
      .trim();
}

(String, String)? _headingKey(String line) {
  final realBracketMatch = RegExp(
    r'^\[\s*(출처|제목|주제|요지|소재|글의\s*흐름|영어\s*지문|한글\s*해석|해석|해설|풀이|어휘|Summary|Topic|Title|Main\s*Idea)\s*\]\s*:?\s*(.*)$',
    caseSensitive: false,
  ).firstMatch(line);
  final realColonMatch = RegExp(
    r'^(?:\d+\.\s*)?(출처|제목|주제|요지|소재|글의\s*흐름|영어\s*지문|한글\s*해석|해석|해설|풀이|어휘|Summary|Topic|Title|Main\s*Idea)\s*:\s*(.*)$',
    caseSensitive: false,
  ).firstMatch(line);
  final realMatch = realBracketMatch ?? realColonMatch;
  if (realMatch != null) {
    final label = realMatch.group(1)!.replaceAll(' ', '').toLowerCase();
    final key = switch (label) {
      '출처' => 'source',
      '제목' || 'title' => 'title',
      '주제' || '소재' || 'topic' => 'topic',
      '요지' || 'summary' || 'mainidea' => 'gist',
      '글의흐름' => 'flow',
      '영어지문' => 'passage',
      '해설' || '풀이' => 'explanation',
      '어휘' => 'vocabulary',
      _ => 'translation',
    };
    return (key, realMatch.group(2)?.trim() ?? '');
  }
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
  var afterLetterClosing = false;
  void flush() {
    if (current.isNotEmpty) groups.add(current);
    current = <String>[];
    afterLetterClosing = false;
  }

  for (final rawLine in rawText.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    final heading = _headingKey(line);
    if (heading != null) {
      flush();
      section = heading.$1;
      continue;
    }
    if (_passageBoundaryLabel(line) != null || line.isEmpty) {
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
    final cleaned = _stripLeadingNumber(line);
    final isLetterClosing = _isLetterClosingLine(cleaned);
    final isSignature = afterLetterClosing && _isLikelyEnglishNameLine(cleaned);
    if (_isEnglishPassageLine(line) || isSignature) {
      current.add(cleaned);
      afterLetterClosing = isLetterClosing;
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
    if (_passageBoundaryLabel(line) != null || line.isEmpty) {
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
  final cleaned = _stripLeadingNumber(line);
  if (_hasPassageNumberMarker(line) && RegExp(r'[A-Za-z]').hasMatch(cleaned)) {
    return true;
  }
  if (_isLetterGreetingLine(cleaned) || _isLetterClosingLine(cleaned)) {
    return true;
  }
  if (line.length < 20) return false;
  final letters = RegExp(r'[A-Za-z]').allMatches(line).length;
  final korean = _koreanCharCount(line);
  final words = RegExp(r"[A-Za-z]+(?:'[A-Za-z]+)?").allMatches(line).length;
  return letters >= 12 && words >= 4 && letters > korean * 2;
}

bool _isKoreanSentenceLine(String line) {
  if (line.length < 8) return false;
  final korean = _koreanCharCount(line);
  final letters = RegExp(r'[A-Za-z]').allMatches(line).length;
  return korean >= 5 && korean > letters;
}

double _englishRatio(String text) {
  final letters = RegExp(r'[A-Za-z]').allMatches(text).length;
  final meaningful = letters + _koreanCharCount(text);
  return meaningful == 0 ? 0 : letters / meaningful;
}

int _koreanCharCount(String text) {
  return text.runes.where((codePoint) => codePoint > 0x7f).length;
}

String _stripLeadingNumber(String line) {
  return line
      .replaceFirst(
        RegExp(r'^\s*(?:[\u2460-\u2473]|\d+[.)]?)\s*'),
        '',
      )
      .trim();
}

bool _hasPassageNumberMarker(String line) {
  return RegExp(r'^\s*(?:[\u2460-\u2473]|\d+[.)])\s*').hasMatch(line);
}

bool _isLetterGreetingLine(String line) {
  return RegExp(r'^Dear\b.+,?$', caseSensitive: false).hasMatch(line.trim());
}

bool _isLetterClosingLine(String line) {
  return RegExp(
    r'^(?:Best regards|Sincerely|Yours sincerely|Yours truly|Regards|Warm regards),?$',
    caseSensitive: false,
  ).hasMatch(line.trim());
}

bool _isLikelyEnglishNameLine(String line) {
  final trimmed = line.trim();
  if (trimmed.length > 40) return false;
  if (!RegExp(r"^[A-Z][A-Za-z.'-]*(?:\s+[A-Z][A-Za-z.'-]*){0,3}$")
      .hasMatch(trimmed)) {
    return false;
  }
  return !RegExp(
    r'^(Unit|Gateway|Chapter|Lesson|No|Best|Dear|Sincerely|Regards)$',
    caseSensitive: false,
  ).hasMatch(trimmed);
}

List<String> _mapTranslationsToSentences(
  String translationText,
  List<String> translations,
  int sentenceCount,
) {
  if (sentenceCount <= 0) return const <String>[];
  if (translations.isEmpty) return List.filled(sentenceCount, '');
  if (translations.length == sentenceCount) return translations;
  return [
    translationText.trim(),
    for (var index = 1; index < sentenceCount; index++) '',
  ];
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
