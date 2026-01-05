import 'package:flutter/material.dart';

import 'package:english_analyzer_app/services/question_maker_service.dart';
import 'package:english_analyzer_app/services/teacher_problem_set_service.dart';
import 'package:english_analyzer_app/screens/teacher/teacher_problem_set_preview_screen.dart';
import 'package:english_analyzer_app/models/teacher_models.dart';

class OrderQuestionPage extends StatefulWidget {
  const OrderQuestionPage({super.key});

  @override
  State<OrderQuestionPage> createState() => _OrderQuestionPageState();
}

class _OrderQuestionPageState extends State<OrderQuestionPage> {
  final _svc = QmService();
  final _input = TextEditingController();

  bool _busy = false;

  int? _analysisId;
  Map<String, dynamic>? _hub;
  bool _didInitArgs = false;

  final int _itemCount = 1; // 순서는 보통 1문항
  List<McqItem> _items = [];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final id = args['analysisId'];
      _analysisId = (id is int) ? id : int.tryParse(id?.toString() ?? '');

      final text = args['text']?.toString();
      if (text != null && text.trim().isNotEmpty) {
        _input.text = text.trim();
      }

      final hubRaw = args['hub'];
      if (hubRaw is Map) {
        _hub = hubRaw.map((k, v) => MapEntry(k.toString(), v));
      }

      final prefill = args['prefillItems'];
      if (prefill is List && prefill.isNotEmpty) {
        final list = prefill.whereType<McqItem>().toList();
        if (list.isNotEmpty) _items = list;
      }
    }

    _didInitArgs = true;
    setState(() {});
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _generateOrder() async {
    final txt = _input.text.trim();
    if (txt.isEmpty) {
      _toast('지문을 먼저 입력해 주세요.');
      return;
    }

    setState(() => _busy = true);

    try {
      // ✅ 1) 서버 호출
      final items = await _svc.generateViaServer(
        type: 'order',
        passage: txt,
        items: _itemCount,
      );
      setState(() => _items = items);
    } catch (e) {
      // ✅ 2) 서버 실패 시 폴백
      final fb = _svc.fallbackOrder(passage: txt);
      setState(() => _items = fb);
      _toast('서버 생성 실패, 대체문항 표시: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_analysisId == null) {
      _toast('analysisId가 없습니다.');
      return;
    }
    if (_items.isEmpty) {
      _toast('저장할 문항이 없습니다.');
      return;
    }

    try {
      final payloadItems = _items
          .map((q) => q.toSaveJson())
          .toList()
          .cast<Map<String, dynamic>>();

      final problemSetId = await TeacherProblemSetService.saveProblemSet(
        analysisId: _analysisId!,
        questionType: 'order',
        name: 'Order 문제',
        items: payloadItems,
      );

      _toast('저장 완료! (id=$problemSetId)');

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TeacherProblemSetPreviewScreen(problemSetId: problemSetId),
        ),
      );
    } catch (e) {
      _toast('저장 실패: $e');
    }
  }

  Widget _buildOrderCard(McqItem q) {
    final fixed = (q.meta['fixed'] ?? '').toString();
    final a = (q.meta['A'] ?? '').toString();
    final b = (q.meta['B'] ?? '').toString();
    final c = (q.meta['C'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.stem, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (fixed.trim().isNotEmpty) ...[
              const Text('<제시문>',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(fixed),
              const SizedBox(height: 10),
            ],
            if (a.trim().isNotEmpty) ...[
              const Text('(A)', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(a),
              const SizedBox(height: 10),
            ],
            if (b.trim().isNotEmpty) ...[
              const Text('(B)', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(b),
              const SizedBox(height: 10),
            ],
            if (c.trim().isNotEmpty) ...[
              const Text('(C)', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(c),
              const SizedBox(height: 10),
            ],
            const Divider(),
            for (final opt in q.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(opt),
              ),
            const SizedBox(height: 6),
            Text(
              '정답: ${_circled(q.answerIndex + 1)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  String _circled(int i) => String.fromCharCode(0x2460 + (i - 1));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('문단 순서 (ID: ${_analysisId ?? "-"})'),
        actions: [
          IconButton(
            tooltip: '저장',
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('연결된 분석 ID: ${_analysisId ?? "-"}'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Passage',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _input,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '지문을 입력하세요',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                FilledButton.icon(
                  onPressed: _busy ? null : _generateOrder,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: const Text('생성'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('저장'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_items.isEmpty)
              const Text('문항이 없습니다. 상단의 “생성” 버튼을 눌러 주세요.')
            else
              ..._items.map(_buildOrderCard),
          ],
        ),
      ),
    );
  }
}
