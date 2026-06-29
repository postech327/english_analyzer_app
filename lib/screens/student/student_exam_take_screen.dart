import 'package:flutter/material.dart';
import '../../services/student_exam_service.dart';
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

    /// 모든 문제 선택 체크
    if (selectedAnswers.length != questions.length) {
      final unanswered = <int>[];

      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        final qId = q['question_id'];

        if (!selectedAnswers.containsKey(qId)) {
          unanswered.add(i + 1);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '아직 선택하지 않은 문제가 있습니다: ${unanswered.join(", ")}번',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final result = await StudentExamService.submitExam(
        problemSetId: widget.problemSetId,
        answers: selectedAnswers.entries
            .map(
              (e) => {
                "question_id": e.key,
                "selected_index": e.value,
              },
            )
            .toList(),
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
        SnackBar(content: Text('시험 제출 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  /// 현재 문제에 보여줄 지문
  /// 다음 단계에서 cloze/order/insertion 유형별 전용 지문 표시를 여기서 처리하면 됨.
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
    final insertionText = (question['question_text'] ?? '').toString().trim();

    if (insertionText.isEmpty) {
      return passage;
    }

    return _formatInsertionText(
      passage: passage,
      insertionText: insertionText,
    );
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

    final questionText = (question['question_text'] ?? '').toString();

    if (questionType == 'cloze' || questionType == 'blank') {
      return '다음 빈칸에 들어갈 말로 가장 적절한 것은?';
    }

    if (questionType == 'order') {
      return '주어진 글 다음에 이어질 글의 순서로 가장 적절한 것은?';
    }

    if (questionType == 'insertion') {
      return '글의 흐름으로 보아, 주어진 문장이 들어가기에 가장 적절한 곳은?';
    }

    return questionText;
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

    final currentQuestion = questions[currentIndex] as Map<String, dynamic>;

    final qId = currentQuestion['question_id'];
    final options = (currentQuestion['options'] ?? []) as List;
    final selectedIndex = selectedAnswers[qId];

    final bool isFirst = currentIndex == 0;
    final bool isLast = currentIndex == questions.length - 1;

    final displayPassage = _buildDisplayPassage(
      passage: passage,
      question: currentQuestion,
    );

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
          ),
          _buildQuestionNavigator(questions),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPassageCard(
                    passage: displayPassage,
                    questionType:
                        (currentQuestion['question_type'] ?? '').toString(),
                  ),
                  const SizedBox(height: 14),
                  _buildQuestionCard(
                    question: currentQuestion,
                    questionNumber: currentIndex + 1,
                    options: options,
                    selectedIndex: selectedIndex,
                    qId: qId,
                  ),
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
          final qId = q['question_id'];

          final bool isCurrent = index == currentIndex;
          final bool isAnswered = selectedAnswers.containsKey(qId);

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
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPassageContent({
    required String passage,
    required String questionType,
  }) {
    final text = passage.trim();
    if (text.isEmpty) {
      return const SelectableText(
        '-',
        style: TextStyle(fontSize: 15, height: 1.72, color: _ink),
      );
    }

    if (questionType == 'insertion') {
      final parts = text.split(RegExp(r'\n\s*\n+'));
      if (parts.length >= 2) {
        final givenSentence = parts.first.trim();
        final body = parts.skip(1).join('\n\n').trim();

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
                    const TextSpan(
                      text: '주어진 문장\n',
                      style: TextStyle(
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
            SelectableText.rich(_passageTextSpan(body)),
          ],
        );
      }
    }

    return SelectableText.rich(_passageTextSpan(text));
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
    required List options,
    required int? selectedIndex,
    required dynamic qId,
  }) {
    final questionType = (question['question_type'] ?? '').toString();
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
            const SizedBox(height: 18),
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
                                  isSelected ? _ink : const Color(0xFF1F2937),
                              fontSize: 15,
                              height: 1.42,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
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
    if (questionType == 'order') {
      return const [
        '① (A)-(C)-(B)',
        '② (B)-(A)-(C)',
        '③ (B)-(C)-(A)',
        '④ (C)-(A)-(B)',
        '⑤ (C)-(B)-(A)',
      ];
    }

    if (questionType == 'insertion') {
      return const ['①', '②', '③', '④', '⑤'];
    }

    return options.asMap().entries.map((entry) {
      final idx = entry.key;
      final opt = entry.value;
      final circled = _circled(idx);

      if (opt is Map) {
        var text = (opt['text'] ?? '').toString().trim();
        text = text.replaceFirst(
          RegExp(r'^\s*(?:[①②③④⑤]|[1-5][\.\)]?|[A-E][\.\)]?)\s*'),
          '',
        );
        return text.isEmpty ? circled : '$circled $text';
      }

      final text = opt.toString().trim();
      return text.isEmpty ? circled : '$circled $text';
    }).toList();
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
