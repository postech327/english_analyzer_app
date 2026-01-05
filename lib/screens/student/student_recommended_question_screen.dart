import 'package:flutter/material.dart';
import '../../services/student_exam_service.dart';
import 'student_recommended_result_screen.dart';

class StudentRecommendedQuestionScreen extends StatefulWidget {
  final int userId;

  const StudentRecommendedQuestionScreen({
    super.key,
    required this.userId,
  });

  @override
  State<StudentRecommendedQuestionScreen> createState() =>
      _StudentRecommendedQuestionScreenState();
}

class _StudentRecommendedQuestionScreenState
    extends State<StudentRecommendedQuestionScreen> {
  late Future<List<dynamic>> _futureQuestions;

  /// question_id -> selected_index
  final Map<int, int> _answers = {};

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _futureQuestions =
        StudentExamService.fetchRecommendedQuestions(userId: widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('추천 문제 풀기'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureQuestions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('에러: ${snapshot.error}'),
            );
          }

          final questions = snapshot.data ?? [];

          if (questions.isEmpty) {
            return const Center(
              child: Text('추천 문제가 없습니다.'),
            );
          }

          return Column(
            children: [
              // ─────────────────────────
              // 문제 리스트
              // ─────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final q = questions[index];
                    final int qid = q['id'];
                    final List options = q['options'];

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
                              '문제 ${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              q['text'],
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 12),

                            // 보기
                            ...options.map<Widget>((opt) {
                              return RadioListTile<int>(
                                value: opt['index'],
                                groupValue: _answers[qid],
                                title: Text(
                                  '${opt['label']}. ${opt['text']}',
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    _answers[qid] = v!;
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ─────────────────────────
              // 제출 버튼
              // ─────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _submitting
                          ? null
                          : () async {
                              if (_answers.length != questions.length) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('모든 문제에 답을 선택해주세요.'),
                                  ),
                                );
                                return;
                              }

                              setState(() => _submitting = true);

                              try {
                                final result = await StudentExamService
                                    .submitRecommendedAnswers(
                                  userId: widget.userId,
                                  answers: _answers,
                                );

                                if (!mounted) return;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        StudentRecommendedResultScreen(
                                      result: result,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('제출 실패: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _submitting = false);
                                }
                              }
                            },
                      child: _submitting
                          ? const CircularProgressIndicator()
                          : const Text(
                              '채점하기',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
