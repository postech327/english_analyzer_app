import 'package:flutter/material.dart';
import 'package:english_analyzer_app/services/student_exam_api.dart';

class RetryQuizScreen extends StatefulWidget {
  final int problemSetId;
  final int userId;

  const RetryQuizScreen({
    super.key,
    required this.problemSetId,
    required this.userId,
  });

  @override
  State<RetryQuizScreen> createState() => _RetryQuizScreenState();
}

class _RetryQuizScreenState extends State<RetryQuizScreen> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _questions = [];
  String _retryType = '';

  /// questionId -> selectedIndex
  final Map<int, int> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await StudentExamApi.fetchRetryQuestions(
        problemSetId: widget.problemSetId,
      );

      if (!mounted) return;
      setState(() {
        _retryType = data['retry_type'];
        _questions = List<Map<String, dynamic>>.from(data['questions']);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EDF6),
      appBar: AppBar(
        title: const Text('오답 다시 풀기'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : _questions.isEmpty
                  ? const Center(child: Text('재도전 문제가 없습니다.'))
                  : _buildQuiz(),
    );
  }

  Widget _buildQuiz() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        /// 🔁 재도전 유형
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '재도전 유형: $_retryType',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        /// ❓ 문제들
        for (int i = 0; i < _questions.length; i++) ...[
          _questionCard(i + 1, _questions[i]),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _questionCard(int no, Map<String, dynamic> q) {
    final int questionId = q['question_id'];
    final int correctIndex = q['correct_index'];
    final List options = q['options'];

    final int? selectedIndex = _selected[questionId];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '[$no] ${q['text']}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            for (final o in options)
              _optionTile(
                questionId: questionId,
                optionIndex: o['index'],
                label: o['label'],
                text: o['text'],
                selectedIndex: selectedIndex,
                correctIndex: correctIndex,
              ),
          ],
        ),
      ),
    );
  }

  /// ===============================
  /// 🅰️ 보기 (즉시 채점 핵심)
  /// ===============================
  Widget _optionTile({
    required int questionId,
    required int optionIndex,
    required String label,
    required String text,
    required int? selectedIndex,
    required int correctIndex,
  }) {
    bool isSelected = selectedIndex == optionIndex;
    bool isCorrect = optionIndex == correctIndex;

    Color color = Colors.black;
    FontWeight weight = FontWeight.normal;

    if (selectedIndex != null) {
      if (isCorrect) {
        color = Colors.green;
        weight = FontWeight.bold;
      } else if (isSelected && !isCorrect) {
        color = Colors.red;
        weight = FontWeight.bold;
      }
    }

    return InkWell(
      onTap: selectedIndex != null
          ? null // ✅ 한 번만 선택
          : () {
              setState(() {
                _selected[questionId] = optionIndex;
              });
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          '$label. $text',
          style: TextStyle(
            color: color,
            fontWeight: weight,
          ),
        ),
      ),
    );
  }
}
