// lib/screens/question_maker/pages/summary_question_page.dart
import 'package:flutter/material.dart';
import 'package:english_analyzer_app/services/question_maker_service.dart';

class SummaryQuestionPage extends StatefulWidget {
  const SummaryQuestionPage({super.key});
  @override
  State<SummaryQuestionPage> createState() => _SummaryQuestionPageState();
}

class _SummaryQuestionPageState extends State<SummaryQuestionPage> {
  final _svc = QmService();

  final _input = TextEditingController(
    text: 'While insect colonies follow rigid genetically programmed patterns, '
        'humans show diverse and dynamic social behavior shaped by nurture.',
  );
  bool _busy = false;

  int _itemCount = 3;
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
      // ✅ 요약-AB 전용 타입 호출
      final items = await _svc.generateViaServer(
        type: 'summary_ab',
        passage: txt,
        items: _itemCount,
      );
      setState(() => _items = items);
    } catch (e) {
      // 폴백: 아주 간단한 더미 한 문제
      final dummy = McqItem(
        stem: 'Which of the following best completes the blanks (A) and (B)?',
        options: List.generate(5, (i) => _circled(i + 1)),
        answerIndex: 4,
        meta: {
          'summary':
              'Our visual perception is shaped by relations, which _____(A)_____ our view, unlike the _____(B)_____ camera perspective.',
          'paired': {
            'A': [
              'enhances',
              'simplifies',
              'interrupts',
              'reinforces',
              'interrupts'
            ],
            'B': ['accurate', 'fixed', 'objective', 'neutral', 'inconsistent'],
          },
        },
      );
      setState(() => _items = [dummy, dummy, dummy].take(_itemCount).toList());

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
    final h = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('요약(summary·AB) 문제 생성',
            style: h.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
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
        if (_items.isEmpty)
          const Text('아직 생성 전입니다.')
        else
          ..._items.map(_buildAbCard),
      ],
    );
  }

  Widget _buildAbCard(McqItem q) {
    final meta = q.meta;
    final summary = (meta['summary'] ?? '').toString();
    final paired = (meta['paired'] as Map?)?.cast<String, dynamic>() ?? {};
    final List<dynamic> A = (paired['A'] as List?) ?? const [];
    final List<dynamic> B = (paired['B'] as List?) ?? const [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.stem, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),

            // ⬇️ 상단 요약 박스(빈칸 A/B 포함)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(summary),
            ),

            // ✅ 여기에 힌트 줄 추가 (요약 박스 아래, 보기 나오기 직전)
            const SizedBox(height: 6),
            const Text(
              '· Blank (A) appears in the 1st sentence, (B) in the 2nd.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),

            const SizedBox(height: 12),

            // ⬇️ (A) (B) 제목
            const Row(
              children: [
                Expanded(
                    child: Text('(A)',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                SizedBox(width: 16),
                Expanded(
                    child: Text('(B)',
                        style: TextStyle(fontWeight: FontWeight.w700))),
              ],
            ),
            const SizedBox(height: 6),

            // ⬇️ 좌/우 5행 표기
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: List.generate(
                      A.length,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('${_circled(i + 1)} ${A[i]}'),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: List.generate(
                      B.length,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('${_circled(i + 1)} ${B[i]}'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text('정답: ${q.answerIndex + 1}번'),
          ],
        ),
      ),
    );
  }

  String _circled(int i) => String.fromCharCode(0x2460 + (i - 1));
}
