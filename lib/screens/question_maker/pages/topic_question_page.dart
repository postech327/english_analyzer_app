// lib/screens/question_maker/pages/topic_question_page.dart
import 'package:flutter/material.dart';
import 'package:english_analyzer_app/services/question_maker_service.dart';

class TopicQuestionPage extends StatefulWidget {
  const TopicQuestionPage({super.key});

  @override
  State<TopicQuestionPage> createState() => _TopicQuestionPageState();
}

class _TopicQuestionPageState extends State<TopicQuestionPage> {
  final _svc = QmService();
  final _input = TextEditingController(
      text:
          'Paste your passage here. This page generates only TOPIC questions (MCQ).');

  bool _busy = false;
  List<McqItem> _items = [];
  int _itemCount = 3; // 생성할 문항 수 (필요하면 UI로 변경)

  Future<void> _generateTopic() async {
    final txt = _input.text.trim();
    if (txt.isEmpty) return;

    setState(() => _busy = true);
    try {
      // ✅ Topic 전용 호출
      final items = await _svc.generateViaServer(
        type: 'topic',
        passage: txt,
        items: _itemCount,
        extra: {'choices': 5}, // 👈 여기로 이동
      );

      setState(() => _items = items);
    } catch (e) {
      // 서버 실패 시 안전망
      final fb = _svc.fallbackTTGS(
        type: 'topic', // ← 파일별로 'title' / 'summary'로 바꿔서 사용
        passage: txt,
        count: _itemCount, // 또는 1
      );
      setState(() => _items = fb);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버 생성 실패, 대체문항 표시: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('주제(Topic) 문제 생성',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),

        // 입력
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _input,
                  minLines: 6,
                  maxLines: 14,
                  decoration: const InputDecoration(
                    labelText: 'Passage',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('문항 수'),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _itemCount,
                      items: const [1, 2, 3, 4, 5]
                          .map((n) =>
                              DropdownMenuItem(value: n, child: Text('$n')))
                          .toList(),
                      onChanged: _busy
                          ? null
                          : (v) {
                              if (v != null) setState(() => _itemCount = v);
                            },
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _busy ? null : _generateTopic,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.quiz_outlined),
                      label: const Text('주제 문제 생성'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 결과
        if (_items.isEmpty)
          const Text('아직 생성된 문제가 없습니다.')
        else ...[
          for (var i = 0; i < _items.length; i++) ...[
            _mcqCard(i + 1, _items[i], cs),
            const SizedBox(height: 12),
          ]
        ],
      ],
    );
  }

  Widget _mcqCard(int no, McqItem q, ColorScheme cs) {
    String circled(int i) => String.fromCharCode(0x2460 + (i - 1));
    return Card(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('[$no] ${q.stem}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (var i = 0; i < q.options.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                // 서버가 이미 ①②…를 붙여줬다면 그대로 표시, 아니면 붙여서 표시
                q.options[i].startsWith('①') || q.options[i].startsWith('1.')
                    ? q.options[i]
                    : '${circled(i + 1)} ${q.options[i]}',
              ),
            ),
          const SizedBox(height: 6),
          Text('정답: ${circled(q.answerIndex + 1)}'),
          () {
            final exp = (q.meta['explain'] ?? '').toString().trim();
            if (exp.isEmpty) return const SizedBox.shrink();
            return Text('해설: $exp');
          }(),
        ]),
      ),
    );
  }
}
