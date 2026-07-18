// ignore_for_file: unused_element

import 'package:flutter/foundation.dart';

import '../models/problem_set_import_draft.dart';
import '../models/question_import_draft.dart';

ProblemSetImportDraft parseQuestionHwpxImportText(
  String rawText, {
  String textbookFolderName = '',
  String unitFolderName = '',
}) {
  final normalized = _qmNormalizeText(rawText);
  final blocks = _qmSplitQuestionBlocks(normalized);
  debugPrint(
    '[QuestionImportParser] normalizedLength=${normalized.length} legacy blocks=${blocks.length}',
  );
  final questions = <QuestionImportDraft>[
    for (var index = 0; index < blocks.length; index++)
      _qmParseQuestionBlock(blocks[index], fallbackNo: index + 1),
  ];
  _qmDebugQuestions(questions);

  final usableQuestions =
      questions.where((question) => question.questionText.trim().isNotEmpty);
  if (questions.isEmpty || usableQuestions.isEmpty) {
    return _legacyParseQuestionHwpxImportText(
      rawText,
      textbookFolderName: textbookFolderName,
      unitFolderName: unitFolderName,
    );
  }

  final firstSource = questions
      .map((question) => question.source.trim())
      .firstWhere((source) => source.isNotEmpty, orElse: () => '');
  final firstPassage = questions
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
    questions: questions,
    warnings: [
      if (questions.isEmpty) '문제 후보를 찾지 못했습니다.',
      if (questions.where((question) => question.isSaveable).isEmpty)
        '저장 가능한 단일정답 객관식 문제가 없습니다.',
    ],
  );
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

List<_QmQuestionBlock> _qmSplitQuestionBlocks(String text) {
  final lines = text
      .split(RegExp(r'\n+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.isEmpty) return const [];

  final starts = <int>[];
  for (var index = 0; index < lines.length; index++) {
    if (_qmIsLegacyBlockStart(lines, index)) starts.add(index);
  }
  if (starts.isEmpty) {
    for (var index = 0; index < lines.length; index++) {
      if (_qmQuestionNumberFromLine(lines[index]) != null &&
          _qmNearbyHasAnswerLine(lines, index + 1)) {
        starts.add(index);
      }
    }
  }
  final answerAnchorStarts = _qmAnswerAnchorStarts(lines);
  if (answerAnchorStarts.length > starts.length) {
    debugPrint(
      '[QuestionImportParser] answer anchors used: ${starts.length} -> ${answerAnchorStarts.length}',
    );
    starts
      ..clear()
      ..addAll(answerAnchorStarts);
  }
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
  if (starts.isEmpty) return [_QmQuestionBlock(number: 1, lines: lines)];

  final blocks = <_QmQuestionBlock>[];
  for (var i = 0; i < starts.length; i++) {
    final start = starts[i];
    final end = i + 1 < starts.length ? starts[i + 1] : lines.length;
    final number = _qmBlockNumber(lines.sublist(start, end)) ?? i + 1;
    blocks.add(
        _QmQuestionBlock(number: number, lines: lines.sublist(start, end)));
  }
  return blocks;
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
  final lowerBound = answerIndex - 8 < 0 ? 0 : answerIndex - 8;
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
  if (questionType.isEmpty) {
    questionTypeWarnings.add('문제 유형을 추론하지 못했습니다.');
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

int? _qmQuestionNumberFromLine(String line) {
  final clean = line.trim();
  final standalone = RegExp(r'^(\d{1,3})$').firstMatch(clean);
  if (standalone != null) return int.tryParse(standalone.group(1)!);
  final marked = RegExp(r'^(\d{1,3})\s*[\).]\s*$').firstMatch(clean);
  if (marked != null) return int.tryParse(marked.group(1)!);
  final inline = RegExp(r'^(\d{1,3})\s*[\).]\s+').firstMatch(clean);
  return inline == null ? null : int.tryParse(inline.group(1)!);
}

String _qmCleanBodyLine(String line) {
  return line
      .replaceFirst(RegExp(r'^\s*\d{1,3}\s*[\).]?\s*$'), '')
      .replaceFirst(RegExp(r'^\s*\d{1,3}\s*[\).]\s+'), '')
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

class _QmQuestionBlock {
  const _QmQuestionBlock({required this.number, required this.lines});

  final int number;
  final List<String> lines;
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
