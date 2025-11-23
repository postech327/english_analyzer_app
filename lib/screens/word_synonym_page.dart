// lib/screens/word_synonym_page.dart
import 'package:flutter/material.dart';
import '../services/analyzer_service.dart';

class WordSynonymPage extends StatefulWidget {
  const WordSynonymPage({super.key});

  @override
  State<WordSynonymPage> createState() => _WordSynonymPageState();
}

class _WordSynonymPageState extends State<WordSynonymPage> {
  final _svc = AnalyzerService();

  // ① 유의어 생성
  final _synInput = TextEditingController(text: 'happy, pen, finished');
  String _synResult = '';
  bool _busySyn = false;

  // ② 단어예문 생성 (MCQ)
  final _mcqInput = TextEditingController(text: 'disrupt');
  String _mcqResult = '';
  bool _busyMcq = false;

  @override
  void dispose() {
    _synInput.dispose();
    _mcqInput.dispose();
    super.dispose();
  }

  Future<void> _runSynonyms() async {
    final list = _synInput.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (list.isEmpty) return;

    setState(() => _busySyn = true);
    try {
      final r = await _svc.wordSynonyms(list);
      setState(() => _synResult = r.text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('유의어 생성 실패: $e')));
    } finally {
      if (mounted) setState(() => _busySyn = false);
    }
  }

  Future<void> _runMcq() async {
    final w = _mcqInput.text.trim();
    if (w.isEmpty) return;

    setState(() => _busyMcq = true);
    try {
      final text = await _svc.generateWordMcq(w); // /word-mcq 호출
      setState(() => _mcqResult = text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('단어예문 생성 실패: $e')));
    } finally {
      if (mounted) setState(() => _busyMcq = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
      children: [
        // 페이지 타이틀
        Text('단어/유의어',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),

        // ① 유의어 생성
        _sectionCard(
          title: '1. 유의어 생성',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _synInput,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'happy, pen, finished',
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _busySyn ? null : _runSynonyms,
                  icon: _busySyn
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.playlist_add_check),
                  label: const Text('단어 분석'),
                ),
              ),
              const SizedBox(height: 8),
              _resultBox(_synResult.isEmpty ? '결과 없음' : _synResult),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ② 단어예문 생성 (MCQ)
        _sectionCard(
          title: '2. 단어예문 생성',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _mcqInput,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '예: disrupt',
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _busyMcq ? null : _runMcq,
                  icon: _busyMcq
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.text_snippet_outlined),
                  label: const Text('예문+객관식 생성'),
                ),
              ),
              const SizedBox(height: 8),
              _resultBox(
                _mcqResult.isEmpty ? '아직 생성 전입니다.' : _mcqResult,
                selectable: true, // 문제는 복사할 수 있게
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 공용 UI 조각들
  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _resultBox(String text, {bool selectable = false}) {
    final content = selectable ? SelectableText(text) : Text(text);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(.6),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: content,
    );
  }
}
