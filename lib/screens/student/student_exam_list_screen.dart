// lib/screens/student/student_exam_list_screen.dart
import 'package:flutter/material.dart';

import '../../services/student_exam_service.dart';
import 'student_exam_take_screen.dart';
import 'student_exam_result_screen.dart';

class StudentExamListScreen extends StatelessWidget {
  final int userId;

  const StudentExamListScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 시험 목록'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: StudentExamService.fetchMyExams(userId: userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('에러: ${snapshot.error}'),
            );
          }

          final exams = snapshot.data ?? [];

          if (exams.isEmpty) {
            return const Center(
              child: Text('배정된 시험이 없습니다.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: exams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final e = exams[index];

              final bool completed = e['is_completed'] == true;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Icon(
                    completed ? Icons.check_circle : Icons.pending_actions,
                    color: completed ? Colors.green : cs.primary,
                  ),
                  title: Text(
                    e['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    completed ? '완료됨 · 결과 보기' : '미응시',
                    style: TextStyle(
                      color: completed
                          ? Colors.green
                          : cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),

                  // 🔥 핵심 분기
                  onTap: () {
                    if (completed) {
                      // ✅ 완료 시험 → 결과 다시 보기
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentExamResultScreen(
                            problemSetId: e['problem_set_id'],
                            userId: userId,
                            title: e['title'],
                          ),
                        ),
                      );
                    } else {
                      // ▶ 미응시 시험 → 시험 풀기
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentExamTakeScreen(
                            userId: userId,
                            problemSetId: e['problem_set_id'],
                            title: e['title'],
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
