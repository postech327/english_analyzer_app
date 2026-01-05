import 'package:flutter/material.dart';

import 'package:english_analyzer_app/services/question_maker_service.dart';
import 'package:english_analyzer_app/services/teacher_problem_set_service.dart';
import 'package:english_analyzer_app/screens/teacher/teacher_problem_set_preview_screen.dart';
import 'package:english_analyzer_app/models/teacher_models.dart';

class TopicQuestionPage extends StatefulWidget {
  const TopicQuestionPage({super.key});

  @override
  State<TopicQuestionPage> createState() => _TopicQuestionPageState();
}

class _TopicQuestionPageState extends State<TopicQuestionPage> {
  final _svc = QmService();
  final _input = TextEditingController();

  bool _busy = false;
  bool _saving = false;

  int? _analysisId;
  Map<String, dynamic>? _hub;
  bool _didInitArgs = false;

  int _itemCount = 3;
  List<McqItem> _items = [];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  // ---------------------------
  // ✅ 공통: 옵션 정규화 (①②③ 제거)
  // ---------------------------
  List<String> _normalizeOptions(List<String> raw) {
    return raw
        .map((o) => o.replaceFirst(
              RegExp(r'^[①②③④⑤⑥⑦⑧⑨⑩]\s*'),
              '',
            ))
        .toList();
  }

  // ---------------------------
  // 라우트 args 1회만 읽기
  // ---------------------------
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
      if (prefill is List) {
        final list = prefill.whereType<McqItem>().toList();
        if (list.isNotEmpty) _items = list;
      }
    }

    _didInitArgs = true;
    setState(() {});
  }

  String _hubValue(String key) => _hub?[key]?.toString() ?? '';

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------
  // ✅ 생성
  // ---------------------------
  Future<void> _generate() async {
    final txt = _input.text.trim();
    if (txt.isEmpty) {
      _toast('지문을 먼저 입력해 주세요.');
      return;
    }

    setState(() => _busy = true);

    try {
      final hubTopic = _hubValue('topic').trim();
      if (hubTopic.isNotEmpty) {
        final fixed = _svc.buildFixedTTGS(
          type: 'topic',
          passage: txt,
          correctText: hubTopic,
          count: _itemCount,
          choices: 5,
        );
        setState(() => _items = fixed);
        return;
      }

      final items = await _svc.generateViaServer(
        type: 'topic',
        passage: txt,
        items: _itemCount,
        extra: const {'choices': 5},
      );
      setState(() => _items = items);
    } catch (e) {
      final fb = _svc.fallbackTTGS(
        type: 'topic',
        passage: txt,
        count: _itemCount,
      );
      setState(() => _items = fb);
      _toast('서버 생성 실패, 대체문항 표시: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------
  // ✅ 저장 → 미리보기
  // ---------------------------
  Future<void> _save() async {
    if (_analysisId == null) {
      _toast('analysisId가 없습니다.');
      return;
    }
    if (_items.isEmpty) {
      _toast('저장할 문항이 없습니다.');
      return;
    }

    setState(() => _saving = true);

    try {
      final payloadItems = _items.map((q) {
        final json = Map<String, dynamic>.from(q.toSaveJson());

        // 🔴 핵심 수정 포인트
        json['options'] = _normalizeOptions(
          List<String>.from(json['options']),
        );

        return json;
      }).toList();

      final problemSetId = await TeacherProblemSetService.saveProblemSet(
        analysisId: _analysisId!,
        questionType: 'topic',
        name: 'Topic 문제',
        items: payloadItems,
      );

      _toast('저장 완료! (id=$problemSetId)');

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherProblemSetPreviewScreen(
            problemSetId: problemSetId,
          ),
        ),
      );
    } catch (e) {
      _toast('저장 실패: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _circled(int i) => String.fromCharCode(0x2460 + (i - 1));

  Widget _buildMcqCard(McqItem q) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.stem, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
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

  @override
  Widget build(BuildContext context) {
    final hubTopic = _hubValue('topic').trim();

    return Scaffold(
      appBar: AppBar(
        title: Text('주제 문제 (ID: ${_analysisId ?? "-"})'),
        actions: [
          IconButton(
            tooltip: '저장',
            onPressed: (_busy || _saving) ? null : _save,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('연결된 분석 ID: ${_analysisId ?? "-"}'),
                    const SizedBox(height: 4),
                    Text(
                      hubTopic.isNotEmpty
                          ? '허브 연결: 있음 (정답을 hub.topic로 고정)'
                          : '허브 연결: 없음',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
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
                      maxLines: 8,
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
                const Text('문항 수'),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: _itemCount,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1')),
                    DropdownMenuItem(value: 2, child: Text('2')),
                    DropdownMenuItem(value: 3, child: Text('3')),
                    DropdownMenuItem(value: 5, child: Text('5')),
                  ],
                  onChanged: (_busy || _saving)
                      ? null
                      : (v) => setState(() => _itemCount = v ?? _itemCount),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: (_busy || _saving) ? null : _generate,
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
                  onPressed: (_busy || _saving) ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('저장'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_items.isEmpty)
              const Text('문항이 없습니다. 상단의 “생성” 버튼을 눌러 주세요.')
            else
              ..._items.map(_buildMcqCard),
          ],
        ),
      ),
    );
  }
}
