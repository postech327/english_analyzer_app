// lib/screens/question_maker/pages/title_question_page.dart
import 'package:flutter/material.dart';
import 'package:english_analyzer_app/services/question_maker_service.dart';

class TitleQuestionPage extends StatefulWidget {
  const TitleQuestionPage({super.key});
  @override
  State<TitleQuestionPage> createState() => _TitleQuestionPageState();
}

class _TitleQuestionPageState extends State<TitleQuestionPage> {
  final _svc = QmService();

  final _input = TextEditingController(
      text: 'Many people believe that technology isolates individuals, '
          'but it can also connect us in meaningful ways when used thoughtfully.');
  bool _busy = false;

  int _itemCount = 3; // 생성 문항 수
  List<McqItem> _items = [];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final txt = _input.text.trim();
    if (txt.isEmpty) return;

    setState(() => _busy = true);
    try {
      final items = await _svc.generateViaServer(
        type: 'title',
        passage: txt,
        items: _itemCount,
      );
      setState(() => _items = items);
    } catch (e) {
      // 서버 실패 시 대체 생성
      final fb = _svc.fallbackTTGS(
        type: 'title', // ← 파일별로 'title' / 'summary'로 바꿔서 사용
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
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('제목(title) 문제 생성',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),

        // 입력 카드
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _input,
                  minLines: 4,
                  maxLines: 10,
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
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text('$e')))
                          .toList(),
                      onChanged: (v) => setState(() => _itemCount = v ?? 3),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _busy ? null : _generate,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh),
                      label: const Text('생성'),
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
          const Text('아직 생성 전입니다.')
        else
          ..._items.map(_buildMcqCard),
      ],
    );
  }

  Widget _buildMcqCard(McqItem q) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.stem, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 6),
            ...List.generate(
                q.options.length,
                (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(q.options[i]),
                    )),
            const SizedBox(height: 6),
            Text('정답: ${q.answerIndex + 1}번'),
            if (q.meta['explain'] != null &&
                q.meta['explain'].toString().trim().isNotEmpty)
              Text('해설: ${q.meta['explain']}'),
          ],
        ),
      ),
    );
  }
}
