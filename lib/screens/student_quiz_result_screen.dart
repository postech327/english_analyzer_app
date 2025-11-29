// lib/screens/student_quiz_result_screen.dart
import 'package:flutter/material.dart';

import '../models/student_models.dart';

class StudentQuizResultScreen extends StatelessWidget {
  final StudentQuestionSet questionSet;
  final Map<int, StudentAnswerCheckResult> results;

  const StudentQuizResultScreen({
    super.key,
    required this.questionSet,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final questions = questionSet.questions;
    final total = questions.length;
    final correct =
        questions.where((q) => results[q.id]?.correct ?? false).length;

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
            if (questionSet.passageTitle != null) ...[
              Text(
                questionSet.passageTitle!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              '총 $total문항 중 $correct문항 정답',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index];
                  final r = results[q.id];
                  final isCorrect = r?.correct ?? false;

                  return ListTile(
                    title: Text(
                      'Q${index + 1}. (${q.questionType})',
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                    subtitle: r == null
                        ? const Text('미응답')
                        : Text(isCorrect ? '정답' : '오답'),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // 결과 화면 닫기
                },
                child: const Text('돌아가기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
