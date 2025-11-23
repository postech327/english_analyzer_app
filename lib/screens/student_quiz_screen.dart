// lib/screens/student_quiz_screen.dart
import 'package:flutter/material.dart';

import '../models/student_models.dart';
import '../services/student_api.dart';

class StudentQuizScreen extends StatefulWidget {
  final int problemSetId;
  final String? questionType; // 나중에 유형 필터용으로 사용 가능

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
        shuffle: true,
      );

      List<StudentQuestion> filtered = set.questions;
      if (widget.questionType != null) {
        filtered = filtered
            .where((q) => q.questionType == widget.questionType)
            .toList();
      }

      setState(() {
        _set = StudentQuestionSet(
          passageId: set.passageId,
          passageTitle: set.passageTitle,
          passageContent: set.passageContent,
          problemSetId: set.problemSetId,
          questions: filtered,
        );
        _isLoading = false;
        _currentIndex = 0;
        _selectedOptionId = null;
        _lastResult = null;
      });
    } catch (e) {
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

  Future<void> _submitAnswer() async {
    final q = _currentQuestion;
    if (q == null) return;
    if (_selectedOptionId == null) return;

    try {
      final result = await StudentApi.checkAnswer(
        questionId: q.id,
        selectedOptionId: _selectedOptionId!,
      );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('정답 전송 실패: $e')),
      );
    }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 지문
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
        // 문제
        Text(
          'Q${_currentIndex + 1}. (${q.questionType})',
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

        // 보기
        Expanded(
          flex: 3,
          child: ListView(
            children: q.options.map((opt) {
              return ListTile(
                title: Text('${opt.label ?? ''} ${opt.text}'),
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
        // 정답 결과 (있다면)
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

        ElevatedButton(
          onPressed: _submitAnswer,
          child: const Text('정답 제출'),
        ),
      ],
    );
  }
}
