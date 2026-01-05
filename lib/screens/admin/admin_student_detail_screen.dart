import 'package:flutter/material.dart';

import '../../services/admin_student_service.dart';
import '../../widgets/admin/admin_student_weak_type_card.dart';
import 'admin_exam_preview_screen.dart'; // ✅ 시험지 미리보기 화면

class AdminStudentDetailScreen extends StatelessWidget {
  final int userId;
  final String name;

  const AdminStudentDetailScreen({
    super.key,
    required this.userId,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$name 학생 상세'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: AdminStudentService.fetchStudentHistory(userId),
        builder: (context, snapshot) {
          // ⏳ 로딩
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ 에러
          if (snapshot.hasError) {
            return Center(child: Text('에러: ${snapshot.error}'));
          }

          final data = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─────────────────────────
                // ① 🔥 유형별 약점 분석 (AI 추천)
                // ─────────────────────────
                const Text(
                  '유형별 약점 분석 (AI 추천)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                /// 약점 유형 카드 (이미 구현된 위젯)
                AdminStudentWeakTypeCard(userId: userId),

                const SizedBox(height: 12),

                // ─────────────────────────
                // ② 🔥 약점 기반 시험 생성 + 미리보기
                // ─────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('이 학생 맞춤 시험 생성'),
                    onPressed: () async {
                      try {
                        final result = await AdminStudentService
                            .generateAutoExamForStudent(
                          userId: userId,
                          title: '$name 맞춤 시험지',
                        );

                        final problemSetId = result['problem_set_id'];

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '시험지 생성 완료 (문항 ${result['total_questions']}개)',
                            ),
                          ),
                        );

                        // ✅ 생성 즉시 시험지 미리보기 화면으로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminExamPreviewScreen(
                              problemSetId: problemSetId,
                              title: '$name 맞춤 시험지',
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('시험 생성 실패: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // ─────────────────────────
                // ③ 학생 풀이 이력
                // ─────────────────────────
                const Text(
                  '최근 풀이 기록',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (data.isEmpty)
                  const Text('풀이 기록이 없습니다.')
                else
                  ...data.map((e) {
                    final correct = e['is_correct'] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(
                          correct ? Icons.check_circle : Icons.cancel,
                          color: correct ? Colors.green : Colors.red,
                        ),
                        title: Text(e['question_type']),
                        subtitle: Text(
                          e['created_at'].toString().substring(0, 10),
                        ),
                        trailing: Text(
                          correct ? '정답' : '오답',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: correct ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
