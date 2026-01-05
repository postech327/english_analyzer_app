import 'package:flutter/material.dart';

import '../models/student_models.dart';
import '../services/student_api.dart';

class StudentQuizScreen extends StatefulWidget {
  final int problemSetId;

  const StudentQuizScreen({
    super.key,
    required this.problemSetId,
  });

  @override
  State<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends State<StudentQuizScreen> {
  StudentQuestionSet? _set;
  bool _isLoading = false;
  String? _error;

  int _currentIndex = 0;
  int? _selectedOptionId;

  StudentAnswerCheckResult? _lastResult;
  final List<StudentAnswerCheckResult> _allResults = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final set = await StudentApi.fetchQuestions(
        problemSetId: widget.problemSetId,
      );

      if (!mounted) return;

      setState(() {
        _set = set;
        _isLoading = false;
        _currentIndex = 0;
        _selectedOptionId = null;
        _lastResult = null;
        _allResults.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '문항 로드 실패';
      });
    }
  }

  StudentQuestion? get _currentQuestion {
    if (_set == null || _set!.questions.isEmpty) return null;
    return _set!.questions[_currentIndex];
  }

  bool get _isLastQuestion {
    if (_set == null) return true;
    return _currentIndex >= _set!.questions.length - 1;
  }

  Future<void> _submitAnswer() async {
    final q = _currentQuestion;
    if (q == null || _selectedOptionId == null) return;

    try {
      final result = await StudentApi.checkAnswer(
        questionId: q.id,
        selectedOptionId: _selectedOptionId!,
      );

      if (!mounted) return;

      setState(() {
        _lastResult = result;
      });

      final idx = _allResults.indexWhere((r) => r.questionId == q.id);
      if (idx >= 0) {
        _allResults[idx] = result;
      } else {
        _allResults.add(result);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.correct == true ? '정답입니다! 🎉' : '오답입니다 😢'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('정답 확인 실패')),
      );
    }
  }

  void _goNextQuestion() {
    setState(() {
      _currentIndex++;
      _selectedOptionId = null;
      _lastResult = null;
    });
  }

  void _goToSummary() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentQuizResultScreen(
          questionSet: _set!,
          results: _allResults,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }

    if (_set == null || _currentQuestion == null) {
      return const Scaffold(body: Center(child: Text('문항 없음')));
    }

    final q = _currentQuestion!;
    final total = _set!.questions.length;
    final questionType = q.questionType ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('학생 퀴즈')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Q${_currentIndex + 1}/$total (${getQuestionTypeLabel(questionType)})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildQuestionBody(q),
            Expanded(child: _buildOptions(q)),
            if (_lastResult != null && _lastResult!.correct == false)
              _buildWrongExplanation(q),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (_selectedOptionId == null) ? null : _submitAnswer,
                    child: const Text('정답 제출'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_lastResult == null)
                        ? null
                        : (_isLastQuestion ? _goToSummary : _goNextQuestion),
                    child: Text(_isLastQuestion ? '결과 보기' : '다음 문제'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// =========================
  /// 문제 타입별 본문
  /// =========================
  Widget _buildQuestionBody(StudentQuestion q) {
    if (q.questionType == 'summary') {
      return _buildSummaryQuestion(q);
    }
    return _buildDefaultQuestion(q);
  }

  Widget _buildDefaultQuestion(StudentQuestion q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGuideBox(getQuestionGuide(q.questionType ?? '')),
        Text(q.text),
        const SizedBox(height: 12),
      ],
    );
  }

  /// =========================
  /// 🔥 SUMMARY + 색상 강조
  /// =========================
  Widget _buildSummaryQuestion(StudentQuestion q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGuideBox(
          '다음 글을 한 문장으로 요약하려고 한다.\n(A), (B)에 들어갈 말로 가장 적절한 것은?',
          highlight: true,
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildHighlightedText(q.text),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// =========================
  /// 🔥 핵심 요약 키워드 강조
  /// =========================
  Widget _buildHighlightedText(String text) {
    const keywords = [
      'increase',
      'decrease',
      'rise',
      'fall',
      'strengthen',
      'weaken',
      'support',
      'challenge',
      'improve',
      'decline',
      'positive',
      'negative',
      'safe',
      'dangerous',
    ];

    final spans = <TextSpan>[];
    final words = text.split(RegExp(r'(\s+)'));

    for (final word in words) {
      final clean = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      final isKey = keywords.contains(clean);

      spans.add(
        TextSpan(
          text: word,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isKey ? FontWeight.bold : FontWeight.normal,
            color: isKey ? Colors.deepOrange : Colors.black,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  /// =========================
  /// 보기
  /// =========================
  Widget _buildOptions(StudentQuestion q) {
    return ListView(
      children: q.options.map((opt) {
        final optId = opt.id!;
        final isAnswered = _lastResult != null;
        final isSelected = _selectedOptionId == optId;

        final isCorrectOption = isAnswered &&
            _lastResult!.correct == true &&
            optId == _lastResult!.correctOptionId;

        Color? tileColor;
        if (isAnswered) {
          if (isCorrectOption) {
            tileColor = Colors.green.withValues(alpha: 0.15);
          } else if (isSelected && _lastResult!.correct == false) {
            tileColor = Colors.red.withValues(alpha: 0.15);
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            title: Text('${opt.label ?? ''} ${opt.text ?? ''}'),
            leading: Radio<int>(
              value: optId,
              groupValue: _selectedOptionId,
              onChanged: isAnswered
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() => _selectedOptionId = v);
                    },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWrongExplanation(StudentQuestion q) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '선택한 보기는 글 전체의 흐름을 정확히 반영하지 못했습니다.\n(A)-(B)의 의미 관계를 다시 확인해 보세요.',
        style: TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildGuideBox(String text, {bool highlight = false}) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.orange.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }

  String getQuestionTypeLabel(String type) {
    switch (type) {
      case 'topic':
        return '주제';
      case 'title':
        return '제목';
      case 'gist':
        return '요지';
      case 'summary':
        return '요약';
      case 'purpose':
        return '목적';
      default:
        return type;
    }
  }

  String getQuestionGuide(String type) {
    switch (type) {
      case 'topic':
        return '다음 글의 주제로 가장 적절한 것은?';
      case 'title':
        return '다음 글의 제목으로 가장 적절한 것은?';
      case 'gist':
        return '다음 글의 요지로 가장 적절한 것은?';
      case 'purpose':
        return '다음 글의 목적으로 가장 적절한 것은?';
      default:
        return '';
    }
  }
}

/// =======================
/// 결과 요약 화면
/// =======================
class StudentQuizResultScreen extends StatelessWidget {
  final StudentQuestionSet questionSet;
  final List<StudentAnswerCheckResult> results;

  const StudentQuizResultScreen({
    super.key,
    required this.questionSet,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final total = questionSet.questions.length;
    final correctCount = results.where((r) => r.correct == true).length;

    return Scaffold(
      appBar: AppBar(title: const Text('결과 요약')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('총 $total문항 중 $correctCount문항 정답'),
      ),
    );
  }
}
