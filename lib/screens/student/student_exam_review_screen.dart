// lib/screens/student/student_exam_result_screen.dart
import 'package:flutter/material.dart';

import '../../services/student_exam_service.dart';

class StudentExamResultScreen extends StatefulWidget {
  final int problemSetId;
  final int userId;
  final String title;

  /// submit_exam 직후 결과 (nullable)
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

    // ✅ submit 직후라면 initialResult 사용
    if (widget.initialResult != null) {
      _futureResult = Future.value(widget.initialResult!);
    } else {
      // ✅ 다시 보기 (GET 결과 API)
      _futureResult = StudentExamService.fetchExamResult(
        problemSetId: widget.problemSetId,
        userId: widget.userId,
      );
    }
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('에러: ${snapshot.error}'),
            );
          }

          final result = snapshot.data!;

          final int total = result['total_questions'];
          final int correct = result['correct_count'];
          final double accuracy = (result['accuracy_rate'] as num).toDouble();

          final List wrongAnswers = result['wrong_answers'] ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─────────────────────────
              // 📊 요약 카드
              // ─────────────────────────
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '점수 요약',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('총 문항: $total'),
                      Text('정답: $correct'),
                      Text(
                        '정답률: $accuracy%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ─────────────────────────
              // ❌ 오답 + GPT 해설
              // ─────────────────────────
              if (wrongAnswers.isNotEmpty) ...[
                Text(
                  '오답 해설 (AI)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.error,
                  ),
                ),
                const SizedBox(height: 12),
                ...wrongAnswers.map((w) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '문제 ${w['order']} · ${w['question_type']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.error,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            w['question_text'],
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 12),

                          Text(
                            '❌ 내가 고른 답: ${w['selected_label']}',
                          ),
                          Text(
                            '✅ 정답: ${w['correct_label']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const Divider(height: 24),

                          // GPT 해설
                          Text(
                            'AI 해설',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            w['gpt_explanation'] ?? '해설을 불러올 수 없습니다.',
                            style: const TextStyle(height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ] else ...[
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    '🎉 모든 문제를 맞혔습니다!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
