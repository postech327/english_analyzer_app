// lib/screens/teacher_mode.dart
import 'package:flutter/material.dart';

class TeacherModePage extends StatelessWidget {
  const TeacherModePage({super.key});

  // ✅ 실제 라우트 이름과 맞추기
  static const routeParagraph = '/analyzer'; // 문단 분석
  static const routeTopic = '/topic_summary'; // 주제/제목/요지
  static const routeWord = '/word_synonym'; // 단어/유의어
  static const routeExportPpt = '/export_ppt'; // 🆕 통합 PPT 만들기

  void _go(BuildContext context, String route, String fallbackLabel) {
    try {
      Navigator.pushNamed(context, route);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fallbackLabel 화면은 추후 연결 예정입니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('선생님 모드'),
        actions: [
          TextButton.icon(
            onPressed: () {
              // 직접 관리형(관리자) 화면으로 이동
              Navigator.pushNamed(context, '/manage');
              // AppShell의 특정 탭으로 열고 싶으면:
              // Navigator.pushNamed(context, '/app', arguments: 0);
            },
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('관리형'),
          ),
        ],
      ),
      backgroundColor: cs.surface,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 3 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _FeatureCard(
              icon: Icons.article_rounded,
              title: '문단분석',
              onTap: () => _go(context, routeParagraph, '문단분석'),
            ),
            _FeatureCard(
              icon: Icons.track_changes_rounded,
              title: '주제/요지',
              onTap: () => _go(context, routeTopic, '주제/요지'),
            ),
            _FeatureCard(
              icon: Icons.extension_rounded,
              title: '단어/유의어',
              onTap: () => _go(context, routeWord, '단어/유의어'),
            ),
            // 🆕 통합 PPT 만들기
            _FeatureCard(
              icon: Icons.slideshow_rounded,
              title: '통합 PPT 만들기',
              onTap: () => _go(context, routeExportPpt, '통합 PPT'),
            ),
            _FeatureCard(
              icon: Icons.quiz_outlined,
              title: '문제제작',
              onTap: () => Navigator.of(context).pushNamed('/teacher_qm'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _FeatureCard({
    required this.icon,
    required this.title,
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
          color: cs.secondaryContainer.withValues(alpha: 0.4), // ✅ 권장 API
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48),
              const SizedBox(height: 8),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
