// lib/screens/student/student_exam_take_screen.dart
import 'package:flutter/material.dart';

import '../../services/student_exam_service.dart';
import 'student_exam_result_screen.dart';

class StudentExamTakeScreen extends StatefulWidget {
  final int userId;
  final int problemSetId;
  final String title;

  const StudentExamTakeScreen({
    super.key,
    required this.userId,
    required this.problemSetId,
    required this.title,
  });

  @override
  State<StudentExamTakeScreen> createState() => _StudentExamTakeScreenState();
}

class _StudentExamTakeScreenState extends State<StudentExamTakeScreen> {
  late Future<Map<String, dynamic>> _futureExam;

  /// question_id -> selected_index
  final Map<int, int> _answers = {};

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _futureExam = StudentExamService.fetchExamDetail(widget.problemSetId);
  }

  Future<void> _submitExam(
    List questions,
  ) async {
    if (_answers.length != questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 문제에 답을 선택해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final result = await StudentExamService.submitExam(
        problemSetId: widget.problemSetId,
        userId: widget.userId,
        answers: questions.map((q) {
          return {
            'question_id': q['id'],
            'selected_index': _answers[q['id']],
          };
        }).toList(),
      );

      if (!mounted) return;

      // ✅ 시험 결과 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentExamResultScreen(
            problemSetId: widget.problemSetId,
            userId: widget.userId,
            title: widget.title,
            initialResult: result, // ✅ 이것만 넘김 // ⛳ 이후 GET 결과 API에서 채움
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
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureExam,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('에러: ${snapshot.error}'),
            );
          }

          final exam = snapshot.data!;
          final List questions = exam['questions'];

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
                            /// 문제 번호 + 유형
                            Text(
                              '문제 ${q['order']} · ${q['question_type']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(height: 8),

                            /// 문제 본문
                            Text(
                              q['text'],
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),

                            /// 보기
                            ...options.map((opt) {
                              final int idx = opt['index'];

                              return RadioListTile<int>(
                                value: idx,
                                groupValue: _answers[qid],
                                onChanged: (v) {
                                  setState(() {
                                    _answers[qid] = v!;
                                  });
                                },
                                title: Text(
                                  '${opt['label']}. ${opt['text']}',
                                ),
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
                      onPressed:
                          _submitting ? null : () => _submitExam(questions),
                      child: _submitting
                          ? const CircularProgressIndicator()
                          : const Text(
                              '시험 제출',
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
