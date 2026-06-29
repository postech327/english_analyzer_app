import 'package:flutter/material.dart';

import '../../models/mock_exam_result_report.dart';
import '../../services/student_mock_exam_service.dart';
import '../../utils/mock_exam_pdf_generator.dart';

class StudentMockExamAttemptDetailScreen extends StatefulWidget {
  const StudentMockExamAttemptDetailScreen({
    super.key,
    required this.attemptId,
    this.title = '오답 다시보기',
    this.fetcher,
  });

  final int attemptId;
  final String title;
  final Future<Map<String, dynamic>> Function(int attemptId)? fetcher;

  @override
  State<StudentMockExamAttemptDetailScreen> createState() =>
      _StudentMockExamAttemptDetailScreenState();
}

class _StudentMockExamAttemptDetailScreenState
    extends State<StudentMockExamAttemptDetailScreen> {
  static const _surface = Color(0xFFF6F8FC);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _blue = Color(0xFF2563EB);
  static const _purple = Color(0xFF7C3AED);
  static const _line = Color(0xFFE5E7EB);
  static const _green = Color(0xFF16A34A);
  static const _red = Color(0xFFDC2626);

  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<Map<String, dynamic>> _fetch() {
    final fetcher = widget.fetcher;
    if (fetcher != null) return fetcher(widget.attemptId);
    return StudentMockExamService.fetchMockExamAttemptDetail(widget.attemptId);
  }

  void _reload() {
    setState(() {
      _future = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessagePanel(
              title: '상세 결과를 불러오지 못했습니다.',
              message: snapshot.error.toString(),
              onTap: _reload,
            );
          }
          return _AttemptDetailBody(data: snapshot.data ?? const {});
        },
      ),
    );
  }
}

class _AttemptDetailBody extends StatefulWidget {
  const _AttemptDetailBody({required this.data});

  final Map<String, dynamic> data;

  @override
  State<_AttemptDetailBody> createState() => _AttemptDetailBodyState();
}

class _AttemptDetailBodyState extends State<_AttemptDetailBody> {
  bool _wrongOnly = false;
  bool _initialized = false;
  final Set<int> _expandedNumbers = {};
  final Map<int, GlobalKey> _questionKeys = {};

  void _ensureQuestionState(List<dynamic> questions) {
    for (final item in questions) {
      final question = _asMap(item);
      final number = _asInt(question['number']);
      if (number > 0) {
        _questionKeys.putIfAbsent(number, GlobalKey.new);
      }
    }

    if (_initialized) return;
    _initialized = true;
    for (final item in questions) {
      final question = _asMap(item);
      if (question['is_correct'] != true) {
        final number = _asInt(question['number']);
        if (number > 0) _expandedNumbers.add(number);
      }
    }
  }

  void _toggleExpanded(int number) {
    setState(() {
      if (_expandedNumbers.contains(number)) {
        _expandedNumbers.remove(number);
      } else {
        _expandedNumbers.add(number);
      }
    });
  }

  void _scrollToQuestion(Map<String, dynamic> question) {
    final number = _asInt(question['number']);
    if (number <= 0) return;

    setState(() {
      _expandedNumbers.add(number);
      if (_wrongOnly && question['is_correct'] == true) {
        _wrongOnly = false;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _questionKeys[number]?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final attempt = _asMap(widget.data['attempt']);
    final summary = _asMap(widget.data['summary']);
    final student = _asMap(widget.data['student']);
    final questions = _asList(widget.data['questions']);
    final report = MockExamResultReport.fromAttemptDetail(widget.data);
    _ensureQuestionState(questions);

    final visibleQuestions = _wrongOnly
        ? questions.where((item) => _asMap(item)['is_correct'] != true).toList()
        : questions;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        _SummaryCard(attempt: attempt, summary: summary, student: student),
        const SizedBox(height: 14),
        _ReportInsightCard(report: report, questions: questions),
        const SizedBox(height: 14),
        _QuestionIndexCard(
          questions: questions,
          wrongOnly: _wrongOnly,
          onFilterChanged: (value) => setState(() => _wrongOnly = value),
          onQuestionTap: _scrollToQuestion,
        ),
        const SizedBox(height: 14),
        if (visibleQuestions.isEmpty)
          _card(
            child: const Text(
              '표시할 오답이 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _StudentMockExamAttemptDetailScreenState._muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          )
        else
          ...visibleQuestions.map((item) {
            final question = _asMap(item);
            final number = _asInt(question['number']);
            return Padding(
              key: _questionKeys[number],
              padding: const EdgeInsets.only(bottom: 14),
              child: _QuestionReviewCard(
                question: question,
                expanded: _expandedNumbers.contains(number),
                onToggle: () => _toggleExpanded(number),
              ),
            );
          }),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.attempt,
    required this.summary,
    required this.student,
  });

  final Map<String, dynamic> attempt;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> student;

  @override
  Widget build(BuildContext context) {
    final weakTypes = _asList(summary['weak_types'])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
    final correct = _asInt(summary['correct_count']);
    final total = _asInt(attempt['total_questions'], 20);
    final score = _score(summary['score']);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _StudentMockExamAttemptDetailScreenState._blue
                .withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_asText(student['nickname']).isNotEmpty) ...[
            Text(
              _asText(student['nickname']),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
          ],
          Text(
            _asText(attempt['title'], '모의고사'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  '점 / 100점',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroPill('$correct문항 정답 / $total문항'),
              _heroPill(_formatDateTime(attempt['submitted_at'])),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Text(
              weakTypes.isEmpty
                  ? '약점 유형 없음. 모든 유형을 잘 풀었습니다.'
                  : '약점: ${weakTypes.join(', ')}',
              style: const TextStyle(
                color: Colors.white,
                height: 1.45,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _QuestionIndexCard extends StatelessWidget {
  const _QuestionIndexCard({
    required this.questions,
    required this.wrongOnly,
    required this.onFilterChanged,
    required this.onQuestionTap,
  });

  final List<dynamic> questions;
  final bool wrongOnly;
  final ValueChanged<bool> onFilterChanged;
  final ValueChanged<Map<String, dynamic>> onQuestionTap;

  @override
  Widget build(BuildContext context) {
    final incorrectCount =
        questions.where((item) => _asMap(item)['is_correct'] != true).length;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('문항별 결과', Icons.fact_check_rounded),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text('전체 보기 ${questions.length}'),
                selected: !wrongOnly,
                onSelected: (_) => onFilterChanged(false),
                selectedColor: const Color(0xFFEFF6FF),
                labelStyle: TextStyle(
                  color: !wrongOnly
                      ? _StudentMockExamAttemptDetailScreenState._blue
                      : _StudentMockExamAttemptDetailScreenState._muted,
                  fontWeight: FontWeight.w900,
                ),
                side: BorderSide(
                  color: !wrongOnly
                      ? const Color(0xFFBFDBFE)
                      : _StudentMockExamAttemptDetailScreenState._line,
                ),
              ),
              ChoiceChip(
                label: Text('오답만 보기 $incorrectCount'),
                selected: wrongOnly,
                onSelected: (_) => onFilterChanged(true),
                selectedColor: const Color(0xFFFEF2F2),
                labelStyle: TextStyle(
                  color: wrongOnly
                      ? _StudentMockExamAttemptDetailScreenState._red
                      : _StudentMockExamAttemptDetailScreenState._muted,
                  fontWeight: FontWeight.w900,
                ),
                side: BorderSide(
                  color: wrongOnly
                      ? const Color(0xFFFECACA)
                      : _StudentMockExamAttemptDetailScreenState._line,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: questions.map((item) {
              final question = _asMap(item);
              final correct = question['is_correct'] == true;
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onQuestionTap(question),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: correct
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: correct
                          ? const Color(0xFFBBF7D0)
                          : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Text(
                    '${_asInt(question['number'])}번 ${_asText(question['type_label'])} ${correct ? 'O' : 'X'}',
                    style: TextStyle(
                      color: correct
                          ? _StudentMockExamAttemptDetailScreenState._green
                          : _StudentMockExamAttemptDetailScreenState._red,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ReportInsightCard extends StatelessWidget {
  const _ReportInsightCard({
    required this.report,
    required this.questions,
  });

  final MockExamResultReport report;
  final List<dynamic> questions;

  @override
  Widget build(BuildContext context) {
    final typeItems = report.typeSummary.values.toList();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('결과지 요약', Icons.insights_rounded),
          const SizedBox(height: 14),
          Text(
            report.scoreComment,
            style: const TextStyle(
              color: _StudentMockExamAttemptDetailScreenState._ink,
              height: 1.45,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: report.weakTypes.isEmpty
                ? [
                    _insightChip(
                      '뚜렷한 약점 유형이 없습니다.',
                      const Color(0xFFF0FDF4),
                      const Color(0xFF16A34A),
                    ),
                  ]
                : report.weakTypes
                    .map(
                      (type) => _insightChip(
                        type,
                        const Color(0xFFFFF7ED),
                        const Color(0xFFC2410C),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Text(
              report.recommendation,
              style: const TextStyle(
                color: _StudentMockExamAttemptDetailScreenState._ink,
                height: 1.45,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('유형별 정답률', Icons.analytics_outlined),
          const SizedBox(height: 12),
          if (typeItems.isEmpty)
            const Text(
              '유형별 결과가 없습니다.',
              style: TextStyle(
                color: _StudentMockExamAttemptDetailScreenState._muted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...typeItems.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Row(
                  children: [
                    SizedBox(
                      width: 82,
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: _StudentMockExamAttemptDetailScreenState._ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (item.rate / 100).clamp(0, 1),
                          minHeight: 9,
                          color: item.rate >= 70
                              ? _StudentMockExamAttemptDetailScreenState._green
                              : _StudentMockExamAttemptDetailScreenState._blue,
                          backgroundColor: const Color(0xFFEFF6FF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 64,
                      child: Text(
                        '${item.correct}/${item.total}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color:
                              _StudentMockExamAttemptDetailScreenState._muted,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await MockExamPdfGenerator.previewOrPrint(
                  report,
                  wrongQuestions: _wrongQuestionPdfItems(),
                );
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF 생성 중 오류가 발생했습니다.')),
                );
              }
            },
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('PDF 출력'),
          ),
        ],
      ),
    );
  }

  Widget _insightChip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  List<MockExamWrongQuestionPdfItem> _wrongQuestionPdfItems() {
    return questions
        .map(_asMap)
        .where((question) => question['is_correct'] != true)
        .map((question) {
      final selectedIndex = _nullableInt(question['selected_index']);
      final answerIndex = _nullableInt(question['answer_index']);
      return MockExamWrongQuestionPdfItem(
        number: _asInt(question['number']),
        typeLabel: _asText(question['type_label'], '문제'),
        selectedAnswer: _choiceLabel(selectedIndex),
        correctAnswer: _choiceLabel(answerIndex),
        explanation: _asText(question['explanation'], '해설 없음'),
      );
    }).toList();
  }
}

class _QuestionReviewCard extends StatelessWidget {
  const _QuestionReviewCard({
    required this.question,
    required this.expanded,
    required this.onToggle,
  });

  final Map<String, dynamic> question;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final number = _asInt(question['number']);
    final correct = question['is_correct'] == true;
    final selectedIndex = _nullableInt(question['selected_index']);
    final answerIndex = _asInt(question['answer_index']);
    final questionType = _asText(question['question_type']).toLowerCase();
    final options = _displayOptions(questionType, _asList(question['options']));

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(22),
      child: _card(
        borderColor:
            correct ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statusBadge(correct),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '문제 $number · ${_asText(question['type_label'])}',
                    style: const TextStyle(
                      color: _StudentMockExamAttemptDetailScreenState._ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: _StudentMockExamAttemptDetailScreenState._muted,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _smallPill('내 답: ${_choiceLabel(selectedIndex)}',
                    selectedIndex == answerIndex ? _greenSoft : _redSoft),
                _smallPill('정답: ${_choiceLabel(answerIndex)}', _greenSoft),
                if (_asText(question['source'], '').isNotEmpty)
                  _smallPill(_asText(question['source']), _skySoft),
              ],
            ),
            if (!expanded) ...[
              const SizedBox(height: 12),
              const Text(
                '카드를 눌러 지문과 해설을 확인하세요.',
                style: TextStyle(
                  color: _StudentMockExamAttemptDetailScreenState._muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (expanded) ...[
              const SizedBox(height: 16),
              _label('지문'),
              const SizedBox(height: 8),
              _passageContent(question, questionType),
              const SizedBox(height: 16),
              _label('문제'),
              const SizedBox(height: 8),
              SelectableText.rich(
                _htmlLikeTextSpan(
                  _questionPrompt(question),
                  baseStyle: const TextStyle(
                    color: _StudentMockExamAttemptDetailScreenState._ink,
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _label('선택지'),
              const SizedBox(height: 8),
              ...options.asMap().entries.map((entry) {
                final index = entry.key;
                final isSelected = selectedIndex == index;
                final isAnswer = answerIndex == index;
                final Color bg;
                final Color border;
                final Color fg;
                if (isAnswer) {
                  bg = const Color(0xFFF0FDF4);
                  border = const Color(0xFFBBF7D0);
                  fg = _StudentMockExamAttemptDetailScreenState._green;
                } else if (isSelected) {
                  bg = const Color(0xFFFEF2F2);
                  border = const Color(0xFFFECACA);
                  fg = _StudentMockExamAttemptDetailScreenState._red;
                } else {
                  bg = Colors.white;
                  border = _StudentMockExamAttemptDetailScreenState._line;
                  fg = _StudentMockExamAttemptDetailScreenState._ink;
                }
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          _circled(index),
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Expanded(
                        child: RichText(
                          text: _htmlLikeTextSpan(
                            entry.value,
                            baseStyle: TextStyle(
                              color: fg,
                              height: 1.45,
                              fontWeight: isSelected || isAnswer
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      if (isSelected || isAnswer) ...[
                        const SizedBox(width: 8),
                        Text(
                          isSelected && !isAnswer ? '내 답' : '정답',
                          style: TextStyle(
                            color: fg,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              _label('해설'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _StudentMockExamAttemptDetailScreenState._line,
                  ),
                ),
                child: SelectableText(
                  _asText(question['explanation'], '해설 없음'),
                  style: const TextStyle(
                    color: _StudentMockExamAttemptDetailScreenState._ink,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const _greenSoft = Color(0xFFF0FDF4);
  static const _redSoft = Color(0xFFFEF2F2);
  static const _skySoft = Color(0xFFEFF6FF);

  Widget _statusBadge(bool correct) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: correct ? _greenSoft : _redSoft,
        shape: BoxShape.circle,
        border: Border.all(
          color: correct ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
        ),
      ),
      child: Text(
        correct ? 'O' : 'X',
        style: TextStyle(
          color: correct
              ? _StudentMockExamAttemptDetailScreenState._green
              : _StudentMockExamAttemptDetailScreenState._red,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _smallPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _StudentMockExamAttemptDetailScreenState._ink,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _StudentMockExamAttemptDetailScreenState._muted,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.title,
    required this.message,
    required this.onTap,
  });

  final String title;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: _card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: _StudentMockExamAttemptDetailScreenState._blue,
                size: 38,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: _StudentMockExamAttemptDetailScreenState._ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _StudentMockExamAttemptDetailScreenState._muted,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _sectionTitle(String title, IconData icon) {
  return Row(
    children: [
      Icon(icon, color: _StudentMockExamAttemptDetailScreenState._blue),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          color: _StudentMockExamAttemptDetailScreenState._ink,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

Widget _card({
  required Widget child,
  Color borderColor = _StudentMockExamAttemptDetailScreenState._line,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

Widget _passageContent(Map<String, dynamic> question, String questionType) {
  if (questionType == 'order') {
    return _orderPassageContent(_orderDisplayText(question));
  }
  if (questionType == 'insertion') {
    return _insertionPassageContent(question);
  }

  final passage = _asText(question['passage'], '');
  return SelectableText.rich(
    _htmlLikeTextSpan(passage.isEmpty ? '-' : passage),
  );
}

String _orderDisplayText(Map<String, dynamic> question) {
  final passage = _asText(question['passage'], '');
  final questionText = _asText(question['question_text'], '');
  if (_looksLikeOrderText(passage)) return passage;
  if (_looksLikeOrderText(questionText)) return questionText;
  return passage;
}

bool _looksLikeOrderText(String text) {
  return text.contains('(A)') && text.contains('(B)') && text.contains('(C)');
}

Widget _orderPassageContent(String text) {
  final sections = _splitOrderSections(text);
  if (sections.isEmpty) {
    return SelectableText.rich(_htmlLikeTextSpan(text.isEmpty ? '-' : text));
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: sections.map((section) {
      final label = section.$1;
      final body = section.$2;
      final isGiven = label == 'Given Text' || label == '주어진 글';
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isGiven ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGiven
                ? const Color(0xFFBFDBFE)
                : _StudentMockExamAttemptDetailScreenState._line,
          ),
        ),
        child: SelectableText.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$label\n',
                style: TextStyle(
                  color: isGiven
                      ? _StudentMockExamAttemptDetailScreenState._blue
                      : _StudentMockExamAttemptDetailScreenState._purple,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  height: 1.55,
                ),
              ),
              ..._htmlLikeTextSpan(body).children ?? [],
            ],
            style: _passageTextStyle(),
          ),
        ),
      );
    }).toList(),
  );
}

List<(String, String)> _splitOrderSections(String raw) {
  var text = raw
      .replaceAll(RegExp(r'\[Given Text\]', caseSensitive: false), '주어진 글')
      .replaceAll(RegExp(r'Given Text\s*:?', caseSensitive: false), '주어진 글')
      .replaceAll(RegExp(r'\s*\(A\)\s*'), '\n(A) ')
      .replaceAll(RegExp(r'\s*\(B\)\s*'), '\n(B) ')
      .replaceAll(RegExp(r'\s*\(C\)\s*'), '\n(C) ')
      .trim();

  final firstPart = text.indexOf(RegExp(r'\([ABC]\)'));
  if (firstPart == -1) return const [];

  final given = text.substring(0, firstPart).trim();
  final partsText = text.substring(firstPart);
  final partPattern = RegExp(r'\(([ABC])\)\s*([\s\S]*?)(?=\n\([ABC]\)|$)');
  final sections = <(String, String)>[];
  if (given.isNotEmpty) {
    sections.add(('주어진 글', given.replaceFirst(RegExp(r'^주어진 글\s*:?\s*'), '')));
  }
  for (final match in partPattern.allMatches(partsText)) {
    final label = match.group(1) ?? '';
    final body = (match.group(2) ?? '').trim();
    if (body.isNotEmpty) sections.add(('($label)', body));
  }
  return sections;
}

Widget _insertionPassageContent(Map<String, dynamic> question) {
  final rawPassage = _asText(question['passage'], '');
  final insertionSentence = _extractInsertionSentence(question);
  final body = _insertionBodyText(rawPassage, insertionSentence);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (insertionSentence.isNotEmpty) ...[
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
                    color: _StudentMockExamAttemptDetailScreenState._blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1.55,
                  ),
                ),
                ..._htmlLikeTextSpan(insertionSentence).children ?? [],
              ],
              style: _passageTextStyle(),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
      SelectableText.rich(_htmlLikeTextSpan(body.isEmpty ? rawPassage : body)),
    ],
  );
}

String _extractInsertionSentence(Map<String, dynamic> question) {
  final passage = _asText(question['passage'], '');
  final questionText = _asText(question['question_text'], '');
  final passageParts = passage.split(RegExp(r'\n\s*\n+'));
  if (passageParts.length >= 2 &&
      !_containsInsertionMarkers(passageParts.first)) {
    return passageParts.first.trim();
  }

  final quoted = RegExp(r'["“](.+?)["”]').firstMatch(questionText);
  if (quoted != null) return quoted.group(1)?.trim() ?? '';
  return '';
}

String _insertionBodyText(String passage, String insertionSentence) {
  var body = passage.trim();
  if (insertionSentence.isNotEmpty && body.startsWith(insertionSentence)) {
    body = body.substring(insertionSentence.length).trim();
  }
  body = body.replaceAll(RegExp(r'^\n+'), '').trim();

  if (_containsInsertionMarkers(body)) {
    return body;
  }

  final sentences = body
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  if (sentences.isEmpty) return body;

  final buffer = StringBuffer();
  for (var i = 0; i < sentences.length; i++) {
    if (i < 5) buffer.write('(${_circled(i)}) ');
    buffer.write(sentences[i]);
    if (i != sentences.length - 1) buffer.write(' ');
  }
  return buffer.toString();
}

bool _containsInsertionMarkers(String text) {
  return RegExp(r'[①②③④⑤]|\(\s*[①②③④⑤]\s*\)').hasMatch(text);
}

String _questionPrompt(Map<String, dynamic> question) {
  final questionType = _asText(question['question_type'], '').toLowerCase();
  final text = _asText(question['question_text'], '');
  if (questionType == 'order' && _looksLikeOrderText(text)) {
    return '주어진 글 다음에 이어질 글의 순서로 가장 적절한 것은?';
  }
  if (questionType == 'insertion') {
    return '글의 흐름으로 보아, 주어진 문장이 들어가기에 가장 적절한 곳은?';
  }
  return text;
}

List<String> _displayOptions(String questionType, List<dynamic> options) {
  if (questionType == 'order') {
    const orderChoices = [
      '(A)-(C)-(B)',
      '(B)-(A)-(C)',
      '(B)-(C)-(A)',
      '(C)-(A)-(B)',
      '(C)-(B)-(A)',
    ];
    if (_optionsLookLikeOrderChoices(options)) {
      return options.map((item) => _stripLeadingChoice('$item')).toList();
    }
    return orderChoices;
  }

  if (questionType == 'insertion') {
    return const ['1', '2', '3', '4', '5'];
  }

  return options.map((item) => _stripLeadingChoice('$item')).toList();
}

bool _optionsLookLikeOrderChoices(List<dynamic> options) {
  return options.length == 5 &&
      options.every(
          (item) => RegExp(r'\([ABC]\)-\([ABC]\)-\([ABC]\)').hasMatch('$item'));
}

String _stripLeadingChoice(String text) {
  return text
      .trim()
      .replaceFirst(RegExp(r'^\s*(?:[①②③④⑤]|[1-5][\.\)]?)\s*'), '')
      .trim();
}

TextSpan _htmlLikeTextSpan(String text, {TextStyle? baseStyle}) {
  final style = baseStyle ?? _passageTextStyle();
  final spans = <TextSpan>[];
  final underlinePattern = RegExp(
    r'^<\s*u(?:\s+[^>]*)?>[\s\S]*?<\s*/\s*u\s*>$',
    caseSensitive: false,
  );
  final pattern = RegExp(
    r'(<\s*u(?:\s+[^>]*)?>[\s\S]*?<\s*/\s*u\s*>|[①②③④⑤]|\([ABC]\)|\[Given Text\]|주어진 글)',
    caseSensitive: false,
  );
  var cursor = 0;

  for (final match in pattern.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(
          TextSpan(text: text.substring(cursor, match.start), style: style));
    }

    final token = match.group(0) ?? '';
    final underline = underlinePattern.hasMatch(token);
    final clean = underline
        ? token
            .replaceFirst(
              RegExp(r'^<\s*u(?:\s+[^>]*)?>', caseSensitive: false),
              '',
            )
            .replaceFirst(
              RegExp(r'<\s*/\s*u\s*>$', caseSensitive: false),
              '',
            )
        : token;
    spans.add(
      TextSpan(
        text: clean,
        style: underline
            ? style.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: style.color ??
                    _StudentMockExamAttemptDetailScreenState._ink,
                decorationThickness: 1.5,
              )
            : _markerStyle(token, style),
      ),
    );
    cursor = match.end;
  }

  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: style));
  }

  return TextSpan(children: spans, style: style);
}

TextStyle _markerStyle(String token, TextStyle baseStyle) {
  final isMarker =
      RegExp(r'^[①②③④⑤]$|^\([ABC]\)$|^\[Given Text\]$|^주어진 글$').hasMatch(token);
  if (!isMarker) return baseStyle;
  return baseStyle.copyWith(
    color: token.contains('Given') || token == '주어진 글'
        ? _StudentMockExamAttemptDetailScreenState._blue
        : _StudentMockExamAttemptDetailScreenState._purple,
    fontWeight: FontWeight.w900,
  );
}

TextStyle _passageTextStyle() {
  return const TextStyle(
    color: _StudentMockExamAttemptDetailScreenState._ink,
    fontSize: 16,
    height: 1.7,
    fontWeight: FontWeight.w500,
  );
}

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map<String, dynamic> ? value : const {};

List<dynamic> _asList(dynamic value) => value is List ? value : const [];

String _asText(dynamic value, [String fallback = '-']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString());
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _score(dynamic value) {
  final number = _asDouble(value);
  if (number % 1 == 0) return number.round().toString();
  return number.toStringAsFixed(1);
}

String _choiceLabel(int? index) {
  if (index == null || index < 0 || index > 4) return '미응답';
  return _circled(index);
}

String _circled(int index) {
  const marks = ['①', '②', '③', '④', '⑤'];
  if (index < 0 || index >= marks.length) return '${index + 1}';
  return marks[index];
}

String _formatDateTime(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return '-';
  final local = date.toLocal();
  return '${local.year}.${_two(local.month)}.${_two(local.day)} '
      '${_two(local.hour)}:${_two(local.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
