// lib/screens/question_maker/question_maker_home.dart
import 'package:flutter/material.dart';

// 페이지들 임포트
import 'package:english_analyzer_app/screens/question_maker/pages/topic_question_page.dart';
import 'package:english_analyzer_app/screens/question_maker/pages/title_question_page.dart';
import 'package:english_analyzer_app/screens/question_maker/pages/gist_question_page.dart';
import 'package:english_analyzer_app/screens/question_maker/pages/summary_question_page.dart';
import 'package:english_analyzer_app/screens/question_maker/pages/cloze_question_page.dart';
import 'package:english_analyzer_app/screens/question_maker/pages/insertion_question_page.dart';
import 'package:english_analyzer_app/screens/question_maker/pages/order_question_page.dart';

// 공용 카드 위젯
class _QMTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QMTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: .4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 38),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class QuestionMakerHome extends StatelessWidget {
  const QuestionMakerHome({super.key});

  @override
  Widget build(BuildContext context) {
    // 라우트 → 위젯 매핑 (named route 미등록이어도 동작)
    final builders = <String, WidgetBuilder>{
      '/qm/topic': (_) => const TopicQuestionPage(),
      '/qm/title': (_) => const TitleQuestionPage(),
      '/qm/gist': (_) => const GistQuestionPage(),
      '/qm/summary': (_) => const SummaryQuestionPage(),
      '/qm/cloze': (_) => const ClozeQuestionPage(),
      '/qm/insertion': (_) => const InsertionQuestionPage(),
      '/qm/order': (_) => const OrderQuestionPage(),
    };

    // 타일 메타
    final cards = <({IconData i, String label, String route})>[
      (i: Icons.flag_circle_outlined, label: '주제', route: '/qm/topic'),
      (i: Icons.title, label: '제목', route: '/qm/title'),
      (i: Icons.lightbulb_outline, label: '요지', route: '/qm/gist'),
      (i: Icons.summarize_outlined, label: '요약', route: '/qm/summary'),
      (i: Icons.crop_7_5_outlined, label: '빈칸', route: '/qm/cloze'),
      (i: Icons.note_add_outlined, label: '삽입', route: '/qm/insertion'),
      (i: Icons.format_list_numbered, label: '순서', route: '/qm/order'),
    ];

    void go(BuildContext ctx, String route) {
      final builder = builders[route];
      if (builder != null) {
        Navigator.of(ctx).push(MaterialPageRoute(builder: builder));
      } else {
        // (선택) named route가 이미 등록돼 있으면 아래 줄로 교체 가능
        // Navigator.of(ctx).pushNamed(route);
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Route not found: $route')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('문제제작')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          children: [
            for (final c in cards)
              _QMTile(
                icon: c.i,
                label: c.label,
                onTap: () => go(context, c.route),
              ),
          ],
        ),
      ),
    );
  }
}
