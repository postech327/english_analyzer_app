// lib/screens/question_maker/pages/order_question_page.dart
import 'package:flutter/material.dart';
import 'package:english_analyzer_app/services/question_maker_service.dart';

class OrderQuestionPage extends StatefulWidget {
  const OrderQuestionPage({super.key});
  @override
  State<OrderQuestionPage> createState() => _OrderQuestionPageState();
}

class _OrderQuestionPageState extends State<OrderQuestionPage> {
  final _svc = QmService();

  final _input = TextEditingController(
      text: 'Cinema and law share the same subjects and audience. '
          'However, there is a crucial distinction: cinema reflects human emotions, whereas law restrains them. '
          'For example, the law seeks to ensure that we are not overwhelmed by our desires and drives. '
          'Therefore, studying their interaction reveals how society both expresses and regulates affect.');
  bool _busy = false;

  int _itemCount = 1; // 보통 1문항
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
        type: 'order',
        passage: txt,
        items: _itemCount,
      );
      setState(() => _items = items);
    } catch (e) {
      final fb = _svc.fallbackOrder(passage: txt);
      setState(() => _items = fb);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('문단 순서(order) 문제 생성',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
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
                Row(
                  children: [
                    const Text('문항 수'),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _itemCount,
                      items: const [1, 2, 3]
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text('$e')))
                          .toList(),
                      onChanged: (v) => setState(() => _itemCount = v ?? 1),
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
        if (_items.isEmpty)
          const Text('아직 생성 전입니다.')
        else
          ..._items.map(_orderCard),
      ],
    );
  }

  Widget _orderCard(McqItem q) {
    final fixed = (q.meta['fixed'] ?? '').toString();
    final a = (q.meta['A'] ?? '').toString();
    final b = (q.meta['B'] ?? '').toString();
    final c = (q.meta['C'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.stem, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            const Text('<제시문>'),
            SelectableText(fixed),
            const SizedBox(height: 6),
            const Text('(A)'),
            SelectableText(a),
            const SizedBox(height: 6),
            const Text('(B)'),
            SelectableText(b),
            const SizedBox(height: 6),
            const Text('(C)'),
            SelectableText(c),
            const SizedBox(height: 10),
            const Divider(),
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
