import 'package:flutter/material.dart';
import 'package:english_analyzer_app/services/question_maker_service.dart';

class ClozeQuestionPage extends StatefulWidget {
  const ClozeQuestionPage({super.key});
  @override
  State<ClozeQuestionPage> createState() => _ClozeQuestionPageState();
}

class _ClozeQuestionPageState extends State<ClozeQuestionPage> {
  final _svc = QmService();

  final _input = TextEditingController(
    text:
        'To build better habits, start small, repeat often, and track your progress daily.',
  );

  // ✅ 선생님이 “정답(서버 실패시 대체용)”을 직접 적는 입력
  final _manualAnswer = TextEditingController(); // 비우면 자동 선택

  bool _busy = false;
  int _itemCount = 3; // 생성 문항 수(보통 1~3)
  List<McqItem> _items = [];

  @override
  void dispose() {
    _input.dispose();
    _manualAnswer.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final passage = _input.text.trim();
    if (passage.isEmpty) return;

    final userAnswer = _manualAnswer.text.trim();
    final hasUserAnswer = userAnswer.isNotEmpty;

    setState(() => _busy = true);
    try {
      // 서버 사용 시: 정답을 함께 전달(없으면 서버가 알아서 추출)
      final items = await _svc.generateViaServer(
        type: 'cloze',
        passage: passage,
        items: _itemCount,
        extra: {
          if (hasUserAnswer) 'answer_text': userAnswer,
        },
      );
      setState(() => _items = items);
    } catch (e) {
      // 서버 실패: 로컬 폴백 — 정답이 있으면 그걸로, 없으면 자동 추출 + 빈칸 삽입
      final fb = _svc.fallbackCloze(
        passage: passage,
        answerText: hasUserAnswer ? userAnswer : null,
      );
      setState(() => _items = fb);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버 실패, 폴백 문항 표시: $e')),
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
        Text(
          '빈칸(cloze) 문제 생성',
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
                  minLines: 4,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: 'Passage',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ 정답(서버 실패시 대체용) — 비워두면 자동 추출
                TextField(
                  controller: _manualAnswer,
                  minLines: 1,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '정답(서버 실패 시 대체용)',
                    hintText: '예) start small',
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
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text('$e'),
                            ),
                          )
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
          ..._items.map(_buildClozeCard),
      ],
    );
  }

  /// ✅ 빈칸 표시를 항상 '__________' 형태로 통일하는 헬퍼
  String _normalizeBlank(String s) {
    var t = s;

    // __(  )__ 형태 → 긴 밑줄
    t = t.replaceAll(RegExp(r'__\(\s*\)__'), '__________');

    // ( ) 또는 (   ) 형태 → 긴 밑줄
    t = t.replaceAll('(   )', '__________');
    t = t.replaceAll('(  )', '__________');
    t = t.replaceAll('( )', '__________');

    // 여러 개의 _ 이 연속된 경우도 전부 정리
    t = t.replaceAll(RegExp(r'_+'), '__________');

    return t;
  }

  Widget _buildClozeCard(McqItem q) {
    final rawMarked = (q.meta['passage_marked'] ?? '').toString();
    final marked = _normalizeBlank(rawMarked);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              q.stem,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),

            // ⬇️ 빈칸이 들어간 본문 보여주기
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(marked.isEmpty ? '(본문 없음)' : marked),
            ),
            const SizedBox(height: 12),
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
