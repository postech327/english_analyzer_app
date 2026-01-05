import 'package:flutter/material.dart';

import '../../services/admin_exam_service.dart';

class AdminExamPreviewScreen extends StatelessWidget {
  final int problemSetId;
  final String title;
  final int? userId; // 배정 대상 학생 (있으면 배정 버튼 활성화)

  const AdminExamPreviewScreen({
    super.key,
    required this.problemSetId,
    required this.title,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('시험지 미리보기'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: AdminExamService.fetchExamDetail(problemSetId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('에러: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final questions = data['questions'] as List<dynamic>;

          return Column(
            children: [
              // ─────────────────────────
              // ① 시험 정보 헤더
              // ─────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '총 문항 수: ${questions.length}문항',
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ─────────────────────────
              // ② 문항 미리보기 리스트
              // ─────────────────────────
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: questions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final q = questions[index];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Q${index + 1}. ${q['question_type']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(q['text']),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ─────────────────────────
              // ③ 학생에게 시험 배정 버튼
              // ─────────────────────────
              if (userId != null)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('이 학생에게 시험 배정'),
                      onPressed: () async {
                        try {
                          await AdminExamService.assignExamToStudent(
                            problemSetId: problemSetId,
                            userId: userId!,
                          );

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('시험지가 학생에게 배정되었습니다'),
                            ),
                          );

                          Navigator.pop(context); // 미리보기 종료
                        } catch (e) {
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('배정 실패: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
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
