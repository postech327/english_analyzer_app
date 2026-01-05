import 'package:flutter/material.dart';
import '../../services/admin_student_service.dart';
import 'admin_student_detail_screen.dart';

class AdminStudentSummaryScreen extends StatelessWidget {
  final String? week; // ex) "2024-12"
  final int? days; // ex) 7

  const AdminStudentSummaryScreen({
    super.key,
    this.week,
    this.days,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          week != null
              ? '학생 학습 요약 ($week)'
              : days != null
                  ? '최근 $days일 학생 요약'
                  : '학생 학습 요약',
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: AdminStudentService.fetchStudentSummary(
          week: week,
          days: days,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('에러: ${snapshot.error}'));
          }

          final students = snapshot.data!;

          if (students.isEmpty) {
            return const Center(child: Text('학생 데이터가 없습니다.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final s = students[index];

              final int userId = s['user_id'];
              final String name = s['name'];
              final int total = s['total_attempts'];
              final double accuracy = (s['accuracy_rate'] as num).toDouble();

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(name.isNotEmpty ? name[0] : '?'),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '풀이 $total · 정답률 ${accuracy.toStringAsFixed(1)}%',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // ✅ STEP 6-② 핵심 연결
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminStudentDetailScreen(
                          userId: userId,
                          name: name,
                        ),
                      ),
                    );
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
