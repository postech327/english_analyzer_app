import 'package:flutter/material.dart';
import 'package:english_analyzer_app/services/question_maker_service.dart';
import 'package:english_analyzer_app/services/teacher_problem_set_service.dart';
import 'package:english_analyzer_app/models/teacher_models.dart';


// pages
import 'package:english_analyzer_app/screens/question_maker/pages/topic_question_page.dart';
import 'package:english_analyzer_app/screens/question_maker/pages/title_question_page.dart';
import 'package:english_analyzer_app/screens/question_maker/pages/gist_question_page.dart';
import 'package:english_analyzer_app/screens/question_maker/pages/summary_question_page.dart';
import 'package:english_analyzer_app/screens/question_maker/pages/cloze_question_page.dart';
import 'package:english_analyzer_app/screens/question_maker/pages/insertion_question_page.dart';
import 'package:english_analyzer_app/screens/question_maker/pages/order_question_page.dart';

class QuestionMakerHome extends StatefulWidget {
  const QuestionMakerHome({super.key});

  @override
  State<QuestionMakerHome> createState() => _QuestionMakerHomeState();
}

class _QuestionMakerHomeState extends State<QuestionMakerHome> {
  final _textCtrl = TextEditingController();
  final _svc = QmService();

  int? _analysisId;
  Map<String, dynamic>? _hub;
  bool _didInitArgs = false;

  bool _busyAll = false;
  bool _savingAll = false;

  // ✅ 타입별 prefill 저장소 (null 금지)
  final Map<String, List<McqItem>> _prefills = {
    'topic': <McqItem>[],
    'title': <McqItem>[],
    'gist': <McqItem>[],
    'summary': <McqItem>[],
    'cloze': <McqItem>[],
    'insertion': <McqItem>[],
    'order': <McqItem>[],
  };

  @override
  void dispose() {
    _textCtrl.dispose();
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
        _textCtrl.text = text.trim();
      }

      final hubRaw = args['hub'];
      if (hubRaw is Map) {
        _hub = hubRaw.map((k, v) => MapEntry(k.toString(), v));
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

  String _hubString(String key) {
    final v = _hub?[key];
    return (v == null) ? '' : v.toString();
  }

  void _openByType(String type) {
    final page = switch (type) {
      'topic' => const TopicQuestionPage(),
      'title' => const TitleQuestionPage(),
      'gist' => const GistQuestionPage(),
      'summary' => const SummaryQuestionPage(),
      'cloze' => const ClozeQuestionPage(),
      'insertion' => const InsertionQuestionPage(),
      'order' => const OrderQuestionPage(),
      _ => const TopicQuestionPage(),
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => page,
        settings: RouteSettings(
          arguments: {
            'analysisId': _analysisId,
            'text': _textCtrl.text.trim(),
            'hub': _hub,
            'prefillItems': _prefills[type] ?? <McqItem>[],
          },
        ),
      ),
    );
  }

  Future<void> _generateAll() async {
    final passage = _textCtrl.text.trim();
    if (passage.isEmpty) {
      _toast('지문이 비어있어요.');
      return;
    }

    setState(() => _busyAll = true);

    try {
      Future<List<McqItem>> fixedOrServer({
        required String type,
        required String hubKey,
        required int count,
      }) async {
        final hubVal = _hubString(hubKey).trim();
        if (hubVal.isNotEmpty) {
          return _svc.buildFixedTTGS(
            type: type,
            passage: passage,
            correctText: hubVal,
            count: count,
            choices: 5,
          );
        }
        return _svc.generateViaServer(
          type: type,
          passage: passage,
          items: count,
          extra: const {'choices': 5},
        );
      }

      _prefills['topic'] =
          await fixedOrServer(type: 'topic', hubKey: 'topic', count: 3);
      _prefills['title'] =
          await fixedOrServer(type: 'title', hubKey: 'title', count: 3);

      // gist/summary는 허브 키가 gist_en/summary_en일 가능성이 높아서 우선 사용
      _prefills['gist'] =
          await fixedOrServer(type: 'gist', hubKey: 'gist_en', count: 3);
      _prefills['summary'] =
          await fixedOrServer(type: 'summary', hubKey: 'summary_en', count: 3);

      // cloze/insertion/order
      try {
        _prefills['cloze'] = await _svc.generateViaServer(
          type: 'cloze',
          passage: passage,
          items: 3,
        );
      } catch (_) {
        _prefills['cloze'] = _svc.fallbackCloze(passage: passage);
      }

      try {
        _prefills['insertion'] = await _svc.generateViaServer(
          type: 'insertion',
          passage: passage,
          items: 1,
          extra: const {'choices_count': 5},
        );
      } catch (_) {
        _prefills['insertion'] =
            _svc.fallbackInsertion(passage: passage, choicesCount: 5);
      }

      try {
        _prefills['order'] = await _svc.generateViaServer(
          type: 'order',
          passage: passage,
          items: 1,
        );
      } catch (_) {
        _prefills['order'] = _svc.fallbackOrder(passage: passage);
      }

      if (!mounted) return;
      setState(() {});
      _toast('전체 생성 완료!');
      _openByType('topic');
    } catch (e) {
      _toast('전체 생성 실패: $e');
    } finally {
      if (mounted) setState(() => _busyAll = false);
    }
  }

  Future<void> _saveAll() async {
    if (_analysisId == null) {
      _toast('analysisId가 없습니다.');
      return;
    }

    final hasAny = _prefills.values.any((v) => v.isNotEmpty);
    if (!hasAny) {
      _toast('저장할 문항이 없습니다. 먼저 생성해 주세요.');
      return;
    }

    setState(() => _savingAll = true);

    try {
      const names = {
        'topic': '주제 문제',
        'title': '제목 문제',
        'gist': '요지 문제',
        'summary': '요약 문제',
        'cloze': '빈칸 문제',
        'insertion': '삽입 문제',
        'order': '순서 문제',
      };

      for (final entry in _prefills.entries) {
        final type = entry.key;
        final items = entry.value;
        if (items.isEmpty) continue;

        final payloadItems = items
            .map((q) => q.toSaveJson())
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        await TeacherProblemSetService.saveProblemSet(
          analysisId: _analysisId!,
          questionType: type,
          name: names[type] ?? type,
          items: payloadItems,
        );
      }

      _toast('전체 저장 완료!');
    } catch (e) {
      _toast('전체 저장 실패: $e');
    } finally {
      if (mounted) setState(() => _savingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = <({String type, IconData i, String label})>[
      (type: 'topic', i: Icons.flag_circle_outlined, label: '주제'),
      (type: 'title', i: Icons.title, label: '제목'),
      (type: 'gist', i: Icons.lightbulb_outline, label: '요지'),
      (type: 'summary', i: Icons.summarize_outlined, label: '요약'),
      (type: 'cloze', i: Icons.crop_7_5_outlined, label: '빈칸'),
      (type: 'insertion', i: Icons.note_add_outlined, label: '삽입'),
      (type: 'order', i: Icons.format_list_numbered, label: '순서'),
    ];

    final hasText = _textCtrl.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('문제제작')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _analysisId == null
                                ? '분석 ID: 없음'
                                : '분석 ID: $_analysisId',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          tooltip: '지문 비우기',
                          onPressed: () {
                            _textCtrl.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _textCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '문제 제작에 사용할 지문이 여기에 들어옵니다.',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    if (_hub != null) ...[
                      const Divider(height: 18),
                      const Text('허브 값(미리보기)',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      _MiniRow(label: 'topic', value: _hubString('topic')),
                      _MiniRow(label: 'title', value: _hubString('title')),
                      _MiniRow(label: 'gist_en', value: _hubString('gist_en')),
                      _MiniRow(
                          label: 'summary_en', value: _hubString('summary_en')),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: (!hasText || _busyAll || _savingAll)
                                ? null
                                : _generateAll,
                            icon: _busyAll
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.auto_fix_high),
                            label: const Text('전체 생성'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: (_busyAll || _savingAll) ? null : _saveAll,
                          icon: _savingAll
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: const Text('전체 저장'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                children: [
                  for (final c in cards)
                    _QMTile(
                      icon: c.i,
                      label: c.label,
                      generated: (_prefills[c.type]?.isNotEmpty ?? false),
                      onTap: () => _openByType(c.type),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QMTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool generated;

  const _QMTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.generated = false,
  });

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
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 38),
                  const SizedBox(height: 10),
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            if (generated)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: cs.primary.withValues(alpha: .18),
                  ),
                  child: const Text('생성됨',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  final String label;
  final String value;
  const _MiniRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final v = value.trim().isEmpty ? '(없음)' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Text(v, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
