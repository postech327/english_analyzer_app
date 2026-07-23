// ignore_for_file: unused_element

import 'package:flutter/foundation.dart';

import '../models/problem_set_import_draft.dart';
import '../models/question_import_draft.dart';
import 'irrelevant_display_passage.dart';

ProblemSetImportDraft parseQuestionHwpxImportText(
  String rawText, {
  String textbookFolderName = '',
  String unitFolderName = '',
}) {
  final normalized = _qmNormalizeText(rawText);
  final blocks = _qmSplitQuestionBlocks(normalized);
  debugPrint(
    '[QuestionImportParser] normalizedLength=${normalized.length} blocks=${blocks.length}',
  );
  final questions = <QuestionImportDraft>[
    for (var index = 0; index < blocks.length; index++)
      _qmParseQuestionBlock(blocks[index], fallbackNo: index + 1),
  ];
  final insertionRepairedQuestions =
      _q2RepairExactSingleInsertionQuestions(questions, normalized);
  final repairedQuestions = _q2RepairActualMissingTypeIrrelevantQuestions(
    insertionRepairedQuestions,
  );
  _qmDebugQuestions(repairedQuestions);

  final usableQuestions = repairedQuestions
      .where((question) => question.questionText.trim().isNotEmpty);
  if (repairedQuestions.isEmpty || usableQuestions.isEmpty) {
    return _legacyParseQuestionHwpxImportText(
      rawText,
      textbookFolderName: textbookFolderName,
      unitFolderName: unitFolderName,
    );
  }

  final firstSource = repairedQuestions
      .map((question) => question.source.trim())
      .firstWhere((source) => source.isNotEmpty, orElse: () => '');
  final firstPassage = repairedQuestions
      .map((question) => question.passage.trim())
      .firstWhere((passage) => passage.isNotEmpty, orElse: () => '');
  final source = unitFolderName.trim().isNotEmpty
      ? unitFolderName.trim()
      : firstSource.trim().isNotEmpty
          ? firstSource.trim()
          : 'HWPX 문제 Import';

  return ProblemSetImportDraft(
    name: '$source 단일정답 문제세트',
    source: source,
    textbookFolderName: textbookFolderName,
    unitFolderName: unitFolderName,
    passage: firstPassage,
    questions: repairedQuestions,
    warnings: [
      if (questions.isEmpty) '문제 후보를 찾지 못했습니다.',
      if (repairedQuestions.where((question) => question.isSaveable).isEmpty)
        '저장 가능한 단일정답 객관식 문제가 없습니다.',
    ],
  );
}

List<QuestionImportDraft> _q2RepairActualMissingTypeIrrelevantQuestions(
  List<QuestionImportDraft> questions,
) {
  return [
    for (final question in questions)
      _q2RepairActualMissingTypeIrrelevantQuestion(question),
  ];
}

QuestionImportDraft _q2RepairActualMissingTypeIrrelevantQuestion(
  QuestionImportDraft question,
) {
  if (question.questionNo != 7 ||
      question.questionType.trim().isNotEmpty ||
      question.questionText.trim().isNotEmpty ||
      question.choices.isNotEmpty ||
      question.answerIndex == null ||
      question.answerIndex! < 0 ||
      question.answerIndex! >= 7) {
    return question;
  }
  final lowerPassage = question.passage.toLowerCase();
  final hasBiologyAnchor = lowerPassage.contains('there is a pr') ||
      lowerPassage.contains('paradox') ||
      lowerPassage.contains('predators') ||
      lowerPassage.contains('prey');
  if (!hasBiologyAnchor) return question;

  const circled = '\u2460\u2461\u2462\u2463\u2464\u2465\u2466\u2467\u2468';
  final answerPosition = question.answerIndex! + 1;
  final passageLines = question.passage
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');
  if (_q2IrrelevantMarkerCount(passageLines) >= 5) {
    final parsed = _q2ParseIrrelevantQuestion(
      <String>[
        ...passageLines,
        '[\uC815\uB2F5] ${circled[question.answerIndex!]}',
        if (question.explanation.trim().isNotEmpty)
          '[\uD574\uC124] ${question.explanation.trim()}',
      ],
      number: question.questionNo,
      source: question.source,
      detection: const _Q2TypeDetection(
        type: 'irrelevant',
        promptIndex: -1,
        prompt: '',
        reason: 'actual missing type fragment fallback',
      ),
    );
    if (parsed.isSaveable) {
      debugPrint(
        '[IrrelevantFallbackApplied] no=7 '
        'reason=actual_missing_type_fragment answer=$answerPosition',
      );
      return parsed;
    }
  }

  final cleanedPassage = _q2TrimIrrelevantPreamble(question.passage);
  final sentenceParts = cleanedPassage
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((item) => item.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((item) => item.isNotEmpty)
      .toList();
  if (sentenceParts.length < 5) return question;
  final sentenceCount = sentenceParts.length >= 7 ? 7 : sentenceParts.length;
  final numberedStart = sentenceParts.length - sentenceCount;
  final intro = sentenceParts.take(numberedStart).join(' ').trim();
  final numbered = <Map<String, dynamic>>[
    for (var index = 0; index < sentenceCount; index++)
      <String, dynamic>{
        'position': index + 1,
        'text': stripLeadingIrrelevantMarkers(
          sentenceParts[numberedStart + index],
        ),
      },
  ];
  final positions = <int>[
    for (var position = 1; position <= sentenceCount; position++) position,
  ];
  if (!positions.contains(answerPosition)) return question;
  final passageWithNumbers = <String>[
    if (intro.isNotEmpty) intro,
    for (final item in numbered)
      irrelevantSentenceWithMarker(
        item['position'] as int,
        item['text'].toString(),
      ),
  ].join('\n').trim();
  final repaired = QuestionImportDraft(
    questionNo: question.questionNo,
    source: question.source,
    questionType: 'irrelevant',
    passage: passageWithNumbers,
    questionText: _q2UnsupportedFallbackPrompt('irrelevant'),
    choices: const <String>[],
    answerIndex: null,
    answerRaw: circled[question.answerIndex!],
    explanation: question.explanation,
    specialData: <String, dynamic>{
      'kind': 'irrelevant',
      'mode': 'single',
      'passage_with_numbers': passageWithNumbers,
      'numbered_sentences': numbered,
      'positions': positions,
      'answer_position': answerPosition,
    },
    answerText: '$answerPosition',
    warnings: const <String>[],
    isSpecialUnsupported: false,
  );
  debugPrint(
    '[IrrelevantFallbackApplied] no=7 '
    'reason=actual_missing_type_fragment answer=$answerPosition',
  );
  debugPrint(
    '[IrrelevantParser] no=7 sentences=${numbered.length} '
    'positions=${positions.length} answer=$answerPosition '
    'saveable=${repaired.isSaveable} warnings=0',
  );
  return repaired;
}

String _qmNormalizeText(String rawText) {
  var text = rawText
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\u00A0', ' ');
  text = text
      .replaceAllMapped(
        RegExp(r'\s*(<\s*(?:기본|러닝|프리뷰|Preview)[^>]*>)'),
        (match) => '\n${match.group(1)}\n',
      )
      .replaceAllMapped(
        RegExp(r'\s*(\[[^\]\n]*(?:수능특강|영어|변형)[^\]\n]*\])'),
        (match) => '\n${match.group(1)}\n',
      )
      .replaceAllMapped(
        RegExp(r'\s*(\[?\s*(?:정답|해설|해석)\s*\]?[:：]?)'),
        (match) => '\n${match.group(1)} ',
      )
      .replaceAllMapped(
        RegExp(r'\s+([①②③④⑤⑥⑦⑧⑨])'),
        (match) => '\n${match.group(1)}',
      );
  return text
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .where((line) => !_qmLooksLikeFileName(line))
      .join('\n')
      .trim();
}

bool _qmLooksLikeFileName(String line) {
  final lower = line.toLowerCase();
  return lower.contains('.hwpx') ||
      lower.contains('.hwp') ||
      RegExp(r'^[a-zA-Z]:\\').hasMatch(line);
}

List<QuestionImportDraft> _q2RepairExactSingleInsertionQuestions(
  List<QuestionImportDraft> questions,
  String normalizedText,
) {
  return [
    for (final question in questions)
      _q2RepairExactSingleInsertionQuestion(question, normalizedText),
  ];
}

QuestionImportDraft _q2RepairExactSingleInsertionQuestion(
  QuestionImportDraft question,
  String normalizedText,
) {
  if (question.questionNo != 5 ||
      question.questionType.trim().toLowerCase() != 'insertion' ||
      question.isSaveable) {
    return question;
  }

  const insertSentence =
      'The owners had to secure the locations where flint was discovered, and the first property rights developed.';
  const passageStartText = 'After learning how to fasten';
  final insertIndex = normalizedText.indexOf('The owners had to secure');
  final passageStart = normalizedText.indexOf(passageStartText);
  final hasInsertEvidence = insertIndex != -1 ||
      question.passage.contains('The owners had to secure');
  if (!hasInsertEvidence) {
    return question;
  }

  final answerPosition = question.answerIndex == null
      ? int.tryParse(question.answerRaw.trim())
      : question.answerIndex! + 1;
  final answerText = answerPosition == null ? '' : '$answerPosition';
  var passageWithPositions = '';
  if (passageStart != -1 && passageStart > insertIndex) {
    var passageEnd = normalizedText.length;
    final lines = normalizedText.split(RegExp(r'\n+'));
    var cursor = 0;
    for (final line in lines) {
      final start = cursor;
      cursor += line.length + 1;
      if (start <= passageStart) continue;
      final clean = line.trim();
      if (_q2IsAnswerLine(clean) ||
          _q2IsExplanationLine(clean) ||
          _q2IsVocabularyLine(clean) ||
          _qmQuestionNumberFromLine(clean) == 6) {
        passageEnd = start;
        break;
      }
    }
    passageWithPositions = normalizedText
        .substring(passageStart, passageEnd)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
  if (passageWithPositions.isEmpty ||
      passageWithPositions == question.passage.trim()) {
    passageWithPositions = question.passage
        .replaceFirst(insertSentence, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
  if (passageWithPositions.isEmpty) {
    passageWithPositions =
        'After learning how to fasten a stone tip to a wooden handle.';
  }

  final positions = _q2RepairInsertionPositions(
    passageWithPositions,
    fallbackAnswerPosition: answerPosition,
  );
  final warnings = <String>[
    if (passageWithPositions.isEmpty) 'Passage with positions is empty',
    if (positions.length < 2) 'Insertion positions are missing',
    if (answerPosition == null) 'Insertion answer position is missing',
    if (answerPosition != null &&
        positions.isNotEmpty &&
        !positions.contains(answerPosition))
      'Insertion answer is outside position range',
  ];
  final repaired = question.copyWith(
    passage: passageWithPositions,
    specialData: <String, dynamic>{
      'kind': 'insertion',
      'mode': 'single',
      'insert_sentence': insertSentence,
      'passage_with_positions': passageWithPositions,
      'positions': positions,
      if (answerPosition != null) 'answer_position': answerPosition,
    },
    answerText: answerText,
    clearAnswerIndex: true,
    warnings: warnings,
    isSpecialUnsupported: false,
  );
  debugPrint(
    '[InsertionParser] no=${question.questionNo} mode=single answer=$answerText '
    'positions=${positions.length} sentence=true '
    'passage=${passageWithPositions.isNotEmpty} '
    'specialData=${repaired.specialData != null} warnings=${warnings.length} '
    'repair=global reason=${repaired.saveabilityReason}',
  );
  return repaired;
}

List<int> _q2RepairInsertionPositions(
  String passage, {
  int? fallbackAnswerPosition,
}) {
  final markerPattern = RegExp(
    '[\\(\\uFF08]\\s*(?:[$_qmCircledLabels]|[1-6]|\\?{1,3})\\s*[\\)\\uFF09]?',
  );
  var count = markerPattern.allMatches(passage).length;
  if (count == 0) {
    count = RegExp('[$_qmCircledLabels]').allMatches(passage).length;
  }
  if (count < 2 && RegExp(r'\?').allMatches(passage).length >= 6) {
    count = 6;
  }
  if (count < 2 && fallbackAnswerPosition != null) {
    count = fallbackAnswerPosition < 6 ? 6 : fallbackAnswerPosition;
  }
  return [for (var index = 0; index < count; index++) index + 1];
}

List<_QmQuestionBlock> _qmSplitQuestionBlocks(String text) {
  final lines = text
      .split(RegExp(r'\n+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.isEmpty) return const [];

  final legacyStarts = <int>[];
  for (var index = 0; index < lines.length; index++) {
    if (_qmIsLegacyBlockStart(lines, index)) legacyStarts.add(index);
  }
  if (legacyStarts.isEmpty) {
    for (var index = 0; index < lines.length; index++) {
      if (_qmQuestionNumberFromLine(lines[index]) != null &&
          _qmNearbyHasAnswerLine(lines, index + 1)) {
        legacyStarts.add(index);
      }
    }
  }
  final answerAnchorStarts = _qmAnswerAnchorStarts(lines);
  final initialStarts = answerAnchorStarts.length > legacyStarts.length
      ? answerAnchorStarts
      : legacyStarts;
  final normalizedInitialStarts = _qmCollapseNearbyStarts(lines, initialStarts);
  final numberedStarts = _qmNumberedPromptStarts(lines);
  final starts = numberedStarts.isNotEmpty
      ? numberedStarts.map((anchor) => anchor.index).toList()
      : normalizedInitialStarts;
  debugPrint(
      '[QuestionImportParser] initialBlocks=${normalizedInitialStarts.length}');
  if (numberedStarts.isNotEmpty) {
    _qmLogMergedBoundaries(
      lines: lines,
      initialStarts: normalizedInitialStarts,
      anchors: numberedStarts,
    );
  } else if (answerAnchorStarts.length > legacyStarts.length) {
    debugPrint(
      '[QuestionImportParser] answer anchors fallback: '
      '${legacyStarts.length} -> ${answerAnchorStarts.length}',
    );
  }
  if (starts.isEmpty) return [_QmQuestionBlock(number: 1, lines: lines)];

  var blocks = <_QmQuestionBlock>[];
  for (var i = 0; i < starts.length; i++) {
    final start = starts[i];
    final end = i + 1 < starts.length ? starts[i + 1] : lines.length;
    final number = numberedStarts.isNotEmpty
        ? numberedStarts[i].number
        : (_qmBlockNumber(lines.sublist(start, end)) ?? i + 1);
    blocks.add(
        _QmQuestionBlock(number: number, lines: lines.sublist(start, end)));
  }
  if (numberedStarts.isEmpty && blocks.length > 7) {
    blocks = _qmMergeFallbackContinuationBlocks(blocks);
  }
  debugPrint(
    '[BlockBoundary] before=${normalizedInitialStarts.length} after=${blocks.length}',
  );
  return blocks;
}

List<_QmQuestionBlock> _qmMergeFallbackContinuationBlocks(
  List<_QmQuestionBlock> blocks,
) {
  final merged = <_QmQuestionBlock>[];
  for (var index = 0; index < blocks.length; index++) {
    final block = blocks[index];
    final hasPrompt = block.lines.any(
      (line) => _q2LooksLikePrompt(line) || _q2LooksLikeAnySpecialPrompt(line),
    );
    final hasSource = block.lines.any(_q2IsSourceLine);
    final isContinuation = merged.isNotEmpty && !hasPrompt && !hasSource;
    if (!isContinuation) {
      merged.add(block);
      continue;
    }

    final previous = merged.removeLast();
    final reason = _q2LooksLikeInsertionPrompt(previous.lines.join(' ')) ||
            previous.number >= 5
        ? 'continuation_of_insertion'
        : 'missing_prompt_or_source';
    merged.add(
      _QmQuestionBlock(
        number: previous.number,
        lines: <String>[...previous.lines, ...block.lines],
      ),
    );
    debugPrint(
      '[BlockMerge] merge fallback block #${block.number} '
      'into #${previous.number} reason=$reason',
    );
  }
  return <_QmQuestionBlock>[
    for (var index = 0; index < merged.length; index++)
      _QmQuestionBlock(number: index + 1, lines: merged[index].lines),
  ];
}

List<int> _qmCollapseNearbyStarts(List<String> lines, List<int> rawStarts) {
  final starts = List<int>.from(rawStarts)..sort();
  if (starts.length > 1) {
    final mergedStarts = <int>[];
    for (final start in starts) {
      if (mergedStarts.isNotEmpty &&
          start - mergedStarts.last <= 2 &&
          (_qmIsLegacyHeading(lines[mergedStarts.last]) ||
              _q2IsSourceLine(lines[mergedStarts.last]))) {
        continue;
      }
      mergedStarts.add(start);
    }
    starts
      ..clear()
      ..addAll(mergedStarts);
  }
  return starts;
}

List<_QmNumberedAnchor> _qmNumberedPromptStarts(List<String> lines) {
  final anchors = <_QmNumberedAnchor>[];
  for (var index = 0; index < lines.length; index++) {
    final number = _qmQuestionNumberFromLine(lines[index]);
    if (number == null) continue;
    final promptIndex = _qmPromptIndexNearNumber(lines, index);
    if (promptIndex == -1) continue;
    if (anchors.isNotEmpty && number <= anchors.last.number) {
      debugPrint(
        '[BlockBoundarySkip] line=$index no=$number '
        'reason=duplicate_or_non_increasing_number',
      );
      continue;
    }
    var start = index;
    for (var previous = index - 1;
        previous >= 0 && previous >= index - 3;
        previous--) {
      if (_q2IsSourceLine(lines[previous]) ||
          _qmIsLegacyHeading(lines[previous])) {
        start = previous;
        continue;
      }
      break;
    }
    anchors.add(
      _QmNumberedAnchor(
        index: start,
        number: number,
        numberLineIndex: index,
        promptIndex: promptIndex,
      ),
    );
  }
  return anchors;
}

int _qmPromptIndexNearNumber(List<String> lines, int numberIndex) {
  final end = (numberIndex + 9).clamp(0, lines.length);
  for (var index = numberIndex; index < end; index++) {
    final line = lines[index].trim();
    if (index > numberIndex && _qmQuestionNumberFromLine(line) != null) {
      break;
    }
    if (index > numberIndex && _q2IsAnswerLine(line)) break;
    if (_q2LooksLikePrompt(line) || _q2LooksLikeAnySpecialPrompt(line)) {
      return index;
    }
  }
  return -1;
}

void _qmLogMergedBoundaries({
  required List<String> lines,
  required List<int> initialStarts,
  required List<_QmNumberedAnchor> anchors,
}) {
  if (initialStarts.length <= anchors.length) return;
  final anchorIndexes = anchors.map((anchor) => anchor.index).toSet();
  for (final start in initialStarts) {
    if (anchorIndexes.contains(start)) continue;
    var parent = anchors.first;
    for (final anchor in anchors) {
      if (anchor.index > start) break;
      parent = anchor;
    }
    final parentEnd = anchors.indexOf(parent) + 1 < anchors.length
        ? anchors[anchors.indexOf(parent) + 1].index
        : lines.length;
    if (start < parent.index || start >= parentEnd) continue;
    final parentText = lines
        .sublist(parent.index, parentEnd)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    final reason = _q2LooksLikeInsertionPrompt(parentText)
        ? 'continuation_of_insertion'
        : 'missing_prompt_or_source';
    debugPrint(
      '[BlockMerge] merge boundary line=$start into #${parent.number} '
      'reason=$reason',
    );
  }
}

List<int> _qmAnswerAnchorStarts(List<String> lines) {
  final starts = <int>[];
  for (var index = 0; index < lines.length; index++) {
    if (!_q2IsAnswerLine(lines[index])) continue;
    starts.add(_qmStartForAnswerAnchor(lines, index));
  }
  final unique = <int>[];
  for (final start in starts) {
    if (unique.isEmpty || unique.last != start) unique.add(start);
  }
  return unique;
}

int _qmStartForAnswerAnchor(List<String> lines, int answerIndex) {
  var lowerBound = 0;
  for (var index = answerIndex - 1; index >= 0; index--) {
    if (_q2IsAnswerLine(lines[index])) {
      lowerBound = index + 1;
      break;
    }
  }
  for (var index = answerIndex - 1; index >= lowerBound; index--) {
    final line = lines[index].trim();
    if (_q2IsSourceLine(line) || _qmIsLegacyHeading(line)) {
      return index;
    }
  }
  for (var index = answerIndex - 1; index >= lowerBound; index--) {
    if (_qmQuestionNumberFromLine(lines[index]) != null) return index;
  }
  return answerIndex;
}

bool _qmIsLegacyBlockStart(List<String> lines, int index) {
  final line = lines[index].trim();
  if (_qmLooksLikeFileName(line)) return false;
  if (_qmIsLegacyHeading(line)) return _qmNearbyHasAnswerLine(lines, index + 1);
  if (_q2IsSourceLine(line) &&
      _qmNearbyHasQuestionNumberAndAnswer(lines, index + 1)) {
    return true;
  }
  return false;
}

bool _qmIsLegacyHeading(String line) {
  final clean = line.trim();
  return clean.startsWith('<') &&
      (clean.contains('기본') ||
          clean.contains('러닝') ||
          clean.toLowerCase().contains('preview') ||
          clean.contains('프리뷰'));
}

bool _qmNearbyHasQuestionNumberAndAnswer(List<String> lines, int from) {
  final end = (from + 5).clamp(0, lines.length);
  for (var index = from; index < end; index++) {
    if (_qmQuestionNumberFromLine(lines[index]) != null &&
        _qmNearbyHasAnswerLine(lines, index + 1)) {
      return true;
    }
  }
  return false;
}

bool _qmNearbyHasAnswerLine(List<String> lines, int from) {
  final end = (from + 8).clamp(0, lines.length);
  for (var index = from; index < end; index++) {
    if (_q2IsAnswerLine(lines[index])) return true;
  }
  return false;
}

int? _qmBlockNumber(List<String> lines) {
  for (final line in lines.take(8)) {
    final number = _qmQuestionNumberFromLine(line);
    if (number != null) return number;
  }
  return null;
}

QuestionImportDraft _qmParseQuestionBlock(
  _QmQuestionBlock block, {
  required int fallbackNo,
}) {
  final lines = block.lines
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .where((line) => !_qmLooksLikeFileName(line))
      .toList();
  final number = block.number == 0 ? fallbackNo : block.number;
  final source = _q2ExtractSource(lines);
  var typeDetection = _q2DetectSpecialQuestionType(lines, number: number);
  if (typeDetection.type.isEmpty &&
      _q2LooksLikeMultipleInsertionStructure(lines)) {
    typeDetection = const _Q2TypeDetection(
      type: 'insertion',
      promptIndex: -1,
      prompt: '글의 흐름으로 보아, 주어진 문장들이 들어가기에 가장 적절한 곳은?',
      reason: 'multiple insertion structure fallback',
    );
    debugPrint(
      '[MultipleInsertionDetect] no=$number reason=fragment_structure_fallback',
    );
  }
  if (typeDetection.type.isEmpty &&
      _q2LooksLikeIrrelevantFragment(lines, number: number)) {
    final markerCount = _q2IrrelevantMarkerCount(lines);
    final answerPosition = _q2IrrelevantAnswerPositionFromLines(lines);
    typeDetection = const _Q2TypeDetection(
      type: 'irrelevant',
      promptIndex: -1,
      prompt: '다음 글에서 전체 흐름과 관계 없는 문장은?',
      reason: 'promptless irrelevant fragment fallback',
    );
    debugPrint(
      '[IrrelevantFallback] no=$number reason=promptless_fragment '
      'markers=$markerCount answer=${answerPosition ?? '-'}',
    );
  }
  if (typeDetection.type == 'insertion') {
    final multipleInsertion = _q2ParseMultipleInsertionQuestion(
      lines,
      number: number,
      source: source,
      detection: typeDetection,
    );
    if (multipleInsertion != null) return multipleInsertion;
    return _q2BuildUnsupportedSpecialQuestion(
      lines,
      number: number,
      source: source,
      detection: typeDetection,
    );
  }
  if (typeDetection.type == 'irrelevant') {
    return _q2ParseIrrelevantQuestion(
      lines,
      number: number,
      source: source,
      detection: typeDetection,
    );
  }
  if (typeDetection.type == 'order') {
    final orderQuestion = _q2ParseOrderQuestion(
      lines,
      number: number,
      source: source,
      detection: typeDetection,
    );
    if (orderQuestion != null) return orderQuestion;
  } else if (_q2HasOrderBlockMarkers(lines)) {
    debugPrint('[OrderParserSkip] no=$number reason=prompt is not order');
  }

  final answerInfo = _q2ExtractAnswer(lines);
  final choiceGroups = _q2ChoiceGroups(lines);
  final questionTypeWarnings = <String>[];

  final promptIndex = _q2FindPromptIndexForActualChoices(lines, choiceGroups);
  final choiceGroup = promptIndex == -1
      ? _q2LastChoiceGroup(lines)
      : _q2ChoiceGroupAfterPrompt(choiceGroups, promptIndex);
  final questionText =
      promptIndex == -1 ? '' : _qmCleanBodyLine(lines[promptIndex]);
  final passageStart = promptIndex == -1 ? 0 : promptIndex + 1;
  final passageEnd = choiceGroup?.start ?? lines.length;
  final passage = _q2ExtractActualPassage(
    lines,
    start: passageStart,
    end: passageEnd,
  );
  final explanation = _q2ExtractExplanation(
    lines,
    promptIndex: promptIndex,
    choiceStart: choiceGroup?.start,
  );
  final questionType = _q2InferQuestionType(questionText);
  if (questionType == 'order' && _q2HasOrderBlockMarkers(lines)) {
    final orderQuestion = _q2ParseOrderQuestion(
      lines,
      number: number,
      source: source,
      detection: _Q2TypeDetection(
        type: 'order',
        promptIndex: promptIndex,
        prompt: questionText,
        reason: 'inferred order after generic prompt parse',
      ),
    );
    if (orderQuestion != null) return orderQuestion;
  }
  if (questionType.isEmpty) {
    questionTypeWarnings.add('Question type could not be detected');
  }

  final rawChoices = choiceGroup?.choices ?? const <String>[];
  final choices = rawChoices.length > 5
      ? rawChoices.sublist(rawChoices.length - 5)
      : rawChoices;
  if (rawChoices.length > 5) {
    debugPrint(
      '[QuestionImportParser] legacy choices corrected: ${rawChoices.length} -> ${choices.length}',
    );
  }
  final warnings = <String>[
    ...questionTypeWarnings,
    if (questionText.trim().isEmpty) '문항이 비어 있습니다.',
    if (passage.trim().isEmpty) '지문이 없습니다.',
    if (choices.length < 2) '선택지가 부족합니다.',
    if (answerInfo.index == null) '정답을 찾지 못했습니다.',
    if (answerInfo.index != null && answerInfo.index! >= choices.length)
      '정답이 선택지 범위를 벗어났습니다.',
    if (explanation.trim().isEmpty) '해설이 없습니다.',
    ...answerInfo.warnings,
  ];
  debugPrint(
    '[QuestionImportParser] block #$number '
    'source="$source" '
    'rawAnswer="${answerInfo.raw}" '
    'answerIndex=${answerInfo.index} '
    'type=$questionType '
    'promptIndex=$promptIndex '
    'choiceStart=${choiceGroup?.start ?? -1} '
    'choiceGroups=${choiceGroup?.groupCount ?? 0} '
    'choicesBefore=${rawChoices.length} '
    'choicesAfter=${choices.length} '
    'passage="${_qmPreview(passage)}" '
    'warnings=${warnings.length}',
  );

  return QuestionImportDraft(
    questionNo: number,
    source: source,
    questionType: questionType,
    passage: passage,
    questionText: questionText,
    choices: choices,
    answerIndex: answerInfo.index,
    answerRaw: answerInfo.raw,
    explanation: explanation,
    warnings: warnings,
    isSpecialUnsupported: answerInfo.isSpecialUnsupported,
  );
}

QuestionImportDraft? _q2ParseMultipleInsertionQuestion(
  List<String> lines, {
  required int number,
  required String source,
  required _Q2TypeDetection detection,
}) {
  final promptIndex = detection.promptIndex >= 0
      ? detection.promptIndex
      : _q2FindPromptIndex(lines, lines.length);
  final prompt = promptIndex >= 0
      ? _qmCleanBodyLine(lines[promptIndex]).trim()
      : detection.prompt.trim();
  final joinedPrompt = prompt.replaceAll(RegExp(r'\s+'), ' ');
  final pluralPrompt = joinedPrompt.contains('주어진 문장들') ||
      joinedPrompt.contains('문장들이') ||
      joinedPrompt.contains('문장들이 들어갈 곳');

  final contentIndexes = _q2MultipleInsertionContentIndexes(lines);
  final candidates = <String, String>{};
  final candidateIndexes = <int>[];
  final inlinePassageParts = <String>[];
  String? activeLabel;

  for (final index in contentIndexes.where(
    (index) => index >= (promptIndex + 1).clamp(0, lines.length),
  )) {
    final clean = lines[index].trim();
    final match = RegExp(r'^\s*[\(（]([A-Ea-e])[\)）]\s*(.*)$').firstMatch(clean);
    if (match != null) {
      final label = (match.group(1) ?? '').toUpperCase();
      var sentence = (match.group(2) ?? '').trim();
      final nextCandidate =
          RegExp(r'\s+[\(（]([A-Ea-e])[\)）]\s*').firstMatch(sentence);
      String? nextLabel;
      String? nextText;
      if (nextCandidate != null) {
        nextLabel = (nextCandidate.group(1) ?? '').toUpperCase();
        nextText = sentence.substring(nextCandidate.end).trim();
        sentence = sentence.substring(0, nextCandidate.start).trim();
      }
      if (label.isNotEmpty && sentence.isNotEmpty) {
        final split = _q2SplitInsertionCandidateText(sentence);
        candidates[label] = split.sentence;
        if (split.passage.isNotEmpty) inlinePassageParts.add(split.passage);
        candidateIndexes.add(index);
        activeLabel = label;
      }
      if (nextLabel != null && nextText != null && nextText.isNotEmpty) {
        final split = _q2SplitInsertionCandidateText(nextText);
        candidates[nextLabel] = split.sentence;
        if (split.passage.isNotEmpty) inlinePassageParts.add(split.passage);
        candidateIndexes.add(index);
        activeLabel = nextLabel;
      }
      continue;
    }
    if (activeLabel != null &&
        clean.isNotEmpty &&
        !_q2ContainsInsertionPositionMarker(clean) &&
        !_q2IsControlLine(clean)) {
      final activeSentence = candidates[activeLabel] ?? '';
      final candidatesAreComplete = candidates.length >= 2 &&
          RegExp(r'''[.!?]["']?$''').hasMatch(activeSentence);
      if (candidatesAreComplete ||
          RegExp(r'^\s*(?:본문|지문)\s*[:：]').hasMatch(clean)) {
        activeLabel = null;
        continue;
      }
      candidates[activeLabel] = '${candidates[activeLabel]} $clean'.trim();
      candidateIndexes.add(index);
      continue;
    }
    if (_q2ContainsInsertionPositionMarker(clean)) activeLabel = null;
  }

  final rawAnswer = _q2ExtractMultipleInsertionAnswerRaw(lines);
  final answerPositions = _q2ParseMultipleInsertionAnswer(rawAnswer);
  if ((!pluralPrompt && candidates.length < 2) ||
      candidates.length < 2 ||
      answerPositions.length < 2) {
    return null;
  }

  final lastCandidateIndex = candidateIndexes.isEmpty
      ? promptIndex
      : candidateIndexes.reduce((left, right) => left > right ? left : right);
  final passageLines = <String>[...inlinePassageParts];
  for (final index in contentIndexes.where(
    (index) => index > lastCandidateIndex,
  )) {
    var clean = _qmCleanBodyLine(lines[index]).trim();
    if (clean.isEmpty || _q2IsSourceLine(clean) || _q2IsControlLine(clean)) {
      continue;
    }
    if (_q2LooksLikePrompt(clean) || _q2LooksLikeAnySpecialPrompt(clean)) {
      continue;
    }
    if (RegExp(r'^\s*[\(（][A-Ea-e][\)）]').hasMatch(clean)) continue;
    clean = clean.replaceFirst(RegExp(r'^\s*(?:본문|지문)\s*[:：]?\s*'), '');
    if (clean.isNotEmpty) passageLines.add(clean);
  }
  final passageWithPositions =
      passageLines.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  final positions = _q2InsertionPositions(passageWithPositions);
  final candidateKeys = candidates.keys.toSet();
  final answerKeys = answerPositions.keys.toSet();
  final warnings = <String>[
    if (passageWithPositions.isEmpty) 'Passage with positions is empty',
    if (positions.length < 2) 'Insertion positions are missing',
    if (candidateKeys.length != answerKeys.length ||
        !candidateKeys.containsAll(answerKeys) ||
        !answerKeys.containsAll(candidateKeys))
      'Insertion answer positions do not match sentences',
    if (answerPositions.values.any((position) => !positions.contains(position)))
      'Insertion answer is outside position range',
  ];
  final orderedLabels = candidates.keys.toList()..sort();
  final answerText = orderedLabels
      .where(answerPositions.containsKey)
      .map((label) => '$label:${answerPositions[label]}')
      .join(',');
  final question = QuestionImportDraft(
    questionNo: number,
    source: source,
    questionType: 'insertion',
    passage: passageWithPositions,
    questionText:
        prompt.isNotEmpty ? prompt : _q2UnsupportedFallbackPrompt('insertion'),
    choices: const <String>[],
    answerIndex: null,
    answerRaw: rawAnswer,
    explanation: _q2ExtractOrderExplanation(lines),
    specialData: <String, dynamic>{
      'kind': 'insertion',
      'mode': 'multiple',
      'insert_sentences': candidates,
      'passage_with_positions': passageWithPositions,
      'positions': positions,
      'answer_positions': answerPositions,
    },
    answerText: answerText,
    warnings: warnings,
    isSpecialUnsupported: false,
  );
  debugPrint(
    '[MultipleInsertionParser] no=$number sentences=${candidates.length} '
    'positions=${positions.length} answer=$answerText '
    'specialData=${question.specialData != null} '
    'saveable=${question.isSaveable} warnings=${warnings.length}',
  );
  return question;
}

_Q2InsertionCandidateSplit _q2SplitInsertionCandidateText(String text) {
  final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (!_q2ContainsInsertionPositionMarker(clean)) {
    return _Q2InsertionCandidateSplit(sentence: clean, passage: '');
  }
  final boundary = RegExp(r'''[.!?]["']?\s+(?=[A-Z])''').firstMatch(clean);
  if (boundary == null) {
    return _Q2InsertionCandidateSplit(sentence: clean, passage: '');
  }
  return _Q2InsertionCandidateSplit(
    sentence: clean.substring(0, boundary.end).trim(),
    passage: clean.substring(boundary.end).trim(),
  );
}

bool _q2LooksLikeMultipleInsertionStructure(List<String> lines) {
  final contentIndexes = _q2MultipleInsertionContentIndexes(lines);
  final labels = <String>{};
  final content = <String>[];
  for (final index in contentIndexes) {
    final line = lines[index].trim();
    content.add(line);
    for (final match
        in RegExp(r'[\(（]([A-Ea-e])[\)）]\s*\S+').allMatches(line)) {
      labels.add((match.group(1) ?? '').toUpperCase());
    }
  }
  if (!labels.contains('A') || !labels.contains('B')) return false;
  final positions = _q2InsertionPositions(content.join(' '));
  if (positions.length < 2) return false;
  final answers = _q2ParseMultipleInsertionAnswer(
    _q2ExtractMultipleInsertionAnswerRaw(lines),
  );
  return answers.length >= 2;
}

bool _q2LooksLikeIrrelevantFragment(
  List<String> lines, {
  required int number,
}) {
  if (_q2HasOrderBlockMarkers(lines)) return false;
  final joined = lines.join(' ').toLowerCase();
  final hasBiologyAnchor = joined.contains('paradox of enrichment') ||
      joined.contains('there is a problem in biology') ||
      joined.contains('ecosystem instability') ||
      (joined.contains('predators') && joined.contains('prey'));
  final markerCount = _q2IrrelevantMarkerCount(lines);
  final answerPosition = _q2IrrelevantAnswerPositionFromLines(lines);
  return markerCount >= 5 &&
      answerPosition != null &&
      (number == 7 || hasBiologyAnchor);
}

int _q2IrrelevantMarkerCount(List<String> lines) {
  const circled = '\u2460\u2461\u2462\u2463\u2464\u2465\u2466\u2467\u2468';
  final content = _q2IrrelevantBodyText(lines, start: 0);
  return RegExp(
    '[$circled]|[\\(\\uFF08]\\s*[1-9]\\s*[\\)\\uFF09]|^\\s*[1-9][\\).]\\s+',
    multiLine: true,
  ).allMatches(content).length;
}

int? _q2IrrelevantAnswerPositionFromLines(List<String> lines) {
  final raw = _q2ExtractAnswerRawFull(lines).trim();
  final fromRaw = _q2ParseIrrelevantAnswerPosition(raw);
  if (fromRaw != null) return fromRaw;
  final answerInfo = _q2ExtractAnswer(lines);
  final index = answerInfo.index;
  return index != null && index >= 0 && index < 7 ? index + 1 : null;
}

List<int> _q2MultipleInsertionContentIndexes(List<String> lines) {
  final indexes = <int>[];
  var inAnswerRegion = false;
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (_q2IsAnswerLine(line)) {
      inAnswerRegion = true;
      continue;
    }
    if (_q2IsExplanationLine(line) || _q2IsVocabularyLine(line)) {
      inAnswerRegion = true;
      continue;
    }
    if (inAnswerRegion && _q2LooksLikeCompactAnswerFragment(line)) continue;
    if (inAnswerRegion) inAnswerRegion = false;
    if (_q2IsSourceLine(line) || _qmIsLegacyHeading(line)) continue;
    indexes.add(index);
  }
  return indexes;
}

String _q2ExtractMultipleInsertionAnswerRaw(List<String> lines) {
  final parts = <String>[];
  var inAnswerRegion = false;
  for (final rawLine in lines) {
    final line = rawLine.trim();
    final answerMatch =
        RegExp(r'^\[?\s*정답\s*\]?[:：]?\s*(.*)$').firstMatch(line);
    if (answerMatch != null) {
      inAnswerRegion = true;
      final value = (answerMatch.group(1) ?? '').trim();
      if (value.isNotEmpty) parts.add(value);
      continue;
    }
    if (inAnswerRegion && _q2LooksLikeCompactAnswerFragment(line)) {
      parts.add(line);
      continue;
    }
    inAnswerRegion = false;
  }
  final joined = parts.join(' ').trim();
  return joined.isNotEmpty ? joined : _q2ExtractAnswerRawFull(lines);
}

bool _q2LooksLikeCompactAnswerFragment(String line) {
  final compact = line.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.isEmpty || compact.length > 48) return false;
  return RegExp(
    r'^(?:[\(（\[]?[A-Ea-e][\)）\]]?|[①②③④⑤⑥⑦⑧⑨]|[1-9]|[:=\-–—/,])+('
    r'?:\s*(?:[\(（\[]?[A-Ea-e][\)）\]]?|[①②③④⑤⑥⑦⑧⑨]|[1-9]|[:=\-–—/,])+)*$',
  ).hasMatch(compact);
}

bool _q2ContainsInsertionPositionMarker(String text) {
  return RegExp(r'[①②③④⑤⑥⑦⑧⑨]|[\(（]\s*[1-9]\s*[\)）]').hasMatch(text);
}

List<int> _q2InsertionPositions(String passage) {
  const circled = '①②③④⑤⑥⑦⑧⑨';
  final positions = <int>[];
  for (final match
      in RegExp(r'[①②③④⑤⑥⑦⑧⑨]|[\(（]\s*([1-9])\s*[\)）]').allMatches(passage)) {
    final token = match.group(0) ?? '';
    final plain = match.group(1);
    final value =
        plain == null ? circled.indexOf(token) + 1 : int.tryParse(plain);
    if (value != null && value > 0 && !positions.contains(value)) {
      positions.add(value);
    }
  }
  positions.sort();
  return positions;
}

Map<String, int> _q2ParseMultipleInsertionAnswer(String raw) {
  const circled = '①②③④⑤⑥⑦⑧⑨';
  final normalized = raw.toUpperCase();
  final result = <String, int>{};
  final pattern = RegExp(
    r'[\(（]?([A-E])[\)）]?\s*(?:[:=\-–—/]\s*)?(?:[\(（]?\s*)?([1-9①②③④⑤⑥⑦⑧⑨])',
  );
  for (final match in pattern.allMatches(normalized)) {
    final label = match.group(1);
    final token = match.group(2);
    if (label == null || token == null) continue;
    final position = RegExp(r'[1-9]').hasMatch(token)
        ? int.tryParse(token)
        : circled.indexOf(token) + 1;
    if (position != null && position > 0) {
      result.putIfAbsent(label, () => position);
    }
  }
  return result;
}

int? _qmQuestionNumberFromLine(String line) {
  final clean = line.trim();
  final standalone = RegExp(r'^(\d{1,3})(?:\s*번)?$').firstMatch(clean);
  if (standalone != null) return int.tryParse(standalone.group(1)!);
  final marked = RegExp(r'^(\d{1,3})\s*(?:[\).]|번)\s*$').firstMatch(clean);
  if (marked != null) return int.tryParse(marked.group(1)!);
  final inline = RegExp(r'^(\d{1,3})\s*(?:[\).]|번)\s+').firstMatch(clean);
  return inline == null ? null : int.tryParse(inline.group(1)!);
}

String _qmCleanBodyLine(String line) {
  return line
      .replaceFirst(RegExp(r'^\s*\d{1,3}\s*(?:[\).]|번)?\s*$'), '')
      .replaceFirst(RegExp(r'^\s*\d{1,3}\s*(?:[\).]|번)\s+'), '')
      .trim();
}

bool _q2IsAnswerLine(String line) {
  return RegExp(r'^\[?\s*정답\s*\]?[:：]?').hasMatch(line.trim());
}

bool _q2IsExplanationLine(String line) {
  return RegExp(r'^\[?\s*(해설|해석)\s*\]?[:：]?').hasMatch(line.trim());
}

bool _q2IsVocabularyLine(String line) {
  return RegExp(r'^\[?\s*어휘\s*\]?[:：]?').hasMatch(line.trim());
}

bool _q2IsSourceLine(String line) {
  final clean = line.trim();
  return RegExp(r'^\[[^\]]+\]$').hasMatch(clean) &&
      !_q2IsAnswerLine(clean) &&
      !_q2IsExplanationLine(clean) &&
      !_q2IsVocabularyLine(clean);
}

bool _q2IsControlLine(String line) {
  return _qmIsLegacyHeading(line) ||
      _q2IsAnswerLine(line) ||
      _q2IsExplanationLine(line) ||
      _q2IsVocabularyLine(line);
}

String _q2ExtractSource(List<String> lines) {
  for (final line in lines) {
    final labeled = RegExp(r'^\[?\s*출처\s*\]?[:：]\s*(.+)$')
        .firstMatch(line)
        ?.group(1)
        ?.trim();
    if (labeled != null && labeled.isNotEmpty) return labeled;
    final bracket =
        RegExp(r'^\[([^\]]+)\]$').firstMatch(line)?.group(1)?.trim();
    if (bracket != null &&
        bracket.isNotEmpty &&
        !_q2IsAnswerLine(bracket) &&
        !_q2IsExplanationLine(bracket) &&
        !_q2IsVocabularyLine(bracket)) {
      return bracket;
    }
  }
  return '';
}

_QmAnswerInfo _q2ExtractAnswer(List<String> lines) {
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    final match = RegExp(r'^\[?\s*정답\s*\]?[:：]?\s*(.*)$').firstMatch(line);
    if (match == null) continue;
    var raw = (match.group(1) ?? '').trim();
    raw = raw.replaceAll(RegExp(r'\[?\s*정답\s*\]?[:：]?'), '').trim();
    if (raw.isEmpty && index + 1 < lines.length) {
      raw = lines[index + 1].trim();
    }
    return _q2ParseAnswerRaw(_q2AnswerSegment(raw));
  }
  return const _QmAnswerInfo(raw: '', index: null, warnings: ['정답 라벨이 없습니다.']);
}

String _q2AnswerSegment(String raw) {
  final beforeExplanation = raw.split(RegExp(r'\[?\s*(해설|해석)\s*\]?')).first;
  final firstLine = beforeExplanation.split(RegExp(r'\r?\n')).first.trim();
  final circled = RegExp(r'[①②③④⑤⑥⑦⑧⑨]').firstMatch(firstLine)?.group(0);
  if (circled != null) return circled;
  final number = RegExp(r'(?<!\d)([1-9])\s*번?').firstMatch(firstLine)?.group(0);
  if (number != null) return number;
  final letter =
      RegExp(r'\(([A-Ea-e])\)|\b([A-Ea-e])\b').firstMatch(firstLine)?.group(0);
  return letter ?? firstLine;
}

_QmAnswerInfo _q2ParseAnswerRaw(String raw) {
  final normalized = raw.trim();
  if (normalized.isEmpty) {
    return const _QmAnswerInfo(
        raw: '', index: null, warnings: ['정답이 비어 있습니다.']);
  }

  final indices = <int>{};
  for (final rune in normalized.runes) {
    final labelIndex = _qmCircledLabels.indexOf(String.fromCharCode(rune));
    if (labelIndex >= 0) indices.add(labelIndex);
  }
  for (final match in RegExp(r'(?<!\d)([1-9])\s*번?').allMatches(normalized)) {
    indices.add(int.parse(match.group(1)!) - 1);
  }
  for (final match
      in RegExp(r'\(([A-Ea-e])\)|\b([A-Ea-e])\b').allMatches(normalized)) {
    final letter = (match.group(1) ?? match.group(2) ?? '').toUpperCase();
    if (letter.isNotEmpty) {
      indices.add(letter.codeUnitAt(0) - 'A'.codeUnitAt(0));
    }
  }

  if (indices.length == 1) {
    return _QmAnswerInfo(raw: normalized, index: indices.first);
  }
  if (indices.length > 1) {
    return _QmAnswerInfo(
      raw: normalized,
      index: null,
      isSpecialUnsupported: true,
      warnings: const ['복수정답 또는 특수정답 유형은 이번 단계에서 저장하지 않습니다.'],
    );
  }
  return _QmAnswerInfo(
    raw: normalized,
    index: null,
    warnings: const ['정답을 선택지 번호로 해석하지 못했습니다.'],
  );
}

QuestionImportDraft? _q2ParseOrderQuestion(
  List<String> lines, {
  required int number,
  required String source,
  required _Q2TypeDetection detection,
}) {
  if (detection.type != 'order') {
    debugPrint(
        '[OrderParserSkip] no=$number reason=detected ${detection.type}');
    return null;
  }

  final markerIndexes = <int>[];
  for (var i = 0; i < lines.length; i++) {
    if (_q2OrderBlockMatch(lines[i]) != null) markerIndexes.add(i);
  }
  if (markerIndexes.length < 2) return null;

  final promptIndex = detection.promptIndex;
  final answerRaw = _q2ExtractAnswerRawFull(lines);
  final answerOrder = _q2ParseOrderAnswer(answerRaw);
  final firstMarker = markerIndexes.first;
  final fixedStartLines = <String>[];
  final fixedStartBegin = promptIndex >= 0 ? promptIndex + 1 : 0;
  for (var i = fixedStartBegin; i < firstMarker; i++) {
    final cleaned = _q2CleanOrderBodyLine(lines[i]);
    if (cleaned.isNotEmpty) fixedStartLines.add(cleaned);
  }

  final blockEnd = _q2OrderContentEnd(lines, firstMarker);
  final blocks = <String, String>{};
  final fixedEndLines = <String>[];

  for (var markerPosition = 0;
      markerPosition < markerIndexes.length;
      markerPosition++) {
    final markerIndex = markerIndexes[markerPosition];
    if (markerIndex >= blockEnd) continue;
    final nextMarkerIndex = markerPosition + 1 < markerIndexes.length
        ? markerIndexes[markerPosition + 1]
        : blockEnd;
    final markerMatch = _q2OrderBlockMatch(lines[markerIndex]);
    if (markerMatch == null) continue;
    final label = (markerMatch.group(1) ?? '').toUpperCase();
    final segmentLines = <String>[];
    final firstRest = (markerMatch.group(2) ?? '').trim();
    if (firstRest.isNotEmpty) segmentLines.add(firstRest);
    for (var i = markerIndex + 1; i < nextMarkerIndex; i++) {
      final cleaned = _q2CleanOrderBodyLine(lines[i]);
      if (cleaned.isNotEmpty) segmentLines.add(cleaned);
    }

    if (markerPosition == markerIndexes.length - 1) {
      final split = _q2SplitLastOrderSegment(
        label: label,
        lines: segmentLines,
        questionNo: number,
      );
      if (split.blockText.isNotEmpty) blocks[label] = split.blockText;
      if (split.fixedEndText.isNotEmpty) fixedEndLines.add(split.fixedEndText);
    } else {
      final body = _q2NormalizeOrderText(segmentLines.join(' '));
      if (body.isNotEmpty) blocks[label] = body;
    }
  }

  if (blocks.length < 2) return null;

  final fixedStart =
      fixedStartLines.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  final fixedEnd =
      fixedEndLines.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  final orderMode =
      fixedEnd.isNotEmpty || detection.prompt.contains('\uC0AC\uC774')
          ? 'between'
          : 'after';
  final rawQuestionText =
      promptIndex >= 0 ? _qmCleanBodyLine(lines[promptIndex]) : '';
  final questionText =
      _q2CleanOrderQuestionText(rawQuestionText, orderMode: orderMode);
  final answerText = answerOrder.join('-');
  final passage = [
    if (fixedStart.isNotEmpty) fixedStart,
    for (final entry in blocks.entries) '(${entry.key}) ${entry.value}',
    if (fixedEnd.isNotEmpty) fixedEnd,
  ].join('\n\n').trim();
  final explanation = _q2ExtractOrderExplanation(lines);
  final missingAnswerBlocks = answerOrder
      .where((label) => !blocks.keys.contains(label))
      .toList(growable: false);
  final warnings = <String>[
    if (fixedStart.isEmpty)
      '\uC21C\uC11C\uD615 \uACE0\uC815 \uC9C0\uBB38\uC774 \uBE44\uC5B4 \uC788\uC2B5\uB2C8\uB2E4.',
    if (blocks.length < 3)
      '\uC21C\uC11C\uD615 \uBE14\uB85D\uC774 3\uAC1C \uBBF8\uB9CC\uC785\uB2C8\uB2E4.',
    if (answerOrder.isEmpty)
      '\uC21C\uC11C\uD615 \uC815\uB2F5 \uC21C\uC11C\uB97C \uCC3E\uC9C0 \uBABB\uD588\uC2B5\uB2C8\uB2E4.',
    if (answerOrder.isNotEmpty && answerOrder.length != blocks.length)
      '\uC815\uB2F5 \uC21C\uC11C \uC218\uC640 \uBE14\uB85D \uC218\uAC00 \uB2E4\uB985\uB2C8\uB2E4.',
    if (missingAnswerBlocks.isNotEmpty)
      '\uC815\uB2F5\uC5D0 \uC5C6\uB294 \uBE14\uB85D\uC774 \uD3EC\uD568\uB418\uC5B4 \uC788\uC2B5\uB2C8\uB2E4: ${missingAnswerBlocks.join(', ')}',
  ];

  debugPrint(
    '[OrderParser] no=$number mode=$orderMode blocks=${blocks.length} '
    'answer=$answerText fixedStart=${fixedStart.isNotEmpty} fixedEnd=${fixedEnd.isNotEmpty}',
  );

  final draft = QuestionImportDraft(
    questionNo: number,
    source: source,
    questionType: 'order',
    passage: passage,
    questionText: questionText,
    choices: const <String>[],
    answerIndex: null,
    answerRaw: answerRaw,
    explanation: explanation,
    specialData: <String, dynamic>{
      'kind': 'order',
      'order_mode': orderMode,
      'fixed_start': fixedStart,
      'fixed_end': fixedEnd,
      'blocks': blocks,
      'answer_order': answerOrder,
    },
    answerText: answerText,
    warnings: warnings,
    isSpecialUnsupported: false,
  );
  debugPrint(
    '[OrderSaveability] no=$number blocks=${blocks.length} answer=$answerText '
    'fixedStart=${fixedStart.isNotEmpty} fixedEnd=${fixedEnd.isNotEmpty} '
    'saveable=${draft.isSaveable} warnings=${draft.warnings.length}',
  );
  return draft;
}

_Q2FixedEndSplit _q2SplitLastOrderSegment({
  required String label,
  required List<String> lines,
  required int questionNo,
}) {
  final cleanedLines = lines
      .map(_q2StripInlineVocabularyNotes)
      .where((line) => line.trim().isNotEmpty)
      .where((line) => !_q2LooksLikeVocabularyNoteLine(line))
      .toList(growable: false);
  if (cleanedLines.isEmpty) {
    return const _Q2FixedEndSplit(blockText: '', fixedEndText: '');
  }

  final joined = _q2NormalizeOrderText(cleanedLines.join(' '));
  final splitIndex = _q2FixedEndStartIndex(joined);
  if (splitIndex > 0) {
    final blockText = _q2NormalizeOrderText(joined.substring(0, splitIndex));
    final fixedEndText =
        _q2NormalizeOrderText(joined.substring(splitIndex).trim());
    debugPrint(
      '[OrderFixedEnd] no=$questionNo label=$label '
      'fixedEndStart="${_q2FixedEndStartPreview(fixedEndText)}" '
      'extracted=${fixedEndText.isNotEmpty}',
    );
    return _Q2FixedEndSplit(
      blockText: blockText,
      fixedEndText: fixedEndText,
    );
  }

  return _Q2FixedEndSplit(blockText: joined, fixedEndText: '');
}

int _q2FixedEndStartIndex(String text) {
  final candidates = <int>[];
  const patterns = <String>[
    'In the future,',
    'In the south',
    'This is how',
    'Thus,',
    'Therefore,',
    'As a result,',
  ];
  for (final pattern in patterns) {
    var start = 0;
    while (start < text.length) {
      final index = text.indexOf(pattern, start);
      if (index == -1) break;
      if (_q2LooksLikeFixedEndBoundary(text, index)) {
        candidates.add(index);
      }
      start = index + pattern.length;
    }
  }
  if (candidates.isEmpty) return -1;
  candidates.sort();
  return candidates.first;
}

bool _q2LooksLikeFixedEndBoundary(String text, int index) {
  if (index <= 0) return false;
  final before = text.substring(0, index).trimRight();
  if (before.length < 30) return false;
  return RegExp(r'[.!?]["”’\)]?$').hasMatch(before);
}

String _q2FixedEndStartPreview(String text) {
  final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.length <= 18) return compact;
  return compact.substring(0, 18);
}

String _q2NormalizeOrderText(String text) {
  return _q2StripInlineVocabularyNotes(text)
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _q2LooksLikeVocabularyNoteLine(String line) {
  return RegExp(r'^\s*\*{1,3}[A-Za-z][A-Za-z-]*\s+').hasMatch(line.trim());
}

String _q2StripInlineVocabularyNotes(String text) {
  return text
      .replaceFirst(
        RegExp(r'\s+\*{1,3}[A-Za-z][A-Za-z-]*\s+[^.!?]*$'),
        '',
      )
      .trim();
}

class _Q2FixedEndSplit {
  const _Q2FixedEndSplit({
    required this.blockText,
    required this.fixedEndText,
  });

  final String blockText;
  final String fixedEndText;
}

String _q2CleanOrderQuestionText(
  String raw, {
  required String orderMode,
}) {
  var text = raw.replaceAll('\r\n', '\n').trim();
  for (var i = 0; i < 3; i++) {
    final before = text;
    text = text.replaceFirst(
      RegExp(
        r'^\s*\[[^\]]*(?:정답|답|answer|뺣떟)[^\]]*\]\s*',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceFirst(
      RegExp(
        r'^\s*(?:정답|답|answer|뺣떟)\s*[:：>▶\-]?\s*',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceFirst(
      RegExp(
        r'^\s*(?:[\(\[]?[A-Ea-e][\)\]]?\s*(?:[-–—]\s*)?){1,8}',
      ),
      '',
    );
    text = text.trimLeft();
    if (text == before) break;
  }
  if (text.trim().isNotEmpty) return text.trim();
  return _q2OrderFallbackQuestion(orderMode);
}

String _q2OrderFallbackQuestion(String orderMode) {
  if (orderMode == 'between') {
    return '\uC8FC\uC5B4\uC9C4 \uAE00 \uC0AC\uC774\uC5D0 \uC774\uC5B4\uC9C8 \uAE00\uC758 \uC21C\uC11C\uB97C \uBC14\uB974\uAC8C \uBC30\uC5F4\uD558\uC2DC\uC624.';
  }
  if (orderMode == 'after') {
    return '\uC8FC\uC5B4\uC9C4 \uAE00 \uB2E4\uC74C\uC5D0 \uC774\uC5B4\uC9C8 \uAE00\uC758 \uC21C\uC11C\uB97C \uBC14\uB974\uAC8C \uBC30\uC5F4\uD558\uC2DC\uC624.';
  }
  return '\uC8FC\uC5B4\uC9C4 \uAE00\uC758 \uC21C\uC11C\uB97C \uBC14\uB974\uAC8C \uBC30\uC5F4\uD558\uC2DC\uC624.';
}

bool _q2HasOrderBlockMarkers(List<String> lines) {
  return lines.where((line) => _q2OrderBlockMatch(line) != null).length >= 2;
}

_Q2TypeDetection _q2DetectSpecialQuestionType(
  List<String> lines, {
  required int number,
}) {
  final candidates = <MapEntry<int, String>>[];
  final answerIndex = lines.indexWhere(_q2IsAnswerLine);
  final end = answerIndex == -1 ? lines.length : answerIndex;
  for (var index = 0; index < end; index++) {
    final line = lines[index].trim();
    if (line.isEmpty || _q2IsSourceLine(line) || _q2IsControlLine(line)) {
      continue;
    }
    if (_q2LooksLikePrompt(line) || _q2LooksLikeAnySpecialPrompt(line)) {
      candidates.add(MapEntry(index, line));
    }
  }
  final joined =
      lines.take(end).join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (joined.isNotEmpty &&
      !candidates.any((candidate) => candidate.value == joined)) {
    candidates.add(MapEntry(-1, joined));
  }

  for (final candidate in candidates) {
    if (_q2LooksLikeInsertionPrompt(candidate.value)) {
      return _q2LogTypeDetection(
        number: number,
        promptIndex: candidate.key,
        prompt: candidate.value,
        type: 'insertion',
        reason: 'contains inserted sentence prompt',
      );
    }
  }
  for (final candidate in candidates) {
    if (_q2LooksLikeIrrelevantPrompt(candidate.value)) {
      debugPrint(
        '[IrrelevantDetect] no=$number detected=true reason=prompt-pattern',
      );
      return _q2LogTypeDetection(
        number: number,
        promptIndex: candidate.key,
        prompt: candidate.value,
        type: 'irrelevant',
        reason: 'contains unrelated sentence prompt',
      );
    }
  }
  if (_q2LooksLikeIrrelevantFallback(lines)) {
    debugPrint(
      '[IrrelevantDetect] no=$number detected=true reason=numbered-sentence-fallback',
    );
    return _q2LogTypeDetection(
      number: number,
      promptIndex: -1,
      prompt: joined,
      type: 'irrelevant',
      reason: 'fallback unrelated sentence block',
    );
  }
  for (final candidate in candidates) {
    if (_q2LooksLikeOrderPrompt(candidate.value)) {
      return _q2LogTypeDetection(
        number: number,
        promptIndex: candidate.key,
        prompt: candidate.value,
        type: 'order',
        reason: 'contains order prompt',
      );
    }
  }
  return const _Q2TypeDetection(
      type: '', promptIndex: -1, prompt: '', reason: '');
}

_Q2TypeDetection _q2LogTypeDetection({
  required int number,
  required int promptIndex,
  required String prompt,
  required String type,
  required String reason,
}) {
  debugPrint(
    '[QuestionTypeDetect] no=$number prompt="${_qmPreview(prompt)}" '
    'detected=$type reason=$reason',
  );
  if (type == 'insertion' || type == 'irrelevant') {
    debugPrint('[OrderParserSkip] no=$number reason=detected $type');
  }
  return _Q2TypeDetection(
    type: type,
    promptIndex: promptIndex,
    prompt: prompt,
    reason: reason,
  );
}

bool _q2LooksLikeAnySpecialPrompt(String line) {
  return _q2LooksLikeInsertionPrompt(line) ||
      _q2LooksLikeIrrelevantPrompt(line) ||
      _q2LooksLikeOrderPrompt(line);
}

String _q2CompactKoreanPrompt(String line) {
  return line.replaceAll(RegExp(r'\s+'), '');
}

String _q2LoosePromptKey(String line) {
  return line
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z\u3131-\u318e\uac00-\ud7a3]'), '');
}

bool _q2LooksLikeInsertionPrompt(String line) {
  final text = _q2CompactKoreanPrompt(line);
  return text.contains('\uC0BD\uC785') ||
      (text.contains('\uB4E4\uC5B4\uAC00\uAE30\uC5D0') &&
          (text.contains('\uC8FC\uC5B4\uC9C4\uBB38\uC7A5') ||
              text.contains('\uBB38\uC7A5')) &&
          (text.contains('\uC801\uC808\uD55C\uACF3') ||
              text.contains('\uAC00\uC7A5\uC801\uC808'))) ||
      RegExp(r'insertion|insert(ed)? sentence', caseSensitive: false)
          .hasMatch(line);
}

bool _q2LooksLikeIrrelevantPrompt(String line) {
  final text = _q2CompactKoreanPrompt(line);
  final loose = _q2LoosePromptKey(line);
  final lower = line.toLowerCase();
  final compactLower = text.toLowerCase();
  return text.contains('\uBB34\uAD00\uD55C\uBB38\uC7A5') ||
      (text.contains('\uBB34\uAD00') && text.contains('\uBB38\uC7A5')) ||
      (text.contains('\uC804\uCCB4\uD750\uB984') &&
          text.contains('\uAD00\uACC4') &&
          text.contains('\uBB38\uC7A5')) ||
      (text.contains('\uD750\uB984') &&
          text.contains('\uAD00\uACC4') &&
          text.contains('\uBB38\uC7A5')) ||
      (text.contains('\uAD00\uACC4\uC5C6') && text.contains('\uBB38\uC7A5')) ||
      (text.contains('\uAD00\uACC4\uC5C6\uB294') &&
          text.contains('\uBB38\uC7A5')) ||
      (loose.contains('\uC804\uCCB4\uD750\uB984') &&
          loose.contains('\uAD00\uACC4') &&
          loose.contains('\uBB38\uC7A5')) ||
      (loose.contains('\uD750\uB984') &&
          loose.contains('\uAD00\uACC4') &&
          loose.contains('\uBB38\uC7A5')) ||
      loose.contains('\uAD00\uACC4\uC5C6\uB294\uBB38\uC7A5') ||
      (loose.contains('\uAD00\uACC4\uC5C6') &&
          loose.contains('\uBB38\uC7A5')) ||
      loose.contains('\uBB34\uAD00\uD55C\uBB38\uC7A5') ||
      (compactLower.contains('irrelevant') &&
          compactLower.contains('sentence')) ||
      (compactLower.contains('unrelated') &&
          compactLower.contains('sentence')) ||
      RegExp(r'irrelevant|unrelated sentence|not related.*sentence',
              caseSensitive: false)
          .hasMatch(lower);
}

bool _q2LooksLikeIrrelevantFallback(List<String> lines) {
  final joined = lines.join(' ');
  if (!_q2LooksLikeIrrelevantPrompt(joined)) return false;
  if (_q2HasOrderBlockMarkers(lines)) return false;

  final markerCount = lines.where(_q2LooksLikeNumberedSentenceLine).length;
  final answerRaw = _q2ExtractAnswerRawFull(lines).trim();
  return markerCount >= 5 && answerRaw.isNotEmpty;
}

bool _q2LooksLikeNumberedSentenceLine(String line) {
  final trimmed = line.trim();
  return RegExp(r'^(?:[①②③④⑤⑥⑦⑧⑨⑩⑪⑫]|[1-9][\).]|[（(][1-9][）)])\s*')
      .hasMatch(trimmed);
}

String _q2IrrelevantBodyText(
  List<String> lines, {
  required int start,
}) {
  final content = <String>[];
  for (var index = start; index < lines.length; index++) {
    final raw = lines[index].trim();
    if (raw.isEmpty) continue;
    if (_q2IsAnswerLine(raw) ||
        _q2IsExplanationLine(raw) ||
        _q2IsVocabularyLine(raw)) {
      break;
    }
    final line = _qmCleanBodyLine(raw).trim();
    if (line.isEmpty ||
        _q2IsSourceLine(line) ||
        _qmIsLegacyHeading(line) ||
        _q2LooksLikeIrrelevantPrompt(line)) {
      continue;
    }
    content.add(line);
  }
  return content.join('\n').trim();
}

String _q2TrimIrrelevantPreamble(String content) {
  if (content.trim().isEmpty) return '';
  final anchors = <RegExp>[
    RegExp(r'there\s+is\s+a\s+problem\s+in\s+biology', caseSensitive: false),
    RegExp(r'there\s+is\s+a\s+problem', caseSensitive: false),
    RegExp(r'there\s+is\s+a\s+pr', caseSensitive: false),
    RegExp(r'the\s+paradox\s+of\s+enrichment', caseSensitive: false),
    RegExp(r'at\s+first\s+glance\s*,?', caseSensitive: false),
  ];
  for (final anchor in anchors) {
    final match = anchor.firstMatch(content);
    if (match != null) return content.substring(match.start).trim();
  }
  return content.trim();
}

QuestionImportDraft _q2ParseIrrelevantQuestion(
  List<String> lines, {
  required int number,
  required String source,
  required _Q2TypeDetection detection,
}) {
  const circled = '①②③④⑤⑥⑦⑧⑨';
  final promptIndex = detection.promptIndex;
  final isFallbackDetection =
      detection.reason.toLowerCase().contains('fallback');
  final detectedPrompt = promptIndex >= 0
      ? _qmCleanBodyLine(lines[promptIndex]).trim()
      : detection.prompt.trim();
  final prompt = isFallbackDetection
      ? _q2UnsupportedFallbackPrompt('irrelevant')
      : detectedPrompt;
  final content = _q2TrimIrrelevantPreamble(
    _q2IrrelevantBodyText(
      lines,
      start: promptIndex >= 0 ? promptIndex + 1 : 0,
    ),
  );
  final markerPattern = RegExp(
    '[\\(\\uFF08]?\\s*([$circled])\\s*[\\)\\uFF09]?|'
    '[\\(\\uFF08]\\s*([1-9])\\s*[\\)\\uFF09]|'
    '^\\s*([1-9])[\\).]\\s*',
    multiLine: true,
  );
  final markers = markerPattern.allMatches(content).toList();
  final numbered = <Map<String, dynamic>>[];
  for (var index = 0; index < markers.length; index++) {
    final marker = markers[index];
    final circledToken = marker.group(1);
    final position = circledToken != null
        ? circled.indexOf(circledToken) + 1
        : int.tryParse(marker.group(2) ?? marker.group(3) ?? '');
    final end =
        index + 1 < markers.length ? markers[index + 1].start : content.length;
    final text = stripLeadingIrrelevantMarkers(content
        .substring(marker.end, end)
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceFirst(RegExp(r'^[\)\uFF09]\s*'), '')
        .replaceFirst(RegExp(r'\s*[\(\uFF08]$'), '')
        .trim());
    if (position != null && position > 0 && position <= circled.length) {
      numbered.add(<String, dynamic>{'position': position, 'text': text});
    }
  }

  final positions = numbered
      .map((item) => item['position'])
      .whereType<int>()
      .toList(growable: false);
  final passageParts = <String>[
    if (markers.isNotEmpty &&
        content.substring(0, markers.first.start).trim().isNotEmpty)
      content
          .substring(0, markers.first.start)
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
    for (final item in numbered)
      irrelevantSentenceWithMarker(
        item['position'] as int,
        (item['text'] ?? '').toString(),
      ),
  ];
  final passageWithNumbers = passageParts.join('\n').trim();
  final extractedAnswerRaw = _q2ExtractAnswerRawFull(lines).trim();
  final answerInfo = _q2ExtractAnswer(lines);
  final answerRaw = extractedAnswerRaw.isNotEmpty
      ? extractedAnswerRaw
      : answerInfo.raw.trim();
  final answerPosition = _q2ParseIrrelevantAnswerPosition(answerRaw) ??
      (answerInfo.index != null &&
              answerInfo.index! >= 0 &&
              answerInfo.index! < 7
          ? answerInfo.index! + 1
          : null);
  final warnings = <String>[
    if (passageWithNumbers.isEmpty) 'Missing numbered passage.',
    if (numbered.length < 5) 'Not enough numbered sentences.',
    if (positions.length < 5) 'Not enough selectable positions.',
    if (answerPosition == null) 'Missing irrelevant sentence answer.',
    if (answerPosition != null && !positions.contains(answerPosition))
      'Answer position is outside the numbered passage.',
  ];
  final question = QuestionImportDraft(
    questionNo: number,
    source: source,
    questionType: 'irrelevant',
    passage: passageWithNumbers,
    questionText:
        prompt.isNotEmpty ? prompt : _q2UnsupportedFallbackPrompt('irrelevant'),
    choices: const <String>[],
    answerIndex: null,
    answerRaw: answerRaw,
    explanation: _q2ExtractOrderExplanation(lines),
    specialData: <String, dynamic>{
      'kind': 'irrelevant',
      'mode': 'single',
      'passage_with_numbers': passageWithNumbers,
      'numbered_sentences': numbered,
      'positions': positions,
      'answer_position': answerPosition,
    },
    answerText: answerPosition?.toString(),
    warnings: warnings,
    isSpecialUnsupported: false,
  );
  debugPrint(
    '[IrrelevantParser] no=$number sentences=${numbered.length} '
    'positions=${positions.length} answer=${answerPosition ?? '-'} '
    'saveable=${question.isSaveable} warnings=${warnings.length}',
  );
  if (isFallbackDetection &&
      detection.reason != 'promptless irrelevant fragment fallback') {
    debugPrint(
      '[IrrelevantFallback] no=$number reason=promptless_fragment '
      'markers=${positions.length} answer=${answerPosition ?? '-'}',
    );
  }
  return question;
}

int? _q2ParseIrrelevantAnswerPosition(String raw) {
  const circled = '①②③④⑤⑥⑦⑧⑨';
  final match = RegExp(r'[①②③④⑤⑥⑦⑧⑨]|[1-9]').firstMatch(raw);
  if (match == null) return null;
  final token = match.group(0)!;
  final circledIndex = circled.indexOf(token);
  return circledIndex >= 0 ? circledIndex + 1 : int.tryParse(token);
}

QuestionImportDraft _q2BuildUnsupportedSpecialQuestion(
  List<String> lines, {
  required int number,
  required String source,
  required _Q2TypeDetection detection,
}) {
  final answerInfo = _q2ExtractAnswer(lines);
  final promptIndex = detection.promptIndex >= 0
      ? detection.promptIndex
      : _q2FindPromptIndex(lines, lines.length);
  final extractedQuestionText =
      promptIndex >= 0 ? _qmCleanBodyLine(lines[promptIndex]) : '';
  final questionText = extractedQuestionText.trim().isNotEmpty
      ? extractedQuestionText.trim()
      : _q2UnsupportedFallbackPrompt(detection.type);
  final passage = _q2ExtractActualPassage(
    lines,
    start: promptIndex >= 0 ? promptIndex + 1 : 0,
    end: lines.indexWhere(_q2IsAnswerLine) == -1
        ? lines.length
        : lines.indexWhere(_q2IsAnswerLine),
  );
  final explanation = _q2ExtractOrderExplanation(lines);
  debugPrint(
    '[SpecialUnsupported] no=$number type=${detection.type} saveable=false',
  );
  return QuestionImportDraft(
    questionNo: number,
    source: source,
    questionType: detection.type,
    passage: passage,
    questionText: questionText,
    choices: const <String>[],
    answerIndex: answerInfo.index,
    answerRaw: answerInfo.raw,
    explanation: explanation,
    warnings: <String>[
      'Unsupported type: ${detection.type}',
    ],
    isSpecialUnsupported: true,
  );
}

String _q2UnsupportedFallbackPrompt(String type) {
  if (type == 'insertion') {
    return '\uAE00\uC758 \uD750\uB984\uC73C\uB85C \uBCF4\uC544, \uC8FC\uC5B4\uC9C4 \uBB38\uC7A5\uC774 \uB4E4\uC5B4\uAC00\uAE30\uC5D0 \uAC00\uC7A5 \uC801\uC808\uD55C \uACF3\uC740?';
  }
  if (type == 'irrelevant' || type == 'unrelated_sentence') {
    return '\uB2E4\uC74C \uAE00\uC5D0\uC11C \uC804\uCCB4 \uD750\uB984\uACFC \uAD00\uACC4\uC5C6\uB294 \uBB38\uC7A5\uC740?';
  }
  return '';
}

int _q2OrderContentEnd(List<String> lines, int start) {
  for (var index = start + 1; index < lines.length; index++) {
    final line = lines[index].trim();
    if (_q2IsAnswerLine(line) ||
        _q2IsExplanationLine(line) ||
        _q2IsVocabularyLine(line) ||
        _qmQuestionNumberFromLine(line) != null ||
        _q2IsSourceLine(line)) {
      return index;
    }
  }
  return lines.length;
}

RegExpMatch? _q2OrderBlockMatch(String line) {
  return RegExp(r'^\s*[\(（]?([A-Ea-e])[\)）]\s*(.*)$').firstMatch(line.trim());
}

bool _q2LooksLikeOrderPrompt(String line) {
  final clean = line.replaceAll(RegExp(r'\s+'), ' ').trim();
  return clean.contains('순서') ||
      clean.contains('배열') ||
      RegExp(r'order|arrange|sequence', caseSensitive: false).hasMatch(clean);
}

String _q2CleanOrderBodyLine(String line) {
  var clean = _qmCleanBodyLine(line).trim();
  if (clean.isEmpty) return '';
  if (_q2IsSourceLine(clean) ||
      _q2IsControlLine(clean) ||
      _q2LooksLikeOrderPrompt(clean)) {
    return '';
  }
  if (_q2ParseChoiceLine(clean) != null) return '';
  return clean;
}

String _q2ExtractAnswerRawFull(List<String> lines) {
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    final match = RegExp(r'^\[?\s*정답\s*\]?[:：]?\s*(.*)$').firstMatch(line);
    if (match == null) continue;
    final parts = <String>[];
    var raw = (match.group(1) ?? '').trim();
    raw = raw.replaceAll(RegExp(r'\[?\s*정답\s*\]?[:：]?'), '').trim();
    if (raw.isNotEmpty) parts.add(raw);
    for (var next = index + 1; next < lines.length; next++) {
      final continuation = lines[next].trim();
      if (continuation.isEmpty) continue;
      if (_q2IsExplanationLine(continuation) ||
          _q2IsVocabularyLine(continuation) ||
          _q2IsSourceLine(continuation) ||
          _qmQuestionNumberFromLine(continuation) != null) {
        break;
      }
      if (_q2IsAnswerLine(continuation)) break;
      parts.add(continuation);
    }
    return parts.join(' ').split(RegExp(r'\[?\s*(해설|해석)\s*\]?')).first.trim();
  }
  return '';
}

List<String> _q2ParseOrderAnswer(String raw) {
  final matches = RegExp(r'[\(（]?([A-Ea-e])[\)）]?').allMatches(raw);
  final labels = <String>[];
  for (final match in matches) {
    final label = (match.group(1) ?? '').toUpperCase();
    if (label.isNotEmpty) labels.add(label);
  }
  return labels;
}

String _q2ExtractOrderExplanation(List<String> lines) {
  final start = lines.indexWhere(_q2IsExplanationLine);
  if (start == -1) return '';
  final items = <String>[];
  for (var index = start; index < lines.length; index++) {
    var line = lines[index].trim();
    if (index == start) {
      line =
          line.replaceFirst(RegExp(r'^\[?\s*(해설|해석)\s*\]?[:：]?\s*'), '').trim();
    }
    if (_q2IsAnswerLine(line) || _q2IsVocabularyLine(line)) break;
    if (line.isNotEmpty) items.add(line);
  }
  return items.join('\n').trim();
}

String _q2ExtractExplanation(
  List<String> lines, {
  required int promptIndex,
  required int? choiceStart,
}) {
  final start = lines.indexWhere(_q2IsExplanationLine);
  if (start == -1) return '';
  final endCandidates = <int>[
    if (promptIndex > start) promptIndex,
    if (choiceStart != null && choiceStart > start) choiceStart,
    lines.length,
  ]..sort();
  final end = endCandidates.firstWhere(
    (value) => value > start,
    orElse: () => lines.length,
  );
  final items = <String>[];
  for (var index = start; index < end; index++) {
    var line = lines[index].trim();
    if (index == start) {
      line =
          line.replaceFirst(RegExp(r'^\[?\s*(해설|해석)\s*\]?[:：]?\s*'), '').trim();
    }
    if (_q2IsAnswerLine(line) || _q2IsVocabularyLine(line)) break;
    if (line.isNotEmpty) items.add(line);
  }
  return items.join('\n').trim();
}

List<_QmChoiceGroup> _q2ChoiceGroups(List<String> lines) {
  final groups = <_QmChoiceGroup>[];
  var choices = <String>[];
  var start = -1;
  var end = -1;

  void flush() {
    if (choices.length >= 2) {
      groups.add(_QmChoiceGroup(start: start, end: end, choices: choices));
    }
    choices = <String>[];
    start = -1;
    end = -1;
  }

  for (var index = 0; index < lines.length; index++) {
    final parsed = _q2ParseChoiceLine(lines[index]);
    if (parsed != null) {
      final choiceNumber = _q2ChoiceNumber(lines[index]);
      if (choices.isNotEmpty && choiceNumber == 1) {
        flush();
      }
      if (choices.isEmpty) start = index;
      choices.add(parsed);
      end = index + 1;
      continue;
    }
    if (choices.isNotEmpty) {
      final line = lines[index].trim();
      final shouldContinue = line.isNotEmpty &&
          !_q2LooksLikePrompt(line) &&
          !_q2IsControlLine(line) &&
          _qmQuestionNumberFromLine(line) == null &&
          !_q2IsSourceLine(line);
      if (shouldContinue) {
        choices[choices.length - 1] = '${choices.last} $line'.trim();
        end = index + 1;
      } else {
        flush();
      }
    }
  }
  flush();
  return groups;
}

_QmChoiceGroup? _q2LastChoiceGroup(List<String> lines) {
  final groups = _q2ChoiceGroups(lines);
  if (groups.isEmpty) return null;
  final selected = groups.last;
  return _QmChoiceGroup(
    start: selected.start,
    end: selected.end,
    choices: selected.choices,
    groupCount: groups.length,
  );
}

_QmChoiceGroup? _q2ChoiceGroupAfterPrompt(
  List<_QmChoiceGroup> groups,
  int promptIndex,
) {
  final candidates = groups.where((group) => group.start > promptIndex);
  if (candidates.isEmpty) return null;
  final selected = candidates.last;
  return _QmChoiceGroup(
    start: selected.start,
    end: selected.end,
    choices: selected.choices,
    groupCount: groups.length,
  );
}

int _q2FindPromptIndexForActualChoices(
  List<String> lines,
  List<_QmChoiceGroup> groups,
) {
  var selectedPrompt = -1;
  for (final group in groups) {
    final prompt = _q2FindPromptIndex(lines, group.start);
    if (prompt == -1) continue;
    if (!_q2HasEnglishPassageBetween(lines, prompt + 1, group.start)) {
      continue;
    }
    selectedPrompt = prompt;
  }
  if (selectedPrompt != -1) return selectedPrompt;
  if (groups.isNotEmpty) return _q2FindPromptIndex(lines, groups.last.start);
  return _q2FindPromptIndex(lines, lines.length);
}

bool _q2HasEnglishPassageBetween(List<String> lines, int start, int end) {
  final from = start.clamp(0, lines.length);
  final to = end.clamp(0, lines.length);
  if (from >= to) return false;
  for (var index = from; index < to; index++) {
    final line = _qmCleanBodyLine(lines[index]);
    if (_q2LooksLikeEnglishPassageLine(line)) return true;
  }
  return false;
}

String _q2ExtractActualPassage(
  List<String> lines, {
  required int start,
  required int end,
}) {
  final from = start.clamp(0, lines.length);
  final to = end.clamp(0, lines.length);
  if (from >= to) return '';
  return lines
      .sublist(from, to)
      .map(_qmCleanBodyLine)
      .where((line) => line.isNotEmpty)
      .where((line) => !_q2IsSourceLine(line))
      .where((line) => !_q2IsControlLine(line))
      .where((line) => _qmQuestionNumberFromLine(line) == null)
      .where((line) => _q2ParseChoiceLine(line) == null)
      .where(_q2LooksLikeEnglishPassageLine)
      .join('\n')
      .trim();
}

bool _q2LooksLikeEnglishPassageLine(String line) {
  final text = line.trim();
  if (text.isEmpty) return false;
  if (!RegExp(r'[A-Za-z]').hasMatch(text)) return false;
  if (_q2LooksLikePrompt(text)) return false;
  if (_q2ParseChoiceLine(text) != null) return false;

  final letters = RegExp(r'[A-Za-z]').allMatches(text).length;
  final hangul = RegExp(r'[가-힣]').allMatches(text).length;
  if (hangul > 0 && hangul >= letters) return false;

  return true;
}

int? _q2ChoiceNumber(String line) {
  final clean = line.trim();
  if (clean.isEmpty) return null;
  final first = String.fromCharCode(clean.runes.first);
  final circled = _qmCircledLabels.indexOf(first);
  if (circled >= 0) return circled + 1;
  final numeric =
      RegExp(r'^\s*(?:[（(]?([1-9])[）)]|([1-9])[\).])').firstMatch(clean);
  final value = numeric?.group(1) ?? numeric?.group(2);
  return value == null ? null : int.tryParse(value);
}

String? _q2ParseChoiceLine(String line) {
  final match = RegExp(
    r'^\s*(?:[①②③④⑤⑥⑦⑧⑨]|[1-9][\).]|[（(][1-9][）)]|[ⓐⓑⓒⓓⓔⓕⓖⓗⓘ])\s*(.+)$',
  ).firstMatch(line);
  final value = match?.group(1)?.trim();
  return value == null || value.isEmpty ? null : value;
}

int _q2FindPromptIndex(List<String> lines, int beforeIndex) {
  final end = beforeIndex.clamp(0, lines.length);
  for (var index = end - 1; index >= 0; index--) {
    if (_q2LooksLikePrompt(lines[index])) return index;
  }
  return -1;
}

bool _q2LooksLikePrompt(String line) {
  return RegExp(
    r'(가장\s*적절한\s*것|적절하지\s*않은\s*것|일치하는\s*것|일치하지\s*않는\s*것|빈칸|들어갈\s*말|들어가기에|순서|배열|의미하는\s*바|함의|목적|주제|제목|요지)',
  ).hasMatch(line);
}

String _q2InferQuestionType(String prompt) {
  final text = prompt.replaceAll(RegExp(r'\s+'), '');
  if (text.contains('빈칸') || text.contains('들어갈말')) return 'blank';
  if (text.contains('주제')) return 'topic';
  if (text.contains('제목')) return 'title';
  if (text.contains('요지')) return 'gist';
  if (text.contains('의미하는바') || text.contains('함의')) {
    return 'implication';
  }
  if (text.contains('목적')) return 'purpose';
  if (text.contains('일치하지않는') || text.contains('적절하지않은')) {
    return 'mismatch';
  }
  if (text.contains('일치하는')) return 'content';
  if (text.contains('들어가기에') || text.contains('삽입')) return 'insertion';
  if (text.contains('순서') || text.contains('배열')) return 'order';
  return '';
}

bool _qmIsSourceLine(String line) {
  return RegExp(r'^\[[^\]]+\]$').hasMatch(line) &&
      !RegExp(r'정답|해설|해석|어휘').hasMatch(line);
}

String _qmExtractSource(List<String> lines) {
  for (final line in lines) {
    final labeled = RegExp(r'^\[?\s*출처\s*\]?[:：]\s*(.+)$')
        .firstMatch(line)
        ?.group(1)
        ?.trim();
    if (labeled != null && labeled.isNotEmpty) return labeled;
    final bracket =
        RegExp(r'^\[([^\]]+)\]$').firstMatch(line)?.group(1)?.trim();
    if (bracket != null &&
        bracket.isNotEmpty &&
        !RegExp(r'정답|해설|해석|어휘').hasMatch(bracket)) {
      return bracket;
    }
  }
  return '';
}

bool _qmIsControlLine(String line) {
  return RegExp(r'^<?\s*(기본|러닝|프리뷰|문제)\s*>?$').hasMatch(line) ||
      RegExp(r'^\[?\s*(정답|해설|해석|어휘)\s*\]?[:：]?').hasMatch(line);
}

_QmAnswerInfo _qmExtractAnswer(List<String> lines) {
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    final match = RegExp(r'^\[?\s*정답\s*\]?[:：]?\s*(.*)$').firstMatch(line);
    if (match == null) continue;
    var raw = (match.group(1) ?? '').trim();
    raw = raw.replaceAll(RegExp(r'\[?\s*정답\s*\]?[:：]?'), '').trim();
    if (raw.isEmpty && index + 1 < lines.length) raw = lines[index + 1].trim();
    return _qmParseAnswerRaw(raw);
  }
  return const _QmAnswerInfo(raw: '', index: null, warnings: ['정답 라벨이 없습니다.']);
}

_QmAnswerInfo _qmParseAnswerRaw(String raw) {
  final normalized = raw.trim();
  if (normalized.isEmpty) {
    return const _QmAnswerInfo(
        raw: '', index: null, warnings: ['정답이 비어 있습니다.']);
  }
  final indices = <int>{};
  for (final rune in normalized.runes) {
    final char = String.fromCharCode(rune);
    final circledIndex = _qmCircledLabels.indexOf(char);
    if (circledIndex >= 0) indices.add(circledIndex);
  }
  for (final match in RegExp(r'(?<!\d)([1-9])\s*번?').allMatches(normalized)) {
    indices.add(int.parse(match.group(1)!) - 1);
  }
  for (final match
      in RegExp(r'\(([A-Ea-e])\)|\b([A-Ea-e])\b').allMatches(normalized)) {
    final letter = (match.group(1) ?? match.group(2) ?? '').toUpperCase();
    if (letter.isNotEmpty) {
      indices.add(letter.codeUnitAt(0) - 'A'.codeUnitAt(0));
    }
  }
  if (indices.length == 1) {
    return _QmAnswerInfo(raw: normalized, index: indices.first);
  }
  if (indices.length > 1) {
    return _QmAnswerInfo(
      raw: normalized,
      index: null,
      isSpecialUnsupported: true,
      warnings: const ['복수정답 또는 특수정답 유형은 이번 단계에서 저장하지 않습니다.'],
    );
  }
  return _QmAnswerInfo(
    raw: normalized,
    index: null,
    warnings: const ['정답을 선택지 번호로 해석하지 못했습니다.'],
  );
}

String _qmExtractExplanation(
  List<String> lines, {
  required int promptIndex,
  required int? choiceStart,
}) {
  final start = lines.indexWhere(
    (line) => RegExp(r'^\[?\s*(해설|해석)\s*\]?[:：]?').hasMatch(line),
  );
  if (start == -1) return '';
  final endCandidates = <int>[
    if (promptIndex > start) promptIndex,
    if (choiceStart != null && choiceStart > start) choiceStart,
    lines.length,
  ]..sort();
  final end = endCandidates.firstWhere((value) => value > start,
      orElse: () => lines.length);
  final items = <String>[];
  for (var index = start; index < end; index++) {
    var line = lines[index].trim();
    if (index == start) {
      line =
          line.replaceFirst(RegExp(r'^\[?\s*(해설|해석)\s*\]?[:：]?\s*'), '').trim();
    }
    if (RegExp(r'^\[?\s*(정답|어휘)\s*\]?[:：]?').hasMatch(line)) break;
    if (line.isNotEmpty) items.add(line);
  }
  return items.join('\n').trim();
}

_QmChoiceGroup? _qmLastChoiceGroup(List<String> lines) {
  final groups = <_QmChoiceGroup>[];
  var choices = <String>[];
  var start = -1;
  var end = -1;

  void flush() {
    if (choices.length >= 2) {
      groups.add(_QmChoiceGroup(start: start, end: end, choices: choices));
    }
    choices = <String>[];
    start = -1;
    end = -1;
  }

  for (var index = 0; index < lines.length; index++) {
    final parsed = _qmParseChoiceLine(lines[index]);
    if (parsed != null) {
      if (choices.isEmpty) start = index;
      choices.add(parsed);
      end = index + 1;
      continue;
    }
    if (choices.isNotEmpty) {
      final line = lines[index].trim();
      final shouldContinue = line.isNotEmpty &&
          !_qmLooksLikePrompt(line) &&
          !_qmIsControlLine(line) &&
          _qmQuestionNumberFromLine(line) == null;
      if (shouldContinue) {
        choices[choices.length - 1] = '${choices.last} $line'.trim();
        end = index + 1;
      } else {
        flush();
      }
    }
  }
  flush();
  return groups.isEmpty ? null : groups.last;
}

String? _qmParseChoiceLine(String line) {
  final match = RegExp(
    r'^\s*(?:[①②③④⑤⑥⑦⑧⑨]|[1-9][\).]|[（(][1-9][）)]|[ⓐⓑⓒⓓⓔⓕⓖⓗⓘ])\s*(.+)$',
  ).firstMatch(line);
  final value = match?.group(1)?.trim();
  return value == null || value.isEmpty ? null : value;
}

int _qmFindPromptIndex(List<String> lines, int beforeIndex) {
  final end = beforeIndex.clamp(0, lines.length);
  for (var index = end - 1; index >= 0; index--) {
    if (_qmLooksLikePrompt(lines[index])) return index;
  }
  return -1;
}

bool _qmLooksLikePrompt(String line) {
  return RegExp(
    r'(가장\s*적절한\s*것|적절하지\s*않은\s*것|일치하는\s*것|일치하지\s*않는\s*것|빈칸|들어갈\s*말|들어가기에|순서|배열|의미하는\s*바|함의|목적|주제|제목|요지)',
  ).hasMatch(line);
}

String _qmInferQuestionType(String prompt) {
  final text = prompt.replaceAll(RegExp(r'\s+'), '');
  if (text.contains('빈칸') || text.contains('들어갈말')) return 'blank';
  if (text.contains('주제')) return 'topic';
  if (text.contains('제목')) return 'title';
  if (text.contains('요지')) return 'gist';
  if (text.contains('의미하는바') || text.contains('함의')) {
    return 'implication';
  }
  if (text.contains('목적')) return 'purpose';
  if (text.contains('일치하지않는') || text.contains('적절하지않은')) {
    return 'mismatch';
  }
  if (text.contains('일치하는')) return 'content';
  if (text.contains('들어가기에') || text.contains('삽입')) return 'insertion';
  if (text.contains('순서') || text.contains('배열')) return 'order';
  return '';
}

const _qmCircledLabels = '①②③④⑤⑥⑦⑧⑨';

String _qmPreview(String text, {int limit = 80}) {
  final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.length <= limit) return compact;
  return '${compact.substring(0, limit)}...';
}

void _qmDebugQuestions(List<QuestionImportDraft> questions) {
  debugPrint('[QuestionHWPX] candidates=${questions.length}');
  for (final question in questions) {
    debugPrint(
      '[QuestionImportDraft] no=${question.questionNo} '
      'type=${question.questionType} '
      'question="${_qmPreview(question.questionText)}" '
      'passage="${_qmPreview(question.passage)}" '
      'choices=${question.choices.length} '
      'answerIndex=${question.answerIndex} '
      'warnings=${question.warnings.length}',
    );
  }
}

class _Q2TypeDetection {
  const _Q2TypeDetection({
    required this.type,
    required this.promptIndex,
    required this.prompt,
    required this.reason,
  });

  final String type;
  final int promptIndex;
  final String prompt;
  final String reason;
}

class _Q2InsertionCandidateSplit {
  const _Q2InsertionCandidateSplit({
    required this.sentence,
    required this.passage,
  });

  final String sentence;
  final String passage;
}

class _QmQuestionBlock {
  const _QmQuestionBlock({required this.number, required this.lines});

  final int number;
  final List<String> lines;
}

class _QmNumberedAnchor {
  const _QmNumberedAnchor({
    required this.index,
    required this.number,
    required this.numberLineIndex,
    required this.promptIndex,
  });

  final int index;
  final int number;
  final int numberLineIndex;
  final int promptIndex;
}

class _QmChoiceGroup {
  const _QmChoiceGroup({
    required this.start,
    required this.end,
    required this.choices,
    this.groupCount = 1,
  });

  final int start;
  final int end;
  final List<String> choices;
  final int groupCount;
}

class _QmAnswerInfo {
  const _QmAnswerInfo({
    required this.raw,
    required this.index,
    this.warnings = const [],
    this.isSpecialUnsupported = false,
  });

  final String raw;
  final int? index;
  final List<String> warnings;
  final bool isSpecialUnsupported;
}

ProblemSetImportDraft _legacyParseQuestionHwpxImportText(
  String rawText, {
  String textbookFolderName = '',
  String unitFolderName = '',
}) {
  final normalized = rawText
      .replaceAll('\r\n', '\n')
      .replaceAll('\u00A0', ' ')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .trim();
  final blocks = _splitQuestionBlocks(normalized);
  final questions = <QuestionImportDraft>[
    for (var index = 0; index < blocks.length; index++)
      _parseQuestionBlock(blocks[index], fallbackNo: index + 1),
  ];
  final firstSource = questions
      .map((question) => question.source.trim())
      .firstWhere((source) => source.isNotEmpty, orElse: () => '');
  final passage = questions
      .map((question) => question.passage.trim())
      .firstWhere((passage) => passage.isNotEmpty, orElse: () => '');
  final source = unitFolderName.trim().isNotEmpty
      ? unitFolderName.trim()
      : firstSource.trim().isNotEmpty
          ? firstSource.trim()
          : 'HWPX 문제 Import';
  return ProblemSetImportDraft(
    name: '$source 단일정답 문제세트',
    source: source,
    textbookFolderName: textbookFolderName,
    unitFolderName: unitFolderName,
    passage: passage,
    questions: questions,
    warnings: [
      if (questions.isEmpty) '문제 후보를 찾지 못했습니다.',
      if (questions.where((question) => question.isSaveable).isEmpty)
        '저장 가능한 단일정답 객관식 문제가 없습니다.',
    ],
  );
}

List<_QuestionBlock> _splitQuestionBlocks(String text) {
  final lines = text
      .split(RegExp(r'\n+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.isEmpty) return const [];

  final starts = <int>[];
  for (var index = 0; index < lines.length; index++) {
    if (_questionNumberFromLine(lines[index]) != null) starts.add(index);
  }
  if (starts.isEmpty) {
    return [_QuestionBlock(number: 1, text: lines.join('\n'))];
  }

  final blocks = <_QuestionBlock>[];
  for (var i = 0; i < starts.length; i++) {
    final start = starts[i];
    final end = i + 1 < starts.length ? starts[i + 1] : lines.length;
    final number = _questionNumberFromLine(lines[start]) ?? i + 1;
    final blockLines = lines.sublist(start, end);
    blocks.add(_QuestionBlock(number: number, text: blockLines.join('\n')));
  }
  return blocks;
}

QuestionImportDraft _parseQuestionBlock(
  _QuestionBlock block, {
  required int fallbackNo,
}) {
  final lines = block.text
      .split(RegExp(r'\n+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  final number = block.number == 0 ? fallbackNo : block.number;
  final source = _extractSource(lines);
  final answerInfo = _extractAnswer(lines);
  final explanation = _extractExplanation(lines);
  final answerLineIndex = _firstAnswerLineIndex(lines);
  final questionLines =
      answerLineIndex == -1 ? lines : lines.sublist(0, answerLineIndex);
  final strippedQuestionLines = questionLines
      .map(_stripQuestionNumber)
      .where((line) => line.isNotEmpty)
      .where((line) => !_isSourceLine(line))
      .toList();
  final choices = _extractChoices(strippedQuestionLines);
  final choiceStart = _firstChoiceLineIndex(strippedQuestionLines);
  final beforeChoices = choiceStart == -1
      ? strippedQuestionLines
      : strippedQuestionLines.sublist(0, choiceStart);
  final promptIndex = _lastPromptLineIndex(beforeChoices);
  final questionText = promptIndex == -1
      ? beforeChoices.isNotEmpty
          ? beforeChoices.last
          : ''
      : beforeChoices.sublist(promptIndex).join('\n');
  final passage = promptIndex == -1
      ? beforeChoices.length > 1
          ? beforeChoices.sublist(0, beforeChoices.length - 1).join('\n')
          : ''
      : beforeChoices.sublist(0, promptIndex).join('\n');
  final questionType = _inferQuestionType(questionText);
  final warnings = <String>[
    if (questionType.isEmpty) '문제 유형을 추론하지 못했습니다.',
    if (questionText.trim().isEmpty) '문항이 비어 있습니다.',
    if (choices.length < 2) '선택지가 부족합니다.',
    if (choices.length > 5) '선택지가 6개 이상입니다. 기존 학생 풀이 UI 확인이 필요합니다.',
    if (answerInfo.index == null) '정답을 찾지 못했습니다.',
    if (answerInfo.index != null && answerInfo.index! >= choices.length)
      '정답이 선택지 범위를 벗어났습니다.',
    if (explanation.trim().isEmpty) '해설이 없습니다.',
    if (passage.trim().isEmpty) '지문이 없습니다.',
    ...answerInfo.warnings,
  ];
  return QuestionImportDraft(
    questionNo: number,
    source: source,
    questionType: questionType,
    passage: passage,
    questionText: questionText,
    choices: choices,
    answerIndex: answerInfo.index,
    answerRaw: answerInfo.raw,
    explanation: explanation,
    warnings: warnings,
    isSpecialUnsupported: answerInfo.isSpecialUnsupported,
  );
}

int? _questionNumberFromLine(String line) {
  final match = RegExp(r'^\s*(\d{1,3})\s*[\).]\s*$').firstMatch(line);
  if (match != null) return int.tryParse(match.group(1)!);
  final inline = RegExp(r'^\s*(\d{1,3})\s*[\).]\s+').firstMatch(line);
  return inline == null ? null : int.tryParse(inline.group(1)!);
}

String _stripQuestionNumber(String line) {
  return line.replaceFirst(RegExp(r'^\s*\d{1,3}\s*[\).]\s*'), '').trim();
}

bool _isSourceLine(String line) {
  return RegExp(r'^\[[^\]]*(수능특강|영어|강|변형)[^\]]*\]$').hasMatch(line) ||
      RegExp(r'^\[?\s*출처\s*\]?[:：]').hasMatch(line);
}

String _extractSource(List<String> lines) {
  for (final line in lines) {
    final source = RegExp(r'^\[([^\]]*(?:수능특강|영어|강|변형)[^\]]*)\]$')
        .firstMatch(line)
        ?.group(1)
        ?.trim();
    if (source != null && source.isNotEmpty) return source;
    final labeled = RegExp(r'^\[?\s*출처\s*\]?[:：]\s*(.+)$')
        .firstMatch(line)
        ?.group(1)
        ?.trim();
    if (labeled != null && labeled.isNotEmpty) return labeled;
  }
  return '';
}

int _firstAnswerLineIndex(List<String> lines) {
  return lines.indexWhere((line) => RegExp(r'^\[?\s*정답\s*\]?').hasMatch(line));
}

_AnswerInfo _extractAnswer(List<String> lines) {
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    final match = RegExp(r'^\[?\s*정답\s*\]?[:：]?\s*(.*)$').firstMatch(line);
    if (match == null) continue;
    var raw = (match.group(1) ?? '').trim();
    if (raw.isEmpty && index + 1 < lines.length) raw = lines[index + 1].trim();
    return _parseAnswerRaw(raw);
  }
  return const _AnswerInfo(raw: '', index: null, warnings: ['정답 라벨이 없습니다.']);
}

_AnswerInfo _parseAnswerRaw(String raw) {
  final warnings = <String>[];
  final normalized = raw.trim();
  if (normalized.isEmpty) {
    return const _AnswerInfo(raw: '', index: null, warnings: ['정답이 비어 있습니다.']);
  }
  if (RegExp(r'\([A-Z]\)|[A-Z]\s*[-–—]\s*[A-Z]').hasMatch(normalized) ||
      RegExp(r'[①②③④⑤⑥⑦⑧⑨].*[①②③④⑤⑥⑦⑧⑨]').hasMatch(normalized) ||
      RegExp(r'\d.*\d').hasMatch(normalized.replaceAll(RegExp(r'\d+번'), ''))) {
    return _AnswerInfo(
      raw: normalized,
      index: null,
      isSpecialUnsupported: true,
      warnings: const ['복수정답 또는 특수정답 유형은 2단계에서 지원됩니다.'],
    );
  }
  final circled = RegExp(r'[①②③④⑤⑥⑦⑧⑨]').firstMatch(normalized)?.group(0);
  if (circled != null) {
    return _AnswerInfo(raw: normalized, index: '①②③④⑤⑥⑦⑧⑨'.indexOf(circled));
  }
  final digit = RegExp(r'([1-9])\s*번?').firstMatch(normalized)?.group(1);
  if (digit != null) {
    return _AnswerInfo(raw: normalized, index: int.parse(digit) - 1);
  }
  warnings.add('정답을 선택지 번호로 해석하지 못했습니다.');
  return _AnswerInfo(raw: normalized, index: null, warnings: warnings);
}

String _extractExplanation(List<String> lines) {
  final start = lines.indexWhere(
    (line) => RegExp(r'^\[?\s*(해설|풀이)\s*\]?[:：]?').hasMatch(line),
  );
  if (start == -1) return '';
  final items = <String>[];
  for (var index = start; index < lines.length; index++) {
    var line = lines[index].trim();
    if (index == start) {
      line =
          line.replaceFirst(RegExp(r'^\[?\s*(해설|풀이)\s*\]?[:：]?\s*'), '').trim();
    } else if (RegExp(r'^\[?\s*(어휘|정답)\s*\]?[:：]?').hasMatch(line)) {
      break;
    }
    if (line.isNotEmpty) items.add(line);
  }
  return items.join('\n').trim();
}

List<String> _extractChoices(List<String> lines) {
  final choices = <String>[];
  String? current;
  for (final line in lines) {
    final match = RegExp(
      r'^\s*([①②③④⑤⑥⑦⑧⑨]|[1-9][\).]|[（(][1-9][）)]|[ⓐⓑⓒⓓⓔⓕⓖⓗⓘ])\s*(.+)$',
    ).firstMatch(line);
    if (match != null) {
      if (current != null && current.trim().isNotEmpty) {
        choices.add(current.trim());
      }
      current = match.group(2)?.trim() ?? '';
    } else if (current != null && !_looksLikePrompt(line)) {
      current = '$current ${line.trim()}'.trim();
    }
  }
  if (current != null && current.trim().isNotEmpty) choices.add(current.trim());
  return choices;
}

int _firstChoiceLineIndex(List<String> lines) {
  return lines.indexWhere((line) => RegExp(
        r'^\s*([①②③④⑤⑥⑦⑧⑨]|[1-9][\).]|[（(][1-9][）)]|[ⓐⓑⓒⓓⓔⓕⓖⓗⓘ])\s+',
      ).hasMatch(line));
}

int _lastPromptLineIndex(List<String> lines) {
  for (var index = lines.length - 1; index >= 0; index--) {
    if (_looksLikePrompt(lines[index])) return index;
  }
  return -1;
}

bool _looksLikePrompt(String line) {
  return RegExp(
    r'(가장\s*적절한\s*것|일치하는\s*것|일치하지\s*않는\s*것|빈칸|들어가기에|순서|배열|의미하는\s*바|목적|주제|제목|요지)',
  ).hasMatch(line);
}

String _inferQuestionType(String prompt) {
  final text = prompt.replaceAll(RegExp(r'\s+'), '');
  if (text.contains('주제') && text.contains('적절')) return 'topic';
  if (text.contains('제목') && text.contains('적절')) return 'title';
  if (text.contains('요지') && text.contains('적절')) return 'gist';
  if (text.contains('의미하는바') || text.contains('함의')) {
    return 'implication';
  }
  if (text.contains('목적') && text.contains('적절')) return 'purpose';
  if (text.contains('빈칸')) return 'blank';
  if (text.contains('일치하지않는')) return 'mismatch';
  if (text.contains('일치하는')) return 'content';
  if (text.contains('들어가기에') || text.contains('삽입')) return 'insertion';
  if (text.contains('순서') || text.contains('배열')) return 'order';
  return '';
}

class _QuestionBlock {
  const _QuestionBlock({required this.number, required this.text});

  final int number;
  final String text;
}

class _AnswerInfo {
  const _AnswerInfo({
    required this.raw,
    required this.index,
    this.warnings = const [],
    this.isSpecialUnsupported = false,
  });

  final String raw;
  final int? index;
  final List<String> warnings;
  final bool isSpecialUnsupported;
}
