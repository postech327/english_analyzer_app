import 'dart:convert';

import 'package:flutter/material.dart';
import '../../services/student_exam_service.dart';
import '../../utils/insertion_display_prompt.dart';
import '../../utils/irrelevant_display_passage.dart';
import 'student_exam_result_screen.dart';

class StudentExamTakeScreen extends StatefulWidget {
  final int problemSetId;

  const StudentExamTakeScreen({
    super.key,
    required this.problemSetId,
  });

  @override
  State<StudentExamTakeScreen> createState() => _StudentExamTakeScreenState();
}

class _StudentExamTakeScreenState extends State<StudentExamTakeScreen> {
  static const _surface = Color(0xFFF6F8FC);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _blue = Color(0xFF2563EB);
  static const _purple = Color(0xFF7C3AED);
  static const _line = Color(0xFFE5E7EB);

  Map<String, dynamic>? _questionSet;

  bool isLoading = true;
  bool isSubmitting = false;

  /// 현재 보고 있는 문제 번호
  int currentIndex = 0;

  /// 지문 접기/펼치기
  bool isPassageExpanded = true;

  /// 문제별 선택값 저장 question_id 기준
  Map<int, int> selectedAnswers = {};
  Map<int, List<String>> orderAnswers = {};
  Map<int, int> insertionAnswers = {};
  Map<int, Map<String, int>> multipleInsertionAnswers = {};
  Map<int, int> irrelevantAnswers = {};

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> _specialData(Map<String, dynamic> question) {
    final value = question['special_data'] ?? question['specialData'];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    final raw = question['special_data_json']?.toString().trim() ?? '';
    if (raw.isEmpty || raw == 'null') return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return <String, dynamic>{};
    }
    return <String, dynamic>{};
  }

  bool _isOrderQuestion(
    Map<String, dynamic> question, [
    Map<String, dynamic>? specialData,
  ]) {
    final type = (question['question_type'] ?? '').toString().toLowerCase();
    final data = specialData ?? _specialData(question);
    return type == 'order' || data['kind']?.toString().toLowerCase() == 'order';
  }

  bool _isInsertionQuestion(
    Map<String, dynamic> question, [
    Map<String, dynamic>? specialData,
  ]) {
    final type =
        (question['question_type'] ?? '').toString().trim().toLowerCase();
    final data = specialData ?? _specialData(question);
    return type == 'insertion' ||
        data['kind']?.toString().trim().toLowerCase() == 'insertion';
  }

  bool _isIrrelevantQuestion(
    Map<String, dynamic> question, [
    Map<String, dynamic>? specialData,
  ]) {
    final type =
        (question['question_type'] ?? '').toString().trim().toLowerCase();
    final kind = (specialData ?? _specialData(question))['kind']
        ?.toString()
        .trim()
        .toLowerCase();
    return type == 'irrelevant' ||
        type == 'unrelated_sentence' ||
        kind == 'irrelevant' ||
        kind == 'unrelated_sentence';
  }

  Map<String, String> _orderBlocks(Map<String, dynamic> specialData) {
    final rawBlocks = specialData['blocks'];
    if (rawBlocks is! Map) return const <String, String>{};
    final entries = rawBlocks.entries
        .map((entry) => MapEntry(entry.key.toString(), entry.value.toString()))
        .where((entry) =>
            entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Map<String, String>.fromEntries(entries);
  }

  bool _isMultipleInsertion(Map<String, dynamic> specialData) =>
      (specialData['mode'] ?? '').toString().trim().toLowerCase() == 'multiple';

  Map<String, String> _multipleInsertionSentences(
    Map<String, dynamic> specialData,
  ) {
    final raw = specialData['insert_sentences'];
    if (raw is! Map) return const <String, String>{};
    final entries = raw.entries
        .map((entry) => MapEntry(entry.key.toString(), entry.value.toString()))
        .where((entry) =>
            entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Map<String, String>.fromEntries(entries);
  }

  bool _isQuestionAnswered(Map<String, dynamic> question) {
    final qId = _asInt(question['question_id'] ?? question['id']);
    final specialData = _specialData(question);
    if (_isOrderQuestion(question, specialData)) {
      final blocks = _orderBlocks(specialData);
      final selected = orderAnswers[qId] ?? const <String>[];
      return blocks.isNotEmpty && selected.length == blocks.length;
    }
    if (_isInsertionQuestion(question, specialData)) {
      if (_isMultipleInsertion(specialData)) {
        final labels = _multipleInsertionSentences(specialData).keys;
        final selected = multipleInsertionAnswers[qId] ?? const <String, int>{};
        return labels.isNotEmpty && labels.every(selected.containsKey);
      }
      return insertionAnswers.containsKey(qId);
    }
    if (_isIrrelevantQuestion(question, specialData)) {
      return irrelevantAnswers.containsKey(qId);
    }
    return selectedAnswers.containsKey(qId);
  }

  int _answeredCount(List questions) {
    var count = 0;
    for (final item in questions) {
      if (item is Map && _isQuestionAnswered(Map<String, dynamic>.from(item))) {
        count++;
      }
    }
    return count;
  }

  String _questionPassage(
    Map<String, dynamic> question, {
    required String fallbackPassage,
  }) {
    final candidates = <String>[
      question['passage']?.toString() ?? '',
      question['passage_content']?.toString() ?? '',
      question['passage_text']?.toString() ?? '',
      question['blanked_passage']?.toString() ?? '',
      fallbackPassage,
    ];

    for (var i = 0; i < candidates.length; i++) {
      final raw = candidates[i].trim();
      if (raw.isEmpty || raw == 'null') continue;

      final cleaned = _cleanStudentPassage(raw);
      if (cleaned.isEmpty) continue;

      debugPrint(
        '[StudentPassagePick] q=${question['question_id'] ?? question['id']} '
        'sourceIndex=$i rawLength=${raw.length} cleanedLength=${cleaned.length}',
      );
      return cleaned;
    }

    return '';
  }

  String _cleanStudentPassage(String raw) {
    final lines = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .where((line) => !_shouldDropKoreanExplanationLine(line))
        .toList();

    return lines.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  bool _shouldDropKoreanExplanationLine(String rawLine) {
    final line = rawLine.trim();
    if (line.isEmpty) return true;

    final lower = line.toLowerCase();
    if (RegExp(
            r'^\s*(?:\[?\uC815\uB2F5\]?|\[?\uD574\uC124\]?|\[?\uD574\uC11D\]?|answer|explanation)[:?\s]')
        .hasMatch(lower)) {
      return true;
    }
    if (lower.contains('\uC815\uB2F5:') ||
        lower.contains('\uD574\uC124:') ||
        lower.contains('\uD574\uC11D:') ||
        lower.contains('[\uC815\uB2F5]') ||
        lower.contains('[\uD574\uC124]') ||
        lower.contains('[\uD574\uC11D]') ||
        lower.contains('answer:') ||
        lower.contains('explanation:')) {
      return true;
    }

    final hasHangul = RegExp(r'[\uAC00-\uD7A3]').hasMatch(line);
    if (!hasHangul) return false;

    final hasEnglish = RegExp(r'[A-Za-z]').hasMatch(line);
    final startsAsChoice = RegExp(
            r'^\s*(?:[\u2460\u2461\u2462\u2463\u2464\u2465\u2466\u2467\u2468\u2469]|[1-5][\.)]|[A-E][\.)])\s*')
        .hasMatch(line);
    final hangulRatio = _charRatio(line, RegExp(r'[\uAC00-\uD7A3]'));
    final englishRatio = _charRatio(line, RegExp(r'[A-Za-z]'));

    if (startsAsChoice && hangulRatio > 0.15) return true;
    if (!hasEnglish && hangulRatio > 0.25 && line.length >= 6) return true;
    if (hangulRatio > 0.32 && englishRatio < 0.18) return true;

    return false;
  }

  double _charRatio(String text, RegExp pattern) {
    if (text.isEmpty) return 0;
    final matches = pattern.allMatches(text).length;
    return matches / text.length;
  }

  bool _hasMostlyEnglish(String text) {
    return _charRatio(text, RegExp(r'[A-Za-z]')) > 0.35;
  }

  @override
  void initState() {
    super.initState();
    _loadExam();
  }

  /// 시험 불러오기
  Future<void> _loadExam() async {
    try {
      final data =
          await StudentExamService.fetchExamDetail(widget.problemSetId);

      if (!mounted) return;

      setState(() {
        _questionSet = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('시험 불러오기 실패: $e')),
      );
    }
  }

  /// 선택 처리
  void _selectAnswer(int questionId, int index) {
    setState(() {
      selectedAnswers[questionId] = index;
    });
  }

  /// 이전 문제
  void _goPrevious() {
    if (currentIndex <= 0) return;

    setState(() {
      currentIndex--;
    });
  }

  /// 다음 문제
  void _goNext(int totalQuestions) {
    if (currentIndex >= totalQuestions - 1) return;

    setState(() {
      currentIndex++;
    });
  }

  /// 번호판 이동
  void _goToQuestion(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  /// 시험 제출
  Future<void> _submitExam() async {
    if (_questionSet == null) return;

    final questions = (_questionSet!['questions'] ?? []) as List;

    final unanswered = <int>[];
    for (int i = 0; i < questions.length; i++) {
      final q = Map<String, dynamic>.from(questions[i] as Map);
      if (!_isQuestionAnswered(q)) unanswered.add(i + 1);
    }

    if (unanswered.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '\uC544\uC9C1 \uC120\uD0DD\uD558\uC9C0 \uC54A\uC740 \uBB38\uC81C\uAC00 \uC788\uC2B5\uB2C8\uB2E4: ${unanswered.join(", ")}\uBC88',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final answers = <Map<String, dynamic>>[];
      for (final item in questions) {
        final q = Map<String, dynamic>.from(item as Map);
        final qId = _asInt(q['question_id'] ?? q['id']);
        final specialData = _specialData(q);
        if (_isOrderQuestion(q, specialData)) {
          final answerText = (orderAnswers[qId] ?? const <String>[]).join('-');
          debugPrint('[StudentOrderAnswer] q=$qId selected=$answerText');
          answers.add({
            'question_id': qId,
            'answer_text': answerText,
          });
        } else if (_isInsertionQuestion(q, specialData)) {
          final answerText = _isMultipleInsertion(specialData)
              ? _multipleInsertionAnswerText(qId, specialData)
              : '${insertionAnswers[qId]}';
          debugPrint('[StudentInsertionAnswer] q=$qId selected=$answerText');
          answers.add({
            'question_id': qId,
            'answer_text': answerText,
          });
        } else if (_isIrrelevantQuestion(q, specialData)) {
          final answerText = '${irrelevantAnswers[qId]}';
          debugPrint('[StudentIrrelevantAnswer] q=$qId selected=$answerText');
          answers.add({
            'question_id': qId,
            'answer_text': answerText,
          });
        } else {
          answers.add({
            'question_id': qId,
            'selected_index': selectedAnswers[qId],
          });
        }
      }

      final result = await StudentExamService.submitExam(
        problemSetId: widget.problemSetId,
        answers: answers,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentExamResultScreen(
            problemSetId: widget.problemSetId,
            totalQuestions: result['total'] ?? questions.length,
            correctAnswers: result['correct'] ?? 0,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\uC2DC\uD5D8 \uC81C\uCD9C \uC2E4\uD328: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  String _buildDisplayPassage({
    required String passage,
    required Map<String, dynamic> question,
  }) {
    final questionType =
        (question['question_type'] ?? '').toString().toLowerCase();

    if (questionType == 'cloze' || questionType == 'blank') {
      return _buildClozePassage(
        passage: passage,
        question: question,
      );
    }

    if (questionType == 'order') {
      return _buildOrderPassage(
        passage: passage,
        question: question,
      );
    }

    if (questionType == 'insertion') {
      return _buildInsertionPassage(
        passage: passage,
        question: question,
      );
    }

    if (questionType == 'irrelevant' || questionType == 'unrelated_sentence') {
      return _buildIrrelevantPassage(
        passage: passage,
        question: question,
      );
    }

    return passage;
  }

  String _visibleBlank(String text) {
    return text.replaceAll(RegExp(r'_{3,}'), '[          ]');
  }

  String _buildOrderPassage({
    required String passage,
    required Map<String, dynamic> question,
  }) {
    String questionText = (question['question_text'] ?? '').toString().trim();

    if (questionText.isEmpty) {
      return passage;
    }

    if (questionText.contains('(A)') &&
        questionText.contains('(B)') &&
        questionText.contains('(C)')) {
      return _formatOrderText(questionText);
    }

    return _buildFallbackOrderPassage(
      passage: passage,
      answerIndex: _safeAnswerIndex(question),
    );
  }

  int _safeAnswerIndex(Map<String, dynamic> question) {
    final raw = question['answer_index'] ?? question['answer'];
    if (raw is int) {
      if (raw >= 0 && raw <= 4) return raw;
      if (raw >= 1 && raw <= 5) return raw - 1;
    }
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null) {
        if (parsed >= 0 && parsed <= 4) return parsed;
        if (parsed >= 1 && parsed <= 5) return parsed - 1;
      }
    }
    return 0;
  }

  String _buildFallbackOrderPassage({
    required String passage,
    required int answerIndex,
  }) {
    final sentences = passage
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (sentences.length < 4) {
      return passage;
    }

    final given = sentences.first;
    final remaining = sentences.skip(1).toList();
    final groups = _splitIntoThreeGroups(remaining);
    final safeIndex = answerIndex.clamp(0, 4).toInt();
    final correctOrder = _orderChoices()[safeIndex];
    final labels =
        correctOrder.replaceAll('(', '').replaceAll(')', '').split('-');

    final labeledGroups = <String, String>{};
    for (var i = 0; i < labels.length && i < groups.length; i++) {
      labeledGroups[labels[i]] = groups[i];
    }

    return [
      '[Given Text]',
      given,
      '',
      '(A) ${labeledGroups['A'] ?? groups[0]}',
      '',
      '(B) ${labeledGroups['B'] ?? groups[1]}',
      '',
      '(C) ${labeledGroups['C'] ?? groups[2]}',
    ].join('\n');
  }

  List<String> _splitIntoThreeGroups(List<String> sentences) {
    final groups = ['', '', ''];
    for (var i = 0; i < sentences.length; i++) {
      final groupIndex = (i * 3 / sentences.length).floor().clamp(0, 2).toInt();
      groups[groupIndex] = '${groups[groupIndex]} ${sentences[i]}'.trim();
    }
    return groups.map((group) => group.trim()).toList();
  }

  List<String> _orderChoices() {
    return const [
      '(A)-(C)-(B)',
      '(B)-(A)-(C)',
      '(B)-(C)-(A)',
      '(C)-(A)-(B)',
      '(C)-(B)-(A)',
    ];
  }

  String _buildInsertionPassage({
    required String passage,
    required Map<String, dynamic> question,
  }) {
    final specialData = _specialData(question);
    final insertSentence =
        (specialData['insert_sentence'] ?? '').toString().trim();
    final passageWithPositions =
        (specialData['passage_with_positions'] ?? '').toString().trim();
    final insertSentences = _multipleInsertionSentences(specialData);
    if (_isMultipleInsertion(specialData) &&
        insertSentences.isNotEmpty &&
        passageWithPositions.isNotEmpty) {
      final given = insertSentences.entries
          .map((entry) => '(${entry.key}) ${entry.value}')
          .join('\n');
      return '$given\n\n$passageWithPositions';
    }
    if (insertSentence.isNotEmpty && passageWithPositions.isNotEmpty) {
      return '$insertSentence\n\n$passageWithPositions';
    }

    final insertionText = (question['question_text'] ?? '').toString().trim();

    if (insertionText.isEmpty) {
      return passage;
    }

    return _formatInsertionText(
      passage: passage,
      insertionText: insertionText,
    );
  }

  String _buildIrrelevantPassage({
    required String passage,
    required Map<String, dynamic> question,
  }) {
    final specialData = _specialData(question);
    final rawPassage =
        (specialData['passage_with_numbers'] ?? passage).toString();
    final displayPassage = irrelevantPassageForDisplay(
      specialData,
      fallbackPassage: passage,
    );
    final questionId = question['question_id'] ?? question['id'] ?? '';
    debugPrint(
      '[IrrelevantDisplayRaw] questionId=$questionId '
      'raw="${rawPassage.replaceAll('\n', r'\n')}"',
    );
    debugPrint(
      '[IrrelevantDisplayClean] questionId=$questionId '
      'clean="${displayPassage.replaceAll('\n', r'\n')}"',
    );
    return displayPassage;
  }

  String _formatInsertionText({
    required String passage,
    required String insertionText,
  }) {
    // 1) 원문에서 삽입 문장 제거
    String cleaned = _removeSimilarText(
      original: passage,
      target: insertionText,
    ).trim();

    if (cleaned.isEmpty) {
      cleaned = passage.trim();
    }

    // 2) 문장 분리
    List<String> parts = cleaned
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // 3) 문장이 5개보다 적으면 긴 문장을 콤마/세미콜론 기준으로 추가 분해
    if (parts.length < 5) {
      final expanded = <String>[];

      for (final p in parts) {
        if (expanded.length >= 5) {
          expanded.add(p);
          continue;
        }

        if (p.length > 80 && (p.contains(',') || p.contains(';'))) {
          final sub = p
              .split(RegExp(r'(?<=[,;])\s+'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

          if (sub.length >= 2) {
            expanded.addAll(sub);
          } else {
            expanded.add(p);
          }
        } else {
          expanded.add(p);
        }
      }

      parts = expanded;
    }

    // 너무 많으면 그냥 유지, 너무 적으면 그대로라도 진행
    if (parts.isEmpty) {
      return insertionText;
    }

    // 4) 최대 5개 위치 표시 삽입
    final markers = ['( ① )', '( ② )', '( ③ )', '( ④ )', '( ⑤ )'];
    final buffer = StringBuffer();

    // 맨 위에 "주어진 문장" 표시
    buffer.writeln(insertionText);
    buffer.writeln();
    buffer.writeln();

    // 원문 + 위치표시
    for (int i = 0; i < parts.length; i++) {
      buffer.write(parts[i]);

      if (i < markers.length) {
        buffer.write(' ${markers[i]} ');
      } else {
        buffer.write(' ');
      }
    }

    return buffer.toString().trim();
  }

  String _formatOrderText(String text) {
    String formatted = text.trim();

    formatted = formatted.replaceAll(
      RegExp(r'Rearrange the sentences to form a coherent paragraph\.?',
          caseSensitive: false),
      '',
    );

    formatted = formatted.replaceAll(
      RegExp(r'Arrange the parts in the correct order based on the passage:?',
          caseSensitive: false),
      '',
    );

    formatted = formatted.replaceAll(
      RegExp(r'Given the sentence:\s*', caseSensitive: false),
      '[Given Text] ',
    );

    formatted = formatted.replaceAll(
      RegExp(r'\[Given Text\]\s*', caseSensitive: false),
      '[Given Text] ',
    );

    formatted = formatted.replaceAll(
      RegExp(r'Arrange the following parts.*?:?', caseSensitive: false),
      '',
    );

    // (A)(B)(C)가 반드시 새 줄에서 시작하도록 처리
    formatted = formatted.replaceAll(RegExp(r'\s*\(A\)\s*'), '\n\n(A) ');
    formatted = formatted.replaceAll(RegExp(r'\s*\(B\)\s*'), '\n\n(B) ');
    formatted = formatted.replaceAll(RegExp(r'\s*\(C\)\s*'), '\n\n(C) ');

    // 중복 제거: (A)(B)(C)에 해당하는 문장이 Given Text에 있으면 제거
    formatted = _removeOrderPartsFromGivenText(formatted);

    // 줄 정리
    formatted = formatted.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return formatted.trim();
  }

  String _removeOrderPartsFromGivenText(String text) {
    String result = text.trim();

    final partPattern = RegExp(
      r'\(([ABC])\)\s*([\s\S]*?)(?=\n\s*\([ABC]\)|$)',
    );

    final matches = partPattern.allMatches(result).toList();

    if (matches.isEmpty) {
      return result;
    }

    final List<String> partTexts = [];

    for (final match in matches) {
      final partText = (match.group(2) ?? '').trim();

      if (partText.isNotEmpty) {
        partTexts.add(partText);
      }
    }

    // (A)(B)(C)가 시작되는 위치
    final firstPartIndex = result.indexOf(RegExp(r'\([ABC]\)'));

    if (firstPartIndex == -1) {
      return result;
    }

    String givenText = result.substring(0, firstPartIndex).trim();
    final partsText = result.substring(firstPartIndex).trim();

    for (final part in partTexts) {
      givenText = _removeSimilarText(
        original: givenText,
        target: part,
      );
    }

    givenText = givenText.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    return '$givenText\n\n$partsText'.trim();
  }

  String _removeSimilarText({
    required String original,
    required String target,
  }) {
    String source = original.trim();
    final String targetText = target.trim();

    if (source.isEmpty || targetText.isEmpty) {
      return source;
    }

    // 1) 완전 일치 제거
    if (source.contains(targetText)) {
      return source.replaceFirst(targetText, '').trim();
    }

    // 2) 대소문자 무시 제거
    final lowerSource = source.toLowerCase();
    final lowerTarget = targetText.toLowerCase();

    final index = lowerSource.indexOf(lowerTarget);

    if (index != -1) {
      return source
          .replaceRange(
            index,
            index + targetText.length,
            '',
          )
          .trim();
    }

    // 3) 긴 문장일 경우 앞부분 일부로 제거 시도
    final targetWords = targetText.split(RegExp(r'\s+'));

    if (targetWords.length >= 8) {
      final shortTarget = targetWords.take(8).join(' ');
      final lowerShortTarget = shortTarget.toLowerCase();

      final shortIndex = lowerSource.indexOf(lowerShortTarget);

      if (shortIndex != -1) {
        int end = source.indexOf('.', shortIndex);

        if (end == -1) {
          end = source.length;
        } else {
          end = end + 1;
        }

        return source.replaceRange(shortIndex, end, '').trim();
      }
    }

    return source;
  }

  String _buildClozePassage({
    required String passage,
    required Map<String, dynamic> question,
  }) {
    final blankedPassage = (question['blanked_passage'] ??
            question['passage_blanked'] ??
            question['passage_with_blank'] ??
            question['cloze_passage'] ??
            '')
        .toString()
        .trim();

    if (blankedPassage.isNotEmpty) {
      return _visibleBlank(blankedPassage);
    }

    final String questionText =
        (question['question_text'] ?? '').toString().trim();

    if (passage.trim().isEmpty || questionText.isEmpty) {
      return passage;
    }

    const String blank = '[          ]';

    final List options = (question['options'] ?? []) as List;

    // 1) 가능하면 answer_index 또는 answer를 이용해서 정답 선택지 텍스트를 찾음
    String answerText = '';

    final dynamic answerIndexValue = question['answer_index'];
    final dynamic answerValue = question['answer'];

    int? answerIndex;

    if (answerIndexValue is int) {
      answerIndex = answerIndexValue;
    } else if (answerIndexValue is String) {
      answerIndex = int.tryParse(answerIndexValue);
    }

    // answer가 1~5 기준으로 들어오는 경우 대비
    if (answerIndex == null) {
      if (answerValue is int) {
        answerIndex = answerValue - 1;
      } else if (answerValue is String) {
        final parsed = int.tryParse(answerValue);
        if (parsed != null) {
          answerIndex = parsed - 1;
        }
      }
    }

    if (answerIndex != null &&
        answerIndex >= 0 &&
        answerIndex < options.length) {
      final opt = options[answerIndex];

      if (opt is Map) {
        answerText = (opt['text'] ?? '').toString().trim();
      }
    }

    // 2) 정답 텍스트를 지문에서 찾아 blank 처리
    // 예: reducing uncertainties
    if (answerText.isNotEmpty) {
      final replaced = _replaceAnswerInPassage(
        passage: passage,
        answerText: answerText,
        blank: blank,
      );

      if (replaced != passage) {
        return replaced;
      }
    }

    final questionBlank = _visibleBlank(questionText);

    if (questionBlank.contains(blank)) {
      final merged = _mergeBlankSentenceIntoPassage(
        passage: passage,
        blankSentence: questionBlank,
        blank: blank,
      );

      if (merged != passage) {
        return merged;
      }
    }

    // 3) 정답 텍스트로 못 찾으면 question_text의 blank 앞부분을 이용해서 문장 일부를 blank 처리
    if (questionText.contains('_____')) {
      final beforeBlank = questionText.split(RegExp(r'_+')).first.trim();

      if (beforeBlank.isNotEmpty) {
        final prefixIndex = passage.indexOf(beforeBlank);

        if (prefixIndex != -1) {
          final start = prefixIndex + beforeBlank.length;

          // blank 뒤쪽은 일단 다음 마침표까지 처리
          int end = passage.indexOf('.', start);

          if (end == -1) {
            end = passage.length;
          }

          return passage.replaceRange(start, end, ' $blank');
        }
      }
    }

    return passage;
  }

  String _mergeBlankSentenceIntoPassage({
    required String passage,
    required String blankSentence,
    required String blank,
  }) {
    final parts = blankSentence.split(blank);
    if (parts.isEmpty) return passage;

    final prefix = parts.first.trim();
    if (prefix.length < 12) return passage;

    final start = passage.toLowerCase().indexOf(prefix.toLowerCase());
    if (start == -1) return passage;

    final sentenceEnd = passage.indexOf('.', start);
    final end = sentenceEnd == -1 ? passage.length : sentenceEnd + 1;
    final originalSentence = passage.substring(start, end);

    if (originalSentence.length < prefix.length) return passage;

    return passage.replaceRange(start, end, blankSentence);
  }

  String _replaceAnswerInPassage({
    required String passage,
    required String answerText,
    required String blank,
  }) {
    if (answerText.trim().isEmpty) {
      return passage;
    }

    // 1) 완전 일치 먼저 시도
    if (passage.contains(answerText)) {
      return passage.replaceFirst(answerText, blank);
    }

    // 2) 대소문자 무시 일치
    final lowerPassage = passage.toLowerCase();
    final lowerAnswer = answerText.toLowerCase();

    final index = lowerPassage.indexOf(lowerAnswer);

    if (index != -1) {
      return passage.replaceRange(
        index,
        index + answerText.length,
        blank,
      );
    }

    // 3) 관사 the/a/an 차이 보정
    // 예: answer = reducing uncertainties
    // passage = reducing the uncertainties
    final words = answerText
        .split(RegExp(r'\s+'))
        .map((e) => RegExp.escape(e))
        .where((e) => e.isNotEmpty)
        .toList();

    if (words.length >= 2) {
      final pattern = words.join(r'\s+(?:the\s+|a\s+|an\s+)?');

      final regex = RegExp(
        pattern,
        caseSensitive: false,
      );

      final match = regex.firstMatch(passage);

      if (match != null) {
        return passage.replaceRange(
          match.start,
          match.end,
          blank,
        );
      }
    }

    return passage;
  }

  String _buildQuestionText(Map<String, dynamic> question) {
    final questionType =
        (question['question_type'] ?? '').toString().toLowerCase();
    final specialData = _specialData(question);
    final insertionMode =
        (specialData['mode'] ?? '').toString().trim().toLowerCase();
    final rawPrompt =
        (question['question_text'] ?? question['text'] ?? '').toString().trim();

    final extracted = _extractStudentQuestionPrompt(rawPrompt);
    final fallback = _fallbackPromptForType(questionType);
    final isInsertion = questionType == 'insertion' ||
        specialData['kind']?.toString().trim().toLowerCase() == 'insertion';
    final isIrrelevant = _isIrrelevantQuestion(question, specialData);
    final finalPrompt = isInsertion
        ? insertionDisplayPromptForMode(insertionMode)
        : isIrrelevant
            ? '다음 글에서 전체 흐름과 관계없는 문장은?'
            : extracted.isNotEmpty
                ? extracted
                : fallback;

    debugPrint(
      '[StudentDisplayCleanup] q=${question['question_id'] ?? question['id']} '
      'type=$questionType mode=$insertionMode '
      'rawPrompt="${_shortLog(rawPrompt)}" '
      'finalPrompt="${_shortLog(finalPrompt)}"',
    );

    return finalPrompt;
  }

  String _extractStudentQuestionPrompt(String rawPrompt) {
    final text = rawPrompt
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\n{2,}'), '\n')
        .trim();
    if (text.isEmpty) return '';

    final patterns = <RegExp>[
      RegExp(
          r'\uB2E4\uC74C\s*\uAE00\uC758\s*\uBE48\uCE78[^??\n]*\uAC00\uC7A5\s*\uC801\uC808\uD55C\s*\uAC83\uC740\s*[??]'),
      RegExp(
          r'\uB2E4\uC74C\s*\uBE48\uCE78[^??\n]*\uAC00\uC7A5\s*\uC801\uC808\uD55C\s*\uAC83\uC740\s*[??]'),
      RegExp(
          r'\uB2E4\uC74C\s*\uAE00\uC758\s*\uC8FC\uC81C\uB85C\s*\uAC00\uC7A5\s*\uC801\uC808\uD55C\s*\uAC83\uC740\s*[??]'),
      RegExp(
          r'\uB2E4\uC74C\s*\uAE00\uC758\s*\uC81C\uBAA9\uC73C\uB85C\s*\uAC00\uC7A5\s*\uC801\uC808\uD55C\s*\uAC83\uC740\s*[??]'),
      RegExp(
          r'\uB2E4\uC74C\s*\uAE00\uC758\s*\uC694\uC9C0\uB85C\s*\uAC00\uC7A5\s*\uC801\uC808\uD55C\s*\uAC83\uC740\s*[??]'),
      RegExp(
          r'\uBC11\uC904\s*\uCE5C[\s\S]{0,120}?\uC758\uBBF8\uD558\uB294\s*\uBC14\uB85C\s*\uAC00\uC7A5\s*\uC801\uC808\uD55C\s*\uAC83\uC740\s*[??]'),
      RegExp(
          r'\uB2E4\uC74C\s*\uAE00\uC758\s*\uB0B4\uC6A9\uACFC\s*\uC77C\uCE58\uD558\uC9C0\s*\uC54A\uB294\s*\uAC83\uC740\s*[??]'),
      RegExp(
          r'\uB2E4\uC74C\s*\uAE00\uC758\s*\uB0B4\uC6A9\uACFC\s*\uC77C\uCE58\uD558\uB294\s*\uAC83\uC740\s*[??]'),
      RegExp(
          r'\uB2E4\uC74C\s*\uAE00\uC758\s*\uBAA9\uC801\uC73C\uB85C\s*\uAC00\uC7A5\s*\uC801\uC808\uD55C\s*\uAC83\uC740\s*[??]'),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text).toList();
      if (matches.isNotEmpty) {
        return matches.last.group(0)!.replaceAll(RegExp(r'\s+'), ' ').trim();
      }
    }

    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .where((line) => !_shouldDropKoreanExplanationLine(line))
        .toList();

    if (lines.isEmpty) return '';
    final cleaned = lines.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (_looksLikeQuestionPrompt(cleaned)) return cleaned;
    return '';
  }

  bool _looksLikeQuestionPrompt(String text) {
    if (text.isEmpty) return false;
    if (_hasMostlyEnglish(text)) return false;
    return text.contains('\uAC00\uC7A5 \uC801\uC808\uD55C \uAC83\uC740') ||
        text.contains('\uC77C\uCE58\uD558\uB294 \uAC83\uC740') ||
        text.contains('\uC77C\uCE58\uD558\uC9C0 \uC54A\uB294 \uAC83\uC740') ||
        text.contains('\uB4E4\uC5B4\uAC08 \uB9D0') ||
        text.contains('\uC758\uBBF8\uD558\uB294 \uBC14\uB85C');
  }

  String _fallbackPromptForType(String questionType) {
    switch (questionType) {
      case 'blank':
      case 'cloze':
        return '\uB2E4\uC74C \uAE00\uC758 \uBE48\uCE78\uC5D0 \uB4E4\uC5B4\uAC08 \uB9D0\uB85C \uAC00\uC7A5 \uC801\uC808\uD55C \uAC83\uC740?';
      case 'topic':
        return '\uB2E4\uC74C \uAE00\uC758 \uC8FC\uC81C\uB85C \uAC00\uC7A5 \uC801\uC808\uD55C \uAC83\uC740?';
      case 'title':
        return '\uB2E4\uC74C \uAE00\uC758 \uC81C\uBAA9\uC73C\uB85C \uAC00\uC7A5 \uC801\uC808\uD55C \uAC83\uC740?';
      case 'gist':
      case 'summary':
        return '\uB2E4\uC74C \uAE00\uC758 \uC694\uC9C0\uB85C \uAC00\uC7A5 \uC801\uC808\uD55C \uAC83\uC740?';
      case 'implication':
        return '\uBC11\uC904 \uCE5C \uBD80\uBD84\uC774 \uB2E4\uC74C \uAE00\uC5D0\uC11C \uC758\uBBF8\uD558\uB294 \uBC14\uB85C \uAC00\uC7A5 \uC801\uC808\uD55C \uAC83\uC740?';
      case 'purpose':
        return '\uB2E4\uC74C \uAE00\uC758 \uBAA9\uC801\uC73C\uB85C \uAC00\uC7A5 \uC801\uC808\uD55C \uAC83\uC740?';
      case 'mismatch':
      case 'content_mismatch':
        return '\uB2E4\uC74C \uAE00\uC758 \uB0B4\uC6A9\uACFC \uC77C\uCE58\uD558\uC9C0 \uC54A\uB294 \uAC83\uC740?';
      case 'content':
      case 'match':
        return '\uB2E4\uC74C \uAE00\uC758 \uB0B4\uC6A9\uACFC \uC77C\uCE58\uD558\uB294 \uAC83\uC740?';
      case 'order':
        return '\uC8FC\uC5B4\uC9C4 \uAE00 \uB2E4\uC74C\uC5D0 \uC774\uC5B4\uC9C8 \uAE00\uC758 \uC21C\uC11C\uB85C \uAC00\uC7A5 \uC801\uC808\uD55C \uAC83\uC740?';
      case 'insertion':
        return '\uAE00\uC758 \uD750\uB984\uC73C\uB85C \uBCF4\uC544, \uC8FC\uC5B4\uC9C4 \uBB38\uC7A5\uC774 \uB4E4\uC5B4\uAC00\uAE30\uC5D0 \uAC00\uC7A5 \uC801\uC808\uD55C \uACF3\uC740?';
      case 'irrelevant':
      case 'unrelated_sentence':
        return '\uB2E4\uC74C \uAE00\uC5D0\uC11C \uC804\uCCB4 \uD750\uB984\uACFC \uAD00\uACC4\uC5C6\uB294 \uBB38\uC7A5\uC740?';
      default:
        return '\uB2E4\uC74C \uAE00\uC744 \uC77D\uACE0 \uBB3C\uC74C\uC5D0 \uB2F5\uD558\uC138\uC694.';
    }
  }

  String _shortLog(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 120) return normalized;
    return '${normalized.substring(0, 120)}...';
  }

  String _extractUnderlineTarget(String rawPrompt) {
    final text = rawPrompt.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return '';

    final quoted = RegExp(
      "[\"'“”‘’]([A-Za-z][A-Za-z0-9 ,;:!?\\-’']{10,}?[A-Za-z0-9])[\"'“”‘’]",
      caseSensitive: false,
    ).firstMatch(text);
    if (quoted != null) return _cleanUnderlineTarget(quoted.group(1) ?? '');

    final matches = RegExp(
      r"[A-Za-z][A-Za-z0-9 ,;:!?'\-’]{14,}[A-Za-z0-9]",
    ).allMatches(text).map((match) => match.group(0) ?? '').toList();
    if (matches.isEmpty) return '';

    matches.sort((a, b) => b.length.compareTo(a.length));
    return _cleanUnderlineTarget(matches.first);
  }

  String _cleanUnderlineTarget(String value) {
    var text = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    const wrappers = ['"', "'", '“', '”', '‘', '’'];
    while (text.isNotEmpty && wrappers.contains(text[0])) {
      text = text.substring(1).trimLeft();
    }
    while (text.isNotEmpty && wrappers.contains(text[text.length - 1])) {
      text = text.substring(0, text.length - 1).trimRight();
    }
    return text.trim();
  }

  _TextRange? _findUnderlineRange(String passage, String target) {
    final cleanTarget = _cleanUnderlineTarget(target);
    if (passage.trim().isEmpty || cleanTarget.isEmpty) return null;

    final directIndex =
        passage.toLowerCase().indexOf(cleanTarget.toLowerCase());
    if (directIndex >= 0) {
      return _TextRange(directIndex, directIndex + cleanTarget.length);
    }

    String normalizeChar(String char) {
      return RegExp(r'[A-Za-z0-9]').hasMatch(char) ? char.toLowerCase() : '';
    }

    final normalizedPassage = StringBuffer();
    final normalizedToOriginal = <int>[];
    for (var index = 0; index < passage.length; index++) {
      final normalized = normalizeChar(passage[index]);
      if (normalized.isEmpty) continue;
      normalizedPassage.write(normalized);
      normalizedToOriginal.add(index);
    }

    final normalizedTarget = cleanTarget
        .split('')
        .map(normalizeChar)
        .where((char) => char.isNotEmpty)
        .join();
    if (normalizedTarget.length < 4) return null;

    final normalizedIndex =
        normalizedPassage.toString().indexOf(normalizedTarget);
    if (normalizedIndex < 0) return null;

    final start = normalizedToOriginal[normalizedIndex];
    final end =
        normalizedToOriginal[normalizedIndex + normalizedTarget.length - 1] + 1;
    return _TextRange(start, end);
  }

  TextSpan _withUnderlineTarget({
    required String text,
    required String target,
  }) {
    final range = _findUnderlineRange(text, target);
    if (range == null) return _passageTextSpan(text);

    final spans = <TextSpan>[];
    if (range.start > 0) {
      spans.add(_passageTextSpan(text.substring(0, range.start)));
    }
    spans.add(
      TextSpan(
        text: text.substring(range.start, range.end),
        style: _passageTextStyle().copyWith(
          decoration: TextDecoration.underline,
          decorationThickness: 1.6,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    if (range.end < text.length) {
      spans.add(_passageTextSpan(text.substring(range.end)));
    }
    return TextSpan(children: spans, style: _passageTextStyle());
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questionSet == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('시험 응시')),
        body: const Center(
          child: Text('시험 정보를 불러오지 못했습니다.'),
        ),
      );
    }

    final questions = (_questionSet!['questions'] ?? []) as List;
    final passage = (_questionSet!['passage_content'] ?? "").toString();

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('시험 응시')),
        body: const Center(
          child: Text('문제가 없습니다.'),
        ),
      );
    }

    if (currentIndex >= questions.length) {
      currentIndex = 0;
    }

    final currentQuestion =
        Map<String, dynamic>.from(questions[currentIndex] as Map);

    final qId = _asInt(currentQuestion['question_id'] ?? currentQuestion['id']);
    final options = (currentQuestion['options'] ?? []) as List;
    final specialData = _specialData(currentQuestion);
    final bool isOrder = _isOrderQuestion(currentQuestion, specialData);
    final bool isInsertion = _isInsertionQuestion(currentQuestion, specialData);
    final bool isIrrelevant =
        _isIrrelevantQuestion(currentQuestion, specialData);
    final selectedIndex = selectedAnswers[qId];
    final answeredTotal = _answeredCount(questions);

    final bool isFirst = currentIndex == 0;
    final bool isLast = currentIndex == questions.length - 1;

    final questionPassage = _questionPassage(
      currentQuestion,
      fallbackPassage: passage,
    );
    final displayPassage = isOrder
        ? ''
        : _buildDisplayPassage(
            passage: questionPassage,
            question: currentQuestion,
          );
    final rawPrompt =
        (currentQuestion['question_text'] ?? currentQuestion['text'] ?? '')
            .toString();
    final underlineTarget = _extractUnderlineTarget(rawPrompt);
    final underlineFound =
        _findUnderlineRange(displayPassage, underlineTarget) != null;
    if (underlineTarget.isNotEmpty) {
      debugPrint(
        '[UnderlineTarget] q=${currentIndex + 1} '
        'type=${(currentQuestion['question_type'] ?? '').toString()} '
        'target="$underlineTarget" found=$underlineFound',
      );
    }

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: _surface,
        title: Text(
          (_questionSet!['title'] ?? '시험 응시').toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressHeader(
            current: currentIndex + 1,
            total: questions.length,
            answered: answeredTotal,
          ),
          _buildQuestionNavigator(questions),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuestionCard(
                    question: currentQuestion,
                    questionNumber: currentIndex + 1,
                  ),
                  const SizedBox(height: 14),
                  if (isOrder)
                    _buildOrderAnswerCard(
                      qId: qId,
                      specialData: specialData,
                    )
                  else if (isInsertion) ...[
                    _buildPassageCard(
                      passage: displayPassage,
                      questionType:
                          (currentQuestion['question_type'] ?? '').toString(),
                      underlineTarget: underlineTarget,
                    ),
                    const SizedBox(height: 14),
                    _buildInsertionAnswerCard(
                      qId: qId,
                      specialData: specialData,
                    ),
                  ] else if (isIrrelevant) ...[
                    _buildPassageCard(
                      passage: displayPassage,
                      questionType:
                          (currentQuestion['question_type'] ?? '').toString(),
                      underlineTarget: underlineTarget,
                    ),
                    const SizedBox(height: 14),
                    _buildIrrelevantAnswerCard(
                      qId: qId,
                      specialData: specialData,
                    ),
                  ] else ...[
                    _buildPassageCard(
                      passage: displayPassage,
                      questionType:
                          (currentQuestion['question_type'] ?? '').toString(),
                      underlineTarget: underlineTarget,
                    ),
                    const SizedBox(height: 14),
                    _buildOptionsCard(
                      questionType:
                          (currentQuestion['question_type'] ?? '').toString(),
                      options: options,
                      selectedIndex: selectedIndex,
                      qId: qId,
                    ),
                  ],
                ],
              ),
            ),
          ),
          _buildBottomButtons(
            isFirst: isFirst,
            isLast: isLast,
            totalQuestions: questions.length,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader({
    required int current,
    required int total,
    required int answered,
  }) {
    final double progress = total == 0 ? 0 : current / total;

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 4, 18, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: _blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '문제 $current / $total',
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '선택 ${selectedAnswers.length} / $total',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _ProgressBadge(
                label: '${(progress * 100).round()}%',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFEFF6FF),
              valueColor: const AlwaysStoppedAnimation<Color>(_blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionNavigator(List questions) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: List.generate(questions.length, (index) {
          final q = questions[index];

          final bool isCurrent = index == currentIndex;
          final bool isAnswered =
              _isQuestionAnswered(Map<String, dynamic>.from(q as Map));

          Color backgroundColor;
          Color textColor;
          BorderSide borderSide;

          if (isCurrent) {
            backgroundColor = _blue;
            textColor = Colors.white;
            borderSide = BorderSide.none;
          } else if (isAnswered) {
            backgroundColor = const Color(0xFFF3E8FF);
            textColor = _purple;
            borderSide = const BorderSide(color: Color(0xFFD8B4FE));
          } else {
            backgroundColor = Colors.white;
            textColor = _muted;
            borderSide = const BorderSide(color: _line);
          }

          return InkWell(
            onTap: () => _goToQuestion(index),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(borderSide),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPassageCard({
    required String passage,
    required String questionType,
    required String underlineTarget,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                isPassageExpanded = !isPassageExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.article_outlined,
                      color: _blue,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '지문',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    isPassageExpanded ? '접기' : '펼치기',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isPassageExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: _muted,
                  ),
                ],
              ),
            ),
          ),
          if (isPassageExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 22),
              child: _buildPassageContent(
                passage: passage,
                questionType: questionType.toLowerCase(),
                underlineTarget: underlineTarget,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPassageContent({
    required String passage,
    required String questionType,
    required String underlineTarget,
  }) {
    final text = passage.trim();
    if (text.isEmpty) {
      return const SelectableText(
        '-',
        style: TextStyle(fontSize: 15, height: 1.72, color: _ink),
      );
    }

    if (questionType == 'irrelevant' || questionType == 'unrelated_sentence') {
      return SelectableText(
        text,
        style: _passageTextStyle(),
      );
    }

    if (questionType == 'insertion') {
      final parts = text.split(RegExp(r'\n\s*\n+'));
      if (parts.length >= 2) {
        final givenSentence = parts.first.trim();
        final body = parts.skip(1).join('\n\n').trim();
        final isMultiple = RegExp(r'^\s*\([A-E]\)', multiLine: true)
                .allMatches(givenSentence)
                .length >=
            2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: SelectableText.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${isMultiple ? '주어진 문장들' : '주어진 문장'}\n',
                      style: const TextStyle(
                        color: _blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.55,
                      ),
                    ),
                    TextSpan(
                      text: givenSentence,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        height: 1.62,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SelectableText.rich(
              _withUnderlineTarget(text: body, target: underlineTarget),
            ),
          ],
        );
      }
    }

    return SelectableText.rich(
      _withUnderlineTarget(text: text, target: underlineTarget),
    );
  }

  TextSpan _passageTextSpan(String text) {
    final spans = <TextSpan>[];
    final pattern = RegExp(
      r'(\[\s{3,}\]|_{3,}|[①②③④⑤]|\([ABC]\)|\[Given Text\])',
    );
    var cursor = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: text.substring(cursor, match.start),
            style: _passageTextStyle(),
          ),
        );
      }

      final token = match.group(0) ?? '';
      final isBlank =
          token.contains('_') || RegExp(r'^\[\s{3,}\]$').hasMatch(token);
      spans.add(
        TextSpan(
          text: isBlank ? ' [          ] ' : token,
          style: _highlightPassageTextStyle(isBlank: isBlank),
        ),
      );
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(cursor),
          style: _passageTextStyle(),
        ),
      );
    }

    return TextSpan(children: spans, style: _passageTextStyle());
  }

  TextStyle _passageTextStyle() {
    return const TextStyle(
      color: Color(0xFF1F2937),
      fontSize: 15.8,
      height: 1.72,
      fontWeight: FontWeight.w500,
    );
  }

  TextStyle _highlightPassageTextStyle({required bool isBlank}) {
    return TextStyle(
      color: isBlank ? _blue : _purple,
      fontSize: isBlank ? 16.2 : 15.8,
      height: 1.72,
      fontWeight: FontWeight.w900,
      backgroundColor: isBlank ? const Color(0xFFEFF6FF) : null,
    );
  }

  Widget _buildQuestionCard({
    required Map<String, dynamic> question,
    required int questionNumber,
  }) {
    final questionType = (question['question_type'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _typeLabel(questionType),
                    style: const TextStyle(
                      color: _blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Q$questionNumber',
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _buildQuestionText(question),
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                height: 1.48,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderAnswerCard({
    required int qId,
    required Map<String, dynamic> specialData,
  }) {
    final blocks = _orderBlocks(specialData);
    final selected = orderAnswers[qId] ?? const <String>[];
    final fixedStart = (specialData['fixed_start'] ?? '').toString().trim();
    final fixedEnd = (specialData['fixed_end'] ?? '').toString().trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '\uC21C\uC11C \uBC30\uC5F4',
              style: TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'A, B, C \uBE14\uB85D\uC744 \uC62C\uBC14\uB978 \uC21C\uC11C\uB300\uB85C \uB20C\uB7EC \uBC30\uC5F4\uD558\uC138\uC694.',
              style: TextStyle(
                color: _muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (fixedStart.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildOrderTextBox(
                  label: '\uC8FC\uC5B4\uC9C4 \uAE00', text: fixedStart),
            ],
            const SizedBox(height: 14),
            ...blocks.entries.map((entry) {
              final selectedOrder = selected.indexOf(entry.key);
              final isSelected = selectedOrder >= 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _toggleOrderBlock(qId, entry.key, blocks.length),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? _blue : _line,
                        width: isSelected ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? _blue : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: isSelected ? _blue : _line),
                          ),
                          child: Text(
                            isSelected
                                ? '${selectedOrder + 1}'
                                : '(${entry.key})',
                            style: TextStyle(
                              color: isSelected ? Colors.white : _blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SelectableText(
                            entry.value,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 15.5,
                              height: 1.58,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (fixedEnd.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildOrderTextBox(
                  label: '\uB9C8\uBB34\uB9AC \uAE00', text: fixedEnd),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selected.isEmpty
                        ? '\uC120\uD0DD\uD55C \uC21C\uC11C: -'
                        : '\uC120\uD0DD\uD55C \uC21C\uC11C: ${selected.join('-')}',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: selected.isEmpty
                      ? null
                      : () {
                          setState(() => orderAnswers.remove(qId));
                          debugPrint('[StudentOrderAnswer] q=$qId selected=');
                        },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('\uCD08\uAE30\uD654'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTextBox({required String label, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: SelectableText.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label\n',
              style: const TextStyle(
                color: _blue,
                fontSize: 12,
                height: 1.55,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(
              text: text,
              style: const TextStyle(
                color: _ink,
                fontSize: 15.5,
                height: 1.62,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleOrderBlock(int qId, String label, int totalBlocks) {
    final current = List<String>.from(orderAnswers[qId] ?? const <String>[]);
    if (current.contains(label)) {
      current.remove(label);
    } else if (current.length < totalBlocks) {
      current.add(label);
    }
    setState(() {
      if (current.isEmpty) {
        orderAnswers.remove(qId);
      } else {
        orderAnswers[qId] = current;
      }
    });
    debugPrint('[StudentOrderAnswer] q=$qId selected=${current.join('-')}');
  }

  Widget _buildInsertionAnswerCard({
    required int qId,
    required Map<String, dynamic> specialData,
  }) {
    final positions = _insertionPositions(specialData);
    if (_isMultipleInsertion(specialData)) {
      return _buildMultipleInsertionAnswerCard(
        qId: qId,
        specialData: specialData,
        positions: positions,
      );
    }
    final selected = insertionAnswers[qId];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '\uC704\uCE58 \uC120\uD0DD',
              style: TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '\uC8FC\uC5B4\uC9C4 \uBB38\uC7A5\uC774 \uB4E4\uC5B4\uAC08 \uC704\uCE58\uB97C \uD558\uB098 \uC120\uD0DD\uD558\uC138\uC694.',
              style: TextStyle(
                color: _muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final position in positions)
                  ChoiceChip(
                    label: Text('$position'),
                    selected: selected == position,
                    onSelected: (_) {
                      setState(() {
                        insertionAnswers[qId] = position;
                      });
                      debugPrint(
                        '[StudentInsertionAnswer] q=$qId selected=$position',
                      );
                    },
                    selectedColor: const Color(0xFFEFF6FF),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected == position ? _blue : _ink,
                      fontWeight: FontWeight.w900,
                    ),
                    side: BorderSide(
                      color: selected == position ? _blue : _line,
                      width: selected == position ? 1.6 : 1,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleInsertionAnswerCard({
    required int qId,
    required Map<String, dynamic> specialData,
    required List<int> positions,
  }) {
    final sentences = _multipleInsertionSentences(specialData);
    final selected = multipleInsertionAnswers[qId] ?? const <String, int>{};
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '문장별 위치 선택',
            style: TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '각 문장이 들어갈 위치를 모두 선택하세요.',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          for (final entry in sentences.entries) ...[
            Text(
              '${entry.key}:',
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final position in positions)
                  ChoiceChip(
                    label: Text(_circledPosition(position)),
                    selected: selected[entry.key] == position,
                    onSelected: (_) {
                      setState(() {
                        final next = Map<String, int>.from(
                          multipleInsertionAnswers[qId] ??
                              const <String, int>{},
                        );
                        next[entry.key] = position;
                        multipleInsertionAnswers[qId] = next;
                      });
                      debugPrint(
                        '[StudentInsertionAnswer] q=$qId selected=${_multipleInsertionAnswerText(qId, specialData)}',
                      );
                    },
                    selectedColor: const Color(0xFFEFF6FF),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected[entry.key] == position ? _blue : _ink,
                      fontWeight: FontWeight.w900,
                    ),
                    side: BorderSide(
                      color: selected[entry.key] == position ? _blue : _line,
                      width: selected[entry.key] == position ? 1.6 : 1,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildIrrelevantAnswerCard({
    required int qId,
    required Map<String, dynamic> specialData,
  }) {
    final positions = _insertionPositions(specialData);
    final selected = irrelevantAnswers[qId];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '문장 선택',
            style: TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '전체 흐름과 관계없는 문장의 번호를 하나 선택하세요.',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final position in positions)
                ChoiceChip(
                  label: Text(_circledPosition(position)),
                  selected: selected == position,
                  onSelected: (_) {
                    setState(() {
                      irrelevantAnswers[qId] = position;
                    });
                    debugPrint(
                      '[StudentIrrelevantAnswer] q=$qId selected=$position',
                    );
                  },
                  selectedColor: const Color(0xFFEFF6FF),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected == position ? _blue : _ink,
                    fontWeight: FontWeight.w900,
                  ),
                  side: BorderSide(
                    color: selected == position ? _blue : _line,
                    width: selected == position ? 1.6 : 1,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _multipleInsertionAnswerText(
    int qId,
    Map<String, dynamic> specialData,
  ) {
    final labels = _multipleInsertionSentences(specialData).keys.toList()
      ..sort();
    final selected = multipleInsertionAnswers[qId] ?? const <String, int>{};
    return labels
        .where(selected.containsKey)
        .map((label) => '$label:${selected[label]}')
        .join(',');
  }

  String _circledPosition(int position) {
    const labels = ['①', '②', '③', '④', '⑤', '⑥', '⑦', '⑧', '⑨'];
    return position >= 1 && position <= labels.length
        ? labels[position - 1]
        : '$position';
  }

  List<int> _insertionPositions(Map<String, dynamic> specialData) {
    final raw = specialData['positions'];
    if (raw is List) {
      final parsed = raw
          .map((item) => int.tryParse(item.toString()))
          .whereType<int>()
          .toList(growable: false);
      if (parsed.isNotEmpty) return parsed;
    }
    return const [1, 2, 3, 4, 5];
  }

  Widget _buildOptionsCard({
    required String questionType,
    required List options,
    required int? selectedIndex,
    required int qId,
  }) {
    final normalizedType = questionType.toLowerCase();
    final displayOptions = _displayOptions(
      questionType: normalizedType,
      options: options,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '\uBCF4\uAE30',
              style: TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            ...displayOptions.asMap().entries.map((entry) {
              final idx = entry.key;
              final optionText = entry.value;
              final bool isSelected = selectedIndex == idx;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _selectAnswer(qId, idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? _blue : _line,
                        width: isSelected ? 1.6 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _blue.withValues(alpha: 0.12),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? _blue : const Color(0xFFF8FAFC),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? _blue : _line,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            optionText,
                            style: TextStyle(
                              color:
                                  isSelected ? _ink : const Color(0xFF111827),
                              fontSize: 16,
                              height: 1.46,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons({
    required bool isFirst,
    required bool isLast,
    required int totalQuestions,
  }) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: _line)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isFirst ? null : _goPrevious,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('이전'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  side: const BorderSide(color: _line),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isLast
                  ? FilledButton.icon(
                      onPressed: isSubmitting ? null : _submitExam,
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: const Text('시험 제출'),
                      style: _primaryButtonStyle(),
                    )
                  : FilledButton.icon(
                      onPressed: () => _goNext(totalQuestions),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('다음'),
                      style: _primaryButtonStyle(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _displayOptions({
    required String questionType,
    required List options,
  }) {
    if (questionType == 'insertion') {
      return const ['?', '?', '?', '?', '?'];
    }

    final cleaned = <String>[];
    for (final entry in options.asMap().entries) {
      final idx = entry.key;
      final opt = entry.value;
      final circled = _circled(idx);
      final rawText =
          opt is Map ? (opt['text'] ?? '').toString() : opt.toString();
      final optionText = _cleanStudentOptionText(rawText);
      if (optionText.isEmpty) continue;
      cleaned.add('$circled $optionText');
    }

    return cleaned;
  }

  String _cleanStudentOptionText(String raw) {
    var normalized = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    normalized = normalized.replaceFirst(
      RegExp(r'^\s*(?:[??????????]|[1-5][\.)]?|[A-E][\.)]?)\s*'),
      '',
    );

    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .where((line) => !_shouldDropKoreanExplanationLine(line))
        .toList();

    if (lines.isEmpty) return '';
    return lines.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _circled(int index) {
    const labels = ['①', '②', '③', '④', '⑤'];
    if (index >= 0 && index < labels.length) return labels[index];
    return '${index + 1}.';
  }

  ButtonStyle _primaryButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: _blue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'topic':
        return '주제';
      case 'title':
        return '제목';
      case 'gist':
        return '요지';
      case 'summary':
        return '요약';
      case 'cloze':
        return '빈칸';
      case 'order':
        return '순서';
      case 'insertion':
        return '삽입';
      case 'mismatch':
        return '불일치';
      case 'grammar':
        return '어법';
      case 'vocabulary':
        return '어휘';
      case 'content':
        return '내용';
      default:
        return type.isEmpty ? '문제' : type;
    }
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _StudentExamTakeScreenState._blue,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TextRange {
  const _TextRange(this.start, this.end);

  final int start;
  final int end;
}
