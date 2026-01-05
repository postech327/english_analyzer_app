import 'package:flutter/material.dart';

import '../../services/student_exam_service.dart';
import '../../widgets/student/student_weak_type_card.dart';
import '../../widgets/student/gpt_explanation_card.dart';
import 'student_recommended_question_screen.dart';
import 'student_weak_concept_screen.dart';

class StudentExamResultScreen extends StatefulWidget {
  final int problemSetId;
  final int userId;
  final String title;
  final Map<String, dynamic>? initialResult;

  const StudentExamResultScreen({
    super.key,
    required this.problemSetId,
    required this.userId,
    required this.title,
    this.initialResult,
  });

  @override
  State<StudentExamResultScreen> createState() =>
      _StudentExamResultScreenState();
}

class _StudentExamResultScreenState extends State<StudentExamResultScreen> {
  late Future<Map<String, dynamic>> _futureResult;

  @override
  void initState() {
    super.initState();

    _futureResult = widget.initialResult != null
        ? Future.value(widget.initialResult)
        : StudentExamService.fetchExamResult(
            problemSetId: widget.problemSetId,
            userId: widget.userId,
          );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} · 결과'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureResult,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final result = snapshot.data!;
          final total = result['total_questions'] ?? 0;
          final correct = result['correct_count'] ?? 0;
          final accuracy = (result['accuracy_rate'] as num?)?.toDouble() ?? 0.0;

          final List questions = result['results'] ??
              result['questions'] ??
              result['wrong_answers'] ??
              [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 점수 요약
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('점수',
                          style: TextStyle(
                              color: cs.primary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        '$correct / $total',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '정답률 ${accuracy.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              StudentWeakTypeCard(userId: widget.userId),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.quiz),
                      label: const Text('이 유형 문제 더 풀기'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentRecommendedQuestionScreen(
                              userId: widget.userId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.menu_book),
                      label: const Text('개념 설명 보기'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentWeakConceptScreen(
                              userId: widget.userId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text('문제별 결과',
                  style: TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 12),

              ...questions.map((q) {
                final isCorrect = q['is_correct'] == true;
                final explanationJson = q['gpt_explanation'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      '문제 ${q['order'] ?? ''} · ${q['question_type'] ?? ''}',
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
                      if (q['text'] != null) Text(q['text']),
                      if (!isCorrect && explanationJson != null) ...[
                        const SizedBox(height: 12),
                        GptExplanationCard(
                          explanationJson: explanationJson,
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
