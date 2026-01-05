// lib/screens/teacher_mode.dart
import 'package:flutter/material.dart';

// 관리자 화면들
import 'package:english_analyzer_app/screens/admin/admin_dashboard_overview_screen.dart';
import 'package:english_analyzer_app/screens/admin/admin_student_summary_screen.dart';
import 'package:english_analyzer_app/screens/admin/admin_exam_auto_generate_screen.dart'; // ⭐ 추가

class TeacherModePage extends StatelessWidget {
  const TeacherModePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('선생님 모드'),
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      backgroundColor: cs.surface,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            // ① 문제 제작
            TeacherModeCard(
              icon: Icons.quiz_outlined,
              title: '문제 제작',
              subtitle: '지문을 넣고 주제·제목·요지·빈칸 등\n각종 문제를 한 번에 생성',
              onTap: () => Navigator.pushNamed(context, '/teacher_qm'),
            ),

            // ② 지문 분석 허브
            TeacherModeCard(
              icon: Icons.description_outlined,
              title: '지문 분석 허브',
              subtitle: '문단 구조 분석 + 주제/요지 + 단어/유의어\n통합 분석 한 곳에서 보기',
              onTap: () => Navigator.pushNamed(context, '/text_analysis_hub'),
            ),

            // ③ 관리자 대시보드
            TeacherModeCard(
              icon: Icons.dashboard_outlined,
              title: '관리자 대시보드',
              subtitle: '전체 학습 현황 · 문제 유형 · 정답률\n관리자 통계 요약',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminDashboardOverviewScreen(),
                  ),
                );
              },
            ),

            // ④ 학생 학습 요약
            TeacherModeCard(
              icon: Icons.analytics_outlined,
              title: '학생 학습 요약',
              subtitle: '학생별 풀이 수 · 정답률 · 학습 수준\n개별 학습 분석',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminStudentSummaryScreen(),
                  ),
                );
              },
            ),

            // ⭐ ⑤ 시험지 자동 생성 (A안 핵심)
            TeacherModeCard(
              icon: Icons.auto_awesome,
              title: '시험지 자동 생성',
              subtitle: '난이도 비율로 문제를 자동 구성\n시험지 즉시 생성',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminExamAutoGenerateScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const TeacherModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 40, color: cs.primary),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurface.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
