import 'package:flutter/material.dart';

import '../models/student_models.dart';
import '../services/student_api.dart';
import 'student_quiz_result_screen.dart';

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

  int? _selectedOptionId; // 🔥 서버용 (option_id)
  int? _selectedOptionIndex; // 🔥 UI용 (index)

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
      });
    } catch (e) {
      print("❌ 문제 로드 실패: $e");

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

  // =========================
  // 🔥 정답 제출 (최종)
  // =========================
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

      setState(() {});

      final idx = _allResults.indexWhere((r) => r.questionId == q.id);

      if (idx >= 0) {
        _allResults[idx] = result;
      } else {
        _allResults.add(result);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.correct ? '정답입니다! 🎉' : '오답입니다 😢',
          ),
        ),
      );
    } catch (e) {
      print("❌ 제출 에러: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('정답 확인 실패')),
      );
    }
  }

  void _goNextQuestion() {
    setState(() {
      _currentIndex++;
      _selectedOptionId = null;
      _selectedOptionIndex = null;
    });
  }

  void _goToSummary() {
    if (_set == null) return;

    Navigator.push(
      context,
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
      return Scaffold(
        body: Center(child: Text(_error!)),
      );
    }

    if (_set == null || _currentQuestion == null) {
      return const Scaffold(
        body: Center(child: Text('문항 없음')),
      );
    }

    final q = _currentQuestion!;
    final total = _set!.questions.length;

    return Scaffold(
      appBar: AppBar(title: const Text('시험 응시')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📘 지문
            if (_set!.passageContent != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_set!.passageContent!),
              ),

            // 📊 문제 번호
            Text('Q${_currentIndex + 1} / $total'),

            const SizedBox(height: 10),

            // ❓ 문제
            Text(
              q.text,
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            // 🔘 선택지
            Expanded(
              child: ListView.builder(
                itemCount: q.options.length,
                itemBuilder: (context, index) {
                  final opt = q.options[index];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedOptionIndex = index;
                        _selectedOptionId = opt.id;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _selectedOptionIndex == index
                            ? Colors.blue.shade100
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedOptionIndex == index
                              ? Colors.blue
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(opt.label ?? ''),
                          const SizedBox(width: 10),
                          Expanded(child: Text(opt.text ?? '')),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 🔥 제출 버튼
            ElevatedButton(
              onPressed: _submitAnswer,
              child: const Text("정답 제출"),
            ),

            const SizedBox(height: 10),

            // ▶ 다음 / 결과
            ElevatedButton(
              onPressed: _isLastQuestion ? _goToSummary : _goNextQuestion,
              child: Text(_isLastQuestion ? "결과 보기" : "다음 문제"),
            )
          ],
        ),
      ),
    );
  }
}
