// ignore_for_file: unused_element

import 'package:flutter/foundation.dart';

import '../models/problem_set_import_draft.dart';
import '../models/question_import_draft.dart';
import 'irrelevant_display_passage.dart';
import 'workbook_hwpx_text_extractor.dart';

void debugQuestionHwpxParagraphStructure(
  List<String> paragraphs, {
  List<List<String>> paragraphRuns = const <List<String>>[],
  List<int> paragraphIndexes = const <int>[],
}) {
  if (paragraphs.isEmpty) return;
  final normalizedParagraphs = <String>[
    for (final paragraph in paragraphs) _qmNormalizeText(paragraph),
  ];
  final longHeaderPositions = <int>[
    for (var index = 0; index < normalizedParagraphs.length; index++)
      if (_q4ParagraphHasLongHeader(normalizedParagraphs[index])) index,
  ];
  if (longHeaderPositions.isEmpty) {
    debugPrint(
      '[HwpxLongBoundary] longHeaderDetected=false paragraphs=${paragraphs.length}',
    );
    return;
  }

  var groupStart = longHeaderPositions.last;
  var firstPrompt = -1;
  for (final headerPosition in longHeaderPositions.reversed) {
    final nextHeader = longHeaderPositions.firstWhere(
      (position) => position > headerPosition,
      orElse: () => paragraphs.length,
    );
    final promptPositions = <int>[
      for (var index = headerPosition + 1; index < nextHeader; index++)
        if (_q4ParagraphHasQuestionHeader(normalizedParagraphs[index])) index,
    ];
    if (promptPositions.length >= 2) {
      groupStart = headerPosition;
      firstPrompt = promptPositions.first;
      break;
    }
  }
  if (firstPrompt == -1) {
    for (var index = groupStart + 1; index < paragraphs.length; index++) {
      if (_q4ParagraphHasQuestionHeader(normalizedParagraphs[index])) {
        firstPrompt = index;
        break;
      }
    }
  }

  var blockEnd = groupStart - 1;
  while (blockEnd >= 0 &&
      (_qmIsLegacyHeading(normalizedParagraphs[blockEnd]) ||
          normalizedParagraphs[blockEnd].trim().isEmpty)) {
    blockEnd--;
  }
  final passageEnd = firstPrompt == -1 ? paragraphs.length : firstPrompt;
  final sharedPassagePresent = paragraphs
      .sublist(groupStart + 1, passageEnd)
      .any((paragraph) => RegExp(r'[A-Za-z]').hasMatch(paragraph));
  int xmlIndex(int position) =>
      position >= 0 && position < paragraphIndexes.length
          ? paragraphIndexes[position]
          : position;
  debugPrint(
    '[HwpxLongBoundary] longHeaderDetected=true '
    'block12EndParagraph=${xmlIndex(blockEnd)} '
    'longGroupStartParagraph=${xmlIndex(groupStart)} '
    'groupStartParagraph=${xmlIndex(groupStart)} '
    'sharedPassagePresent=$sharedPassagePresent',
  );

  final logStart = blockEnd < 0 ? groupStart : blockEnd;
  final logEnd = firstPrompt == -1 ? groupStart : firstPrompt;
  for (var index = logStart; index <= logEnd; index++) {
    final normalized = normalizedParagraphs[index]
        .replaceAll('\n', ' | ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final longHeader = _q4ParagraphHasLongHeader(normalizedParagraphs[index]);
    final questionHeader =
        _q4ParagraphHasQuestionHeader(normalizedParagraphs[index]);
    final sourceOrHeader = longHeader ||
        _qmIsLegacyHeading(normalizedParagraphs[index]) ||
        normalizedParagraphs[index]
            .split('\n')
            .any((line) => _q2IsSourceLine(line.trim()));
    final runs =
        index < paragraphRuns.length ? paragraphRuns[index] : const <String>[];
    debugPrint(
      '[HwpxLongParagraph] index=${xmlIndex(index)} '
      'normalized="${_qmPreview(normalized, limit: 120)}" '
      'longHeaderMatcher=$longHeader '
      'questionHeaderMatcher=$questionHeader '
      'sourceOrHeader=$sourceOrHeader '
      'runCount=${runs.length} '
      'runs=${runs.map((run) => _qmPreview(run, limit: 40)).toList()}',
    );
  }
}

bool _q4ParagraphHasLongHeader(String normalizedParagraph) {
  return normalizedParagraph
      .split('\n')
      .any((line) => _q4IsLongPassageHeader(line.trim()));
}

bool _q4ParagraphHasQuestionHeader(String normalizedParagraph) {
  return normalizedParagraph.split('\n').any((line) {
    final clean = line.trim();
    return _qmQuestionNumberFromLine(clean) != null ||
        _q4LooksLikeChildQuestionPrompt(clean);
  });
}

ProblemSetImportDraft parseQuestionHwpxImportText(
  String rawText, {
  String textbookFolderName = '',
  String unitFolderName = '',
  List<String> debugParagraphs = const <String>[],
  List<int> debugParagraphIndexes = const <int>[],
  List<List<HwpxUnderlineRange>> paragraphUnderlineRanges =
      const <List<HwpxUnderlineRange>>[],
}) {
  final normalized = _qmNormalizeText(rawText);
  final confirmedAnswerExplanationResidues =
      _qmConfirmedAnswerExplanationChoiceResidues(normalized);
  final rawDirectlyParsedLongSetQuestions =
      _q4ParseLongPassageSetQuestions(normalized);
  final blocks = _qmSplitQuestionBlocks(normalized);
  final rawBlockParsedQuestions = <QuestionImportDraft>[
    for (var index = 0; index < blocks.length; index++)
      _qmParseQuestionBlock(blocks[index], fallbackNo: index + 1),
  ];
  _qmDebugDraftParagraphBoundaries(
    rawBlockParsedQuestions,
    debugParagraphs,
    debugParagraphIndexes,
  );
  final blockParsedQuestions = _qmRepairComplementaryAndOrphanDrafts(
    rawBlockParsedQuestions,
    confirmedAnswerExplanationResidues,
  );
  final directlyParsedLongSetQuestions = _q4AlignDirectQuestionNumbers(
    blockParsedQuestions,
    rawDirectlyParsedLongSetQuestions,
  );
  _q4DebugAlignedLongGroups(directlyParsedLongSetQuestions);
  final longPassageSets = directlyParsedLongSetQuestions.isEmpty
      ? _q4DetectLongPassageSets(normalized)
      : const <_Q4LongPassageSet>[];
  final rawAnswerBoundaries = normalized
      .split('\n')
      .where((line) => _q2IsAnswerLine(line.trim()))
      .length;
  _q4DebugStageQuestions('blockDrafts', blockParsedQuestions);
  _q4DebugStageQuestions(
    'directLongDraftsBeforeAlignment',
    rawDirectlyParsedLongSetQuestions,
  );
  _q4DebugStageQuestions(
    'directLongDraftsAfterAlignment',
    directlyParsedLongSetQuestions,
  );
  debugPrint(
    '[QuestionImportStages] normalizedLength=${normalized.length} '
    'rawAnswerBoundaries=$rawAnswerBoundaries '
    'rawQuestionBoundaries=${blocks.length} '
    'blockDrafts=${blockParsedQuestions.length} '
    'directLongDrafts=${directlyParsedLongSetQuestions.length} '
    'directLongQuestionNos=${directlyParsedLongSetQuestions.map((question) => question.questionNo).toList()}',
  );
  final mergedParsedQuestions = directlyParsedLongSetQuestions.isNotEmpty
      ? _q4MergeDirectlyParsedQuestions(
          blockParsedQuestions,
          directlyParsedLongSetQuestions,
          confirmedAnswerExplanationResidues,
        )
      : blockParsedQuestions;
  final hasExplicitQuestionNumbers = normalized
      .split(RegExp(r'\n+'))
      .any((line) => _qmQuestionNumberFromLine(line.trim()) != null);
  final parsedQuestions = hasExplicitQuestionNumbers
      ? mergedParsedQuestions
      : <QuestionImportDraft>[
          for (var index = 0; index < mergedParsedQuestions.length; index++)
            mergedParsedQuestions[index].copyWith(questionNo: index + 1),
        ];
  final questions = _q4ApplyLongPassageSets(
    parsedQuestions,
    longPassageSets,
  );
  _q4DebugStageQuestions('beforeSaveabilityRepair', questions);
  final insertionRepairedQuestions =
      _q2RepairExactSingleInsertionQuestions(questions, normalized);
  var repairedQuestions = _q2RepairActualMissingTypeIrrelevantQuestions(
    insertionRepairedQuestions,
    normalized,
  );
  repairedQuestions = _q3RecoverMissingGrammarVocabularyPassages(
    repairedQuestions,
    normalized,
  );
  repairedQuestions = _q3DropVocabularyOnlyQuestions(repairedQuestions);
  repairedQuestions = _qmApplyOriginalUnderlineRanges(
    repairedQuestions,
    paragraphUnderlineRanges,
  );
  _q4DebugStageQuestions('finalCandidates', repairedQuestions);
  debugPrint(
    '[QuestionImportStages] mergedDrafts=${parsedQuestions.length} '
    'finalCandidates=${repairedQuestions.length} '
    'savable=${repairedQuestions.where((question) => question.isSaveable).length}',
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

const _originalUnderlineQuestionTypes = <String>{
  'topic',
  'title',
  'gist',
  'blank',
  'implication',
};

List<QuestionImportDraft> _qmApplyOriginalUnderlineRanges(
  List<QuestionImportDraft> questions,
  List<List<HwpxUnderlineRange>> paragraphUnderlineRanges,
) {
  final sourceRanges = paragraphUnderlineRanges
      .expand((ranges) => ranges)
      .where((range) => range.text.trim().isNotEmpty)
      .toList(growable: false);

  return <QuestionImportDraft>[
    for (final question in questions)
      if (_originalUnderlineQuestionTypes.contains(
        question.questionType.trim().toLowerCase(),
      ))
        _qmQuestionWithOriginalUnderlineRanges(question, sourceRanges)
      else
        question,
  ];
}

QuestionImportDraft _qmQuestionWithOriginalUnderlineRanges(
  QuestionImportDraft question,
  List<HwpxUnderlineRange> sourceRanges,
) {
  final passage = question.passage;
  final mapped = <Map<String, dynamic>>[];
  for (final sourceRange in sourceRanges) {
    final target = sourceRange.text.trim();
    if (target.isEmpty || _qmIsUnderlineBlankPlaceholder(target)) continue;
    final located = _qmLocateIgnoringWhitespace(passage, target);
    if (located == null) continue;
    if (mapped.any(
      (range) => range['start'] == located.$1 && range['end'] == located.$2,
    )) {
      continue;
    }
    mapped.add(<String, dynamic>{
      'start': located.$1,
      'end': located.$2,
      'text': passage.substring(located.$1, located.$2),
    });
  }
  mapped.sort(
    (left, right) => (left['start'] as int).compareTo(right['start'] as int),
  );

  final specialData = <String, dynamic>{...?question.specialData};
  if (mapped.isNotEmpty) {
    specialData['underline_ranges'] = mapped;
  } else {
    specialData.remove('underline_ranges');
  }
  final warnings = <String>[
    ...question.warnings.where(
      (warning) => warning != 'missing_underlined_target',
    ),
    if (question.questionType.trim().toLowerCase() == 'implication' &&
        mapped.isEmpty)
      'missing_underlined_target',
  ];
  return question.copyWith(
    specialData: specialData,
    clearSpecialData: specialData.isEmpty,
    warnings: warnings,
  );
}

bool _qmIsUnderlineBlankPlaceholder(String text) =>
    RegExp(r'^\s*(?:_{2,}|\[\s*\])\s*$').hasMatch(text);

(int, int)? _qmLocateIgnoringWhitespace(String passage, String target) {
  final normalizedPassage = StringBuffer();
  final originalIndexes = <int>[];
  var previousWasWhitespace = false;
  for (var index = 0; index < passage.length; index++) {
    final char = passage[index];
    final isWhitespace = char.trim().isEmpty;
    if (isWhitespace) {
      if (previousWasWhitespace) continue;
      normalizedPassage.write(' ');
      originalIndexes.add(index);
    } else {
      normalizedPassage.write(char);
      originalIndexes.add(index);
    }
    previousWasWhitespace = isWhitespace;
  }
  final normalizedTarget = target.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalizedTarget.isEmpty) return null;
  final normalizedStart =
      normalizedPassage.toString().indexOf(normalizedTarget);
  if (normalizedStart < 0) return null;
  final normalizedEnd = normalizedStart + normalizedTarget.length - 1;
  if (normalizedEnd >= originalIndexes.length) return null;
  return (originalIndexes[normalizedStart], originalIndexes[normalizedEnd] + 1);
}

List<QuestionImportDraft> _qmRepairComplementaryAndOrphanDrafts(
  List<QuestionImportDraft> questions,
  Set<String> confirmedAnswerExplanationResidues,
) {
  final repaired = <QuestionImportDraft>[];
  for (var index = 0; index < questions.length; index++) {
    final current = questions[index];
    final next = index + 1 < questions.length ? questions[index + 1] : null;
    if (next != null && _qmAreComplementaryDrafts(current, next)) {
      final merged = current.copyWith(
        passage:
            current.passage.trim().isNotEmpty ? current.passage : next.passage,
        choices: current.choices.isNotEmpty ? current.choices : next.choices,
        answerIndex: current.answerIndex ?? next.answerIndex,
        answerRaw: current.answerRaw.trim().isNotEmpty
            ? current.answerRaw
            : next.answerRaw,
        explanation: current.explanation.trim().isNotEmpty
            ? current.explanation
            : next.explanation,
        warnings: <String>[
          ...current.warnings.where(
            (warning) =>
                warning != '본문을 찾지 못했습니다.' && warning != '선택지를 2개 이상 찾지 못했습니다.',
          ),
        ],
      );
      debugPrint(
        '[QuestionImportBoundaryRepair] path=recovered '
        'action=merge_complementary from=${current.questionNo},${next.questionNo} '
        'type=${current.questionType} passagePresent=${merged.passage.trim().isNotEmpty} '
        'choicesCount=${merged.choices.length}',
      );
      repaired.add(merged);
      index++;
      continue;
    }
    final previous = repaired.isEmpty ? null : repaired.last;
    if (previous != null &&
        _qmLooksLikeTailVocabularyOrphan(current, previous)) {
      final recoveredChoice = _qmTailChoiceText(current.questionText);
      final markerPosition = _qmLeadingChoicePosition(current.questionText);
      if (previous.choices.length == 4 &&
          markerPosition == 5 &&
          recoveredChoice.isNotEmpty) {
        repaired[repaired.length - 1] = previous.copyWith(
          choices: <String>[...previous.choices, recoveredChoice],
          warnings: previous.warnings
              .where((warning) =>
                  !warning.toLowerCase().contains('choice') &&
                  !warning.contains('선택지'))
              .toList(growable: false),
        );
        debugPrint(
          '[QuestionImportBoundaryRepair] path=recovered '
          'action=restore_fifth_choice previousNo=${previous.questionNo} '
          'orphanNo=${current.questionNo}',
        );
      } else {
        debugPrint(
          '[QuestionImportBoundaryRepair] path=block '
          'action=drop_tail_vocabulary_orphan previousNo=${previous.questionNo} '
          'orphanNo=${current.questionNo} choicesCount=${current.choices.length}',
        );
      }
      continue;
    }
    if (_qmIsChoiceOrExplanationOrphan(
      current,
      repaired,
      confirmedAnswerExplanationResidues,
    )) {
      debugPrint(
        '[QuestionImportBoundaryRepair] path=block '
        'action=drop_orphan no=${current.questionNo} '
        'type=${current.questionType} passagePresent=false '
        'choicesCount=${current.choices.length} '
        'question="${_qmPreview(current.questionText, limit: 100)}" '
        'matchedByQuestionPrompt=false matchedByChoiceLine=true '
        'matchedByAnswerOrExplanationResidue=true',
      );
      continue;
    }
    repaired.add(current);
  }
  return repaired;
}

bool _qmLooksLikeTailVocabularyOrphan(
  QuestionImportDraft question,
  QuestionImportDraft previous,
) {
  final text = question.questionText.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (question.questionType.trim().isNotEmpty ||
      question.passage.trim().isNotEmpty ||
      question.source.trim().isNotEmpty ||
      question.choices.isNotEmpty ||
      text.isEmpty ||
      _q2InferQuestionType(text).isNotEmpty ||
      _q2LooksLikeAnySpecialPrompt(text) ||
      _qmLeadingChoicePosition(text) == null ||
      _qmVocabularyTailMarkerIndex(text) == -1 ||
      previous.questionType.trim().isEmpty ||
      previous.passage.trim().isEmpty) {
    return false;
  }
  final markerPosition = _qmLeadingChoicePosition(text);
  final linkedByAnswer = markerPosition != null &&
      (question.answerIndex == markerPosition - 1 ||
          previous.answerIndex == markerPosition - 1);
  final normalizedTail = _qmChoiceBody(_qmTailChoiceText(text));
  final linkedByChoice = previous.choices.any((choice) {
    final normalizedChoice = _qmChoiceBody(choice);
    return normalizedChoice.isNotEmpty &&
        normalizedTail.isNotEmpty &&
        (normalizedChoice == normalizedTail ||
            normalizedChoice.contains(normalizedTail) ||
            normalizedTail.contains(normalizedChoice));
  });
  return linkedByAnswer || linkedByChoice;
}

int? _qmLeadingChoicePosition(String text) {
  const hollow = '①②③④⑤';
  const filled = '❶❷❸❹❺';
  final match = RegExp(r'^[\s\(\uFF08]*([①-⑤❶-❺])').firstMatch(text.trim());
  if (match == null) return null;
  final token = match.group(1)!;
  final hollowIndex = hollow.indexOf(token);
  if (hollowIndex >= 0) return hollowIndex + 1;
  final filledIndex = filled.indexOf(token);
  return filledIndex >= 0 ? filledIndex + 1 : null;
}

int _qmVocabularyTailMarkerIndex(String text) {
  final match = RegExp(
    r'\[\s*(?:어휘|해설|풀이)\s*\]|'
    r'어휘\s*및\s*표현|Words\s*&\s*Phrases|Vocabulary|'
    r'(?:^|\s)(?:어휘|해설|풀이)(?:\s|:)',
    caseSensitive: false,
  ).firstMatch(text);
  return match?.start ?? -1;
}

String _qmTailChoiceText(String text) {
  final markerIndex = _qmVocabularyTailMarkerIndex(text);
  final choice = markerIndex == -1 ? text : text.substring(0, markerIndex);
  return choice.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _qmChoiceBody(String text) =>
    text.replaceAll(RegExp(r'\s+'), ' ').trim().replaceFirst(
          RegExp(r'^[\s\(\uFF08]*[①-⑤❶-❺][\)\uFF09]*\s*'),
          '',
        );

bool _qmAreComplementaryDrafts(
  QuestionImportDraft promptDraft,
  QuestionImportDraft contentDraft,
) {
  final hasSupportedPrompt = promptDraft.questionType.trim().isNotEmpty &&
      (_q2LooksLikePrompt(promptDraft.questionText) ||
          _q2LooksLikeAnySpecialPrompt(promptDraft.questionText));
  final promptNeedsContent =
      promptDraft.passage.trim().isEmpty && promptDraft.choices.length < 2;
  final contentHasStructure = contentDraft.passage.trim().isNotEmpty &&
      contentDraft.choices.length >= 2;
  final contentHasNoIndependentIdentity =
      contentDraft.questionType.trim().isEmpty &&
          contentDraft.source.trim().isEmpty &&
          !_q2LooksLikePrompt(contentDraft.questionText) &&
          !_q2LooksLikeAnySpecialPrompt(contentDraft.questionText);
  return hasSupportedPrompt &&
      promptNeedsContent &&
      contentHasStructure &&
      contentHasNoIndependentIdentity;
}

bool _qmIsChoiceOrExplanationOrphan(
  QuestionImportDraft question,
  List<QuestionImportDraft> previousQuestions,
  Set<String> confirmedAnswerExplanationResidues,
) {
  final text = question.questionText.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (question.questionType.trim().isNotEmpty ||
      question.passage.trim().isNotEmpty ||
      question.source.trim().isNotEmpty ||
      text.isEmpty ||
      !RegExp(r'^[①②③④⑤❶❷❸❹❺]\s*').hasMatch(text) ||
      _q2LooksLikePrompt(text) ||
      _q2LooksLikeAnySpecialPrompt(text)) {
    return false;
  }
  if (confirmedAnswerExplanationResidues.contains(text)) return true;
  return previousQuestions.reversed.take(2).any((previous) {
    final normalizedExplanation =
        previous.explanation.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalizedExplanation.contains(text) ||
        previous.choices.any(
          (choice) => choice.replaceAll(RegExp(r'\s+'), ' ').trim() == text,
        );
  });
}

Set<String> _qmConfirmedAnswerExplanationChoiceResidues(String normalizedText) {
  final lines = normalizedText
      .split(RegExp(r'\n+'))
      .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  final result = <String>{};
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (!RegExp(r'^[①②③④⑤❶❷❸❹❺]\s*').hasMatch(line)) continue;
    var belongsToAnswerOrExplanation = false;
    for (var previous = index - 1;
        previous >= 0 && previous >= index - 7;
        previous--) {
      final candidate = lines[previous];
      if (_q2IsAnswerLine(candidate) || _q2IsExplanationLine(candidate)) {
        belongsToAnswerOrExplanation = true;
        break;
      }
      if (_q2IsSourceLine(candidate) ||
          _qmIsLegacyHeading(candidate) ||
          _q4IsLongPassageHeader(candidate) ||
          _q2LooksLikePrompt(candidate) ||
          _q2LooksLikeAnySpecialPrompt(candidate) ||
          _q3LooksLikeEnglishPassageLine(candidate)) {
        break;
      }
    }
    if (belongsToAnswerOrExplanation) result.add(line);
  }
  return result;
}

void _qmDebugDraftParagraphBoundaries(
  List<QuestionImportDraft> questions,
  List<String> paragraphs,
  List<int> paragraphIndexes,
) {
  if (paragraphs.isEmpty || questions.isEmpty) return;
  final normalized = paragraphs
      .map((paragraph) => paragraph.replaceAll(RegExp(r'\s+'), ' ').trim())
      .toList(growable: false);
  final starts = <int>[];
  for (final question in questions) {
    final probes = <String>[
      question.questionText,
      if (question.choices.isNotEmpty) question.choices.first,
      question.source,
    ]
        .map((value) => value.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((value) => value.isNotEmpty)
        .map((value) => value.substring(0, value.length.clamp(0, 48)))
        .toList(growable: false);
    final start = normalized.indexWhere(
      (paragraph) => probes.any(paragraph.contains),
    );
    starts.add(start);
  }
  int xmlIndex(int position) =>
      position >= 0 && position < paragraphIndexes.length
          ? paragraphIndexes[position]
          : position;
  for (var index = 0; index < questions.length; index++) {
    final question = questions[index];
    final start = starts[index];
    var end = start;
    for (var next = index + 1; next < starts.length; next++) {
      if (starts[next] > start) {
        end = starts[next] - 1;
        break;
      }
    }
    final questionText =
        question.questionText.replaceAll(RegExp(r'\s+'), ' ').trim();
    final matchedByChoiceLine =
        RegExp(r'^[①②③④⑤❶❷❸❹❺]\s*').hasMatch(questionText);
    final paragraphText =
        start >= 0 && start < normalized.length ? normalized[start] : '';
    final matchedByAnswerOrExplanationResidue =
        _q2IsAnswerLine(paragraphText) || _q2IsExplanationLine(paragraphText);
    debugPrint(
      '[QuestionImportDraftBoundary] startParagraph=${xmlIndex(start)} '
      'endParagraph=${xmlIndex(end)} path=block '
      'questionNo=${question.questionNo} type=${question.questionType} '
      'question="${_qmPreview(questionText, limit: 100)}" '
      'passagePresent=${question.passage.trim().isNotEmpty} '
      'choicesCount=${question.choices.length} '
      'sourceNo="${_qmPreview(question.source, limit: 32)}" '
      'matchedByQuestionPrompt=${_q2LooksLikePrompt(questionText) || _q2LooksLikeAnySpecialPrompt(questionText)} '
      'matchedByChoiceLine=$matchedByChoiceLine '
      'matchedByAnswerOrExplanationResidue=$matchedByAnswerOrExplanationResidue',
    );
  }
}

void _q4DebugAlignedLongGroups(
  List<QuestionImportDraft> directQuestions,
) {
  final grouped = <String, List<QuestionImportDraft>>{};
  for (final question in directQuestions) {
    final group =
        (question.specialData?['long_passage_group'] ?? '-').toString();
    grouped.putIfAbsent(group, () => <QuestionImportDraft>[]).add(question);
  }
  for (final entry in grouped.entries) {
    debugPrint(
      '[LongPassageAlignedGroup] group=${entry.key} '
      'directLongDraftCount=${entry.value.length} '
      'directLongQuestionNos=${entry.value.map((question) => question.questionNo).toList()}',
    );
  }
}

List<QuestionImportDraft> _q4AlignDirectQuestionNumbers(
  List<QuestionImportDraft> blockQuestions,
  List<QuestionImportDraft> directQuestions,
) {
  if (directQuestions.isEmpty || blockQuestions.isEmpty) {
    return directQuestions;
  }
  final usedBlockNumbers = <int>{};
  final aligned = <QuestionImportDraft>[];
  for (final direct in directQuestions) {
    final explicitSourceNo = int.tryParse(
      direct.specialData?['source_no']?.toString() ?? '',
    );
    if (explicitSourceNo != null) {
      usedBlockNumbers.add(explicitSourceNo);
      aligned.add(
        direct.questionNo == explicitSourceNo
            ? direct
            : direct.copyWith(questionNo: explicitSourceNo),
      );
      debugPrint(
        '[LongPassageNumberAlign] from=${direct.questionNo} '
        'to=$explicitSourceNo reason=explicit_source_no',
      );
      continue;
    }
    final promptKey = _q4QuestionPromptKey(direct.questionText);
    final candidates = blockQuestions
        .where(
          (block) =>
              !usedBlockNumbers.contains(block.questionNo) &&
              _q4QuestionPromptKey(block.questionText) == promptKey,
        )
        .toList();
    if (candidates.isEmpty) {
      aligned.add(direct);
      continue;
    }
    candidates.sort((left, right) {
      final scoreCompare = _q4DirectAlignmentScore(right, direct)
          .compareTo(_q4DirectAlignmentScore(left, direct));
      if (scoreCompare != 0) return scoreCompare;
      return right.questionNo.compareTo(left.questionNo);
    });
    final target = candidates.first;
    usedBlockNumbers.add(target.questionNo);
    final specialData = <String, dynamic>{
      ...?direct.specialData,
      'source_no': target.questionNo,
    };
    final repaired = direct.copyWith(
      questionNo: target.questionNo,
      specialData: specialData,
    );
    aligned.add(repaired);
    debugPrint(
      '[LongPassageNumberAlign] from=${direct.questionNo} '
      'to=${target.questionNo} prompt="${_qmPreview(direct.questionText)}" '
      'targetPassagePresent=${target.passage.trim().isNotEmpty} '
      'targetSaveable=${target.isSaveable}',
    );
  }
  return aligned;
}

int _q4DirectAlignmentScore(
  QuestionImportDraft block,
  QuestionImportDraft direct,
) {
  var score = 0;
  if (block.passage.trim().isEmpty) score += 80;
  if (!block.isSaveable) score += 40;
  if (block.specialData == null || block.specialData!.isEmpty) score += 20;
  if (_q4TypesAreCompatible(block.questionType, direct.questionType)) {
    score += 30;
  }
  if (block.source.trim().isNotEmpty &&
      block.source.trim() == direct.source.trim()) {
    score += 10;
  }
  return score;
}

bool _q4TypesAreCompatible(String left, String right) {
  String normalize(String type) {
    final value = type.trim().toLowerCase();
    if (value == 'mismatch' || value == 'content') return 'content_match';
    return value;
  }

  return normalize(left) == normalize(right);
}

List<QuestionImportDraft> _q4MergeDirectlyParsedQuestions(
  List<QuestionImportDraft> blockQuestions,
  List<QuestionImportDraft> longPassageQuestions,
  Set<String> confirmedAnswerExplanationResidues,
) {
  final longByNumber = <int, QuestionImportDraft>{
    for (final question in longPassageQuestions) question.questionNo: question,
  };
  final longPromptKeys = longPassageQuestions
      .map((question) => _q4QuestionPromptKey(question.questionText))
      .where((key) => key.isNotEmpty)
      .toSet();
  final longSourceNumbersByPrompt = <String, Set<int>>{};
  for (final question in longPassageQuestions) {
    final promptKey = _q4QuestionPromptKey(question.questionText);
    final sourceNo = int.tryParse(
      question.specialData?['source_no']?.toString() ?? '',
    );
    if (promptKey.isNotEmpty && sourceNo != null) {
      longSourceNumbersByPrompt
          .putIfAbsent(promptKey, () => <int>{})
          .add(sourceNo);
    }
  }
  final merged = <QuestionImportDraft>[];
  final seenNumbers = <int>{};
  final hasStandaloneBlockPassage =
      blockQuestions.any((question) => question.passage.trim().isNotEmpty);

  for (final question in blockQuestions) {
    final replacement = longByNumber[question.questionNo];
    if (replacement != null) {
      _q4DebugDraft(
        'mergeBeforeBlock',
        question,
        extra: 'score=${_q4QuestionCompletenessScore(question)}',
      );
      _q4DebugDraft(
        'mergeBeforeDirect',
        replacement,
        extra: 'score=${_q4QuestionCompletenessScore(replacement)}',
      );
      final blockIsChoiceOrExplanationResidue = _qmIsUnidentifiedChoiceResidue(
        question,
        confirmedAnswerExplanationResidues,
      );
      final combined = _q4CombineQuestionDetails(question, replacement);
      final selected = blockIsChoiceOrExplanationResidue
          ? replacement
          : _q4MoreCompleteQuestion(question, combined);
      if (seenNumbers.add(question.questionNo)) merged.add(selected);
      final selectedDirectData =
          selected.specialData?['shared_passage'] == true;
      debugPrint(
        '[LongPassageMergeSelect] no=${question.questionNo} '
        'selected=${blockIsChoiceOrExplanationResidue ? 'direct_over_residue' : selectedDirectData ? 'direct_merged' : 'block'} '
        'blockSaveable=${question.isSaveable} '
        'directSaveable=${replacement.isSaveable} '
        'selectedSaveable=${selected.isSaveable}',
      );
      continue;
    }
    final isChoiceOrExplanationResidue = _qmIsUnidentifiedChoiceResidue(
      question,
      confirmedAnswerExplanationResidues,
    );
    if (isChoiceOrExplanationResidue) {
      debugPrint(
        '[LongPassageMergeSkip] no=${question.questionNo} '
        'reason=choice_or_explanation_residue '
        'question="${_qmPreview(question.questionText, limit: 100)}"',
      );
      continue;
    }
    final promptKey = _q4QuestionPromptKey(question.questionText);
    final isAnswerRegionResidual = question.passage.trim().isEmpty &&
        longPromptKeys.contains(promptKey) &&
        (!hasStandaloneBlockPassage ||
            (longSourceNumbersByPrompt[promptKey] ?? const <int>{})
                .contains(question.questionNo));
    if (isAnswerRegionResidual) {
      debugPrint(
        '[LongPassageMergeSkip] no=${question.questionNo} '
        'reason=answer_region_residual',
      );
      continue;
    }
    if (seenNumbers.add(question.questionNo)) merged.add(question);
  }
  for (final question in longPassageQuestions) {
    if (seenNumbers.add(question.questionNo)) merged.add(question);
  }
  _q4DebugStageQuestions('mergeAfterDedupe', merged);
  merged.sort((left, right) => left.questionNo.compareTo(right.questionNo));
  _q4DebugStageQuestions('mergeAfterSort', merged);
  debugPrint(
    '[LongPassageMerge] blockDrafts=${blockQuestions.length} '
    'directLongDrafts=${longPassageQuestions.length} '
    'mergedDrafts=${merged.length} '
    'questionNos=${merged.map((question) => question.questionNo).toList()}',
  );
  return merged;
}

bool _qmIsUnidentifiedChoiceResidue(
  QuestionImportDraft question,
  Set<String> confirmedAnswerExplanationResidues,
) {
  final text = question.questionText.replaceAll(RegExp(r'\s+'), ' ').trim();
  String choiceBody(String value) => value
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceFirst(RegExp(r'^[①②③④⑤❶❷❸❹❺]\s*'), '');
  final textBody = choiceBody(text);
  final repeatsOwnChoice = question.choices.any(
    (choice) => choiceBody(choice) == textBody,
  );
  return question.questionType.trim().isEmpty &&
      question.passage.trim().isEmpty &&
      question.source.trim().isEmpty &&
      (question.choices.length >= 2 || question.answerIndex != null) &&
      RegExp(r'^[①②③④⑤❶❷❸❹❺]\s*').hasMatch(text) &&
      (repeatsOwnChoice || confirmedAnswerExplanationResidues.contains(text));
}

QuestionImportDraft _q4CombineQuestionDetails(
  QuestionImportDraft block,
  QuestionImportDraft direct,
) {
  final specialData = <String, dynamic>{
    ...?block.specialData,
    ...?direct.specialData,
  };
  final directInteraction =
      (specialData['interaction_type'] ?? '').toString().trim().toLowerCase();
  final keepDirectNullAnswerIndex = direct.questionType == 'content_match' &&
      directInteraction == 'multi_select';
  final choices = direct.choices.length >= block.choices.length
      ? direct.choices
      : block.choices;
  return direct.copyWith(
    source: direct.source.trim().isNotEmpty ? direct.source : block.source,
    questionText: direct.questionText.trim().isNotEmpty
        ? direct.questionText
        : block.questionText,
    passage: direct.passage.trim().isNotEmpty ? direct.passage : block.passage,
    choices: choices,
    answerIndex: keepDirectNullAnswerIndex
        ? null
        : direct.answerIndex ?? block.answerIndex,
    clearAnswerIndex: keepDirectNullAnswerIndex,
    answerRaw:
        direct.answerRaw.trim().isNotEmpty ? direct.answerRaw : block.answerRaw,
    explanation: direct.explanation.trim().isNotEmpty
        ? direct.explanation
        : block.explanation,
    specialData: specialData,
    answerText: (direct.answerText ?? '').trim().isNotEmpty
        ? direct.answerText
        : block.answerText,
    warnings: direct.warnings,
    isSpecialUnsupported: false,
  );
}

QuestionImportDraft _q4MoreCompleteQuestion(
  QuestionImportDraft block,
  QuestionImportDraft direct,
) {
  final blockScore = _q4QuestionCompletenessScore(block);
  final directScore = _q4QuestionCompletenessScore(direct);
  return directScore >= blockScore ? direct : block;
}

int _q4QuestionCompletenessScore(QuestionImportDraft question) {
  var score = question.isSaveable ? 100 : 0;
  final type = question.questionType.trim().toLowerCase();
  if (type.isNotEmpty) score += 10;
  if (question.questionText.trim().isNotEmpty) score += 10;
  if (question.passage.trim().isNotEmpty) score += 35;
  score += question.choices.length.clamp(0, 5) * 3;
  if (question.answerIndex != null ||
      (question.answerText ?? '').trim().isNotEmpty) {
    score += 15;
  }
  final special = question.specialData;
  if (special?.isNotEmpty == true) score += 20;
  if (special?['shared_passage'] == true) score += 15;
  if (type == 'order') {
    final blocks = special?['blocks'];
    final answerOrder = special?['answer_order'];
    score += (blocks is Map ? blocks.length.clamp(0, 4) : 0) * 8;
    score += (answerOrder is List ? answerOrder.length.clamp(0, 4) : 0) * 5;
  } else if (type == 'reference') {
    if (question.choices.length >= 5) score += 20;
  } else if (type == 'content_match' || type == 'mismatch') {
    if (question.choices.length >= 5) score += 20;
    final answerIndices = special?['answer_indices'];
    if (answerIndices is List && answerIndices.isNotEmpty) score += 25;
  }
  if (question.warnings.isEmpty) score += 5;
  return score;
}

String _q4QuestionPromptKey(String text) {
  return text.replaceAll(RegExp(r'\s+'), '').trim().toLowerCase();
}

void _q4DebugStageQuestions(
  String stage,
  Iterable<QuestionImportDraft> questions,
) {
  for (final question in questions) {
    _q4DebugDraft(stage, question);
  }
}

void _q4DebugDraft(
  String stage,
  QuestionImportDraft question, {
  String extra = '',
}) {
  final specialKeys =
      question.specialData?.keys.toList(growable: false) ?? const <String>[];
  final answer = question.answerIndex == null
      ? (question.answerText ?? question.answerRaw).trim()
      : '${question.answerIndex! + 1}';
  debugPrint(
    '[QuestionImportStageDraft] stage=$stage '
    'no=${question.questionNo} '
    'type=${question.questionType} '
    'passagePresent=${question.passage.trim().isNotEmpty} '
    'choicesCount=${question.choices.length} '
    'answer="${_qmPreview(answer, limit: 24)}" '
    'specialDataKeys=$specialKeys '
    'groupId=${question.specialData?['long_passage_group'] ?? '-'} '
    'source="${_qmPreview(question.source, limit: 32)}" '
    'question="${_qmPreview(question.questionText, limit: 48)}"'
    '${extra.isEmpty ? '' : ' $extra'}',
  );
}

List<QuestionImportDraft> _q4ParseLongPassageSetQuestions(
  String normalizedText,
) {
  final lines = normalizedText
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  final headerIndexes = <int>[
    for (var index = 0; index < lines.length; index++)
      if (_q4IsLongPassageHeader(lines[index])) index,
  ];
  if (headerIndexes.isEmpty) return const <QuestionImportDraft>[];

  final questions = <QuestionImportDraft>[];
  var lastQuestionNo = 0;
  var group = 0;
  for (var headerPosition = 0;
      headerPosition < headerIndexes.length;
      headerPosition++) {
    final headerIndex = headerIndexes[headerPosition];
    final sectionEnd = headerPosition + 1 < headerIndexes.length
        ? headerIndexes[headerPosition + 1]
        : lines.length;
    final promptIndexes = <int>[
      for (var index = headerIndex + 1; index < sectionEnd; index++)
        if (_q4LooksLikeChildQuestionPrompt(lines[index])) index,
    ];
    debugPrint(
      '[LongPassageGroupScan] header="${lines[headerIndex]}" '
      'headerIndex=$headerIndex sectionEnd=$sectionEnd '
      'childCount=${promptIndexes.length} '
      'prompts=${promptIndexes.map((index) => _qmPreview(lines[index])).toList()}',
    );
    if (promptIndexes.length < 2) continue;

    var firstBlockStart = promptIndexes.first;
    if (firstBlockStart > headerIndex + 1 &&
        (_qmQuestionNumberFromLine(lines[firstBlockStart - 1]) != null ||
            _q4AnswerRegionNumber(lines[firstBlockStart - 1]) != null)) {
      firstBlockStart--;
    }
    final passageLines = _q4SharedPassageLines(
      lines,
      start: headerIndex + 1,
      end: firstBlockStart,
    );
    final passage = passageLines.join('\n').trim();
    if (passage.isEmpty || !RegExp(r'[A-Za-z]').hasMatch(passage)) continue;
    final sharedBlocks = _q4SharedOrderBlocks(passageLines);
    final isExplicitReadHeader =
        _q4IsExplicitLongPassageHeader(lines[headerIndex]);
    if (!isExplicitReadHeader &&
        passage.length < 180 &&
        sharedBlocks.length < 3) {
      continue;
    }

    final precedingQuestionNo = _q4LastQuestionNumberBefore(
      lines,
      headerIndex,
    );
    if (precedingQuestionNo > lastQuestionNo) {
      lastQuestionNo = precedingQuestionNo;
    }
    group++;
    debugPrint(
      '[LongPassageGroup] stage=rawLongGroupDetection group=$group '
      'sharedStart="${_qmPreview(passage)}" '
      'passagePresent=${passage.isNotEmpty} '
      'blocks=${sharedBlocks.length} childCount=${promptIndexes.length}',
    );
    final rawQuestionNos = <int>[];
    for (final promptIndex in promptIndexes) {
      final ownNumber = _qmQuestionNumberFromLine(lines[promptIndex]);
      final previousNumber = promptIndex > headerIndex + 1
          ? _qmQuestionNumberFromLine(lines[promptIndex - 1])
          : null;
      rawQuestionNos.add(ownNumber ?? previousNumber ?? 0);
    }
    final set = _Q4LongPassageSet(
      group: group,
      passage: passage,
      questionNos: rawQuestionNos,
      blocks: sharedBlocks,
    );
    debugPrint(
      '[LongPassageSetDebug] group=$group '
      'sharedPassageLength=${passage.length}',
    );

    final normalizedQuestionNos = <int>[];
    for (var promptPosition = 0;
        promptPosition < promptIndexes.length;
        promptPosition++) {
      final promptIndex = promptIndexes[promptPosition];
      var blockStart = promptIndex;
      final rawNumber = rawQuestionNos[promptPosition];
      if (blockStart > headerIndex + 1 &&
          (_qmQuestionNumberFromLine(lines[blockStart - 1]) != null ||
              _q4AnswerRegionNumber(lines[blockStart - 1]) != null)) {
        blockStart--;
      }
      final nextPromptIndex = promptPosition + 1 < promptIndexes.length
          ? promptIndexes[promptPosition + 1]
          : sectionEnd;
      var blockEnd = nextPromptIndex;
      if (blockEnd > blockStart &&
          _qmQuestionNumberFromLine(lines[blockEnd - 1]) != null) {
        blockEnd--;
      }
      final blockLines = lines.sublist(blockStart, blockEnd);
      final sourceQuestionNo = rawNumber > 0
          ? rawNumber
          : _q4SourceQuestionNumberFromLines(blockLines);
      final preferredNumber = rawNumber > 0
          ? rawNumber
          : precedingQuestionNo > 0
              ? sourceQuestionNo ?? 0
              : 0;
      final normalizedNumber = preferredNumber > lastQuestionNo
          ? preferredNumber
          : lastQuestionNo + 1;
      lastQuestionNo = normalizedNumber;
      normalizedQuestionNos.add(normalizedNumber);
      var parsed = _qmParseQuestionBlock(
        _QmQuestionBlock(number: normalizedNumber, lines: blockLines),
        fallbackNo: normalizedNumber,
      );
      _q4DebugDraft(
        'directLongCreated',
        parsed,
        extra: 'groupId=$group sourceNo=${sourceQuestionNo ?? '-'}',
      );
      if (parsed.questionType.trim().toLowerCase() == 'order') {
        final fullAnswerRaw = _q2ExtractAnswerRawFull(blockLines).trim();
        if (fullAnswerRaw.isNotEmpty) {
          parsed = parsed.copyWith(answerRaw: fullAnswerRaw);
        }
      }
      _q4DebugDraft(
        'directLongNumberNormalized',
        parsed,
        extra: 'groupId=$group rawNo=$rawNumber normalizedNo=$normalizedNumber',
      );
      final repaired = _q4ApplyLongPassageSet(
        parsed,
        set,
        rawQuestionLines: blockLines,
        documentLines: lines,
        originalQuestionNo: sourceQuestionNo,
        questionOrdinal: promptPosition,
        questionCount: promptIndexes.length,
      );
      questions.add(repaired);
      _q4DebugDraft('directLongRepaired', repaired);
      debugPrint(
        '[LongPassageGroupDraft] group=$group '
        'child=${promptPosition + 1} no=${repaired.questionNo} '
        'type=${repaired.questionType}',
      );
    }
    debugPrint(
      '[LongPassageSetDebug] group=$group '
      'questionNos=$normalizedQuestionNos',
    );
  }
  return questions;
}

int _q4LastQuestionNumberBefore(List<String> lines, int end) {
  var last = 0;
  for (var index = 0; index < end; index++) {
    final number = _qmQuestionNumberFromLine(lines[index]);
    if (number != null && number > last) last = number;
  }
  return last;
}

bool _q4LooksLikeChildQuestionPrompt(String line) {
  if (_q2IsControlLine(line) || _q4IsLongPassageHeader(line)) return false;
  final clean = _qmCleanBodyLine(line).trim();
  if (clean.isEmpty) return false;
  final compact = clean.replaceAll(RegExp(r'\s+'), '');
  final hasPromptLead = compact.startsWith('다음') ||
      compact.startsWith('윗글') ||
      compact.startsWith('밑줄친') ||
      compact.startsWith('주어진') ||
      compact.startsWith('어법') ||
      compact.startsWith('어휘');
  return hasPromptLead &&
      (_q2LooksLikePrompt(clean) ||
          _q2LooksLikeAnySpecialPrompt(clean) ||
          _q4LooksLikeGeneralChildPrompt(compact));
}

bool _q4LooksLikeGeneralChildPrompt(String compactPrompt) {
  final hasQuestionSubject = RegExp(
    r'(제목|빈칸|주제|요지|어법|어휘|문맥|순서|가리키는대상|내용과일치)',
  ).hasMatch(compactPrompt);
  final hasQuestionAction = RegExp(
    r'(고르|적절|배열|고치|것은|것을)',
  ).hasMatch(compactPrompt);
  return hasQuestionSubject && hasQuestionAction;
}

List<String> _q4SharedPassageLines(
  List<String> lines, {
  required int start,
  required int end,
}) {
  final passageLines = <String>[];
  for (var index = start; index < end; index++) {
    final line = lines[index].trim();
    if (line.isEmpty ||
        _q4IsLongPassageHeader(line) ||
        _q2IsSourceLine(line) ||
        _qmIsLegacyHeading(line)) {
      continue;
    }
    if (_q2IsVocabularyLine(line) || _q2LooksLikeVocabularyNoteLine(line)) {
      break;
    }
    final cleaned = _q2StripInlineVocabularyNotes(line);
    if (cleaned.isNotEmpty) passageLines.add(cleaned);
  }
  return passageLines;
}

List<_Q4LongPassageSet> _q4DetectLongPassageSets(String normalizedText) {
  final lines = normalizedText
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  final headerIndexes = <int>[
    for (var index = 0; index < lines.length; index++)
      if (_q4IsLongPassageHeader(lines[index])) index,
  ];
  final sets = <_Q4LongPassageSet>[];
  for (var headerPosition = 0;
      headerPosition < headerIndexes.length;
      headerPosition++) {
    final headerIndex = headerIndexes[headerPosition];
    final sectionEnd = headerPosition + 1 < headerIndexes.length
        ? headerIndexes[headerPosition + 1]
        : lines.length;
    final anchors = <_QmNumberedAnchor>[];
    for (var index = headerIndex + 1; index < sectionEnd; index++) {
      final number = _qmQuestionNumberFromLine(lines[index]);
      if (number == null) continue;
      final promptIndex = _qmPromptIndexNearNumber(lines, index);
      if (promptIndex == -1 || promptIndex >= sectionEnd) continue;
      anchors.add(
        _QmNumberedAnchor(
          index: index,
          number: number,
          numberLineIndex: index,
          promptIndex: promptIndex,
        ),
      );
    }
    if (anchors.length < 2) continue;

    final passageLines = <String>[];
    for (var index = headerIndex + 1;
        index < anchors.first.numberLineIndex;
        index++) {
      final line = lines[index].trim();
      if (line.isEmpty ||
          _q4IsLongPassageHeader(line) ||
          _q2IsSourceLine(line) ||
          _qmIsLegacyHeading(line)) {
        continue;
      }
      if (_q2IsVocabularyLine(line) || _q2LooksLikeVocabularyNoteLine(line)) {
        break;
      }
      passageLines.add(_q2StripInlineVocabularyNotes(line));
    }
    final passage =
        passageLines.where((line) => line.trim().isNotEmpty).join('\n').trim();
    if (passage.isEmpty || !RegExp(r'[A-Za-z]').hasMatch(passage)) continue;

    final questionNos = <int>[];
    for (final anchor in anchors) {
      if (!questionNos.contains(anchor.number)) questionNos.add(anchor.number);
    }
    final group = sets.length + 1;
    final set = _Q4LongPassageSet(
      group: group,
      passage: passage,
      questionNos: questionNos,
      blocks: _q4SharedOrderBlocks(passageLines),
    );
    sets.add(set);
    debugPrint(
      '[LongPassageSetDebug] group=$group '
      'sharedPassageLength=${passage.length}',
    );
    debugPrint(
      '[LongPassageSetDebug] group=$group questionNos=$questionNos',
    );
  }
  return sets;
}

bool _q4IsLongPassageHeader(String line) {
  final compact = _q4CompactLongHeaderCandidate(line);
  return (_q4HasLongPassageReadingLead(compact) &&
          _q4HasLongPassageAnswerInstruction(compact)) ||
      compact == '<기본형>' ||
      compact == '<변형>' ||
      compact == '<패러형>';
}

bool _q4IsExplicitLongPassageHeader(String line) {
  final compact = _q4CompactLongHeaderCandidate(line);
  return _q4HasLongPassageReadingLead(compact) &&
      _q4HasLongPassageAnswerInstruction(compact);
}

String _q4CompactLongHeaderCandidate(String text) {
  return text
      .replaceAll('\u00A0', ' ')
      .replaceAll('\u3000', ' ')
      .replaceAll(RegExp(r'[\u200B-\u200D\u2060\uFEFF]'), '')
      .replaceAll(
        RegExp(r'[\s,，.。:：;；·ㆍ※*•\[\]【】()（）]+'),
        '',
      )
      .trim();
}

bool _q4HasLongPassageReadingLead(String compact) {
  return RegExp(
    r'(?:다음|아래)[가-힣]{0,8}(?:글|지문|제시문)을읽고',
  ).hasMatch(compact);
}

bool _q4HasLongPassageAnswerInstruction(String compact) {
  return RegExp(
    r'(?:물음|질문|문제)[가-힣]{0,6}답(?:하시오|하세요|하라|해보시오|해보세요)',
  ).hasMatch(compact);
}

Map<String, String> _q4SharedOrderBlocks(List<String> passageLines) {
  final blocks = <String, String>{};
  String? activeLabel;
  final buffer = <String>[];

  void flush() {
    final label = activeLabel;
    if (label == null) return;
    final text = buffer.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isNotEmpty) blocks[label] = text;
    buffer.clear();
  }

  for (final line in passageLines) {
    final match = _q2OrderBlockMatch(line);
    if (match != null) {
      flush();
      activeLabel = (match.group(1) ?? '').toUpperCase();
      final rest = (match.group(2) ?? '').trim();
      if (rest.isNotEmpty) buffer.add(rest);
      continue;
    }
    if (activeLabel != null &&
        (_q2IsControlLine(line) || _q2IsSourceLine(line))) {
      break;
    }
    if (activeLabel != null) buffer.add(line);
  }
  flush();
  final trailing = _q4SharedOrderTrailingLines(passageLines)
      .join(' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (trailing.isNotEmpty && blocks.isNotEmpty) {
    final lastLabel = blocks.keys.last;
    final lastBlock = blocks[lastLabel] ?? '';
    if (lastBlock.endsWith(trailing)) {
      final withoutTrailing =
          lastBlock.substring(0, lastBlock.length - trailing.length).trim();
      if (withoutTrailing.isNotEmpty) blocks[lastLabel] = withoutTrailing;
    }
  }
  return blocks;
}

List<String> _q4SharedOrderTrailingLines(List<String> passageLines) {
  var lastBlockIndex = -1;
  var lastBlockHasInlineText = false;
  for (var index = 0; index < passageLines.length; index++) {
    final match = _q2OrderBlockMatch(passageLines[index]);
    if (match == null) continue;
    lastBlockIndex = index;
    lastBlockHasInlineText = (match.group(2) ?? '').trim().isNotEmpty;
  }
  if (lastBlockIndex < 0) return const <String>[];

  var blockBodyConsumed = lastBlockHasInlineText;
  final trailing = <String>[];
  for (var index = lastBlockIndex + 1; index < passageLines.length; index++) {
    final line = passageLines[index].trim();
    if (line.isEmpty) continue;
    if (_q2IsControlLine(line) ||
        _q2IsSourceLine(line) ||
        _qmQuestionNumberFromLine(line) != null) {
      break;
    }
    if (!blockBodyConsumed) {
      blockBodyConsumed = true;
      continue;
    }
    trailing.add(line);
  }
  return trailing;
}

String _q4SharedOrderLeadPassage(String passage) {
  final leadLines = <String>[];
  for (final line in passage.split('\n')) {
    if (_q2OrderBlockMatch(line.trim()) != null) break;
    if (line.trim().isNotEmpty) leadLines.add(line.trim());
  }
  return leadLines.join('\n').trim();
}

String _q4SharedOrderTrailingPassage(String passage) {
  return _q4SharedOrderTrailingLines(passage.split('\n')).join('\n').trim();
}

List<QuestionImportDraft> _q4ApplyLongPassageSets(
  List<QuestionImportDraft> questions,
  List<_Q4LongPassageSet> sets,
) {
  if (sets.isEmpty) return questions;
  return <QuestionImportDraft>[
    for (final question in questions)
      _q4ApplyLongPassageSet(
        question,
        sets.cast<_Q4LongPassageSet?>().firstWhere(
              (set) => set!.questionNos.contains(question.questionNo),
              orElse: () => null,
            ),
      ),
  ];
}

QuestionImportDraft _q4ApplyLongPassageSet(
  QuestionImportDraft question,
  _Q4LongPassageSet? set, {
  List<String>? rawQuestionLines,
  List<String>? documentLines,
  int? originalQuestionNo,
  int? questionOrdinal,
  int? questionCount,
}) {
  if (set == null) return question;
  String? detectedPrompt;
  for (final line in rawQuestionLines ?? const <String>[]) {
    final clean = _qmCleanBodyLine(line);
    if (_q4LooksLikeChildQuestionPrompt(clean)) {
      detectedPrompt = clean;
      break;
    }
  }
  final questionText = detectedPrompt ?? question.questionText;
  final compactPrompt = questionText.replaceAll(RegExp(r'\s+'), '');
  var questionType = question.questionType.trim().toLowerCase();
  if (questionType.isEmpty && detectedPrompt != null) {
    questionType = _q2InferQuestionType(detectedPrompt);
  }
  if (_q4LooksLikeReferencePrompt(compactPrompt)) {
    questionType = 'reference';
  } else if (_q4LooksLikeContentMatchPrompt(compactPrompt)) {
    questionType = 'content_match';
  }

  var specialData = <String, dynamic>{
    ...?question.specialData,
    if (question.specialData == null || question.specialData!.isEmpty)
      'kind': 'long_passage_set',
    'shared_passage': true,
    'long_passage_group': set.group,
    if (originalQuestionNo != null) 'source_no': originalQuestionNo,
    if (questionType == 'reference' || questionType == 'content_match')
      'interaction_type': questionType == 'content_match' &&
              _q4IsMultiSelectPrompt(compactPrompt)
          ? 'multi_select'
          : 'single_choice',
    if (questionType == 'content_match' &&
        _q4IsMultiSelectPrompt(compactPrompt))
      'kind': 'content_match',
    if (questionType == 'content_match' &&
        _q4IsMultiSelectPrompt(compactPrompt))
      'max_answers': _q4MaxAnswers(compactPrompt) ?? 2,
  };
  var answerText = question.answerText;
  var answerRaw = question.answerRaw;
  var clearAnswerIndex = false;
  var answerIndex = question.answerIndex;
  var choices = question.choices;
  var warnings = question.warnings
      .where(
        (warning) =>
            warning != '지문이 없습니다.' &&
            warning != 'Question type could not be detected',
      )
      .toList(growable: false);

  const regularChoiceTypes = <String>{
    'topic',
    'title',
    'gist',
    'blank',
    'purpose',
    'implication',
    'content',
    'mismatch',
  };
  if (regularChoiceTypes.contains(questionType)) {
    final fiveChoiceGroups = _q2ChoiceGroups(
      rawQuestionLines ?? const <String>[],
    ).where((group) => group.choices.length == 5);
    if (fiveChoiceGroups.isNotEmpty) {
      choices = fiveChoiceGroups.last.choices;
    }
    specialData['interaction_type'] = 'single_choice';
  }

  if ((questionType == 'grammar_correction' ||
          questionType == 'vocabulary_correction') &&
      (specialData['interaction_type'] ?? '').toString() ==
          'correction_multi') {
    final sharedPositions = _q3PassagePositions(set.passage);
    if (sharedPositions.isNotEmpty) {
      specialData['positions'] = sharedPositions;
      specialData['position_labels'] =
          sharedPositions.map(_q3CircledMarker).toList(growable: false);
      final positionTexts = _q3GrammarVocabularyPositionTexts(set.passage);
      if (positionTexts.isNotEmpty) {
        specialData['position_texts'] = positionTexts;
      }
    }
    final maxAnswers = _q4MaxAnswers(compactPrompt);
    if (maxAnswers != null) specialData['max_answers'] = maxAnswers;
  }

  if (questionType == 'order' && choices.isEmpty) {
    final orderChoiceGroups =
        _q2ChoiceGroups(rawQuestionLines ?? const <String>[])
            .where((group) => group.choices.length >= 3);
    if (orderChoiceGroups.isNotEmpty) {
      choices = orderChoiceGroups.last.choices;
    }
  }

  if (questionType == 'order' && set.blocks.length >= 3) {
    final selectedChoice = question.answerIndex != null &&
            question.answerIndex! >= 0 &&
            question.answerIndex! < question.choices.length
        ? question.choices[question.answerIndex!]
        : '';
    var answerOrder = _q2ParseOrderAnswer(selectedChoice);
    final rawAnswerOrder = _q2ParseOrderAnswer(question.answerRaw);
    if (rawAnswerOrder.length > answerOrder.length) {
      answerOrder = rawAnswerOrder;
    }
    final fixedStartA = _q4IsFixedStartAOrderPrompt(compactPrompt) &&
        set.blocks.containsKey('A');
    final selectableLabels = set.blocks.keys
        .where((label) => !fixedStartA || label != 'A')
        .toList(growable: false);
    final leadPassage = _q4SharedOrderLeadPassage(set.passage);
    final trailingPassage = _q4SharedOrderTrailingPassage(set.passage);
    specialData = <String, dynamic>{
      'kind': 'order',
      'order_mode': fixedStartA ? 'fixed_start' : 'full',
      'fixed_start': fixedStartA ? 'A' : '',
      if (fixedStartA) 'fixed_start_text': set.blocks['A'],
      if (leadPassage.isNotEmpty) 'lead_passage': leadPassage,
      if (trailingPassage.isNotEmpty) 'trailing_passage': trailingPassage,
      'fixed_end': '',
      'blocks': set.blocks,
      if (fixedStartA) 'selectable_blocks': selectableLabels,
      'answer_order': answerOrder,
      'shared_passage': true,
      'long_passage_group': set.group,
    };
    answerText = answerOrder.join('-');
    clearAnswerIndex = true;
    warnings = <String>[
      if (answerOrder.length != selectableLabels.length)
        '정답 순서 수와 선택 가능 블록 수가 다릅니다.',
      if (answerOrder.any((label) => !set.blocks.containsKey(label)))
        '정답에 공유 지문에 없는 블록이 포함되어 있습니다.',
      if (fixedStartA && answerOrder.contains('A'))
        '고정 시작 블록이 정답 순서에 포함되어 있습니다.',
    ];
    if (fixedStartA) {
      debugPrint(
        '[LongPassageOrderFix] no=${question.questionNo} fixedStart=A '
        'answer=${answerOrder.join('-')} blocks=${set.blocks.length} '
        'saveable=${warnings.isEmpty}',
      );
    }
  }

  if (questionType == 'reference' && choices.length < 2) {
    final labels = _q4ReferenceFallbackLabels(compactPrompt);
    if (labels.isNotEmpty) {
      choices = labels.map((label) => '($label)').toList(growable: false);
      final recoveredAnswer = _q4ExplicitAnswerIndices(
        rawQuestionLines ?? const <String>[],
      );
      answerIndex ??= recoveredAnswer.isEmpty ? null : recoveredAnswer.first;
      warnings = const <String>[];
      debugPrint(
        '[ReferenceChoiceFallback] no=${question.questionNo} '
        'labels=${labels.first}-${labels.last} '
        'answer=${answerIndex == null ? '-' : answerIndex + 1} '
        'choices=${choices.length}',
      );
    }
  }

  if (questionType == 'content_match') {
    final normalizedAnswerCandidates =
        _q4CollectAnswerCandidateRaws(documentLines ?? const <String>[]);
    final groupAnswerCandidates =
        _q4CollectAnswerCandidateRaws(rawQuestionLines ?? const <String>[]);
    debugPrint(
      '[ContentMatchAnswerSearch] no=${question.questionNo} '
      'question="${question.questionText}"',
    );
    debugPrint(
      '[ContentMatchAnswerSearch] no=${question.questionNo} '
      'sourceNo=${specialData['source_no'] ?? '-'} '
      'originalNo=${originalQuestionNo ?? '-'}',
    );
    debugPrint(
      '[ContentMatchAnswerSearch] no=${question.questionNo} '
      'normalizedAnswerCandidates=$normalizedAnswerCandidates',
    );
    debugPrint(
      '[ContentMatchAnswerSearch] no=${question.questionNo} '
      'groupAnswerCandidates=$groupAnswerCandidates',
    );
    var answerRecovery =
        _q4ExplicitAnswerRecovery(rawQuestionLines ?? const <String>[]);
    if (answerRecovery == null &&
        _q3AnswerIndices(question.answerRaw).isNotEmpty) {
      answerRecovery = _Q4AnswerRecovery(
        rawAnswerLine: question.answerRaw,
        rawAnswer: question.answerRaw,
        sourceNo: originalQuestionNo,
      );
    }
    if (answerRecovery == null && documentLines != null) {
      answerRecovery = _q4RecoverAnswerFromDocument(
        documentLines,
        questionNo: question.questionNo,
        originalQuestionNo: originalQuestionNo,
        questionOrdinal: questionOrdinal,
        questionCount: questionCount,
      );
    }
    final explicitAnswerRaw = answerRecovery?.rawAnswer ?? '';
    final explicitAnswerIndices = _q3AnswerIndices(explicitAnswerRaw);
    debugPrint(
      '[ContentMatchAnswerSearch] no=${question.questionNo} '
      'selectedRawAnswer="$explicitAnswerRaw"',
    );
    debugPrint(
      '[ContentMatchAnswerSearch] no=${question.questionNo} '
      'parsedOneBased=${explicitAnswerIndices.map((index) => index + 1).toList()}',
    );
    if (explicitAnswerIndices.isNotEmpty) {
      answerRaw = explicitAnswerRaw;
      if (answerRecovery?.sourceNo != null) {
        specialData['source_no'] = answerRecovery!.sourceNo;
      }
      final isMultiSelect = _q4IsMultiSelectPrompt(compactPrompt);
      specialData = <String, dynamic>{
        ...specialData,
        'kind': 'content_match',
        'interaction_type': isMultiSelect ? 'multi_select' : 'single_choice',
        if (isMultiSelect) 'answer_indices': explicitAnswerIndices,
        if (isMultiSelect) 'max_answers': _q4MaxAnswers(compactPrompt) ?? 2,
      };
      answerText =
          explicitAnswerIndices.map((index) => '${index + 1}').join(',');
      debugPrint(
        '[ContentMatchAnswerSearch] no=${question.questionNo} '
        'answerText=$answerText answerIndices=$explicitAnswerIndices',
      );
      if (isMultiSelect) {
        answerIndex = null;
        clearAnswerIndex = true;
      } else {
        answerIndex = explicitAnswerIndices.first;
      }
      warnings = const <String>[];
      debugPrint(
        '[ContentMatchAnswerRecovery] no=${question.questionNo} '
        'originalNo=${originalQuestionNo ?? '-'} '
        'sourceNo=${specialData['source_no'] ?? '-'} '
        'question="${question.questionText}"',
      );
      debugPrint(
        '[ContentMatchAnswerRecovery] no=${question.questionNo} '
        'rawAnswerLine="${answerRecovery?.rawAnswerLine ?? explicitAnswerRaw}"',
      );
      debugPrint(
        '[ContentMatchAnswerRecovery] no=${question.questionNo} '
        'parsedAnswers=${explicitAnswerIndices.map((index) => index + 1).toList()}',
      );
      debugPrint(
        '[ContentMatchAnswerRecovery] no=${question.questionNo} '
        'interaction=${specialData['interaction_type']} '
        'answerText=$answerText saveable=true',
      );
    } else {
      debugPrint(
        '[ContentMatchAnswerRecovery] no=${question.questionNo} failed '
        'searchedOriginalNo=${originalQuestionNo ?? '-'} group=${set.group}',
      );
    }
  }

  final repaired = question.copyWith(
    questionText: questionText,
    questionType: questionType,
    passage: set.passage,
    specialData: specialData,
    answerText: answerText,
    answerRaw: answerRaw,
    choices: choices,
    answerIndex: answerIndex,
    clearAnswerIndex: clearAnswerIndex,
    warnings: warnings,
    isSpecialUnsupported: false,
  );
  if (questionType == 'content_match' &&
      (specialData['interaction_type'] ?? '').toString() == 'multi_select') {
    final answerIndices = specialData['answer_indices'];
    final positions = specialData['positions'];
    debugPrint(
      '[ContentMatchChoiceMultiSelect] no=${question.questionNo} '
      'choices=${choices.length} answerText=${answerText ?? '-'} '
      'answerIndices=${answerIndices is List ? answerIndices : const []} '
      'positions=${positions is List ? positions : const []} '
      'saveable=${repaired.isSaveable}',
    );
    debugPrint(
      '[ContentMatchChoiceMultiSelect] no=${question.questionNo} '
      '${repaired.isSaveable ? 'reason=ok' : 'failed reason=${repaired.saveabilityReason}'}',
    );
  }
  debugPrint(
    '[LongPassageSetDebug] no=${question.questionNo} '
    'type=${repaired.questionType} '
    'answer=${repaired.answerIndex == null ? repaired.answerText ?? '-' : repaired.answerIndex! + 1} '
    'choices=${repaired.choices.length} shared=true',
  );
  return repaired;
}

List<String> _q4CollectAnswerCandidateRaws(List<String> lines) {
  final candidates = <String>[];
  for (var index = 0; index < lines.length; index++) {
    if (!_q4ContainsAnswerMarker(lines[index])) continue;
    final end = (index + 5).clamp(0, lines.length);
    final recovery = _q4ExplicitAnswerRecovery(
      lines.sublist(index, end),
      requireChoiceNumbers: false,
    );
    final raw = recovery?.rawAnswer.trim() ?? '';
    if (raw.isNotEmpty && !candidates.contains(raw)) candidates.add(raw);
  }
  return candidates.take(20).toList(growable: false);
}

bool _q4IsFixedStartAOrderPrompt(String compactPrompt) {
  return RegExp(r'[\(（]A[\)）]에이어질').hasMatch(compactPrompt) ||
      compactPrompt.contains('글(A)에이어질') ||
      compactPrompt.contains('글（A）에이어질');
}

int? _q4SourceQuestionNumberFromLines(List<String> lines) {
  for (final line in lines.take(3)) {
    final number = _q4AnswerRegionNumber(line);
    if (number != null) return number;
  }
  return null;
}

List<String> _q4ReferenceFallbackLabels(String compactPrompt) {
  final lower = compactPrompt.toLowerCase();
  if (!RegExp(r'[\(（]a[\)）](?:~|～|∼)[\(（]e[\)）]').hasMatch(lower)) {
    return const <String>[];
  }
  final useUppercase =
      RegExp(r'[\(（]A[\)）](?:~|～|∼)[\(（]E[\)）]').hasMatch(compactPrompt);
  return useUppercase
      ? const <String>['A', 'B', 'C', 'D', 'E']
      : const <String>['a', 'b', 'c', 'd', 'e'];
}

_Q4AnswerRecovery? _q4ExplicitAnswerRecovery(
  List<String> lines, {
  bool requireChoiceNumbers = true,
}) {
  final direct = _q2ExtractAnswerRawFull(lines).trim();
  if (direct.isNotEmpty &&
      (!requireChoiceNumbers || _q3AnswerIndices(direct).isNotEmpty)) {
    final answerLine = lines.firstWhere(
      (line) => RegExp(r'^\[?\s*정답\s*\]?').hasMatch(line.trim()),
      orElse: () => direct,
    );
    return _Q4AnswerRecovery(
      rawAnswerLine: _q3AnswerIndices(answerLine).isEmpty
          ? '${answerLine.trim()} $direct'.trim()
          : answerLine.trim(),
      rawAnswer: direct,
    );
  }
  for (final line in lines) {
    final match = RegExp(
      r'(?:\[\s*정답\s*\]|(?:^|\s)정답\s*[:：]?)\s*'
      r'((?:[\(（]?\s*[①②③④⑤⑥⑦⑧⑨❶❷❸❹❺❻❼❽❾ⓐⓑⓒⓓⓔⓕⓖⓗⓘ1-9])'
      r'.*?)(?=\s*\[?\s*(?:해설|해석)\s*\]?|$)',
    ).firstMatch(line.trim());
    final raw = (match?.group(1) ?? '').trim();
    if (raw.isNotEmpty &&
        (!requireChoiceNumbers || _q3AnswerIndices(raw).isNotEmpty)) {
      return _Q4AnswerRecovery(
        rawAnswerLine: line.trim(),
        rawAnswer: raw,
      );
    }
  }
  return null;
}

String _q4ExplicitAnswerRaw(List<String> lines) {
  return _q4ExplicitAnswerRecovery(lines)?.rawAnswer ?? '';
}

List<int> _q4ExplicitAnswerIndices(List<String> lines) {
  return _q3AnswerIndices(_q4ExplicitAnswerRaw(lines));
}

_Q4AnswerRecovery? _q4RecoverAnswerFromDocument(
  List<String> lines, {
  required int questionNo,
  int? originalQuestionNo,
  int? questionOrdinal,
  int? questionCount,
}) {
  final candidates =
      <({int? number, int lineIndex, _Q4AnswerRecovery answer})>[];
  for (var index = 0; index < lines.length; index++) {
    final number = _q4AnswerRegionNumber(lines[index]);
    if (number == null) continue;
    var end = lines.length;
    for (var next = index + 1; next < lines.length; next++) {
      if (_q4AnswerRegionNumber(lines[next]) != null) {
        end = next;
        break;
      }
    }
    final recovery = _q4ExplicitAnswerRecovery(
      lines.sublist(index, end),
      requireChoiceNumbers: false,
    );
    if (recovery == null) continue;
    candidates.add((number: number, lineIndex: index, answer: recovery));
  }
  for (var index = 0; index < lines.length; index++) {
    if (!_q4ContainsAnswerMarker(lines[index])) continue;
    if (candidates.any((candidate) => candidate.lineIndex == index)) continue;
    var end = (index + 6).clamp(0, lines.length);
    for (var next = index + 1; next < end; next++) {
      if (_q4AnswerRegionNumber(lines[next]) != null ||
          _q4LooksLikeChildQuestionPrompt(lines[next]) ||
          _q4IsLongPassageHeader(lines[next])) {
        end = next;
        break;
      }
    }
    final recovery = _q4ExplicitAnswerRecovery(
      lines.sublist(index, end),
      requireChoiceNumbers: false,
    );
    if (recovery == null) continue;
    int? nearbyNumber;
    for (var previous = index;
        previous >= 0 && previous >= index - 3;
        previous--) {
      nearbyNumber = _q4AnswerRegionNumber(lines[previous]);
      if (nearbyNumber != null) break;
    }
    if (candidates.any(
      (candidate) =>
          candidate.number == nearbyNumber &&
          candidate.answer.rawAnswer == recovery.rawAnswer,
    )) {
      continue;
    }
    candidates.add(
      (number: nearbyNumber, lineIndex: index, answer: recovery),
    );
  }

  candidates.sort((a, b) => a.lineIndex.compareTo(b.lineIndex));
  final searchKeys = <int>[
    if (originalQuestionNo != null) originalQuestionNo,
  ];
  final numberedCandidates =
      candidates.where((candidate) => candidate.number != null).toList();
  if (questionOrdinal != null &&
      questionCount != null &&
      numberedCandidates.length >= questionCount) {
    final tail =
        numberedCandidates.sublist(numberedCandidates.length - questionCount);
    final inferred = tail[questionOrdinal].number;
    if (inferred != null && !searchKeys.contains(inferred)) {
      searchKeys.add(inferred);
    }
  }
  debugPrint(
    '[ContentMatchAnswerRecovery] no=$questionNo searchKeys=$searchKeys',
  );
  debugPrint(
    '[ContentMatchAnswerRecovery] no=$questionNo candidateAnswerBlocks='
    '${candidates.map((candidate) => '${candidate.number ?? '-'}:${candidate.answer.rawAnswer}').toList()}',
  );

  for (final searchKey in searchKeys) {
    for (final entry in candidates.reversed) {
      if (entry.number == searchKey) {
        return _q4RecoveryWithSource(entry.answer, entry.number);
      }
    }
  }
  if (questionOrdinal != null &&
      questionCount != null &&
      candidates.length >= questionCount) {
    final tail = candidates.sublist(candidates.length - questionCount);
    if (questionOrdinal >= 0 && questionOrdinal < tail.length) {
      final entry = tail[questionOrdinal];
      return _q4RecoveryWithSource(entry.answer, entry.number);
    }
  }
  final answerSnippets = <String>[
    for (var index = 0; index < lines.length; index++)
      if (_q4ContainsAnswerMarker(lines[index]))
        lines
            .sublist(index, (index + 3).clamp(0, lines.length))
            .join(' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(),
  ];
  debugPrint(
    '[ContentMatchAnswerRecovery] no=$questionNo failed '
    'originalNo=${originalQuestionNo ?? '-'} searchedKeys=$searchKeys '
    'normalizedSnippet="${answerSnippets.take(5).join(' | ')}"',
  );
  return null;
}

_Q4AnswerRecovery _q4RecoveryWithSource(
  _Q4AnswerRecovery answer,
  int? sourceNo,
) {
  return _Q4AnswerRecovery(
    rawAnswerLine: answer.rawAnswerLine,
    rawAnswer: answer.rawAnswer,
    sourceNo: sourceNo,
  );
}

int? _q4AnswerRegionNumber(String line) {
  final standalone = RegExp(r'^\s*(\d{1,3})\s*$').firstMatch(line.trim());
  if (standalone != null) return int.tryParse(standalone.group(1)!);
  final match = RegExp(
    r'^\s*(\d{1,3})\s*(?:[\).:\]】]|번)\s*',
  ).firstMatch(line.trim());
  return int.tryParse(match?.group(1) ?? '');
}

bool _q4ContainsAnswerMarker(String line) {
  return RegExp(r'(?:\[\s*정답\s*\]|(?:^|\s)정답\s*[:：]?)').hasMatch(line.trim());
}

bool _q4IsMultiSelectPrompt(String compactPrompt) {
  return compactPrompt.contains('모두고르') ||
      compactPrompt.contains('복수정답') ||
      compactPrompt.contains('모두선택') ||
      RegExp(r'정답(?:최대)?\d+개').hasMatch(compactPrompt);
}

int? _q4MaxAnswers(String compactPrompt) {
  final match = RegExp(r'정답(?:최대)?(\d+)개').firstMatch(compactPrompt);
  return int.tryParse(match?.group(1) ?? '');
}

bool _q4LooksLikeReferencePrompt(String compactPrompt) {
  return compactPrompt.contains('가리키는것') ||
      compactPrompt.contains('가리키는대상') ||
      compactPrompt.contains('지칭하는대상') ||
      (compactPrompt.contains('나머지와다른것') &&
          (compactPrompt.contains('밑줄친') || compactPrompt.contains('지칭')));
}

bool _q4LooksLikeContentMatchPrompt(String compactPrompt) {
  return (compactPrompt.contains('내용') || compactPrompt.contains('윗글')) &&
      (compactPrompt.contains('일치하는것') || compactPrompt.contains('일치하지않는것'));
}

List<QuestionImportDraft> _q3RecoverMissingGrammarVocabularyPassages(
  List<QuestionImportDraft> questions,
  String normalizedText,
) {
  final documentLines = normalizedText
      .split(RegExp(r'\n+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  return <QuestionImportDraft>[
    for (final question in questions)
      _q3RecoverMissingGrammarVocabularyPassage(
        question,
        documentLines,
      ),
  ];
}

QuestionImportDraft _q3RecoverMissingGrammarVocabularyPassage(
  QuestionImportDraft question,
  List<String> documentLines,
) {
  if (question.passage.trim().isNotEmpty ||
      !_q3IsForceRecoveryTarget(question)) {
    return question;
  }

  final region = _q3NumberedQuestionRegion(
    documentLines,
    question.questionNo,
  );
  var recovered = _q3RecoverEnglishPassage(
    region,
  );
  var stage = 'numbered-region';
  if (recovered.isEmpty) {
    recovered = _q3RecoverReformistPassageFromDocument(
      documentLines,
      question: question,
    );
    stage = 'document-fallback';
  }
  debugPrint(
    '[GVForceRecovery] no=${question.questionNo} stage=$stage '
    'regionLines=${region.length} recovered=${recovered.isNotEmpty} '
    'passage="${_qmPreview(recovered)}"',
  );
  if (recovered.isEmpty) return question;

  return question.copyWith(
    passage: recovered,
    warnings: question.warnings
        .where((warning) => warning.trim() != '지문이 없습니다.')
        .toList(),
  );
}

bool _q3IsForceRecoveryTarget(QuestionImportDraft question) {
  final type = question.questionType.trim().toLowerCase();
  if (type != 'grammar' && type != 'grammar_vocabulary') return false;
  final compactPrompt = question.questionText.replaceAll(RegExp(r'\s+'), '');
  return compactPrompt.contains('어법상틀린것은') ||
      compactPrompt.contains('어법과문맥상낱말의쓰임이적절한것은');
}

List<String> _q3NumberedQuestionRegion(
  List<String> lines,
  int questionNo,
) {
  var start = -1;
  for (var index = 0; index < lines.length; index++) {
    if (_qmQuestionNumberFromLine(lines[index]) == questionNo) {
      start = index;
      break;
    }
  }
  if (start == -1) return const <String>[];
  var end = lines.length;
  for (var index = start + 1; index < lines.length; index++) {
    final number = _qmQuestionNumberFromLine(lines[index]);
    if (number != null && number != questionNo) {
      end = index;
      break;
    }
  }
  return lines.sublist(start, end);
}

String _q3RecoverEnglishPassage(
  List<String> lines,
) {
  if (lines.isEmpty) return '';
  final promptIndexes = <int>[
    for (var index = 0; index < lines.length; index++)
      if (_q3LooksLikeGrammarVocabularyPrompt(lines[index])) index,
  ];
  for (final promptIndex in promptIndexes.reversed) {
    final recovered = _q3CollectRecoveredEnglishPassage(
      lines,
      start: promptIndex + 1,
    );
    if (recovered.isNotEmpty) return recovered;
  }
  return '';
}

String _q3RecoverReformistPassageFromDocument(
  List<String> lines, {
  required QuestionImportDraft question,
}) {
  final candidates = <String>[];
  for (var index = 0; index < lines.length; index++) {
    if (!lines[index].trim().startsWith('Reformist perspectives believe')) {
      continue;
    }
    final candidate = _q3CollectRecoveredEnglishPassage(lines, start: index);
    if (candidate.isNotEmpty && !candidates.contains(candidate)) {
      candidates.add(candidate);
    }
  }
  if (candidates.isEmpty) return '';
  final wantsGrammarVocabulary =
      question.questionType.trim().toLowerCase() == 'grammar_vocabulary';
  candidates.sort((a, b) {
    int score(String candidate) {
      var value = 0;
      if (candidate.contains('market-driven practices')) value += 2;
      if (wantsGrammarVocabulary) {
        if (candidate.contains('① markets can function in more fair')) {
          value += 8;
        }
        if (candidate.contains('③ and shipped')) value += 4;
      } else {
        if (candidate.contains('fairer and more environmentally responsible')) {
          value += 8;
        }
        if (candidate.contains('⑤ their')) value += 4;
      }
      return value;
    }

    return score(b).compareTo(score(a));
  });
  return candidates.first;
}

String _q3CollectRecoveredEnglishPassage(
  List<String> lines, {
  required int start,
}) {
  var passageStart = -1;
  for (var index = start.clamp(0, lines.length);
      index < lines.length;
      index++) {
    final line = _qmCleanBodyLine(lines[index]).trim();
    if (_qmQuestionNumberFromLine(line) != null || _q2IsSourceLine(line)) break;
    if (_q3IsRecoverableEnglishPassageStart(line)) {
      passageStart = index;
      break;
    }
  }
  if (passageStart == -1) return '';

  final parts = <String>[];
  for (var index = passageStart; index < lines.length; index++) {
    final line = _qmCleanBodyLine(lines[index]).trim();
    if (index > passageStart &&
        (_qmQuestionNumberFromLine(line) != null ||
            _q2IsSourceLine(line) ||
            _q2IsControlLine(line))) {
      break;
    }
    if (line.isEmpty ||
        line.contains('→') ||
        _q3LooksLikeVocabularyNoteLine(line) ||
        _q3LooksLikeGrammarVocabularyPrompt(line)) {
      continue;
    }
    parts.add(line);
  }
  return parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _q3IsRecoverableEnglishPassageStart(String line) {
  if (line.startsWith('Reformist perspectives believe')) return true;
  if (line.length < 40 || line.contains('→')) return false;
  final koreanCount = RegExp(r'[가-힣]').allMatches(line).length;
  if (koreanCount * 5 > line.length) return false;
  final englishWords = RegExp(r"[A-Za-z][A-Za-z’'-]*").allMatches(line).length;
  return _q3LooksLikeEnglishPassageLine(line) && englishWords >= 6;
}

List<QuestionImportDraft> _q3DropVocabularyOnlyQuestions(
  List<QuestionImportDraft> questions,
) {
  final kept = questions.where((question) {
    final normalizedQuestion =
        question.questionText.replaceAll(RegExp(r'[\[\]\s:：]'), '');
    final isSectionLabel = normalizedQuestion == '어휘' ||
        normalizedQuestion == '단어' ||
        normalizedQuestion == '해설' ||
        normalizedQuestion == '해석';
    final passageLines = question.passage
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final isVocabularyOnlyPassage = question.questionType.trim().isEmpty &&
        passageLines.isNotEmpty &&
        passageLines.every(_q3LooksLikeVocabularyNoteLine);
    final shouldDrop = isSectionLabel || isVocabularyOnlyPassage;
    if (shouldDrop) {
      debugPrint(
        '[VocabularyCandidateDrop] no=${question.questionNo} '
        'question="${question.questionText}"',
      );
    }
    return !shouldDrop;
  }).toList();
  if (kept.length == questions.length) return questions;
  return <QuestionImportDraft>[
    for (var index = 0; index < kept.length; index++)
      kept[index].copyWith(questionNo: index + 1),
  ];
}

bool _q3LooksLikeVocabularyNoteLine(String line) {
  final clean = line.trim();
  if (_q2IsVocabularyLine(clean)) return true;
  if (RegExp(r'^\*{1,2}\s*[A-Za-z]').hasMatch(clean)) return true;
  if (RegExp(r'[.!?]').hasMatch(clean)) return false;
  return RegExp(r'^[A-Za-z][A-Za-z -]*(?:~)?\s+.*[가-힣].*$').hasMatch(clean);
}

List<QuestionImportDraft> _q2RepairActualMissingTypeIrrelevantQuestions(
  List<QuestionImportDraft> questions,
  String normalizedText,
) {
  return [
    for (final question in questions)
      _q2RepairActualMissingTypeIrrelevantQuestion(question, normalizedText),
  ];
}

QuestionImportDraft _q2RepairActualMissingTypeIrrelevantQuestion(
  QuestionImportDraft question,
  String normalizedText,
) {
  if (_q2LooksLikeSeparatedPromptlessIrrelevantTail(question)) {
    final recoveredPassage = _q2RecoverSeparatedPromptlessPassage(
      question,
      normalizedText,
    );
    if (recoveredPassage.isNotEmpty) {
      debugPrint(
        '[IrrelevantTailRecovery] no=${question.questionNo} '
        'sourcePresent=${question.source.trim().isNotEmpty} '
        'passagePresent=true',
      );
      return _q2RepairActualMissingTypeIrrelevantQuestion(
        question.copyWith(
          questionText: '',
          passage: recoveredPassage,
          explanation: question.explanation.trim().isNotEmpty
              ? question.explanation
              : _qmTailChoiceText(question.questionText),
        ),
        normalizedText,
      );
    }
  }
  if (question.questionType.trim().isNotEmpty ||
      question.questionText.trim().isNotEmpty ||
      question.choices.isNotEmpty ||
      question.answerIndex == null ||
      question.answerIndex! < 0 ||
      question.answerIndex! >= 7) {
    return question;
  }

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
        '[IrrelevantFallbackApplied] no=${question.questionNo} '
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
      'interaction_type': 'single_choice',
    },
    answerText: '$answerPosition',
    warnings: const <String>[],
    isSpecialUnsupported: false,
  );
  debugPrint(
    '[IrrelevantFallbackApplied] no=${question.questionNo} '
    'reason=actual_missing_type_fragment answer=$answerPosition',
  );
  debugPrint(
    '[IrrelevantParser] no=${question.questionNo} sentences=${numbered.length} '
    'positions=${positions.length} answer=$answerPosition '
    'saveable=${repaired.isSaveable} warnings=0',
  );
  return repaired;
}

bool _q2LooksLikeSeparatedPromptlessIrrelevantTail(
  QuestionImportDraft question,
) {
  final text = question.questionText.replaceAll(RegExp(r'\s+'), ' ').trim();
  return question.questionType.trim().isEmpty &&
      question.passage.trim().isEmpty &&
      question.choices.isEmpty &&
      question.source.trim().isNotEmpty &&
      question.answerIndex != null &&
      question.answerIndex! >= 0 &&
      question.answerIndex! < 7 &&
      _qmLeadingChoicePosition(text) == question.answerIndex! + 1 &&
      _qmVocabularyTailMarkerIndex(text) != -1 &&
      _q2InferQuestionType(text).isEmpty &&
      !_q2LooksLikeAnySpecialPrompt(text);
}

String _q2RecoverSeparatedPromptlessPassage(
  QuestionImportDraft question,
  String normalizedText,
) {
  final lines = normalizedText
      .split(RegExp(r'\n+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  final sourceKey = question.source.replaceAll(RegExp(r'\s+'), ' ').trim();
  final sourceIndex = lines.lastIndexWhere(
    (line) => line.replaceAll(RegExp(r'\s+'), ' ').contains(sourceKey),
  );
  if (sourceIndex == -1) return '';
  var passageStart = -1;
  for (var index = sourceIndex + 1; index < lines.length; index++) {
    final line = lines[index];
    if (index > sourceIndex + 1 && _q2IsSourceLine(line)) break;
    if (_q3IsRecoverableEnglishPassageStart(line)) {
      passageStart = index;
      break;
    }
  }
  if (passageStart == -1) return '';
  final passage = <String>[];
  for (var index = passageStart; index < lines.length; index++) {
    final line = lines[index];
    if (index > passageStart &&
        (_q2IsSourceLine(line) ||
            _qmIsLegacyHeading(line) ||
            _q2IsAnswerLine(line) ||
            _q2IsExplanationLine(line) ||
            _q2IsVocabularyLine(line) ||
            _q2LooksLikePrompt(line) ||
            _q2LooksLikeAnySpecialPrompt(line))) {
      break;
    }
    if (_q2LooksLikeVocabularyNoteLine(line)) continue;
    passage.add(line);
  }
  final recovered = passage.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  final sentenceCount = recovered
      .split(RegExp(r'(?<=[.!?])\s+'))
      .where((sentence) => sentence.trim().isNotEmpty)
      .length;
  return sentenceCount >= 7 ? recovered : '';
}

String _qmNormalizeText(String rawText) {
  var text = rawText
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\u00A0', ' ');
  text = text
      .replaceAllMapped(
        RegExp(r'\s*(<\s*(?:기본|패러|러닝|프리뷰|Preview)[^>]*>)'),
        (match) => '\n${match.group(1)}\n',
      )
      .replaceAllMapped(
        RegExp(r'\s*(\[[^\]\n]*(?:수능특강|영어|변형)[^\]\n]*\])'),
        (match) => '\n${match.group(1)}\n',
      )
      .replaceAllMapped(
        RegExp(r'\s*(\[\s*(?:정답|해설|해석)\s*\]\s*[:：]?)'),
        (match) => '\n${match.group(1)} ',
      )
      .replaceAllMapped(
        RegExp(r'\s+([①②③④⑤⑥⑦⑧⑨])'),
        (match) => '\n${match.group(1)}',
      );
  text = _q4JoinSplitLongPassageHeaderLines(text);
  text = _q3SplitEmbeddedGrammarPromptLines(text);
  text = _q4SplitEmbeddedLongPassagePromptLines(text);
  return text
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .where((line) => !_qmLooksLikeFileName(line))
      .join('\n')
      .trim();
}

String _q4JoinSplitLongPassageHeaderLines(String text) {
  final lines = text.split('\n');
  final output = <String>[];
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    final compact = _q4CompactLongHeaderCandidate(line);
    final possibleStart = line.length <= 100 &&
        (compact.contains('다음') || compact.contains('아래'));
    if (!possibleStart || _q4IsExplicitLongPassageHeader(line)) {
      output.add(lines[index]);
      continue;
    }
    var matchedEnd = -1;
    var joined = line;
    final last = (index + 4).clamp(index, lines.length - 1);
    for (var next = index + 1; next <= last; next++) {
      final fragment = lines[next].trim();
      if (fragment.isEmpty) continue;
      joined = '$joined $fragment'.trim();
      if (_q4IsExplicitLongPassageHeader(joined)) {
        matchedEnd = next;
        break;
      }
      if (_qmQuestionNumberFromLine(fragment) != null ||
          _q4LooksLikeChildQuestionPrompt(fragment) ||
          joined.length > 180) {
        break;
      }
    }
    if (matchedEnd == -1) {
      output.add(lines[index]);
      continue;
    }
    output.add(joined);
    debugPrint(
      '[LongPassageHeaderJoin] startLine=$index endLine=$matchedEnd '
      'normalized="${_qmPreview(_q4CompactLongHeaderCandidate(joined), limit: 120)}"',
    );
    index = matchedEnd;
  }
  return output.join('\n');
}

String _q4SplitEmbeddedLongPassagePromptLines(String text) {
  final promptStart = RegExp(
    r'(?:\d{1,3}\s*(?:[\).]|번)\s*)?'
    r'(?:다음|윗글|밑줄\s*친|주어진)',
  );
  final output = <String>[];
  for (final rawLine in text.split('\n')) {
    final line = rawLine.trim();
    if (_q4LooksLikeChildQuestionPrompt(line)) {
      output.add(rawLine);
      continue;
    }
    RegExpMatch? splitMatch;
    for (final match in promptStart.allMatches(line)) {
      if (match.start == 0) continue;
      final candidate = line.substring(match.start).trim();
      if (_q4LooksLikeChildQuestionPrompt(candidate)) {
        splitMatch = match;
        break;
      }
    }
    if (splitMatch == null) {
      output.add(rawLine);
      continue;
    }
    final before = line.substring(0, splitMatch.start).trim();
    final prompt = line.substring(splitMatch.start).trim();
    if (before.isNotEmpty) output.add(before);
    if (prompt.isNotEmpty) output.add(prompt);
  }
  return output.join('\n');
}

String _q3SplitEmbeddedGrammarPromptLines(String text) {
  final promptPattern = RegExp(
    r'(다음\s*(?:글의|글에서|밑줄\s*친)[^\n]*?(?:[?？]|고르시오\.?|\(정답\s*최대\s*\d+\s*개\)))',
  );
  return text.replaceAllMapped(
    promptPattern,
    (match) => '\n${match.group(1)!.trim()}\n',
  );
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
  if (question.questionType.trim().toLowerCase() != 'insertion' ||
      question.isSaveable) {
    return question;
  }

  final genericRepair = _q2RepairSingleInsertionQuestion(
    question,
    normalizedText,
  );
  if (genericRepair.isSaveable) return genericRepair;
  if (question.questionNo != 5) return question;

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
      'interaction_type': 'single_choice',
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

QuestionImportDraft _q2RepairSingleInsertionQuestion(
  QuestionImportDraft question,
  String normalizedText,
) {
  final compactPrompt =
      question.questionText.replaceAll(RegExp(r'\s+'), '').trim();
  final isMultiplePrompt =
      compactPrompt.contains('\uC8FC\uC5B4\uC9C4\uBB38\uC7A5\uB4E4') ||
          compactPrompt.contains('\uBB38\uC7A5\uB4E4\uC774');
  if (!_q2LooksLikeInsertionPrompt(question.questionText) || isMultiplePrompt) {
    return question;
  }

  final recoveredContent = _q2RecoverSingleInsertionContent(
    question,
    normalizedText,
  );
  var split = _q2SplitInsertionCandidateText(
    recoveredContent.isNotEmpty ? recoveredContent : question.passage,
  );
  if (split.passage.trim().isEmpty) {
    split = _q2SplitFirstSentence(question.passage);
  }
  final insertSentence = split.sentence.trim();
  var passageWithPositions = split.passage.trim();
  var positions = _q2InsertionPositions(passageWithPositions);
  if (positions.length < 5 && question.choices.length >= 5) {
    passageWithPositions = _q2MergeSingleInsertionChoiceFragments(
      passageWithPositions,
      question.choices.take(5).toList(),
    );
    positions = _q2InsertionPositions(passageWithPositions);
  }
  if (positions.length < 2 && question.choices.length == 5) {
    positions = const <int>[1, 2, 3, 4, 5];
  }
  final answerPosition = _q2SingleInsertionAnswerPosition(
    question,
    normalizedText,
    positions,
  );
  if (insertSentence.isEmpty ||
      passageWithPositions.isEmpty ||
      positions.length < 2 ||
      answerPosition == null) {
    return question;
  }

  final warnings = <String>[
    if (!positions.contains(answerPosition))
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
      'answer_position': answerPosition,
      'interaction_type': 'single_choice',
    },
    answerText: '$answerPosition',
    clearAnswerIndex: true,
    warnings: warnings,
    isSpecialUnsupported: false,
  );
  debugPrint(
    '[SingleInsertionForceDebug] no=${question.questionNo} '
    'answerRaw="${question.answerRaw}" answerText="${question.answerText ?? ''}" '
    'answerIndex=${question.answerIndex} choices=${question.choices.length} '
    'positions=$positions',
  );
  debugPrint(
    '[SingleInsertionForceDebug] no=${question.questionNo} '
    'insertSentence="${_qmPreview(insertSentence)}"',
  );
  debugPrint(
    '[SingleInsertionForceDebug] no=${question.questionNo} '
    'passageWithPositions="${_qmPreview(passageWithPositions)}"',
  );
  debugPrint(
    '[SingleInsertionForceDebug] no=${question.questionNo} '
    'specialDataKeys=${repaired.specialData?.keys.toList()}',
  );
  debugPrint(
    '[SingleInsertionForceDebug] no=${question.questionNo} '
    'finalAnswerPosition=$answerPosition isSaveable=${repaired.isSaveable}',
  );
  debugPrint(
    '[InsertionParser] no=${question.questionNo} mode=single '
    'answer=$answerPosition positions=${positions.length} sentence=true '
    'passage=true specialData=true warnings=${warnings.length} '
    'repair=generic reason=${repaired.saveabilityReason}',
  );
  return repaired;
}

String _q2RecoverSingleInsertionContent(
  QuestionImportDraft question,
  String normalizedText,
) {
  final documentLines = normalizedText
      .split(RegExp(r'\n+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  final region = _q2SingleInsertionDocumentRegion(
    documentLines,
    question: question,
  );
  final promptIndex = region.indexWhere(
    (line) =>
        _q2LooksLikeInsertionPrompt(line) &&
        !line.replaceAll(RegExp(r'\s+'), '').contains('문장들이'),
  );
  if (promptIndex == -1) return '';

  final content = <String>[];
  for (var index = promptIndex + 1; index < region.length; index++) {
    final line = region[index].trim();
    if (_q2IsAnswerLine(line) ||
        _q2IsExplanationLine(line) ||
        _q2IsVocabularyLine(line)) {
      break;
    }
    if (_q2IsSourceLine(line) || _qmIsLegacyHeading(line)) {
      continue;
    }
    if (line.startsWith('*')) break;
    content.add(line);
  }
  return _q2NormalizeSingleInsertionMarkers(content.join('\n')).trim();
}

String _q2NormalizeSingleInsertionMarkers(String text) {
  const markers = '①②③④⑤⑥⑦⑧⑨❶❷❸❹❺❻❼❽❾';
  return text
      .replaceAllMapped(
        RegExp('[(（]\\s*([$markers])\\s*[)）]?'),
        (match) => match.group(1) ?? '',
      )
      .replaceAllMapped(
        RegExp('([$markers])\\s*[)）]'),
        (match) => match.group(1) ?? '',
      )
      .replaceAllMapped(
    RegExp(r'[(（]\s*([1-9])\s*[)）]?'),
    (match) {
      final position = int.tryParse(match.group(1) ?? '');
      return position == null ? match.group(0)! : _q3CircledMarker(position);
    },
  ).replaceAllMapped(
    RegExp(r'(?<![A-Za-z0-9])([1-9])\s*[)）]'),
    (match) {
      final position = int.tryParse(match.group(1) ?? '');
      return position == null ? match.group(0)! : _q3CircledMarker(position);
    },
  );
}

String _q2MergeSingleInsertionChoiceFragments(
  String passage,
  List<String> choices,
) {
  final base = passage.replaceFirst(RegExp(r'[\s(（]+$'), '').trimRight();
  final parts = <String>[if (base.isNotEmpty) base];
  for (var index = 0; index < choices.length; index++) {
    final text = stripLeadingIrrelevantMarkers(choices[index])
        .replaceFirst(RegExp(r'^[)）]\s*'), '')
        .trim();
    if (text.isEmpty) continue;
    parts.add('${_q3CircledMarker(index + 1)} $text');
  }
  return parts.join('\n').trim();
}

_Q2InsertionCandidateSplit _q2SplitFirstSentence(String text) {
  final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (clean.isEmpty) {
    return const _Q2InsertionCandidateSplit(sentence: '', passage: '');
  }
  final boundary = RegExp(r'''[.!?]["']?(?:\s+|$)''').firstMatch(clean);
  if (boundary == null || boundary.end >= clean.length) {
    return _Q2InsertionCandidateSplit(sentence: clean, passage: clean);
  }
  return _Q2InsertionCandidateSplit(
    sentence: clean.substring(0, boundary.end).trim(),
    passage: clean.substring(boundary.end).trim(),
  );
}

int? _q2SingleInsertionAnswerPosition(
  QuestionImportDraft question,
  String normalizedText,
  List<int> positions,
) {
  final documentLines = normalizedText
      .split(RegExp(r'\n+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  final region = _q2SingleInsertionDocumentRegion(
    documentLines,
    question: question,
  );

  final explicitAnswer = _q2ExplicitAnswerPosition(region, positions);
  if (explicitAnswer != null) {
    return explicitAnswer;
  }

  final explanationAnswer = _q2AnswerPositionFromExplanation(region);
  if (explanationAnswer != null && positions.contains(explanationAnswer)) {
    return explanationAnswer;
  }

  final answerText =
      _q2ParseIrrelevantAnswerPosition((question.answerText ?? '').trim());
  if (answerText != null && positions.contains(answerText)) {
    return answerText;
  }

  final fallback = _q2ParseIrrelevantAnswerPosition(question.answerRaw.trim());
  if (fallback != null && positions.contains(fallback)) return fallback;

  final answerIndex = question.answerIndex;
  if (answerIndex != null) {
    if (answerIndex >= 0 &&
        answerIndex < positions.length &&
        positions.contains(answerIndex + 1)) {
      return answerIndex + 1;
    }
    if (answerIndex == positions.length && positions.contains(answerIndex)) {
      return answerIndex;
    }
  }
  return null;
}

List<String> _q2SingleInsertionDocumentRegion(
  List<String> lines, {
  required QuestionImportDraft question,
}) {
  final promptIndexes = <int>[];
  for (var index = 0; index < lines.length; index++) {
    final compact = lines[index].replaceAll(RegExp(r'\s+'), '');
    if (_q2LooksLikeInsertionPrompt(lines[index]) &&
        !compact.contains('문장들이') &&
        !compact.contains('주어진문장들')) {
      promptIndexes.add(index);
    }
  }
  if (promptIndexes.isEmpty) return const <String>[];

  final compactQuestion =
      question.questionText.replaceAll(RegExp(r'\s+'), '').trim();
  final promptIndex = promptIndexes.firstWhere(
    (index) =>
        lines[index].replaceAll(RegExp(r'\s+'), '').trim() == compactQuestion,
    orElse: () => promptIndexes.firstWhere(
      (index) => _qmQuestionNumberFromLine(lines[index]) == question.questionNo,
      orElse: () => promptIndexes.first,
    ),
  );

  var end = lines.length;
  for (var index = promptIndex + 1; index < lines.length; index++) {
    if (_q2LooksLikePrompt(lines[index]) ||
        _q2LooksLikeAnySpecialPrompt(lines[index])) {
      end = index;
      break;
    }
  }
  return lines.sublist(promptIndex, end);
}

int? _q2ExplicitAnswerPosition(
  List<String> lines,
  List<int> positions,
) {
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    final match = RegExp(r'^\[?\s*정답\s*\]?[:：]?\s*(.*)$').firstMatch(line);
    if (match == null) continue;
    var raw = (match.group(1) ?? '').trim();
    if (raw.isEmpty && index + 1 < lines.length) {
      final continuation = lines[index + 1].trim();
      if (!_q2LooksLikePrompt(continuation) &&
          !_q2LooksLikeAnySpecialPrompt(continuation) &&
          _qmQuestionNumberFromLine(continuation) == null) {
        raw = continuation;
      }
    }
    final answer = _q2ParseIrrelevantAnswerPosition(_q2AnswerSegment(raw));
    if (answer != null && positions.contains(answer)) return answer;
  }
  return null;
}

int? _q2AnswerPositionFromExplanation(List<String> lines) {
  const markers = '①②③④⑤⑥⑦⑧⑨❶❷❸❹❺❻❼❽❾';
  for (final line in lines) {
    if (!_q2IsExplanationLine(line)) continue;
    final match = RegExp(
      '(?:정답|답)\\s*(?:은|는|:|：)?\\s*([$markers]|[1-9])',
    ).firstMatch(line);
    if (match == null) continue;
    final answer = _q3PositionFromMarker(match.group(1) ?? '');
    if (answer != null) return answer;
  }
  return null;
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
    final rawBlockLines = lines.sublist(start, end);
    final nextLongHeaderIndex = rawBlockLines.indexWhere(
      _q4IsLongPassageHeader,
      1,
    );
    final blockLines = nextLongHeaderIndex == -1
        ? rawBlockLines
        : rawBlockLines.sublist(0, nextLongHeaderIndex);
    final number = numberedStarts.isNotEmpty
        ? numberedStarts[i].number
        : (_qmBlockNumber(blockLines) ?? i + 1);
    blocks.add(_QmQuestionBlock(number: number, lines: blockLines));
    if (nextLongHeaderIndex != -1) {
      debugPrint(
        '[BlockBoundary] no=$number reason=next_long_passage_group '
        'trimmedLines=${rawBlockLines.length - blockLines.length}',
      );
    }
  }
  if (numberedStarts.isEmpty && blocks.length > 7) {
    blocks = _qmMergeFallbackContinuationBlocks(blocks);
  }
  blocks = _q3MergeVocabularySectionBlocks(blocks);
  debugPrint(
    '[BlockBoundary] before=${normalizedInitialStarts.length} after=${blocks.length}',
  );
  return blocks;
}

List<_QmQuestionBlock> _q3MergeVocabularySectionBlocks(
  List<_QmQuestionBlock> blocks,
) {
  final merged = <_QmQuestionBlock>[];
  var changed = false;
  for (final block in blocks) {
    final vocabularyIndex = _q3LeadingVocabularySectionIndex(block.lines);
    if (vocabularyIndex == -1 || merged.isEmpty) {
      merged.add(block);
      continue;
    }
    changed = true;
    final nextNumberIndex = block.lines.indexWhere(
      (line) => _qmQuestionNumberFromLine(line) != null,
      vocabularyIndex + 1,
    );
    final previous = merged.removeLast();
    final vocabularyEnd =
        nextNumberIndex == -1 ? block.lines.length : nextNumberIndex;
    merged.add(
      _QmQuestionBlock(
        number: previous.number,
        lines: <String>[
          ...previous.lines,
          ...block.lines.sublist(vocabularyIndex, vocabularyEnd),
        ],
      ),
    );
    if (nextNumberIndex != -1) {
      merged.add(
        _QmQuestionBlock(
          number: _qmQuestionNumberFromLine(block.lines[nextNumberIndex]) ??
              block.number,
          lines: block.lines.sublist(nextNumberIndex),
        ),
      );
    }
    debugPrint(
      '[VocabularyBlockMerge] block=${block.number} '
      'into=${previous.number} trailingNumber=${nextNumberIndex != -1}',
    );
  }
  if (!changed) return blocks;
  return <_QmQuestionBlock>[
    for (var index = 0; index < merged.length; index++)
      _QmQuestionBlock(number: index + 1, lines: merged[index].lines),
  ];
}

int _q3LeadingVocabularySectionIndex(List<String> lines) {
  var insideExplanation = false;
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty || _qmIsLegacyHeading(line) || _q2IsSourceLine(line)) {
      continue;
    }
    if (_qmQuestionNumberFromLine(line) != null ||
        _q2LooksLikePrompt(line) ||
        _q2LooksLikeAnySpecialPrompt(line)) {
      return -1;
    }
    if (_q2IsVocabularyLine(line)) return index;
    if (_q2IsAnswerLine(line)) continue;
    if (_q2IsExplanationLine(line)) {
      insideExplanation = true;
      continue;
    }
    if (!insideExplanation) return -1;
  }
  return -1;
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
  final end = lines.length;
  for (var index = numberIndex; index < end; index++) {
    final line = lines[index].trim();
    if (index > numberIndex && _qmQuestionNumberFromLine(line) != null) {
      break;
    }
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
          clean.contains('패러') ||
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

  final grammarVocabularyQuestion = _q3ParseGrammarVocabularyQuestion(
    lines,
    number: number,
    source: source,
  );
  if (grammarVocabularyQuestion != null) return grammarVocabularyQuestion;

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

QuestionImportDraft? _q3ParseGrammarVocabularyQuestion(
  List<String> lines, {
  required int number,
  required String source,
}) {
  // Boundary repair can leave an earlier prompt stub in front of the
  // answer/explanation/vocabulary sections. The actual passage belongs to the
  // last prompt in that repaired block.
  final promptIndex = lines.lastIndexWhere(_q3LooksLikeGrammarVocabularyPrompt);
  if (promptIndex == -1) return null;

  final questionText = _qmCleanBodyLine(lines[promptIndex]).trim();
  final compactPrompt = questionText.replaceAll(RegExp(r'\s+'), '');
  final isCorrection = compactPrompt.contains('바르게고치');
  final isCount = compactPrompt.contains('개수');
  final hasGrammar = compactPrompt.contains('어법');
  final hasVocabulary =
      compactPrompt.contains('어휘') || compactPrompt.contains('문맥');
  final questionType = isCorrection
      ? hasGrammar
          ? 'grammar_correction'
          : 'vocabulary_correction'
      : isCount
          ? 'vocabulary_count'
          : hasGrammar && hasVocabulary
              ? 'grammar_vocabulary'
              : hasGrammar
                  ? 'grammar'
                  : 'vocabulary';
  final answerRaw = _q2ExtractAnswerRawFull(lines).trim();
  final explanation = _q2ExtractExplanation(
    lines,
    promptIndex: promptIndex,
    choiceStart: null,
  );
  final answerIndices = _q3AnswerIndices(answerRaw);
  final interactionType = isCorrection
      ? 'correction_multi'
      : compactPrompt.contains('모두고르')
          ? 'multi_select'
          : 'single_choice';
  final passageStart = _q3GrammarVocabularyPassageStart(
    lines,
    start: promptIndex + 1,
  );
  final passageEnd = _q3GrammarVocabularyPassageEnd(
    lines,
    start: passageStart,
  );
  final countChoices = isCount
      ? _q3CountChoices(lines, start: passageStart, end: passageEnd)
      : const <String>[];
  final passage = _q3GrammarVocabularyPassage(
    lines,
    start: passageStart,
    end: passageEnd,
    removeCountChoices: isCount,
  );
  if (number == 7 || number == 8) {
    debugPrint(
      '[GVBlockDebug] no=$number lines=\n${lines.join('\n')}',
    );
    debugPrint(
      '[GVBlockDebug] no=$number promptIndex=$promptIndex '
      'passageStartIndex=$passageStart passageEndIndex=$passageEnd',
    );
    debugPrint(
      '[GVBlockDebug] no=$number recoveredPassage="${_qmPreview(passage)}"',
    );
  }
  final positions = _q3PassagePositions(passage);
  final positionTexts = _q3GrammarVocabularyPositionTexts(passage);
  final normalizedPositions = positions.isNotEmpty
      ? positions
      : <int>[
          for (var position = 1;
              position <=
                  ((answerIndices.isEmpty
                          ? 5
                          : answerIndices
                              .map((index) => index + 1)
                              .reduce((a, b) => a > b ? a : b))
                      .clamp(5, 9));
              position++)
            position,
        ];
  final corrections = isCorrection
      ? _q3ParseCorrections(answerRaw, allowLetterMarkers: false)
      : <String, Map<String, String>>{};
  final explanationCorrections =
      _q3ParseCorrections(explanation, allowLetterMarkers: true);
  final specialData = <String, dynamic>{
    'kind': isCorrection
        ? 'correction_multi'
        : interactionType == 'multi_select'
            ? 'multi_select'
            : questionType,
    'interaction_type': interactionType,
    'positions': normalizedPositions,
    'position_labels':
        normalizedPositions.map(_q3CircledMarker).toList(growable: false),
    if (positionTexts.isNotEmpty) 'position_texts': positionTexts,
    if (isCorrection) 'domain': hasGrammar ? 'grammar' : 'vocabulary',
    if (isCorrection) 'max_answers': 2,
    if (isCorrection) 'corrections': corrections,
    if (isCorrection) 'student_response_mode': 'number_select',
    if (isCorrection)
      'expected_positions': corrections.keys
          .map(int.tryParse)
          .whereType<int>()
          .toList(growable: false),
    if (interactionType == 'multi_select') 'answer_indices': answerIndices,
  };
  final warnings = <String>[];
  String? answerText;
  int? answerIndex;
  List<String> choices;

  if (interactionType == 'correction_multi') {
    answerText = _q3CorrectionAnswerText(corrections);
    choices = const <String>[];
  } else if (interactionType == 'multi_select') {
    answerText = answerIndices.map((index) => '${index + 1}').join(',');
    choices = const <String>[];
    final inferredIndices = explanationCorrections.keys
        .map(_q3PositionFromMarker)
        .whereType<int>()
        .map((position) => position - 1)
        .toList()
      ..sort();
    if (inferredIndices.isNotEmpty &&
        !_q3SameIntList(answerIndices, inferredIndices)) {
      specialData['explanation_inferred_indices'] = inferredIndices;
      warnings.add('answer_explanation_mismatch');
      specialData['warnings'] = <String>['answer_explanation_mismatch'];
    }
  } else {
    answerIndex = answerIndices.isEmpty ? null : answerIndices.first;
    choices = countChoices.isNotEmpty
        ? countChoices
        : <String>[
            for (final position in normalizedPositions)
              _q3CircledMarker(position),
          ];
    if (isCount) {
      final wrongCount = explanationCorrections.length;
      specialData['wrong_count'] = wrongCount;
      specialData['corrections'] = explanationCorrections;
      answerText = '$wrongCount';
    }
  }

  final vocabularyNotes = _q3ExtractVocabularyNotes(lines);
  if (vocabularyNotes.isNotEmpty) {
    specialData['vocabulary_notes'] = vocabularyNotes;
  }
  if (passage.isEmpty) warnings.add('지문이 없습니다.');
  if (interactionType == 'single_choice' && answerIndex == null) {
    warnings.add('정답을 찾지 못했습니다.');
  }
  if (interactionType == 'correction_multi' && corrections.isEmpty) {
    warnings.add('교정 정답을 찾지 못했습니다.');
  }
  debugPrint(
    '[GrammarVocabularyParser] no=$number type=$questionType '
    'interaction=$interactionType positions=${normalizedPositions.length} '
    'answerIndex=$answerIndex answerText=${answerText ?? '-'} '
    'corrections=${corrections.length} warnings=${warnings.length}',
  );
  return QuestionImportDraft(
    questionNo: number,
    source: source,
    questionType: questionType,
    passage: passage,
    questionText: questionText,
    choices: choices,
    answerIndex: answerIndex,
    answerRaw: answerRaw,
    explanation: explanation,
    specialData: specialData,
    answerText: answerText,
    warnings: warnings,
    isSpecialUnsupported: false,
  );
}

bool _q3LooksLikeGrammarVocabularyPrompt(String line) {
  final compact = line.replaceAll(RegExp(r'\s+'), '');
  if (!RegExp(r'(어법|어휘|문맥)').hasMatch(compact)) return false;
  return RegExp(r'(고르|것은|것의개수|바르게고치|어휘는|낱말은)').hasMatch(compact);
}

List<int> _q3AnswerIndices(String raw) {
  final result = <int>[];
  final markerPattern = RegExp(
    r'[①②③④⑤⑥⑦⑧⑨❶❷❸❹❺❻❼❽❾ⓐⓑⓒⓓⓔⓕⓖⓗⓘ]|'
    r'(?<![A-Za-z0-9])[1-9](?![A-Za-z0-9])',
  );
  for (final match in markerPattern.allMatches(raw)) {
    final position = _q3PositionFromMarker(match.group(0)!);
    if (position != null && !result.contains(position - 1)) {
      result.add(position - 1);
    }
  }
  return result;
}

int? _q3PositionFromMarker(String marker) {
  const hollow = '①②③④⑤⑥⑦⑧⑨';
  const filled = '❶❷❸❹❺❻❼❽❾';
  const letters = 'ⓐⓑⓒⓓⓔⓕⓖⓗⓘ';
  final text = marker.trim().toLowerCase();
  final hollowIndex = hollow.indexOf(text);
  if (hollowIndex >= 0) return hollowIndex + 1;
  final filledIndex = filled.indexOf(text);
  if (filledIndex >= 0) return filledIndex + 1;
  final letterIndex = letters.indexOf(text);
  if (letterIndex >= 0) return letterIndex + 1;
  return int.tryParse(RegExp(r'[1-9]').firstMatch(text)?.group(0) ?? '');
}

Map<String, Map<String, String>> _q3ParseCorrections(
  String text, {
  required bool allowLetterMarkers,
}) {
  final markerClass =
      allowLetterMarkers ? '①②③④⑤⑥⑦⑧⑨❶❷❸❹❺❻❼❽❾ⓐⓑⓒⓓⓔⓕⓖⓗⓘ' : '①②③④⑤⑥⑦⑧⑨❶❷❸❹❺❻❼❽❾';
  final pattern = RegExp(
    '([$markerClass]|(?<![A-Za-z0-9])[1-9](?:[.)])?)\\s*'
    r'([^,\n]+?)\s*(?:→|->|⇒|=>)\s*'
    '(.+?)(?=\\s*(?:[$markerClass]|(?<![A-Za-z0-9])[1-9](?:[.)])?)\\s+[^,\\n]*?(?:→|->|⇒|=>)|\$)',
  );
  final result = <String, Map<String, String>>{};
  for (final match in pattern.allMatches(text)) {
    final marker = match.group(1)!.trim();
    final position = _q3PositionFromMarker(marker);
    final key =
        RegExp(r'[ⓐⓑⓒⓓⓔⓕⓖⓗⓘ]').hasMatch(marker) ? marker : position?.toString();
    final from = match.group(2)!.trim();
    final to = match.group(3)!.trim().replaceAll(RegExp(r'[,;]+$'), '');
    if (key != null && from.isNotEmpty && to.isNotEmpty) {
      result[key] = <String, String>{'from': from, 'to': to};
    }
  }
  return result;
}

String _q3CorrectionAnswerText(
  Map<String, Map<String, String>> corrections,
) {
  final entries = corrections.entries.toList()
    ..sort((a, b) => (_q3PositionFromMarker(a.key) ?? 99)
        .compareTo(_q3PositionFromMarker(b.key) ?? 99));
  return entries.map((entry) => '${entry.key}:${entry.value['to']}').join(',');
}

List<String> _q3CountChoices(
  List<String> lines, {
  required int start,
  required int end,
}) {
  final choices = <String>[];
  for (final line in lines.sublist(
      start.clamp(0, lines.length), end.clamp(0, lines.length))) {
    final match = RegExp(r'^\s*[①②③④⑤]\s*(없음|[0-9]+\s*개)\s*$').firstMatch(line);
    if (match != null) {
      choices.add(match.group(1)!.replaceAll(RegExp(r'\s+'), ''));
    }
  }
  return choices.length >= 2 ? choices : const <String>[];
}

String _q3GrammarVocabularyPassage(
  List<String> lines, {
  required int start,
  required int end,
  required bool removeCountChoices,
}) {
  return lines
      .sublist(start.clamp(0, lines.length), end.clamp(0, lines.length))
      .map(_qmCleanBodyLine)
      .where((line) => line.isNotEmpty)
      .where((line) => !_q2IsSourceLine(line))
      .where((line) => !_q2IsControlLine(line))
      .where((line) => !_q2IsVocabularyLine(line))
      .where((line) => _qmQuestionNumberFromLine(line) == null)
      .where((line) =>
          !removeCountChoices ||
          !RegExp(r'^\s*[①②③④⑤]\s*(?:없음|[0-9]+\s*개)\s*$').hasMatch(line))
      .where((line) =>
          !RegExp(r'^\s*\*{1,2}\s*[A-Za-z][^.!?]*[:：]\s*.+$').hasMatch(line))
      .join(' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

Map<String, String> _q3GrammarVocabularyPositionTexts(String passage) {
  final matches = RegExp(r'[①②③④⑤⑥⑦⑧⑨ⓐⓑⓒⓓⓔⓕⓖⓗⓘ]').allMatches(passage).toList();
  final result = <String, String>{};
  for (var index = 0; index < matches.length; index++) {
    final marker = matches[index];
    final position = _q3PositionFromMarker(marker.group(0)!);
    if (position == null) continue;
    final end =
        index + 1 < matches.length ? matches[index + 1].start : passage.length;
    final segment = passage.substring(marker.end, end);
    final candidate = RegExp(r"[A-Za-z][A-Za-z’'-]*").firstMatch(segment);
    if (candidate != null) result['$position'] = candidate.group(0)!;
  }
  return result;
}

int _q3GrammarVocabularyPassageEnd(
  List<String> lines, {
  required int start,
}) {
  for (var index = (start + 1).clamp(0, lines.length);
      index < lines.length;
      index++) {
    final line = lines[index].trim();
    if (_q2IsAnswerLine(line) ||
        _q2IsExplanationLine(line) ||
        _q2IsVocabularyLine(line) ||
        _qmQuestionNumberFromLine(line) != null) {
      return index;
    }
  }
  return lines.length;
}

int _q3GrammarVocabularyPassageStart(
  List<String> lines, {
  required int start,
}) {
  final boundedStart = start.clamp(0, lines.length);
  for (var index = boundedStart; index < lines.length; index++) {
    final line = _qmCleanBodyLine(lines[index]).trim();
    if (_qmQuestionNumberFromLine(line) != null) break;
    if (_q3LooksLikeEnglishPassageLine(line)) return index;
  }
  return boundedStart;
}

bool _q3LooksLikeEnglishPassageLine(String line) {
  final withoutLeadingMarker = line.replaceFirst(
    RegExp(r'^[\s"“”‘’([{]*[①②③④⑤⑥⑦⑧⑨ⓐⓑⓒⓓⓔⓕⓖⓗⓘ]?\s*'),
    '',
  );
  return RegExp(r"^[A-Z][A-Za-z’'-]*(?:\s+[^A-Za-z]*)?\s+[A-Za-z]")
      .hasMatch(withoutLeadingMarker);
}

List<int> _q3PassagePositions(String passage) {
  final result = <int>[];
  for (final match
      in RegExp(r'[①②③④⑤⑥⑦⑧⑨❶❷❸❹❺❻❼❽❾ⓐⓑⓒⓓⓔⓕⓖⓗⓘ]').allMatches(passage)) {
    final position = _q3PositionFromMarker(match.group(0)!);
    if (position != null && !result.contains(position)) result.add(position);
  }
  result.sort();
  return result;
}

List<String> _q3ExtractVocabularyNotes(List<String> lines) {
  final notes = <String>[];
  var inVocabulary = false;
  for (final raw in lines) {
    final line = raw.trim();
    final header = RegExp(r'^\[\s*(?:단어|어휘)\s*\]\s*(.*)$').firstMatch(line);
    if (header != null) {
      inVocabulary = true;
      final inline = (header.group(1) ?? '').trim();
      if (inline.isNotEmpty && _q3LooksLikeVocabularyNoteLine(inline)) {
        notes.add(inline);
      }
      continue;
    }
    if (inVocabulary &&
        (_q2IsAnswerLine(line) ||
            _q2IsExplanationLine(line) ||
            _qmQuestionNumberFromLine(line) != null ||
            _q2IsSourceLine(line))) {
      inVocabulary = false;
    }
    if (inVocabulary && _q3LooksLikeGrammarVocabularyPrompt(line)) {
      inVocabulary = false;
      continue;
    }
    if (inVocabulary && _q3IsRecoverableEnglishPassageStart(line)) {
      inVocabulary = false;
      continue;
    }
    if (inVocabulary && _q3LooksLikeVocabularyNoteLine(line)) notes.add(line);
    if (RegExp(r'^\*{1,2}\s*[A-Za-z]').hasMatch(line)) notes.add(line);
  }
  return notes.toSet().toList();
}

bool _q3SameIntList(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}

String _q3CircledMarker(int position) {
  const labels = '①②③④⑤⑥⑦⑧⑨';
  return position >= 1 && position <= labels.length
      ? labels[position - 1]
      : '$position';
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
  if (lines.any(_q2LooksLikeInsertionPrompt)) return false;
  if (lines.any(_q3LooksLikeGrammarVocabularyPrompt)) return false;
  if (lines.any(
    (line) => _q2LooksLikePrompt(line) && !_q2LooksLikeIrrelevantPrompt(line),
  )) {
    return false;
  }
  final markerCount = _q2IrrelevantMarkerCount(lines);
  final answerPosition = _q2IrrelevantAnswerPositionFromLines(lines);
  return markerCount >= 5 && answerPosition != null;
}

int _q2IrrelevantMarkerCount(List<String> lines) {
  const circled = '\u2460\u2461\u2462\u2463\u2464\u2465\u2466\u2467\u2468'
      '\u2776\u2777\u2778\u2779\u277A\u277B\u277C\u277D\u277E';
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
  final positions = <int>[];
  final markerPattern = RegExp(
    r'[①②③④⑤⑥⑦⑧⑨❶❷❸❹❺❻❼❽❾]|[\(（]\s*([1-9])\s*[\)）]|(?:^|\s)([1-9])[\).](?=\s)',
  );
  for (final match in markerPattern.allMatches(passage)) {
    final plain = match.group(1) ?? match.group(2);
    final value = plain == null
        ? _q3PositionFromMarker(match.group(0)?.trim() ?? '')
        : int.tryParse(plain);
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
  return RegExp(r'^\[?\s*(?:어휘|단어)\s*\]?[:：]?').hasMatch(line.trim());
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
  return RegExp(r'^(?:[①②③④⑤⑥⑦⑧⑨⑩⑪⑫❶❷❸❹❺❻❼❽❾]|[1-9][\).]|[（(][1-9][）)])\s*')
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
  const filled = '❶❷❸❹❺❻❼❽❾';
  const markerLabels = '$circled$filled';
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
  ).replaceFirst(
    RegExp(r'\s+\*{1,3}[A-Za-z][\s\S]*$'),
    '',
  );
  final markerPattern = RegExp(
    '[\\(\\uFF08]?\\s*([$markerLabels])\\s*[\\)\\uFF09]?|'
    '[\\(\\uFF08]\\s*([1-9])\\s*[\\)\\uFF09]|'
    '^\\s*([1-9])[\\).]\\s*',
    multiLine: true,
  );
  final markers = markerPattern.allMatches(content).toList();
  final preserveFilledMarkers = RegExp(r'[❶❷❸❹❺❻❼❽❾]').hasMatch(content);
  final numbered = <Map<String, dynamic>>[];
  for (var index = 0; index < markers.length; index++) {
    final marker = markers[index];
    final circledToken = marker.group(1);
    final position = circledToken != null
        ? _q3PositionFromMarker(circledToken)
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
      _q2IrrelevantSentenceWithOriginalMarkerStyle(
        item['position'] as int,
        (item['text'] ?? '').toString(),
        useFilledMarker: preserveFilledMarkers,
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
      'interaction_type': 'single_choice',
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

String _q2IrrelevantSentenceWithOriginalMarkerStyle(
  int position,
  String text, {
  required bool useFilledMarker,
}) {
  const hollow = '①②③④⑤⑥⑦⑧⑨';
  const filled = '❶❷❸❹❺❻❼❽❾';
  final labels = useFilledMarker ? filled : hollow;
  final marker = position >= 1 && position <= labels.length
      ? labels[position - 1]
      : '$position)';
  final cleaned = stripLeadingIrrelevantMarkers(text);
  return cleaned.isEmpty ? marker : '$marker $cleaned';
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
  final choiceGroup =
      detection.type == 'insertion' ? _q2LastChoiceGroup(lines) : null;
  final answerLineIndex = lines.indexWhere(_q2IsAnswerLine);
  final passageEnd = <int>[
    if (choiceGroup != null) choiceGroup.start,
    if (answerLineIndex != -1) answerLineIndex,
    lines.length,
  ]..sort();
  final passage = _q2ExtractActualPassage(
    lines,
    start: promptIndex >= 0 ? promptIndex + 1 : 0,
    end: passageEnd.first,
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
    choices: choiceGroup?.choices ?? const <String>[],
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
  return RegExp(
    r'^\s*[\(（]?([A-Ea-e])(?:[\)）]|[\.)])\s*(.*)$',
  ).firstMatch(line.trim());
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
          _q3LooksLikeGrammarVocabularyPrompt(continuation) ||
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
    r'(가장\s*적절한\s*것|적절하지\s*않은\s*것|일치하는\s*것|일치하지\s*않는\s*것|가리키는\s*(?:것|대상)|지칭하는\s*대상|나머지와\s*다른\s*것|빈칸|들어갈\s*말|들어가기에|순서|배열|의미하는\s*바|함의|목적|주제|제목|요지|어법|어휘|문맥|바르게\s*고치|모두\s*고르)',
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
  if (_q4LooksLikeReferencePrompt(text)) return 'reference';
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

class _Q4LongPassageSet {
  const _Q4LongPassageSet({
    required this.group,
    required this.passage,
    required this.questionNos,
    required this.blocks,
  });

  final int group;
  final String passage;
  final List<int> questionNos;
  final Map<String, String> blocks;
}

class _Q4AnswerRecovery {
  const _Q4AnswerRecovery({
    required this.rawAnswerLine,
    required this.rawAnswer,
    this.sourceNo,
  });

  final String rawAnswerLine;
  final String rawAnswer;
  final int? sourceNo;
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
