import 'package:flutter/material.dart';
import 'package:english_analyzer_app/services/teacher_problem_set_service.dart';

class TeacherProblemSetPreviewScreen extends StatefulWidget {
  final int problemSetId;
  const TeacherProblemSetPreviewScreen({super.key, required this.problemSetId});

  @override
  State<TeacherProblemSetPreviewScreen> createState() =>
      _TeacherProblemSetPreviewScreenState();
}

class _TeacherProblemSetPreviewScreenState
    extends State<TeacherProblemSetPreviewScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = TeacherProblemSetService.fetchProblemSet(widget.problemSetId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('미리보기 (ID: ${widget.problemSetId})'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorBox(message: '불러오기 실패: ${snap.error}');
          }

          final data = snap.data ?? {};
          final passage = (data['passage'] as Map?) ?? {};
          final questions = (data['questions'] as List?) ?? [];

          final passageTitle = (passage['title'] ?? '').toString();
          final passageContent = (passage['content'] ?? '').toString();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _PassageCard(
                title: passageTitle.isEmpty ? '(제목 없음)' : passageTitle,
                content: passageContent,
              ),
              const SizedBox(height: 16),
              Text(
                '문항 (${questions.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...questions.map((q) => _QuestionCard(q: q as Map)),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _PassageCard extends StatelessWidget {
  final String title;
  final String content;
  const _PassageCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('지문', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            SelectableText(
              content.isEmpty ? '(내용 없음)' : content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Map q;
  const _QuestionCard({required this.q});

  @override
  Widget build(BuildContext context) {
    final order = q['order']?.toString() ?? '';
    final text = (q['text'] ?? '').toString();
    final explanation = (q['explanation'] ?? '').toString();
    final options = (q['options'] as List?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('문항 $order', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SelectableText(text),
            const SizedBox(height: 12),
            ...options.map((o) {
              final m = o as Map;
              final label = (m['label'] ?? '').toString();
              final optText = (m['text'] ?? '').toString();
              final isCorrect = (m['is_correct'] == true);

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 26, child: Text(label)),
                    Expanded(
                      child: Text(
                        optText,
                        style: TextStyle(
                          fontWeight: isCorrect ? FontWeight.w700 : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (explanation.trim().isNotEmpty) ...[
              const Divider(height: 18),
              Text('해설', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              SelectableText(explanation),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message),
      ),
    );
  }
}
