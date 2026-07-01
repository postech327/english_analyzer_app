import '../models/workbook_import_candidate.dart';
import 'workbook_question_parser.dart';

List<WorkbookImportCandidate> parseWorkbookImportText(
  String rawText, {
  String workbookSource = '',
}) {
  return parseWorkbookImportTextDetailed(
    rawText,
    workbookSource: workbookSource,
  ).candidates;
}

class WorkbookImportParseResult {
  const WorkbookImportParseResult({
    required this.candidates,
    required this.omittedCount,
    required this.removedPreamble,
  });

  final List<WorkbookImportCandidate> candidates;
  final int omittedCount;
  final bool removedPreamble;
}

WorkbookImportParseResult parseWorkbookImportTextDetailed(
  String rawText, {
  String workbookSource = '',
}) {
  var normalized = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  var removedPreamble = false;
  if (!_hasExplicitTypeTag(normalized)) {
    final firstHeader = _importBlockHeaderPattern.firstMatch(normalized);
    if (firstHeader != null &&
        normalized.substring(0, firstHeader.start).trim().isNotEmpty) {
      normalized = normalized.substring(firstHeader.start);
      removedPreamble = true;
    }
  }
  final chunks = _splitImportChunks(normalized);
  final omittedCount = chunks.where(_isOmittedChunk).length;
  final includedChunks =
      chunks.where((chunk) => !_isOmittedChunk(chunk)).toList();
  final candidates = [
    for (var index = 0; index < includedChunks.length; index++)
      _parseCandidate(
        includedChunks[index],
        index: index,
        workbookSource: workbookSource,
      ),
  ];
  return WorkbookImportParseResult(
    candidates: candidates,
    omittedCount: omittedCount,
    removedPreamble: removedPreamble,
  );
}

bool _hasExplicitTypeTag(String text) {
  return RegExp(r'^\s*\[([^\]\n]+)\]\s*$', multiLine: true)
      .allMatches(text)
      .any((match) => _typeFromTag(match.group(1) ?? '') != null);
}

bool _isOmittedChunk(_ImportChunk chunk) {
  return RegExp(r'도표\s*생략').hasMatch(chunk.rawText);
}

class _ImportChunk {
  const _ImportChunk({required this.rawText, this.taggedType});

  final String rawText;
  final String? taggedType;
}

class _TagMatch {
  const _TagMatch({
    required this.start,
    required this.end,
    required this.type,
  });

  final int start;
  final int end;
  final String type;
}

List<_ImportChunk> _splitImportChunks(String rawText) {
  final normalized = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final matches = <_TagMatch>[];
  for (final match in RegExp(r'^\s*\[([^\]\n]+)\]\s*$', multiLine: true)
      .allMatches(normalized)) {
    final type = _typeFromTag(match.group(1) ?? '');
    if (type != null) {
      matches.add(_TagMatch(start: match.start, end: match.end, type: type));
    }
  }

  if (matches.isNotEmpty) {
    final chunks = <_ImportChunk>[];
    final preamble = _cleanChunk(normalized.substring(0, matches.first.start));
    if (preamble.isNotEmpty) chunks.add(_ImportChunk(rawText: preamble));
    for (var index = 0; index < matches.length; index++) {
      final match = matches[index];
      final end = index + 1 < matches.length
          ? matches[index + 1].start
          : normalized.length;
      final body = _cleanChunk(normalized.substring(match.end, end));
      if (body.isNotEmpty) {
        chunks.add(_ImportChunk(rawText: body, taggedType: match.type));
      }
    }
    return chunks;
  }

  final separated = normalized
      .split(RegExp(r'^\s*(?:---+|===+|###)\s*$', multiLine: true))
      .map(_cleanChunk)
      .where((text) => text.isNotEmpty)
      .toList();
  return [
    for (final text in separated)
      for (final unitBlock in _splitUnitBlocks(text))
        if (_detectType(unitBlock) == 'inline_choice')
          ..._splitInlineChoiceUnits(unitBlock)
        else
          _ImportChunk(rawText: unitBlock),
  ];
}

final RegExp _unitHeaderPattern = RegExp(
  r'^\s*(Unit\s+\d+\s+(?:Gateway|No\.?\s*\d+))(?=\s|$).*$',
  caseSensitive: false,
  multiLine: true,
);

final RegExp _testHeaderPattern = RegExp(
  r'^\s*Test\s+(\d+)\b.*$',
  caseSensitive: false,
  multiLine: true,
);

final RegExp _importBlockHeaderPattern = RegExp(
  r'^\s*(?:Unit\s+\d+\s+(?:Gateway|No\.?\s*\d+)(?=\s|$).*|Test\s+\d+\b.*)$',
  caseSensitive: false,
  multiLine: true,
);

List<String> _splitUnitBlocks(String text) {
  final matches = _importBlockHeaderPattern.allMatches(text).toList();
  if (matches.length < 2) return [text];
  return [
    for (var index = 0; index < matches.length; index++)
      text
          .substring(
            index == 0 ? 0 : matches[index].start,
            index + 1 < matches.length ? matches[index + 1].start : text.length,
          )
          .trim(),
  ].where((block) => block.isNotEmpty).toList();
}

List<_ImportChunk> _splitInlineChoiceUnits(String text) {
  final chunks = <_ImportChunk>[];
  final body = <String>[];
  String? unitHeader;

  void flush() {
    final value = body.join('\n').trim();
    if (value.isNotEmpty && _detectType(value) == 'inline_choice') {
      chunks.add(_ImportChunk(rawText: value));
    }
    body.clear();
  }

  for (final rawLine in text.split('\n')) {
    final line = rawLine.trim();
    final headerTitle = _importHeaderTitle(line);
    if (headerTitle != null) {
      flush();
      unitHeader = headerTitle;
      body.add(headerTitle);
      continue;
    }
    if (_isQuestionNumberHeader(line)) {
      flush();
      if (unitHeader != null) body.add(unitHeader);
      body.add(line);
      continue;
    }
    body.add(rawLine);
  }
  flush();
  return chunks.isEmpty ? [_ImportChunk(rawText: text)] : chunks;
}

String? _unitTitle(String text) =>
    _unitHeaderPattern.firstMatch(text)?.group(1)?.trim();

String? _testTitle(String text) {
  final number = _testHeaderPattern.firstMatch(text)?.group(1);
  return number == null ? null : 'Test $number';
}

String? _importHeaderTitle(String text) => _unitTitle(text) ?? _testTitle(text);

bool _isQuestionNumberHeader(String line) {
  return RegExp(r'^\d+\s*(?:번|[.)])$').hasMatch(line);
}

String _cleanChunk(String value) {
  return value
      .replaceAll(
        RegExp(r'^\s*(?:---+|===+|###)\s*$', multiLine: true),
        '',
      )
      .trim();
}

String? _typeFromTag(String value) {
  final tag = value
      .toLowerCase()
      .replaceAll(RegExp(r'[\s/_-]+'), '')
      .replaceAll('.', '');
  return switch (tag) {
    '본문선택형' || '선택형' => 'inline_choice',
    '확인학습' => 'check_learning_set',
    '영어tf' => 'true_false_en',
    '한글tf' => 'true_false_ko',
    '첫글자빈칸' => 'initial_blank',
    '문장삽입' => 'sentence_insertion',
    '문단배열' => 'paragraph_order',
    _ => null,
  };
}

String _detectType(String rawText) {
  if (RegExp(r'\[\[\s*\d+\s*:.*?\|.*?\]\]|\[[^\]\n]+/[^\]\n]+\]')
      .hasMatch(rawText)) {
    return 'inline_choice';
  }
  if (_looksLikeInitialBlank(rawText)) return 'initial_blank';
  final trueFalseSubtype = _detectTrueFalseSubtype(rawText);
  if (trueFalseSubtype != null) return trueFalseSubtype;
  if (_looksLikeParagraphOrder(rawText)) return 'paragraph_order';
  if (_looksLikeSentenceInsertion(rawText)) return 'sentence_insertion';
  if (RegExp(r'삽입할\s*문장\s*[:：]').hasMatch(rawText) &&
      RegExp(r'[①②③④⑤]').hasMatch(rawText)) {
    return 'sentence_insertion';
  }
  if (RegExp(r'^\s*[ABC]\s*[:：]', multiLine: true).allMatches(rawText).length >=
      3) {
    return 'paragraph_order';
  }
  if (RegExp(r'\[\s*T\s*/\s*F\s*\]', caseSensitive: false).hasMatch(rawText)) {
    final statements = _sections(rawText)['문항'] ?? rawText;
    return RegExp(r'[가-힣]').hasMatch(statements)
        ? 'true_false_ko'
        : 'true_false_en';
  }
  if (RegExp(r'_{3,}').hasMatch(rawText) &&
      RegExp(r'(보기|word\s*bank)\s*[:：]', caseSensitive: false)
          .hasMatch(rawText)) {
    return 'check_learning_set';
  }
  return 'unknown';
}

final RegExp _initialBlankPattern = RegExp(
  r'(?:\(([a-zA-Z])\)\s*)?([A-Za-z])_{3,}',
);

bool _looksLikeInitialBlank(String rawText) {
  final hasWordBank = RegExp(
    r'(보기|word\s*bank)\s*[:：]',
    caseSensitive: false,
  ).hasMatch(rawText);
  return !hasWordBank && _initialBlankPattern.allMatches(rawText).length >= 2;
}

bool _looksLikeParagraphOrder(String rawText) {
  return const ['A', 'B', 'C'].every(
    (label) => RegExp('\\($label\\)\\s*').hasMatch(rawText),
  );
}

bool _looksLikeSentenceInsertion(String rawText) {
  if (_looksLikeParagraphOrder(rawText)) return false;
  final positions = RegExp(r'[①②③④⑤]').allMatches(rawText).length;
  return positions >= 2 &&
      RegExp(r'[①②③④⑤1-5]').hasMatch(_importAnswerPayload(rawText));
}

String _importAnswerPayload(String rawText) {
  return RegExp(
        r'\[(?:정답|답)\]\s*:?[ \t]*([^\n]*)',
        caseSensitive: false,
      ).firstMatch(rawText)?.group(1)?.trim() ??
      RegExp(
        r'^\s*(?:정답|답)\s*[:：]\s*([^\n]*)$',
        caseSensitive: false,
        multiLine: true,
      ).firstMatch(rawText)?.group(1)?.trim() ??
      '';
}

String? _detectTrueFalseSubtype(String rawText) {
  final answerMatch = RegExp(
    r'^\s*\[(?:정답|답)\]\s*:?[ \t]*([^\n]*)$',
    caseSensitive: false,
    multiLine: true,
  ).firstMatch(rawText);
  if (answerMatch == null) return null;
  final compactAnswers =
      (answerMatch.group(1) ?? '').replaceAll(RegExp(r'[^TtFfOo○×]'), '');
  if (compactAnswers.length < 2) return null;

  final beforeAnswers = rawText.substring(0, answerMatch.start);
  final statements = _numberedStatementMatches(beforeAnswers);
  if (statements.length < 2) return null;
  final statementText =
      statements.map((match) => match.group(1) ?? '').join(' ');
  final koreanCount = RegExp(r'[가-힣]').allMatches(statementText).length;
  final englishCount = RegExp(r'[A-Za-z]').allMatches(statementText).length;
  return koreanCount > englishCount ? 'true_false_ko' : 'true_false_en';
}

List<RegExpMatch> _numberedStatementMatches(String text) {
  return RegExp(
    r'^\s*\d+\s*[.)]\s*(.+)$',
    multiLine: true,
  ).allMatches(text).toList();
}

WorkbookImportCandidate _parseCandidate(
  _ImportChunk chunk, {
  required int index,
  required String workbookSource,
}) {
  final detectedType = chunk.taggedType ?? _detectType(chunk.rawText);
  final localId = 'import-${index + 1}';
  final sections = _sections(chunk.rawText);
  return switch (detectedType) {
    'inline_choice' => _inlineChoiceCandidate(
        localId,
        chunk.rawText,
        workbookSource,
      ),
    'check_learning_set' => _checkLearningCandidate(
        localId,
        chunk.rawText,
        sections,
        workbookSource,
      ),
    'true_false_en' || 'true_false_ko' => _trueFalseCandidate(
        localId,
        chunk.rawText,
        sections,
        detectedType,
        workbookSource,
      ),
    'initial_blank' => _initialBlankCandidate(
        localId,
        chunk.rawText,
        sections,
        workbookSource,
      ),
    'sentence_insertion' => _sentenceInsertionCandidate(
        localId,
        chunk.rawText,
        sections,
        workbookSource,
      ),
    'paragraph_order' => _paragraphOrderCandidate(
        localId,
        chunk.rawText,
        sections,
        workbookSource,
      ),
    _ => _unknownCandidate(localId, chunk.rawText),
  };
}

WorkbookImportCandidate _inlineChoiceCandidate(
  String id,
  String rawText,
  String source,
) {
  final metadata = _inlineChoiceMetadata(rawText, id);
  final parsed = parseInlineChoiceRawText(
    metadata.body,
    explanationText: metadata.explanationText,
  );
  final explanationCount = parsed.items
      .where((item) => (item.explanation ?? '').trim().isNotEmpty)
      .length;
  final errors = [...parsed.errors];
  if (parsed.items.isEmpty && errors.isEmpty) {
    errors.add('선택 항목을 찾지 못했습니다.');
  }
  final warnings = [...parsed.warnings];
  if (parsed.items.length >= 50) {
    warnings.add('선택 항목이 50개 이상입니다. 후보 분리가 필요할 수 있습니다.');
  }
  final cleanup = cleanStudentPassageText(
    parsed.passageText,
    parsed.items.map((item) => item.answer),
  );
  final answer = parsed.toAnswerJson(unitTitle: source)
    ..['passage_text'] = cleanup.cleanedText;
  return WorkbookImportCandidate(
    localId: id,
    detectedType: 'inline_choice',
    questionType: 'inline_choice',
    typeLabel: '본문 선택형',
    title: metadata.title,
    prompt: '본문에서 알맞은 표현을 고르세요.',
    passageText: cleanup.cleanedText,
    answer: answer,
    rawText: rawText,
    summary: '선택 항목 ${parsed.items.length}개 · 해설 $explanationCount개',
    errors: errors,
    warnings: warnings,
    infoMessages: [
      if (cleanup.removedLineCount > 0)
        '본문 뒤 정답/해설 추정 ${cleanup.removedLineCount}줄을 학생용 본문에서 제외했습니다.',
    ],
  );
}

class StudentPassageCleanupResult {
  const StudentPassageCleanupResult({
    required this.cleanedText,
    required this.removedLineCount,
  });

  final String cleanedText;
  final int removedLineCount;
}

StudentPassageCleanupResult cleanStudentPassageText(
  String passageText,
  Iterable<String> parsedAnswers,
) {
  final answers = parsedAnswers
      .map(_normalizeAnswerNote)
      .where((answer) => answer.isNotEmpty)
      .toSet();
  if (answers.isEmpty || passageText.trim().isEmpty) {
    return StudentPassageCleanupResult(
      cleanedText: passageText.trim(),
      removedLineCount: 0,
    );
  }

  final lines = passageText.split(RegExp(r'\r?\n'));
  var cursor = lines.length - 1;
  var matchedLines = 0;
  var cutIndex = lines.length;
  while (cursor >= 0) {
    final line = lines[cursor].trim();
    if (line.isEmpty) {
      if (matchedLines > 0) cutIndex = cursor;
      cursor--;
      continue;
    }
    if (!_isTrailingAnswerNote(line, answers)) break;
    matchedLines++;
    cutIndex = cursor;
    cursor--;
  }

  if (matchedLines < 2) {
    return StudentPassageCleanupResult(
      cleanedText: passageText.trim(),
      removedLineCount: 0,
    );
  }
  final cleaned = lines.take(cutIndex).join('\n').trim();
  if (cleaned.length < 40) {
    return StudentPassageCleanupResult(
      cleanedText: passageText.trim(),
      removedLineCount: 0,
    );
  }
  return StudentPassageCleanupResult(
    cleanedText: cleaned,
    removedLineCount: matchedLines,
  );
}

bool _isTrailingAnswerNote(String line, Set<String> answers) {
  final withoutPrefix = line.replaceFirst(
    RegExp(r'^\s*(?:[-•·]\s*|\d+\s*[.)]\s*)'),
    '',
  );
  final parenthesisIndex = withoutPrefix.indexOf('(');
  final answerPart = parenthesisIndex >= 0
      ? withoutPrefix.substring(0, parenthesisIndex)
      : withoutPrefix;
  return answers.contains(_normalizeAnswerNote(answerPart));
}

String _normalizeAnswerNote(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9가-힣]+'), '');
}

class _InlineChoiceMetadata {
  const _InlineChoiceMetadata({
    required this.title,
    required this.body,
    required this.explanationText,
  });

  final String title;
  final String body;
  final String explanationText;
}

_InlineChoiceMetadata _inlineChoiceMetadata(String rawText, String id) {
  String? unit;
  String? number;
  final body = <String>[];
  final explanations = <String>[];
  for (final rawLine in rawText.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    final headerTitle = _importHeaderTitle(line);
    if (unit == null && headerTitle != null) {
      unit = headerTitle;
      continue;
    }
    if (number == null && _isQuestionNumberHeader(line)) {
      final digits = RegExp(r'\d+').firstMatch(line)?.group(0) ?? '';
      number = digits.isEmpty ? line : '$digits번';
      continue;
    }
    if (RegExp(r'^\d{3,}\s*[.)]\s+.+$').hasMatch(line) &&
        !RegExp(r'\[[^\]\n]+[/|][^\]\n]+\]').hasMatch(line)) {
      explanations.add(line);
      continue;
    }
    body.add(rawLine);
  }
  final titleParts = [
    if ((unit ?? '').isNotEmpty) unit!,
    if ((number ?? '').isNotEmpty) number!,
  ];
  final fallbackNumber = RegExp(r'\d+$').firstMatch(id)?.group(0) ?? '';
  return _InlineChoiceMetadata(
    title: titleParts.isEmpty
        ? '본문 선택형 ${fallbackNumber.isEmpty ? '' : fallbackNumber}'.trim()
        : titleParts.join(' '),
    body: body.join('\n').trim(),
    explanationText: explanations.join('\n'),
  );
}

WorkbookImportCandidate _checkLearningCandidate(
  String id,
  String rawText,
  Map<String, String> sections,
  String source,
) {
  final parsed = parseCheckLearningWordBankBlank(
    unitTitle: source,
    wordBankText: sections['보기'] ?? '',
    passageText: sections['본문'] ?? '',
    answerText: sections['정답'] ?? '',
  );
  final section = parsed.sectionB;
  final bankCount = (section['word_bank'] as List?)?.length ?? 0;
  final blankCount = section['blank_count'] as int? ?? 0;
  final answerCount = (section['answers'] as List?)?.length ?? 0;
  final cleanup = cleanStudentPassageText(
    (section['passage_text'] ?? '').toString(),
    ((section['answers'] as List?) ?? const []).map((value) => '$value'),
  );
  final answer = parsed.toAnswerJson();
  final answerSection = answer['section_b'];
  if (answerSection is Map<String, dynamic>) {
    answerSection['passage_text'] = cleanup.cleanedText;
  }
  return WorkbookImportCandidate(
    localId: id,
    detectedType: 'check_learning_set',
    questionType: 'check_learning_set',
    typeLabel: '확인학습',
    title: '확인학습',
    prompt: '확인학습',
    passageText: cleanup.cleanedText,
    answer: answer,
    rawText: rawText,
    summary: '보기 $bankCount개 · 빈칸 $blankCount개 · 정답 $answerCount개',
    errors: parsed.errors,
    warnings: parsed.warnings,
    infoMessages: [
      if (cleanup.removedLineCount > 0)
        '본문 뒤 정답/해설 추정 ${cleanup.removedLineCount}줄을 학생용 본문에서 제외했습니다.',
    ],
  );
}

WorkbookImportCandidate _trueFalseCandidate(
  String id,
  String rawText,
  Map<String, String> sections,
  String subtype,
  String source,
) {
  final imported = _parseTrueFalseImport(rawText);
  final statementText =
      (sections['문항'] ?? imported.statementText ?? rawText).replaceAll(
    RegExp(r'\[\s*T\s*/\s*F\s*\]', caseSensitive: false),
    '',
  );
  final passage = sections['본문'] ?? imported.passageText ?? '';
  final answerExplanationText =
      sections['정답'] ?? imported.answerExplanationText ?? '';
  final parsed = parseTrueFalseRawText(
    statementText,
    subtype,
    answerExplanationText: answerExplanationText,
  );
  final label = subtype == 'true_false_ko' ? '한글 T/F' : '영어 T/F';
  final answerCount = parsed.items.where((item) => item.answer != null).length;
  return WorkbookImportCandidate(
    localId: id,
    detectedType: subtype,
    questionType: 'true_false',
    subtype: subtype,
    typeLabel: label,
    title: imported.title ?? label,
    prompt: subtype == 'true_false_ko'
        ? '한글 진술문이 본문과 일치하면 T, 일치하지 않으면 F를 고르세요.'
        : '영어 진술문이 본문과 일치하면 T, 일치하지 않으면 F를 고르세요.',
    passageText: passage,
    answer: parsed.toAnswerJson(
      unitTitle: source,
      sourceLabel: source,
      passageText: passage,
    ),
    rawText: rawText,
    summary: 'T/F 문항 ${parsed.items.length}개 · 정답 $answerCount개',
    errors: parsed.errors,
    warnings: parsed.warnings,
  );
}

class _TrueFalseImportData {
  const _TrueFalseImportData({
    this.title,
    this.passageText,
    this.statementText,
    this.answerExplanationText,
  });

  final String? title;
  final String? passageText;
  final String? statementText;
  final String? answerExplanationText;
}

_TrueFalseImportData _parseTrueFalseImport(String rawText) {
  final answerMarker = RegExp(
    r'^\s*\[(?:정답|답)\]\s*:?[ \t]*([^\n]*)$',
    caseSensitive: false,
    multiLine: true,
  ).firstMatch(rawText);
  if (answerMarker == null) return const _TrueFalseImportData();

  final explanationMarker = RegExp(
    r'^\s*\[해설\]\s*:?[ \t]*(.*)$',
    multiLine: true,
  ).firstMatch(rawText);
  final translationMarker = RegExp(
    r'^\s*\[해석\]\s*:?[ \t]*(.*)$',
    multiLine: true,
  ).firstMatch(rawText);
  final beforeAnswers = rawText.substring(0, answerMarker.start).trim();
  final statementMatches = _numberedStatementMatches(beforeAnswers);
  if (statementMatches.isEmpty) return const _TrueFalseImportData();

  final firstStatementStart = statementMatches.first.start;
  final headerAndPassage = beforeAnswers.substring(0, firstStatementStart);
  final unitMatch = _unitHeaderPattern.firstMatch(headerAndPassage);
  final passage =
      headerAndPassage.replaceFirst(unitMatch?.group(0) ?? '', '').trim();
  final statements = beforeAnswers.substring(firstStatementStart).trim();
  final answerPayload = (answerMarker.group(1) ?? '').trim();

  String explanationText = '';
  if (explanationMarker != null) {
    final end = translationMarker != null &&
            translationMarker.start > explanationMarker.start
        ? translationMarker.start
        : rawText.length;
    final sameLine = (explanationMarker.group(1) ?? '').trim();
    final following = rawText.substring(explanationMarker.end, end).trim();
    explanationText =
        [sameLine, following].where((value) => value.isNotEmpty).join('\n');
  }
  final canonicalAnswerText = [
    '정답: $answerPayload',
    if (explanationText.isNotEmpty) '해설:\n$explanationText',
  ].join('\n');

  return _TrueFalseImportData(
    title: unitMatch?.group(1)?.trim(),
    passageText: passage,
    statementText: statements,
    answerExplanationText: canonicalAnswerText,
  );
}

WorkbookImportCandidate _initialBlankCandidate(
  String id,
  String rawText,
  Map<String, String> sections,
  String source,
) {
  final passage = sections['본문'] ?? rawText;
  final imported =
      sections.isEmpty ? _parseImportedInitialBlank(rawText) : null;
  final answer = imported == null
      ? buildInitialBlankAnswerJson(
          unitTitle: source,
          passageText: passage,
          answerText: sections['정답'] ?? '',
        )
      : imported.toAnswerJson(
          unitTitle: source.isNotEmpty ? source : imported.title,
        );
  final items = (answer['items'] as List?)?.whereType<Map>().toList() ?? [];
  final cleanup = cleanStudentPassageText(
    (answer['passage_text'] ?? passage).toString(),
    items.map((item) => (item['answer'] ?? '').toString()),
  );
  answer['passage_text'] = cleanup.cleanedText;
  final missing =
      items.where((item) => (item['answer'] ?? '').toString().isEmpty).length;
  final errors = <String>[
    if (items.isEmpty) '첫 글자 빈칸을 찾지 못했습니다.',
    if (missing > 0) '$missing개 빈칸의 정답을 찾지 못했습니다.',
  ];
  return WorkbookImportCandidate(
    localId: id,
    detectedType: 'initial_blank',
    questionType: 'initial_blank',
    typeLabel: '첫 글자 빈칸',
    title: imported?.title ?? '첫 글자 빈칸',
    prompt: '첫 글자를 참고하여 빈칸에 알맞은 단어를 쓰세요.',
    passageText: cleanup.cleanedText,
    answer: answer,
    rawText: rawText,
    summary: '빈칸 ${items.length}개 · 정답 ${items.length - missing}개',
    errors: errors,
    infoMessages: [
      if (cleanup.removedLineCount > 0)
        '본문 뒤 정답/해설 추정 ${cleanup.removedLineCount}줄을 학생용 본문에서 제외했습니다.',
    ],
  );
}

class _InitialBlankImportData {
  const _InitialBlankImportData({
    required this.title,
    required this.passageText,
    required this.items,
  });

  final String title;
  final String passageText;
  final List<Map<String, dynamic>> items;

  Map<String, dynamic> toAnswerJson({String? unitTitle}) {
    return {
      if ((unitTitle ?? '').trim().isNotEmpty) 'unit_title': unitTitle!.trim(),
      'instruction': '첫 글자를 참고하여 빈칸에 알맞은 단어를 쓰세요.',
      'passage_text': passageText,
      'items': items,
    };
  }
}

_InitialBlankImportData? _parseImportedInitialBlank(String rawText) {
  if (_initialBlankPattern.allMatches(rawText).length < 2) return null;

  final explicitAnswers = <String, String>{};
  final orderedAnswers = <String>[];
  final answerMarkers = RegExp(
    r'\[(?:정답|답)\]\s*:?[ \t]*([^\n]*)',
    caseSensitive: false,
  ).allMatches(rawText);
  for (final marker in answerMarkers) {
    final payload = marker.group(1) ?? '';
    final labeledAnswers = RegExp(
      r"\(([a-zA-Z])\)\s*([A-Za-z][A-Za-z'’\-]*)",
    ).allMatches(payload).toList();
    if (labeledAnswers.isNotEmpty) {
      for (final match in labeledAnswers) {
        final label = (match.group(1) ?? '').toLowerCase();
        final value = match.group(2) ?? '';
        if (label.isNotEmpty && value.isNotEmpty) {
          explicitAnswers[label] = value;
          orderedAnswers.add(value);
        }
      }
    } else {
      orderedAnswers.addAll(
        payload
            .split(RegExp(r'[,/\s]+'))
            .map((value) => value.trim())
            .where((value) => RegExp(
                  r"^[A-Za-z][A-Za-z'’\-]*$",
                ).hasMatch(value)),
      );
    }
  }

  final content = rawText
      .split(RegExp(r'\r?\n'))
      .where((line) => !_unitHeaderPattern.hasMatch(line))
      .map(
        (line) => line.replaceFirst(
          RegExp(r'\[(?:정답|답)\].*$', caseSensitive: false),
          '',
        ),
      )
      .where((line) => line.trim().isNotEmpty)
      .join('\n')
      .trim();
  final matches = _initialBlankPattern.allMatches(content).toList();
  final items = <Map<String, dynamic>>[];
  final output = StringBuffer();
  var cursor = 0;

  for (var index = 0; index < matches.length; index++) {
    final match = matches[index];
    output.write(content.substring(cursor, match.start));
    final explicitLabel = (match.group(1) ?? '').toLowerCase();
    final label = explicitLabel.isNotEmpty ? explicitLabel : _blankLabel(index);
    final initial = match.group(2) ?? '';
    final underscoreCount = RegExp('_').allMatches(match.group(0) ?? '').length;
    final underscores = List.filled(underscoreCount, '_').join();
    output.write('($label) $initial$underscores');

    final tail = content.substring(match.end);
    final answerMatch = RegExp(r"^\s+([A-Za-z][A-Za-z'’\-]*)").firstMatch(tail);
    final candidate = answerMatch?.group(1) ?? '';
    final hasMatchingInitial = candidate.isNotEmpty &&
        candidate[0].toLowerCase() == initial.toLowerCase();
    final mappedAnswer = explicitAnswers[label] ??
        (index < orderedAnswers.length ? orderedAnswers[index] : '');
    final answer = mappedAnswer.isNotEmpty
        ? mappedAnswer
        : hasMatchingInitial
            ? candidate
            : '';
    items.add({
      'label': label,
      'initial': initial,
      'answer': answer,
    });
    cursor = mappedAnswer.isEmpty && hasMatchingInitial
        ? match.end + (answerMatch?.end ?? 0)
        : match.end;
  }
  output.write(content.substring(cursor));

  return _InitialBlankImportData(
    title: _unitTitle(rawText) ?? '첫 글자 빈칸',
    passageText: output.toString().replaceAll(RegExp(r'[ \t]+'), ' ').trim(),
    items: items,
  );
}

String _blankLabel(int index) {
  if (index < 26) return String.fromCharCode('a'.codeUnitAt(0) + index);
  return '${index + 1}';
}

WorkbookImportCandidate _sentenceInsertionCandidate(
  String id,
  String rawText,
  Map<String, String> sections,
  String source,
) {
  final imported =
      sections.isEmpty ? _parseSentenceInsertionImport(rawText) : null;
  final sentence = sections['삽입할 문장'] ?? imported?.sentence ?? '';
  final passage = sections['본문'] ?? imported?.passage ?? '';
  final answerText = sections['정답'] ?? imported?.answer ?? '';
  final answer = buildSentenceInsertionAnswerJson(
    unitTitle: source.isNotEmpty ? source : imported?.title,
    insertSentence: sentence,
    passageText: passage,
    answerText: answerText,
  );
  final positions = (answer['positions'] as List?) ?? const [];
  final answerValue = (answer['answer'] ?? '').toString();
  return WorkbookImportCandidate(
    localId: id,
    detectedType: 'sentence_insertion',
    questionType: 'sentence_insertion',
    typeLabel: '문장 삽입',
    title: imported?.title ?? '문장 삽입',
    prompt: '주어진 문장이 들어갈 가장 알맞은 곳을 고르세요.',
    passageText: passage,
    answer: answer,
    rawText: rawText,
    summary:
        '위치 ${positions.length}개 · 정답 ${answerValue.isEmpty ? '없음' : answerValue}',
    errors: [
      if (sentence.isEmpty) '삽입할 문장을 찾지 못했습니다.',
      if (positions.length < 2) '문장 삽입 위치를 2개 이상 찾지 못했습니다.',
      if (answerValue.isEmpty) '문장 삽입 정답을 찾지 못했습니다.',
    ],
  );
}

class _SentenceInsertionImportData {
  const _SentenceInsertionImportData({
    required this.title,
    required this.sentence,
    required this.passage,
    required this.answer,
  });

  final String title;
  final String sentence;
  final String passage;
  final String answer;
}

_SentenceInsertionImportData? _parseSentenceInsertionImport(String rawText) {
  final body = _stripImportHeaderAndAnswer(rawText);
  final paragraphs = body
      .split(RegExp(r'\n\s*\n'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
  var passageIndex = paragraphs.indexWhere(
    (value) => RegExp(r'[①②③④⑤]').hasMatch(value),
  );
  if (passageIndex <= 0) {
    final lines = body
        .split(RegExp(r'\r?\n'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    passageIndex = lines.indexWhere(
      (value) => RegExp(r'[①②③④⑤]').hasMatch(value),
    );
    if (passageIndex <= 0) return null;
    return _SentenceInsertionImportData(
      title: _unitTitle(rawText) ?? '문장 삽입',
      sentence: lines.take(passageIndex).join(' '),
      passage: lines.skip(passageIndex).join(' '),
      answer: _importAnswerPayload(rawText),
    );
  }
  return _SentenceInsertionImportData(
    title: _unitTitle(rawText) ?? '문장 삽입',
    sentence: paragraphs.take(passageIndex).join('\n\n'),
    passage: paragraphs.skip(passageIndex).join('\n\n'),
    answer: _importAnswerPayload(rawText),
  );
}

String _stripImportHeaderAndAnswer(String rawText) {
  return rawText
      .split(RegExp(r'\r?\n'))
      .where((line) => !_unitHeaderPattern.hasMatch(line))
      .map(
        (line) => line
            .replaceFirst(
              RegExp(r'\[(?:정답|답)\].*$', caseSensitive: false),
              '',
            )
            .replaceFirst(
              RegExp(r'^\s*(?:정답|답)\s*[:：].*$', caseSensitive: false),
              '',
            ),
      )
      .join('\n')
      .trim();
}

WorkbookImportCandidate _paragraphOrderCandidate(
  String id,
  String rawText,
  Map<String, String> sections,
  String source,
) {
  final imported =
      sections.isEmpty ? _parseParagraphOrderImport(rawText) : null;
  final answer = buildParagraphOrderAnswerJson(
    unitTitle: source.isNotEmpty ? source : imported?.title,
    leadText: sections['제시문'] ?? imported?.lead ?? '',
    segmentA: sections['A'] ?? imported?.segments['A'] ?? '',
    segmentB: sections['B'] ?? imported?.segments['B'] ?? '',
    segmentC: sections['C'] ?? imported?.segments['C'] ?? '',
    answerText: sections['정답'] ?? imported?.answer ?? '',
  );
  final segments =
      (answer['segments'] as List?)?.whereType<Map>().toList() ?? [];
  final completeSegments = segments
      .where((segment) => (segment['text'] ?? '').toString().trim().isNotEmpty)
      .length;
  final order = (answer['answer_order'] as List?) ?? const [];
  return WorkbookImportCandidate(
    localId: id,
    detectedType: 'paragraph_order',
    questionType: 'paragraph_order',
    typeLabel: '문단 배열',
    title: imported?.title ?? '문단 배열',
    prompt: '글의 흐름에 맞게 (A), (B), (C)를 배열하세요.',
    passageText: sections['제시문'] ?? imported?.lead,
    answer: answer,
    rawText: rawText,
    summary: '문단 $completeSegments개 · 정답 ${order.join('-')}',
    errors: [
      if (completeSegments != 3) 'A, B, C 문단을 모두 찾지 못했습니다.',
      if (order.length != 3 || order.toSet().length != 3)
        '문단 배열 정답 순서를 찾지 못했습니다.',
    ],
  );
}

class _ParagraphOrderImportData {
  const _ParagraphOrderImportData({
    required this.title,
    required this.lead,
    required this.segments,
    required this.answer,
  });

  final String title;
  final String lead;
  final Map<String, String> segments;
  final String answer;
}

_ParagraphOrderImportData? _parseParagraphOrderImport(String rawText) {
  final body = _stripImportHeaderAndAnswer(rawText);
  final markers = RegExp(r'\(([ABC])\)\s*').allMatches(body).toList();
  if (markers.isEmpty) return null;

  final segments = <String, String>{};
  for (var index = 0; index < markers.length; index++) {
    final marker = markers[index];
    final label = marker.group(1) ?? '';
    final end =
        index + 1 < markers.length ? markers[index + 1].start : body.length;
    if (label.isNotEmpty) {
      segments[label] = body.substring(marker.end, end).trim();
    }
  }
  return _ParagraphOrderImportData(
    title: _unitTitle(rawText) ?? '문단 배열',
    lead: body.substring(0, markers.first.start).trim(),
    segments: segments,
    answer: _importAnswerPayload(rawText),
  );
}

WorkbookImportCandidate _unknownCandidate(String id, String rawText) {
  return WorkbookImportCandidate(
    localId: id,
    detectedType: 'unknown',
    questionType: 'unknown',
    typeLabel: '유형 미확인',
    title: '유형을 인식하지 못했습니다.',
    prompt: '',
    answer: const {},
    rawText: rawText,
    summary: '수동 문제 추가에서 유형을 선택해 입력해 주세요.',
    errors: const ['유형을 인식하지 못했습니다.'],
  );
}

Map<String, String> _sections(String rawText) {
  const aliases = {
    '보기': '보기',
    '본문': '본문',
    '문항': '문항',
    '정답': '정답',
    '답': '정답',
    '삽입할문장': '삽입할 문장',
    '제시문': '제시문',
    'a': 'A',
    'b': 'B',
    'c': 'C',
  };
  final result = <String, String>{};
  String? current;
  final buffer = StringBuffer();

  void save() {
    if (current == null) return;
    result[current] = buffer.toString().trim();
    buffer.clear();
  }

  final labelPattern = RegExp(
    r'^\s*\[?\s*(보기|본문|문항|정답|답|삽입할\s*문장|제시문|A|B|C)\s*\]?\s*[:：]\s*(.*)$',
    caseSensitive: false,
  );
  for (final line in rawText.split(RegExp(r'\r?\n'))) {
    final match = labelPattern.firstMatch(line);
    if (match != null) {
      save();
      final normalized =
          (match.group(1) ?? '').toLowerCase().replaceAll(RegExp(r'\s+'), '');
      current = aliases[normalized];
      final sameLine = (match.group(2) ?? '').trim();
      if (sameLine.isNotEmpty) buffer.writeln(sameLine);
      continue;
    }
    if (current != null) buffer.writeln(line);
  }
  save();
  return result;
}
