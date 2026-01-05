import 'package:flutter/material.dart';

import '../../services/admin_dashboard_service.dart';
import '../../screens/admin/admin_type_detail_screen.dart';

class AdminAccuracyByTypeCard extends StatelessWidget {
  const AdminAccuracyByTypeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<List<dynamic>>(
      future: AdminDashboardService.fetchAccuracyByType(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;

        if (data.isEmpty) {
          return const Text('유형별 데이터가 없습니다.');
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
                  '유형별 정답률',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),

                /// 유형 리스트
                ...data.map((e) {
                  final String type = e['question_type'];
                  final double accuracy =
                      (e['accuracy_rate'] as num).toDouble();

                  final Color color = accuracy >= 80
                      ? Colors.green
                      : accuracy >= 60
                          ? Colors.orange
                          : Colors.red;

                  return GestureDetector(
                    onTap: () {
                      // ✅ STEP 6-①: 유형 상세 화면 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminTypeDetailScreen(type: type),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// 라벨 행
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                type,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('${accuracy.toStringAsFixed(1)}%'),
                            ],
                          ),
                          const SizedBox(height: 6),

                          /// 진행 바
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: accuracy / 100,
                              minHeight: 10,
                              backgroundColor:
                                  cs.surfaceContainerHighest.withOpacity(0.5),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ],
                      ),
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
