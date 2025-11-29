import 'package:flutter/material.dart';

import '../models/student_models.dart';
import '../services/student_api.dart';

class StudentQuizScreen extends StatefulWidget {
  final int problemSetId;
  final String? questionType; // 지금은 표시용/확장용, 필터에는 사용하지 않음

  const StudentQuizScreen({
    super.key,
    required this.problemSetId,
    this.questionType,
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

  /// 모든 문항의 채점 결과를 모아두는 리스트
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
      // ✅ API 에서 해당 problem_set 의 전체 문항을 받아온다
      final set = await StudentApi.fetchQuestions(
        problemSetId: widget.problemSetId,
        shuffle: true,
      );

      if (!mounted) return;

      setState(() {
        _set = set; // questionType 으로 재필터링하지 않고 그대로 사용
        _isLoading = false;
        _currentIndex = 0;
        _selectedOptionId = null;
        _lastResult = null;
        _allResults.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '문항 로드 실패: $e';
      });
    }
  }

  StudentQuestion? get _currentQuestion {
    if (_set == null || _set!.questions.isEmpty) return null;
    if (_currentIndex < 0 || _currentIndex >= _set!.questions.length) {
      return null;
    }
    return _set!.questions[_currentIndex];
  }

  bool get _isLastQuestion {
    if (_set == null) return true;
    return _currentIndex >= _set!.questions.length - 1;
  }

  Future<void> _submitAnswer() async {
    final q = _currentQuestion;
    if (q == null) return;
    if (_selectedOptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 보기를 선택해 주세요.')),
      );
      return;
    }

    try {
      final result = await StudentApi.checkAnswer(
        questionId: q.id,
        selectedOptionId: _selectedOptionId!,
      );

      if (!mounted) return;

      // 같은 문항의 결과가 이미 있으면 교체
      final existingIndex = _allResults.indexWhere(
        (r) => r.questionId == q.id,
      );
      if (existingIndex >= 0) {
        _allResults[existingIndex] = result;
      } else {
        _allResults.add(result);
      }

      setState(() {
        _lastResult = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.correct ? '정답입니다! 🎉' : '오답입니다 😢',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('정답 전송 실패: $e')),
      );
    }
  }

  void _goNextQuestion() {
    if (_set == null) return;
    if (_currentIndex >= _set!.questions.length - 1) return;

    setState(() {
      _currentIndex++;
      _selectedOptionId = null;
      _lastResult = null;
    });
  }

  void _goToSummary() {
    if (_set == null) return;

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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('학생 퀴즈'),
      ),
      backgroundColor: cs.surface,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_set == null || _set!.questions.isEmpty) {
      return const Center(
        child: Text('불러올 문항이 없습니다.'),
      );
    }

    final q = _currentQuestion!;
    final total = _set!.questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // (1) 지문
        if (_set!.passageTitle != null) ...[
          Text(
            _set!.passageTitle!,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Text(
              _set!.passageContent,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        const Divider(height: 24),

        // (2) 문제
        Text(
          'Q${_currentIndex + 1}/$total. (${q.questionType})',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(q.stem),
        if (q.extraInfo != null) ...[
          const SizedBox(height: 4),
          Text(
            q.extraInfo!,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
        const SizedBox(height: 12),

        // (3) 보기
        Expanded(
          flex: 3,
          child: ListView(
            children: q.options.map((opt) {
              final label = opt.label ?? '';
              final text = opt.text ?? '';

              return ListTile(
                title: Text(
                  text.isEmpty ? label : '$label $text',
                ),
                leading: Radio<int>(
                  value: opt.id,
                  groupValue: _selectedOptionId,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedOptionId = v);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),

        // (4) 정답 결과 표시
        if (_lastResult != null) ...[
          Text(
            _lastResult!.correct ? '✅ 정답!' : '❌ 오답',
            style: TextStyle(
              color: _lastResult!.correct ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_lastResult!.explanation != null) ...[
            const SizedBox(height: 4),
            Text(
              _lastResult!.explanation!,
              style: const TextStyle(fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
        ],

        // (5) 버튼들: [정답 제출]  [다음 문제 / 결과 보기]
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: (_selectedOptionId == null) ? null : _submitAnswer,
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
    );
  }
}

/// 결과 요약 화면
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
    final cs = Theme.of(context).colorScheme;

    final total = questionSet.questions.length;
    final correctCount = results.where((r) => r.correct).length;

    // questionId -> result 맵
    final resultMap = {
      for (final r in results) r.questionId: r,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('결과 요약'),
      ),
      backgroundColor: cs.surface,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              questionSet.passageTitle ?? '자동 생성 지문',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text('총 $total문항 중 $correctCount문항 정답'),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: questionSet.questions.length,
                itemBuilder: (context, index) {
                  final q = questionSet.questions[index];
                  final r = resultMap[q.id];
                  final isCorrect = r?.correct ?? false;

                  return ListTile(
                    title: Text(
                      'Q${index + 1}. (${q.questionType})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(isCorrect ? '정답' : '오답'),
                    trailing: Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
