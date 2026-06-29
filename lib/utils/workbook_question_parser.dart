// Workbook raw-text parsers intentionally live outside the editor UI.
// Later HWP upload/text extraction should call these helpers first; Excel
// import is a lower-priority path and should reuse the same parser contracts.

class InlineChoiceParseResult {
  const InlineChoiceParseResult({
    required this.rawText,
    required this.passageText,
    required this.items,
    required this.errors,
    this.warnings = const [],
  });

  final String rawText;
  final String passageText;
  final List<InlineChoiceItem> items;
  final List<String> errors;
  final List<String> warnings;

  bool get hasItems => items.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;

  Map<String, dynamic> toAnswerJson({String? unitTitle}) {
    return {
      if (unitTitle != null && unitTitle.trim().isNotEmpty)
        'unit_title': unitTitle.trim(),
      'raw_text': rawText,
      'passage_text': passageText,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class InlineChoiceItem {
  const InlineChoiceItem({
    required this.number,
    required this.choices,
    required this.answer,
    required this.answerIndex,
    this.explanation,
  });

  final int number;
  final List<String> choices;
  final String answer;
  final int answerIndex;
  final String? explanation;

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'choices': choices,
      'answer': answer,
      'answer_index': answerIndex,
      if (explanation != null && explanation!.trim().isNotEmpty)
        'explanation': explanation!.trim(),
    };
  }
}

InlineChoiceParseResult parseInlineChoiceRawText(
  String rawText, {
  String? explanationText,
}) {
  final explanationSet = _parseInlineChoiceExplanations(explanationText ?? '');
  var sequentialExplanationIndex = 0;
  var numberedFallbackIndex = 0;
  var usedExplanationCount = 0;
  final usedNumberedExplanations = <int>{};
  String? takeExplanation(int number) {
    final numbered = explanationSet.numbered[number];
    if (numbered != null &&
        numbered.isNotEmpty &&
        usedNumberedExplanations.add(number)) {
      usedExplanationCount++;
      return numbered;
    }
    final canUseLargeNumberFallback = explanationSet.numbered.isNotEmpty &&
        explanationSet.numbered.keys.every((key) => key >= 100);
    if (canUseLargeNumberFallback) {
      final entries = explanationSet.numbered.entries.toList();
      while (numberedFallbackIndex < entries.length &&
          usedNumberedExplanations.contains(
            entries[numberedFallbackIndex].key,
          )) {
        numberedFallbackIndex++;
      }
      if (numberedFallbackIndex < entries.length) {
        final entry = entries[numberedFallbackIndex++];
        usedNumberedExplanations.add(entry.key);
        usedExplanationCount++;
        return entry.value;
      }
    }
    if (sequentialExplanationIndex >= explanationSet.sequential.length) {
      return null;
    }
    usedExplanationCount++;
    return explanationSet.sequential[sequentialExplanationIndex++];
  }

  List<String> explanationWarnings() {
    if (usedExplanationCount >= explanationSet.totalCount) return const [];
    return const ['일부 해설은 선택 항목과 매칭되지 않았습니다. 저장은 가능합니다.'];
  }

  final explicitPattern = RegExp(
    r'\[\[\s*(\d+)\s*:\s*([^|\]]+)\|([^\]]+)\]\]',
  );
  final explicitMatches = explicitPattern.allMatches(rawText).toList();
  if (explicitMatches.isNotEmpty) {
    final errors = <String>[];
    final items = <InlineChoiceItem>[];
    final seenNumbers = <int>{};
    final buffer = StringBuffer();
    var cursor = 0;
    for (final match in explicitMatches) {
      buffer.write(rawText.substring(cursor, match.start));
      final number = int.parse(match.group(1)!);
      final correct = _cleanInlineChoice(match.group(2)!);
      final wrong = _cleanInlineChoice(match.group(3)!);
      if (!seenNumbers.add(number)) {
        errors.add('$number번 선택 항목 번호가 중복되었습니다.');
      }
      if (correct.isEmpty || wrong.isEmpty) {
        errors.add('$number번 선택 항목의 정답과 오답을 모두 입력해 주세요.');
      } else {
        items.add(
          InlineChoiceItem(
            number: number,
            choices: [correct, wrong],
            answer: correct,
            answerIndex: 0,
            explanation: takeExplanation(number),
          ),
        );
      }
      buffer.write('[[$number:$correct|$wrong]]');
      cursor = match.end;
    }
    buffer.write(rawText.substring(cursor));
    return InlineChoiceParseResult(
      rawText: rawText,
      passageText: buffer.toString().trim(),
      items: items,
      errors: errors,
      warnings: explanationWarnings(),
    );
  }

  final bracketPattern = RegExp(r'\[([^\[\]/]+)\/([^\[\]]+)\]');
  final matches = bracketPattern.allMatches(rawText).toList();
  final errors = <String>[];
  final items = <InlineChoiceItem>[];
  final buffer = StringBuffer();
  var cursor = 0;

  for (final match in matches) {
    buffer.write(rawText.substring(cursor, match.start));
    final choices = [
      _cleanInlineChoice(match.group(1)!),
      _cleanInlineChoice(match.group(2)!),
    ];
    final after = rawText.substring(match.end);
    final answerMatch = _matchAnswer(after, choices);
    final number = items.length + 1;

    final hasNoExplicitAnswer = after.trimLeft().isEmpty ||
        RegExp(r'^[.!?]').hasMatch(after.trimLeft());
    if (answerMatch == null && !hasNoExplicitAnswer) {
      errors.add('$number번 [${choices.join('/')}] 뒤에 정답이 없거나 선택지와 일치하지 않습니다.');
      buffer.write('[[$number:${choices.join('|')}]]');
      cursor = match.end;
      continue;
    }

    final matchedAnswer = answerMatch?.choice ?? choices.first;
    var consumed = answerMatch?.consumed ?? 0;
    var explanation = '';
    final explanationPrefix = RegExp(
          r'^\s*(?:[,;:]\s*)?',
        ).firstMatch(after.substring(consumed))?.group(0) ??
        '';
    final explanationStart = consumed + explanationPrefix.length;
    if (after.length > explanationStart && after[explanationStart] == '(') {
      final closeIndex = after.indexOf(')', explanationStart + 1);
      if (closeIndex > explanationStart) {
        explanation = after.substring(explanationStart + 1, closeIndex).trim();
        consumed = closeIndex + 1;
      }
    }
    explanation = takeExplanation(number) ?? explanation;

    final answerIndex = choices.indexWhere(
      (choice) =>
          _cleanInlineChoice(choice).toLowerCase() ==
          _cleanInlineChoice(matchedAnswer).toLowerCase(),
    );
    items.add(
      InlineChoiceItem(
        number: number,
        choices: choices,
        answer: choices[answerIndex],
        answerIndex: answerIndex,
        explanation: explanation.isEmpty ? null : explanation,
      ),
    );
    buffer.write('[[$number:${choices.join('|')}]]');
    cursor = match.end + consumed;
  }

  if (matches.isEmpty && rawText.trim().isNotEmpty) {
    errors.add('[선택지1/선택지2] 형태의 선택 항목을 찾지 못했습니다.');
  }

  buffer.write(rawText.substring(cursor));
  return InlineChoiceParseResult(
    rawText: rawText,
    passageText: buffer.toString().trim(),
    items: items,
    errors: errors,
    warnings: explanationWarnings(),
  );
}

class _InlineChoiceExplanationSet {
  const _InlineChoiceExplanationSet({
    required this.numbered,
    required this.sequential,
  });

  final Map<int, String> numbered;
  final List<String> sequential;

  int get totalCount => numbered.length + sequential.length;
}

_InlineChoiceExplanationSet _parseInlineChoiceExplanations(String rawText) {
  final numbered = <int, String>{};
  final sequential = <String>[];
  final numberedMatches = RegExp(
    r'(^|\s)(\d+)\s*[.)]\s*',
    multiLine: true,
  ).allMatches(rawText).toList();
  if (numberedMatches.isNotEmpty) {
    for (var index = 0; index < numberedMatches.length; index++) {
      final match = numberedMatches[index];
      final end = index + 1 < numberedMatches.length
          ? numberedMatches[index + 1].start
          : rawText.length;
      final explanation = _inlineExplanationContent(
        rawText.substring(match.end, end),
      );
      if (explanation.isNotEmpty) {
        numbered[int.parse(match.group(2)!)] = explanation;
      }
    }
  } else {
    sequential.addAll(
      RegExp(r'\(([^()]*)\)')
          .allMatches(rawText)
          .map((match) => (match.group(1) ?? '').trim())
          .where((text) => text.isNotEmpty),
    );
    if (sequential.isEmpty) {
      sequential.addAll(
        rawText
            .split(RegExp(r'\r?\n'))
            .map(
              (line) => line.trim().replaceFirst(RegExp(r'^[•\-]\s*'), ''),
            )
            .where((line) => line.isNotEmpty),
      );
    }
  }
  return _InlineChoiceExplanationSet(
    numbered: numbered,
    sequential: sequential,
  );
}

String _inlineExplanationContent(String value) {
  final text = value.trim();
  final parenthetical = RegExp(
    r'\(([^()]*)\)\s*[.,;:]?\s*$',
  ).firstMatch(text);
  final content = parenthetical?.group(1)?.trim();
  return content != null && content.isNotEmpty ? content : text;
}

class TrueFalseRawParseResult {
  const TrueFalseRawParseResult({
    required this.rawText,
    required this.answerExplanationText,
    required this.subtype,
    required this.items,
    required this.errors,
    required this.warnings,
  });

  final String rawText;
  final String answerExplanationText;
  final String subtype;
  final List<TrueFalseRawItem> items;
  final List<String> errors;
  final List<String> warnings;

  bool get hasItems => items.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;

  Map<String, dynamic> toAnswerJson({
    String? unitTitle,
    String? sourceLabel,
    String? passageText,
  }) {
    return {
      if (unitTitle != null && unitTitle.trim().isNotEmpty)
        'unit_title': unitTitle.trim(),
      if (sourceLabel != null && sourceLabel.trim().isNotEmpty)
        'source_label': sourceLabel.trim(),
      'subtype': subtype,
      if (passageText != null && passageText.trim().isNotEmpty)
        'passage_text': passageText.trim(),
      'raw_text': rawText,
      'answer_explanation_text': answerExplanationText,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class TrueFalseRawItem {
  const TrueFalseRawItem({
    required this.number,
    required this.statement,
    this.answer,
    this.explanation,
    this.evidence,
  });

  final int number;
  final String statement;
  final bool? answer;
  final String? explanation;
  final String? evidence;

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'statement': statement,
      if (answer != null) 'answer': answer,
      if (explanation != null && explanation!.trim().isNotEmpty)
        'explanation': explanation!.trim(),
      if (evidence != null && evidence!.trim().isNotEmpty)
        'evidence': evidence!.trim(),
    };
  }
}

TrueFalseRawParseResult parseTrueFalseRawText(
  String rawText,
  String subtype, {
  String? answerExplanationText,
}) {
  final normalizedSubtype =
      subtype == 'true_false_ko' ? 'true_false_ko' : 'true_false_en';
  final errors = <String>[];
  final warnings = <String>[];
  final statements = _parseNumberedBlocks(rawText);
  final answerText = answerExplanationText ?? '';
  final answers = _parseTrueFalseAnswers(answerText);
  final explanations = _parseExplanations(answerText);

  if (statements.isEmpty && rawText.trim().isNotEmpty) {
    final fallbackLines = rawText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    for (var i = 0; i < fallbackLines.length; i++) {
      statements[i + 1] = fallbackLines[i];
    }
  }

  if (statements.isEmpty) {
    errors.add('T/F 문항을 1개 이상 입력해 주세요.');
  }
  if (answers.isEmpty && answerText.trim().isNotEmpty) {
    warnings.add('정답을 찾지 못했습니다. 예: 정답: F F T F T');
  }
  if (answers.isNotEmpty && answers.length != statements.length) {
    warnings
        .add('정답 개수(${answers.length})와 문항 개수(${statements.length})가 다릅니다.');
  }

  final items = <TrueFalseRawItem>[];
  final sortedKeys = statements.keys.toList()..sort();
  for (final key in sortedKeys) {
    final statement = statements[key]?.trim() ?? '';
    if (statement.isEmpty) continue;
    final answer = key <= answers.length ? answers[key - 1] : null;
    if (answer == null) {
      errors.add('$key번 문항의 정답이 없습니다.');
    }
    items.add(
      TrueFalseRawItem(
        number: items.length + 1,
        statement: statement,
        answer: answer,
        explanation: explanations[key],
      ),
    );
  }

  return TrueFalseRawParseResult(
    rawText: rawText,
    answerExplanationText: answerText,
    subtype: normalizedSubtype,
    items: items,
    errors: errors,
    warnings: warnings,
  );
}

class CheckLearningRawParseResult {
  const CheckLearningRawParseResult({
    required this.unitTitle,
    required this.rawA,
    required this.rawB,
    required this.rawC,
    required this.sectionA,
    required this.sectionB,
    required this.sectionC,
    required this.errors,
    required this.warnings,
  });

  final String unitTitle;
  final String rawA;
  final String rawB;
  final String rawC;
  final Map<String, dynamic> sectionA;
  final Map<String, dynamic> sectionB;
  final Map<String, dynamic> sectionC;
  final List<String> errors;
  final List<String> warnings;

  bool get hasSections =>
      (sectionB['word_bank'] as List?)?.isNotEmpty == true ||
      (sectionB['passage_text'] ?? '').toString().trim().isNotEmpty ||
      (sectionB['answers'] as List?)?.isNotEmpty == true;

  Map<String, dynamic> toAnswerJson() {
    return {
      if (unitTitle.trim().isNotEmpty) 'unit_title': unitTitle.trim(),
      'raw_text': [
        if (rawA.trim().isNotEmpty) '보기\n$rawA',
        if (rawB.trim().isNotEmpty) '본문\n$rawB',
        if (rawC.trim().isNotEmpty) '정답\n$rawC',
      ].join('\n\n'),
      'section_b': sectionB,
    };
  }
}

CheckLearningRawParseResult parseCheckLearningRawText(
  String rawText, {
  String unitTitle = '',
  String? sectionBText,
  String? sectionCText,
}) {
  return parseCheckLearningWordBankBlank(
    unitTitle: unitTitle,
    chunkText: [rawText, sectionBText ?? '', sectionCText ?? '']
        .where((text) => text.trim().isNotEmpty)
        .join('\n\n'),
  );
}

CheckLearningRawParseResult buildCheckLearningSetJson({
  required String unitTitle,
  required String sectionAText,
  required String sectionBText,
  required String sectionCText,
}) {
  return parseCheckLearningWordBankBlank(
    unitTitle: unitTitle,
    wordBankText: sectionAText,
    passageText: sectionBText,
    answerText: sectionCText,
  );
}

CheckLearningRawParseResult parseCheckLearningWordBankBlank({
  required String unitTitle,
  String wordBankText = '',
  String passageText = '',
  String answerText = '',
  String explanationText = '',
  String chunkText = '',
}) {
  final errors = <String>[];
  final warnings = <String>[];
  final sectionB = chunkText.trim().isNotEmpty
      ? _parseCheckLearningBlank(chunkText, errors, warnings)
      : _buildCheckLearningBlankSection(
          wordBankText: wordBankText,
          passageText: passageText,
          answerText: answerText,
          explanationText: explanationText,
          errors: errors,
          warnings: warnings,
        );
  if ((sectionB['word_bank'] as List).isEmpty) {
    warnings.add('보기 개수가 0개입니다.');
  }
  if ((sectionB['blank_count'] as int? ?? 0) == 0) {
    warnings.add('빈칸이 없습니다.');
  }
  if ((sectionB['answers'] as List).isEmpty) {
    errors.add('확인학습 정답이 비어 있습니다.');
  }
  return CheckLearningRawParseResult(
    unitTitle: unitTitle,
    rawA: wordBankText,
    rawB: passageText,
    rawC: answerText,
    sectionA: const {'items': []},
    sectionB: sectionB,
    sectionC: const {'items': []},
    errors: errors,
    warnings: warnings,
  );
}

Map<String, dynamic> _parseCheckLearningBlank(
  String text,
  List<String> errors,
  List<String> warnings,
) {
  final answerPayload = _sectionAnswerPayload(text, 'B') ?? '';
  final answerParts = _splitTrailingParenthetical(answerPayload);
  final body = text
      .split(RegExp(r'\r?\n'))
      .where((line) => !_isSectionAnswerLine(line.trim(), 'B'))
      .join('\n')
      .trim();
  final explicitWordBankMatch = RegExp(
    r'(?:보기|word\s*bank)\s*[:：]?\s*([\s\S]*?)(?:\n\s*(?:본문|passage)\s*[:：]|\n\s*\[(?:정답|답)\]\s*B|$)',
    caseSensitive: false,
  ).firstMatch(body);
  final explicitPassageMatch = RegExp(
    r'(?:본문|passage)\s*[:：]?\s*([\s\S]*?)(?:\n\s*\[(?:정답|답)\]\s*B|$)',
    caseSensitive: false,
  ).firstMatch(body);

  var wordBankText = explicitWordBankMatch?.group(1) ?? '';
  var passage = (explicitPassageMatch?.group(1) ?? '').trim();
  if (explicitWordBankMatch == null && explicitPassageMatch == null) {
    final lines = body
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final passageStart = lines.indexWhere(_containsBlank);
    if (passageStart >= 0) {
      wordBankText = lines.take(passageStart).join('\n');
      passage = lines.skip(passageStart).join('\n').trim();
    } else {
      passage = body;
    }
  }

  return _buildCheckLearningBlankSection(
    wordBankText: wordBankText,
    passageText: passage,
    answerText: answerParts.value,
    explanationText: answerParts.note,
    errors: errors,
    warnings: warnings,
  );
}

Map<String, dynamic> _buildCheckLearningBlankSection({
  required String wordBankText,
  required String passageText,
  required String answerText,
  required String explanationText,
  required List<String> errors,
  required List<String> warnings,
}) {
  final wordBank = _splitLooseTokenList(wordBankText);
  final passage = passageText.trim();
  final normalizedAnswerText = _stripCheckLearningAnswerPrefix(answerText);
  final answerParts = _splitTrailingParenthetical(normalizedAnswerText);
  final answers = _splitLooseTokenList(answerParts.value);
  final note = [
    answerParts.note,
    explanationText.trim(),
  ].where((item) => item.isNotEmpty).join('\n');
  final explanations = _splitExplanations('', answers.length);
  final blankCount = RegExp(r'_{2,}|\[\s*\]').allMatches(passage).length;
  if ([wordBankText, passageText, answerText].join('\n').trim().isNotEmpty &&
      answers.isEmpty) {
    errors.add('확인학습 정답이 비어 있습니다.');
  }
  if (blankCount > 0 && answers.isNotEmpty && blankCount != answers.length) {
    warnings.add('정답 개수와 빈칸 수가 다릅니다.');
  }
  return {
    'title': 'B',
    'type': 'word_bank_blank',
    'instruction': '<보기>에서 알맞은 표현을 골라 빈칸을 완성하세요.',
    'word_bank': wordBank,
    'passage_text': passage,
    'blank_count': blankCount > 0 ? blankCount : answers.length,
    'answers': answers,
    'explanations': explanations,
    if (note.isNotEmpty) 'note': note,
  };
}

class _TextAndNote {
  const _TextAndNote(this.value, this.note);

  final String value;
  final String note;
}

bool _isSectionAnswerLine(String line, String section) {
  final escapedSection = RegExp.escape(section);
  return RegExp(
    '^\\s*\\[(?:정답|답)\\]\\s*(?:(?:$escapedSection|확인학습)\\s+)?',
    caseSensitive: false,
  ).hasMatch(line);
}

String? _sectionAnswerPayload(String text, String section) {
  final escapedSection = RegExp.escape(section);
  for (final line in text.split(RegExp(r'\r?\n'))) {
    final match = RegExp(
      '^\\s*\\[(?:정답|답)\\]\\s*(?:(?:$escapedSection|확인학습)\\s+)?(.*)\$',
      caseSensitive: false,
    ).firstMatch(line.trim());
    if (match != null) return (match.group(1) ?? '').trim();
  }
  return null;
}

String _stripCheckLearningAnswerPrefix(String text) {
  return text
      .replaceFirst(
        RegExp(
          r'^\s*\[(?:정답|답)\]\s*(?:B\b|확인학습)?\s*',
          caseSensitive: false,
        ),
        '',
      )
      .replaceFirst(
        RegExp(r'^\s*(?:정답|답)\s*[:：]?\s*', caseSensitive: false),
        '',
      )
      .trim();
}

bool _containsBlank(String line) {
  return RegExp(r'_{2,}|\[\s*\]').hasMatch(line);
}

_TextAndNote _splitTrailingParenthetical(String text) {
  final trimmed = text.trim();
  final match = RegExp(r'\(([^()]*)\)\s*$').firstMatch(trimmed);
  if (match == null) return _TextAndNote(trimmed, '');
  return _TextAndNote(
    trimmed.substring(0, match.start).trim(),
    (match.group(1) ?? '').trim(),
  );
}

List<String> _splitLooseTokenList(String text) {
  return text
      .replaceAll(RegExp(r'\s+'), ' ')
      .split(RegExp(r'[/, ]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

List<String> _splitExplanations(String text, int count) {
  final lines = text
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.isEmpty) return List.filled(count, '');
  if (lines.length == count) return lines;
  return [
    lines.join('\n'),
    for (var i = 1; i < count; i++) '',
  ];
}

class _InlineAnswerMatch {
  const _InlineAnswerMatch({required this.choice, required this.consumed});

  final String choice;
  final int consumed;
}

_InlineAnswerMatch? _matchAnswer(String text, List<String> choices) {
  final candidates = [...choices]..sort((a, b) => b.length.compareTo(a.length));
  final leading = RegExp(
        r'''^[\s,;:)\]"“”‘’']*''',
      ).firstMatch(text)?.group(0)?.length ??
      0;
  final target = text.substring(leading);
  final lower = target.toLowerCase();
  for (final choice in candidates) {
    final normalizedChoice = _cleanInlineChoice(choice);
    if (normalizedChoice.isEmpty ||
        !lower.startsWith(normalizedChoice.toLowerCase())) {
      continue;
    }
    final boundaryIndex = normalizedChoice.length;
    if (boundaryIndex < target.length &&
        RegExp(r'''[A-Za-z0-9_\-'’]''').hasMatch(target[boundaryIndex])) {
      continue;
    }
    var consumed = leading + boundaryIndex;
    while (consumed < text.length &&
        RegExp(r'''["”’']''').hasMatch(text[consumed])) {
      consumed++;
    }
    return _InlineAnswerMatch(choice: choice, consumed: consumed);
  }
  return null;
}

String _cleanInlineChoice(String value) {
  return value
      .trim()
      .replaceFirst(RegExp(r'''^[\s,.;:()\[\]"“”‘’']+'''), '')
      .replaceFirst(RegExp(r'''[\s,.;:()\[\]"“”‘’']+$'''), '')
      .trim();
}

Map<int, String> _parseNumberedBlocks(String text) {
  final blocks = <int, String>{};
  final matches = RegExp(
    r'(^|\n)\s*(\d+)[\.\)]\s*',
    multiLine: true,
  ).allMatches(text).toList();
  if (matches.isEmpty) return blocks;

  for (var i = 0; i < matches.length; i++) {
    final match = matches[i];
    final number = int.tryParse(match.group(2) ?? '') ?? i + 1;
    final start = match.end;
    final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
    final body = text.substring(start, end).trim();
    if (body.isNotEmpty) blocks[number] = body;
  }
  return blocks;
}

List<bool> _parseTrueFalseAnswers(String text) {
  final normalized =
      text.replaceAll(RegExp(r'[Oo○]'), 'T').replaceAll('×', 'F');
  final answerLine = RegExp(
    r'(정답|답|answer)\s*[:：]?\s*([TtFf\s,/\-]+)',
    caseSensitive: false,
  ).firstMatch(normalized);
  final target = answerLine?.group(2) ?? normalized;
  final compact = target.replaceAll(RegExp(r'[^TtFf]'), '');
  if (compact.isEmpty) return const [];
  return compact.split('').map((value) => value.toUpperCase() == 'T').toList();
}

Map<int, String> _parseExplanations(String text) {
  final explanationStart =
      RegExp(r'(해설|설명)\s*[:：]?', caseSensitive: false).firstMatch(text)?.end;
  final target =
      explanationStart == null ? text : text.substring(explanationStart);
  final blocks = _parseNumberedBlocks(target);
  return blocks.map((key, value) => MapEntry(key, value.trim()));
}

Map<String, dynamic> buildInitialBlankAnswerJson({
  required String passageText,
  required String answerText,
  String? unitTitle,
  String? note,
}) {
  final blankPattern = RegExp(r'\(([a-zA-Z])\)\s*([A-Za-z])_+');
  final answerPattern = RegExp(r'\(([a-zA-Z])\)\s*([A-Za-z]+)');
  final answerSource = _stripGenericAnswerPrefix(answerText);
  final answerMap = <String, String>{};
  for (final match in answerPattern.allMatches(answerSource)) {
    answerMap[(match.group(1) ?? '').toLowerCase()] = match.group(2) ?? '';
  }
  final items = <Map<String, dynamic>>[];
  for (final match in blankPattern.allMatches(passageText)) {
    final label = (match.group(1) ?? '').toLowerCase();
    if (label.isEmpty) continue;
    items.add({
      'label': label,
      'initial': match.group(2) ?? '',
      'answer': answerMap[label] ?? '',
    });
  }
  return {
    if ((unitTitle ?? '').trim().isNotEmpty) 'unit_title': unitTitle!.trim(),
    'instruction': '첫 글자를 참고하여 빈칸에 알맞은 단어를 쓰세요.',
    'passage_text': passageText.trim(),
    'items': items,
    if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
  };
}

Map<String, dynamic> buildSentenceInsertionAnswerJson({
  required String insertSentence,
  required String passageText,
  required String answerText,
  String? unitTitle,
  String? note,
}) {
  return {
    if ((unitTitle ?? '').trim().isNotEmpty) 'unit_title': unitTitle!.trim(),
    'instruction': '주어진 문장이 들어갈 가장 알맞은 곳을 고르세요.',
    'insert_sentence': insertSentence.trim(),
    'passage_text': passageText.trim(),
    'positions': _detectInsertionPositions(passageText),
    'answer': _normalizeInsertionAnswer(answerText),
    if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
  };
}

Map<String, dynamic> buildParagraphOrderAnswerJson({
  required String leadText,
  required String segmentA,
  required String segmentB,
  required String segmentC,
  required String answerText,
  String? unitTitle,
  String? note,
}) {
  return {
    if ((unitTitle ?? '').trim().isNotEmpty) 'unit_title': unitTitle!.trim(),
    'instruction': '글의 흐름에 맞게 (A), (B), (C)를 배열하세요.',
    'lead_text': leadText.trim(),
    'segments': [
      {'label': 'A', 'text': segmentA.trim()},
      {'label': 'B', 'text': segmentB.trim()},
      {'label': 'C', 'text': segmentC.trim()},
    ],
    'answer_order': _parseParagraphOrder(answerText),
    if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
  };
}

String _stripGenericAnswerPrefix(String text) {
  return text
      .replaceFirst(
        RegExp(r'^\s*\[(?:정답|답)\]\s*', caseSensitive: false),
        '',
      )
      .replaceFirst(
        RegExp(r'^\s*(?:정답|답)\s*[:：]?\s*', caseSensitive: false),
        '',
      )
      .trim();
}

List<String> _detectInsertionPositions(String passageText) {
  const circleMap = {'1': '①', '2': '②', '3': '③', '4': '④', '5': '⑤'};
  final positions = <String>[];
  for (final mark in circleMap.values) {
    if (passageText.contains(mark) || passageText.contains('($mark)')) {
      positions.add(mark);
    }
  }
  if (positions.isNotEmpty) return positions;
  for (final match
      in RegExp(r'\(([1-5])\)|(?:^|\s)([1-5])[\.\)]').allMatches(passageText)) {
    final number = match.group(1) ?? match.group(2);
    final mark = circleMap[number];
    if (mark != null && !positions.contains(mark)) positions.add(mark);
  }
  return positions.isEmpty ? circleMap.values.toList() : positions;
}

String _normalizeInsertionAnswer(String text) {
  final clean = _stripGenericAnswerPrefix(text);
  const circleMap = {'1': '①', '2': '②', '3': '③', '4': '④', '5': '⑤'};
  for (final mark in circleMap.values) {
    if (clean.contains(mark)) return mark;
  }
  final number = RegExp(r'[1-5]').firstMatch(clean)?.group(0);
  return circleMap[number] ?? clean.trim();
}

List<String> _parseParagraphOrder(String text) {
  final clean = _stripGenericAnswerPrefix(text).toUpperCase();
  return RegExp(r'[ABC]').allMatches(clean).map((m) => m.group(0)!).toList();
}
