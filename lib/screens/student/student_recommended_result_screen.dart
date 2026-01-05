import 'package:flutter/material.dart';

class StudentRecommendedResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const StudentRecommendedResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final List questions = result['questions'] ?? [];
    final int total = result['total_questions'] ?? questions.length;
    final int correct = result['correct_count'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('추천 문제 결과'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─────────────────────────
          // 결과 요약
          // ─────────────────────────
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    '결과 요약',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$correct / $total',
                    style: const TextStyle(fontSize: 28),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ─────────────────────────
          // 문제별 결과 + GPT 해설
          // ─────────────────────────
          ...questions.map((q) {
            final bool isCorrect = q['is_correct'] == true;
            final String? explanation = q['gpt_explanation'];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ExpansionTile(
                leading: Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
                title: Text(
                  q['text'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isCorrect ? '정답' : '오답',
                  style: TextStyle(
                    color: isCorrect ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  if (!isCorrect && explanation != null) ...[
                    Divider(color: cs.outline.withOpacity(0.4)),
                    const SizedBox(height: 8),
                    Text(
                      'GPT 오답 해설',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      explanation,
                      style: const TextStyle(height: 1.5),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
