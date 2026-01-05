import 'package:flutter/material.dart';

import '../../services/admin_dashboard_service.dart';
import '../../widgets/admin/admin_weekly_activity_chart.dart';
import '../../widgets/admin/admin_accuracy_by_type_card.dart';

class AdminDashboardOverviewScreen extends StatelessWidget {
  const AdminDashboardOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('관리자 대시보드')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: AdminDashboardService.fetchOverview(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('에러 발생: ${snapshot.error}'));
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔢 통계 카드
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StatCard(
                      title: '학생 수',
                      value: '${data['total_students']}명',
                      icon: Icons.people_outline,
                      color: cs.primary,
                    ),
                    _StatCard(
                      title: '총 풀이 수',
                      value: '${data['total_answers']}',
                      icon: Icons.quiz_outlined,
                      color: cs.secondary,
                    ),
                    _StatCard(
                      title: '평균 정답률',
                      value: '${data['average_accuracy']}%',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    const _StatCard(
                      title: '선택 주차',
                      value: '전체',
                      icon: Icons.calendar_today,
                      color: Colors.orange,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /// 📊 주간 활동 추이
                const Text(
                  '주간 활동 추이',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const SizedBox(
                  height: 260,
                  child: AdminWeeklyActivityChart(),
                ),

                const SizedBox(height: 32),

                /// 📊 유형별 정답률
                const Text(
                  '유형별 정답률',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const AdminAccuracyByTypeCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ─────────────────────────────
/// 🔹 Stat Card
/// ─────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surfaceContainerHighest.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
