// lib/screens/question_maker/pages/insertion_question_page.dart
import 'package:flutter/material.dart';
import 'package:english_analyzer_app/services/question_maker_service.dart';

class InsertionQuestionPage extends StatefulWidget {
  const InsertionQuestionPage({super.key});
  @override
  State<InsertionQuestionPage> createState() => _InsertionQuestionPageState();
}

class _InsertionQuestionPageState extends State<InsertionQuestionPage> {
  final _svc = QmService();

  final _input = TextEditingController(
    text:
        'Humans are not the most social animal. Ants, bees, and termites put humanity to shame on many metrics of sociality. '
        'Bees always build hexagonal hives, ants march in lines, and termites move in zigzag formations. '
        'These patterns recur predictably because they are tightly programmed genetically and propelled pheromonally. '
        'We humans are more free and thus more diverse in our social patterns.',
  );

  /// 사용자가 직접 지정할 “삽입할 문장”(선택)
  final _manualInsert = TextEditingController();

  bool _busy = false;
  int _choicesCount = 5; // 서버 옵션 유지용
  List<McqItem> _items = [];

  @override
  void dispose() {
    _input.dispose();
    _manualInsert.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final txt = _input.text.trim();
    if (txt.isEmpty) return;

    final userInsert = _manualInsert.text.trim();
    final hasUserInsert = userInsert.isNotEmpty;

    setState(() => _busy = true);
    try {
      final extra = <String, dynamic>{
        'choices_count': _choicesCount,
        if (hasUserInsert) 'insert_sentence': userInsert,
      };

      final items = await _svc.generateViaServer(
        type: 'insertion',
        passage: txt,
        items: 1,
        extra: extra,
      );
      setState(() => _items = items);
    } catch (e) {
      final fb = _svc.fallbackInsertion(
        passage: txt,
        choicesCount: _choicesCount,
        insertSentence: hasUserInsert ? userInsert : null,
      );
      setState(() => _items = fb);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          '문장 삽입(insertion) 문제 생성',
          style: h.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
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
                  minLines: 5,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    labelText: 'Passage',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // 수동 삽입 문장(선택)
                TextField(
                  controller: _manualInsert,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '삽입할 문장(선택 · 서버 실패 시 대체용)',
                    hintText:
                        '예) We humans are more free and thus more diverse in our social patterns.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    const Text('보기 개수'),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _choicesCount,
                      items: const [5, 6, 7]
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text('$e')))
                          .toList(),
                      onChanged: (v) => setState(() => _choicesCount = v ?? 5),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _busy ? null : _generate,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
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

        if (_items.isEmpty)
          const Text('아직 생성 전입니다.')
        else
          ..._items.map(_insertionCard),
      ],
    );
  }

  /// 결과 카드
  Widget _insertionCard(McqItem q) {
    final insert = (q.meta['insert_sentence'] ?? '').toString();
    final marked = (q.meta['passage_marked'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.stem, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            const Text('삽입할 문장:',
                style: TextStyle(fontWeight: FontWeight.w700)),
            Text(insert),
            const SizedBox(height: 10),
            const Divider(),
            const Text('<지문>'),
            SelectableText(marked),
            const SizedBox(height: 10),
            const Divider(),
            ...List.generate(
              q.options.length,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(q.options[i]),
              ),
            ),
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
