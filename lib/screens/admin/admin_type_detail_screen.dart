import 'package:flutter/material.dart';
import '../../services/admin_dashboard_service.dart';

class AdminTypeDetailScreen extends StatelessWidget {
  final String type;

  const AdminTypeDetailScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('유형별 분석 - $type'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: AdminDashboardService.fetchTypeDetail(type),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          if (data.isEmpty) {
            return const Center(child: Text('데이터 없음'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final s = data[index];
              final accuracy = s['accuracy_rate'] as num;

              final color = accuracy >= 80
                  ? Colors.green
                  : accuracy >= 60
                      ? Colors.orange
                      : Colors.red;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Text(
                      s['nickname'][0],
                      style: TextStyle(color: color),
                    ),
                  ),
                  title: Text(s['nickname']),
                  subtitle: Text(
                    '풀이 ${s['total_attempts']} · 정답률 ${accuracy.toStringAsFixed(1)}%',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
