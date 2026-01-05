import 'package:flutter/material.dart';
import '../../services/admin/admin_charts_service.dart';
import '../../screens/admin/admin_student_summary_screen.dart';

class AdminWeeklyActivityChart extends StatelessWidget {
  final ValueChanged<String>? onWeekSelected; // ✅ 추가

  const AdminWeeklyActivityChart({
    super.key,
    this.onWeekSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<List<dynamic>>(
      future: AdminChartsService.fetchWeeklyActivity(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final maxValue = data
            .map((e) => e['total_attempts'] as int)
            .fold<int>(0, (a, b) => a > b ? a : b);

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
                  '주간 풀이 수',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // 📊 차트 영역
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: data.map((e) {
                      final total = e['total_attempts'] as int;
                      final accuracy = e['accuracy_rate'] as num;
                      final ratio = maxValue == 0 ? 0 : total / maxValue;
                      final week = e['week'].toString();

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // ✅ 막대 클릭 → 학생 요약 (주차 기준)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AdminStudentSummaryScreen(week: week),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // 숫자 표시
                              Text(
                                '$total',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // 막대
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                height: 140.0 * ratio.toDouble(),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: accuracy >= 80
                                      ? cs.primary
                                      : accuracy >= 60
                                          ? Colors.orange
                                          : Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),

                              const SizedBox(height: 6),

                              // 주차 라벨
                              Text(
                                week.substring(5),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // 🎨 정답률 기준 색상 범례
                const Row(
                  children: [
                    _Legend(color: Colors.green, label: '80% 이상'),
                    SizedBox(width: 12),
                    _Legend(color: Colors.orange, label: '60~79%'),
                    SizedBox(width: 12),
                    _Legend(color: Colors.red, label: '60% 미만'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}
