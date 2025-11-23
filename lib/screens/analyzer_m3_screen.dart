// lib/screens/analyzer_m3_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/analyzer_service.dart';
import '../models/analyzer_models.dart';
import '../widgets/colored_spans_text.dart';

enum ViewMode { raw, bracketed, colored }

class AnalyzerM3Screen extends StatefulWidget {
  const AnalyzerM3Screen({super.key});
  @override
  State<AnalyzerM3Screen> createState() => _AnalyzerM3ScreenState();
}

class _AnalyzerM3ScreenState extends State<AnalyzerM3Screen>
    with SingleTickerProviderStateMixin {
  final _svc = AnalyzerService();

  // 입력
  final _paragraph = TextEditingController(
    text:
        'In the wild, a squeaking kitten out in the open is likely to attract predators, which is bad news for any other kittens around it. A rapid rescue of any crying kitten would be a good strategy to prevent them from drawing unwanted attention.',
  );

  // 상태
  bool _busy = false;
  ViewMode _mode = ViewMode.bracketed;
  double _fontSize = 16;
  double _lineHeight = 1.5;

  // 결과
  ParagraphResponse? _para;

  @override
  void dispose() {
    _paragraph.dispose();
    super.dispose();
  }

  Future<void> _runParagraph() async {
    final text = _paragraph.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    try {
      final r = await _svc.analyzeParagraph(text);
      setState(() => _para = r);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('문단 분석 실패: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textStyle = TextStyle(fontSize: _fontSize, height: _lineHeight);

    return Scaffold(
      appBar: AppBar(title: const Text('문단 분석')),
      body: Material(
        color: cs.surface,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _sectionTitle(context, '문단 분석'),
            _inputCard(
              label: '영어 문단 입력',
              child: TextField(
                controller: _paragraph,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              trailing: FilledButton.icon(
                onPressed: _busy ? null : _runParagraph,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_fix_high),
                label: const Text('분석하기'),
              ),
            ),
            const SizedBox(height: 8),

            // 보기 모드
            SegmentedButton<ViewMode>(
              segments: const [
                ButtonSegment(
                    value: ViewMode.raw,
                    icon: Icon(Icons.article),
                    label: Text('원문')),
                ButtonSegment(
                    value: ViewMode.bracketed,
                    icon: Icon(Icons.data_array),
                    label: Text('괄호')),
                ButtonSegment(
                    value: ViewMode.colored,
                    icon: Icon(Icons.palette),
                    label: Text('색상')),
              ],
              selected: <ViewMode>{_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 8),

            // 🔑 Slider가 머티리얼 트리 안에 있도록 Scaffold/Material 아래에 둠
            Row(
              children: [
                const Text('글자'),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 12,
                    max: 28,
                    onChanged: (v) => setState(() => _fontSize = v),
                  ),
                ),
                const Text('간격'),
                Expanded(
                  child: Slider(
                    value: _lineHeight,
                    min: 1.2,
                    max: 2.0,
                    onChanged: (v) => setState(() => _lineHeight = v),
                  ),
                ),
              ],
            ),

            // 범례
            Wrap(
              spacing: 8,
              children: [
                Chip(
                    label: const Text('[ ] 절'),
                    backgroundColor: cs.primaryContainer),
                Chip(
                    label: const Text('( ) 구'),
                    backgroundColor: cs.secondaryContainer),
                Chip(
                    label: const Text('{ } 준동사'),
                    backgroundColor: cs.tertiaryContainer),
              ],
            ),
            const SizedBox(height: 8),

            if (_para == null)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('아직 분석 전입니다.'),
              )
            else ...[
              // 문장별 카드
              ..._para!.sentences.map((s) => _sentenceCard(s, textStyle)),
              const SizedBox(height: 12),
              // 전체
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    _mode == ViewMode.bracketed
                        ? _para!.fullAnalyzed
                        : _para!.fullText,
                    style: textStyle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sentenceCard(SentenceResult s, TextStyle style) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(radius: 12, child: Text('${s.index}')),
              const SizedBox(width: 8),
              Text('Sentence ${s.index}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                tooltip: '복사',
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text: _mode == ViewMode.bracketed ? s.analyzedText : s.text,
                  ));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('복사 완료')));
                },
                icon: const Icon(Icons.copy_rounded),
              ),
            ]),
            const SizedBox(height: 8),
            if (_mode == ViewMode.raw)
              SelectableText(s.text, style: style)
            else if (_mode == ViewMode.bracketed)
              SelectableText(s.analyzedText, style: style)
            else
              ColoredSpansText(text: s.text, spans: s.spans, style: style),
          ],
        ),
      ),
    );
  }

  // 공용 작은 타이틀 + 구분선
  Widget _sectionTitle(BuildContext context, String title) {
    final ts = Theme.of(context).textTheme.titleMedium;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ts?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Divider(height: 1),
        ],
      ),
    );
  }

  // 공용 입력 카드
  Widget _inputCard({
    required String label,
    required Widget child,
    Widget? trailing,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          child,
          if (trailing != null) ...[
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: trailing),
          ],
        ]),
      ),
    );
  }
}
