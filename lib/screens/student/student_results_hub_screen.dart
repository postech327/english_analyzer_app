import 'package:flutter/material.dart';

import '../../widgets/dashboard_feature_card.dart';
import 'integrated_report_screen.dart';
import 'mock_exam_report_screen.dart';
import 'problem_set_results_screen.dart';

class StudentResultsHubScreen extends StatelessWidget {
  const StudentResultsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FC),
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Results',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            const Text(
              '나의 학습 결과',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '내신 문제세트와 모의고사 결과를 구분해서 확인해 보세요.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 720 ? 2 : 1;
                final items = [
                  DashboardFeatureCard(
                    title: 'Problem Set Results',
                    subtitle: '지문 기반 10문제 세트의 점수와 오답을 확인합니다.',
                    icon: Icons.fact_check_rounded,
                    accentColor: const Color(0xFF7C3AED),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProblemSetResultsScreen(),
                        ),
                      );
                    },
                  ),
                  DashboardFeatureCard(
                    title: 'Mock Exam Results',
                    subtitle: '20문항 모의고사 점수, 약점 유형, 오답을 확인합니다.',
                    icon: Icons.stacked_bar_chart_rounded,
                    accentColor: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentMockExamReportScreen(),
                        ),
                      );
                    },
                  ),
                  DashboardFeatureCard(
                    title: 'Integrated Report',
                    subtitle: '내신 대비와 모의고사 대비 결과를 함께 분석합니다.',
                    icon: Icons.query_stats_rounded,
                    accentColor: const Color(0xFF0EA5E9),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IntegratedReportScreen(),
                        ),
                      );
                    },
                  ),
                ];
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: columns == 1 ? 1.85 : 1.3,
                  ),
                  itemBuilder: (context, index) => items[index],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
