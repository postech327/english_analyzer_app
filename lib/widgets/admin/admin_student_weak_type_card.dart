import 'package:flutter/material.dart';
import '../../services/recommendation_service.dart';

class AdminStudentWeakTypeCard extends StatelessWidget {
  final int userId;

  const AdminStudentWeakTypeCard({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<List<dynamic>>(
      future: RecommendationService.fetchWeakTypes(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;

        if (data.isEmpty) {
          return const Text('📘 약점 유형이 발견되지 않았습니다.');
        }

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📌 추천 학습 유형 (약점)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...data.map((e) {
                  final type = e['question_type'];
                  final accuracy = (e['accuracy_rate'] as num).toDouble();
                  final priority = e['priority'];

                  final color = priority == 'high'
                      ? Colors.red
                      : priority == 'medium'
                          ? Colors.orange
                          : cs.primary;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        // 색상 바
                        Container(
                          width: 6,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '정답률 ${accuracy.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Text(
                          priority == 'high'
                              ? '집중'
                              : priority == 'medium'
                                  ? '보완'
                                  : '양호',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
