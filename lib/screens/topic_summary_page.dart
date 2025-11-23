// lib/screens/topic_summary_page.dart
import 'package:flutter/material.dart';
import '../services/analyzer_service.dart';
import '../models/analyzer_models.dart';

// ✅ PPT 내보내기
import 'package:english_analyzer_app/config/api.dart'; // ✅ 추가
import 'package:english_analyzer_app/services/export_service.dart'; // 이미 있으면 중복X

class TopicSummaryPage extends StatefulWidget {
  const TopicSummaryPage({super.key});

  @override
  State<TopicSummaryPage> createState() => _TopicSummaryPageState();
}

class _TopicSummaryPageState extends State<TopicSummaryPage> {
  final _svc = AnalyzerService();

  final _input = TextEditingController(
    text:
        'In the wild, a squeaking kitten out in the open is likely to attract predators, which is bad news for any other kittens around it. A rapid rescue of any crying kitten would be a good strategy to prevent them from drawing unwanted attention.',
  );

  bool _busy = false; // 분석/내보내기 공용 스피너
  TopicTitleSummary? _tts;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;

    setState(() => _busy = true);
    try {
      final r = await _svc.analyzeTopicTitleSummary(text);
      setState(() => _tts = r);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('분석 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ✅ 날짜 "YYYY MM DD" 포맷
  String _todayYmd() {
    final t = DateTime.now();
    return '${t.year} ${t.month.toString().padLeft(2, '0')} ${t.day.toString().padLeft(2, '0')}';
  }

  // ✅ PPT 생성 실행 (ExportService 인스턴스 + downloadPpt 호출)
  Future<void> _exportPpt() async {
    if (_tts == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 요지를 추출해 주세요.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final service = ExportService(ApiConfig.baseUrl);

      // 필요하면 passageBracketed 자리에 분석된 괄호 버전 넣기
      await service.downloadPpt(
        passage: _input.text.trim(),
        passageBracketed: null,
        dateStr: _todayYmd(),
        maxWords: 12,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PPT 저장 완료!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PPT 생성 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
      children: [
        Text(
          '파이널터치',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),

        // 입력 카드
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('같은 문단 사용',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: _input,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _run,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lightbulb),
                    label: const Text('요지 추출'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (_tts == null)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('아직 분석 전입니다.'),
          )
        else ...[
          // FLOW CHECK
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionHeader('FLOW CHECK', cs),
                  const SizedBox(height: 8),
                  _flowRow('서론', _flowIntro(_input.text)),
                  const Divider(height: 18),
                  _flowRow('본론', _flowBody(_input.text)),
                  const Divider(height: 18),
                  _flowRow('결론', _flowConclusion(_input.text)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // CONTENTS
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionHeader('CONTENTS', cs),
                  const SizedBox(height: 14),
                  _block(
                      label: '주  제',
                      en: _tts!.topic,
                      ko: _try(_ttsTopicKoFrom(_tts))),
                  _block(
                      label: '제  목',
                      en: _tts!.title,
                      ko: _try(_ttsTitleKoFrom(_tts))),
                  _block(
                      label: '요  지', en: _tts!.gistEn, ko: _try(_tts!.gistKo)),
                  _block(
                      label: '요  약',
                      en: _ttsSummaryEnFrom(_tts),
                      ko: _try(_ttsSummaryKoFrom(_tts))),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 통합 PPT 만들기 카드
          Card(
            elevation: 0,
            color: cs.surfaceContainerHighest.withValues(alpha: .4),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_fill_rounded),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('통합 PPT 만들기',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text(
                          '문단분석 + 주제/제목/요지 + 유의어 ⇒ PPT\n현재 입력한 본문으로 서버에서 자동 분석 후 PPT를 생성합니다.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _busy ? null : _exportPpt,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded),
                    label: const Text('PPT 생성 & 저장'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// --- UI helpers ---
  Widget _sectionHeader(String title, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _flowRow(String label, String text) {
    const titleStyle = TextStyle(fontWeight: FontWeight.w700, fontSize: 15);
    const bodyStyle = TextStyle(fontSize: 14, height: 1.4);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 52, child: Text(label, style: titleStyle)),
        const SizedBox(width: 8),
        Expanded(child: SelectableText(text, style: bodyStyle)),
      ],
    );
  }

  Widget _block(
      {required String label, required String en, required String ko}) {
    const titleStyle = TextStyle(fontWeight: FontWeight.w700, fontSize: 16);
    const enStyle = TextStyle(fontSize: 15, height: 1.4);
    const koStyle = TextStyle(fontSize: 14, height: 1.4, color: Colors.black54);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 56, child: Text(label, style: titleStyle)),
              const SizedBox(width: 10),
              const Expanded(
                  child:
                      Divider(height: 1, thickness: 1, color: Colors.black12)),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(en, style: enStyle),
          const SizedBox(height: 4),
          SelectableText(ko, style: koStyle),
        ],
      ),
    );
  }

  /// --- Data helpers ---
  String _try(String? v) => (v == null || v.trim().isEmpty) ? '—' : v.trim();

  String? _ttsTopicKoFrom(TopicTitleSummary? t) => null; // 추후 서버 값 오면 연동
  String? _ttsTitleKoFrom(TopicTitleSummary? t) => null; // 추후 서버 값 오면 연동
  String _ttsSummaryEnFrom(TopicTitleSummary? t) => t?.gistEn ?? '';
  String? _ttsSummaryKoFrom(TopicTitleSummary? t) => t?.gistKo;

  // 임시 Flow 생성기(서론/본론/결론)
  String _flowIntro(String text) {
    if (text.length < 50) return '도입: 주제 소개(임시 분류).';
    final s = _split(text);
    return s.$1.trim().isEmpty ? '도입 부분이 짧습니다.' : s.$1.trim();
  }

  String _flowBody(String text) {
    final s = _split(text);
    return s.$2.trim().isEmpty ? '전개 부분이 짧습니다.' : s.$2.trim();
  }

  String _flowConclusion(String text) {
    final s = _split(text);
    return s.$3.trim().isEmpty ? '결론 부분이 짧습니다.' : s.$3.trim();
  }

  (String, String, String) _split(String text) {
    final n = text.length;
    final a = (n * 0.33).round();
    final b = (n * 0.66).round();
    return (text.substring(0, a), text.substring(a, b), text.substring(b));
  }
}
