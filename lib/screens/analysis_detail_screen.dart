// lib/screens/analysis_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/analysis_record_model.dart';
import '../services/analyzer_service.dart';

class AnalysisDetailScreen extends StatefulWidget {
  const AnalysisDetailScreen({super.key});

  @override
  State<AnalysisDetailScreen> createState() => _AnalysisDetailScreenState();
}

class _AnalysisDetailScreenState extends State<AnalysisDetailScreen> {
  final _service = AnalyzerService();

  bool _loading = true;
  String? _error;

  AnalysisRecord? _record;

  int? _id;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // arguments: {'id': 30} or 30
    final args = ModalRoute.of(context)?.settings.arguments;
    if (_id == null) {
      if (args is int) _id = args;
      if (args is Map && args['id'] != null) {
        final v = args['id'];
        _id = v is int ? v : int.tryParse(v.toString());
      }
      _load();
    }
  }

  Future<void> _load() async {
    if (_id == null) return;

    setState(() {
      _loading = true;
      _error = null;
      _record = null;
    });

    try {
      final r = await _service.fetchAnalysisById(_id!);
      if (!mounted) return;
      setState(() => _record = r);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '불러오기 실패: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _copy(String text, {String label = '복사'}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label 완료')),
    );
  }

  Map<String, dynamic>? _tryParseJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  Widget _section({
    required String title,
    required String body,
    VoidCallback? onCopy,
    IconData copyIcon = Icons.copy,
  }) {
    return Card(
      elevation: 1,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (onCopy != null)
                  IconButton(
                    tooltip: '복사',
                    onPressed: onCopy,
                    icon: Icon(copyIcon),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            BracketColorText(
              body.isEmpty ? '(비어있음)' : body,
              style: const TextStyle(height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EDF6),
      appBar: AppBar(
        title: Text(_id == null ? '분석 상세' : '분석 상세 (ID: $_id)'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                )
              : _record == null
                  ? const Center(child: Text('데이터가 없습니다.'))
                  : _buildDetail(_record!),
    );
  }

  Widget _buildDetail(AnalysisRecord r) {
    final parsed =
        (r.resultJson.isNotEmpty) ? _tryParseJson(r.resultJson) : null;

    // text_hub 계열이면 보기 좋게 key를 뽑아서 섹션화
    final topic = parsed?['topic']?.toString() ?? '';
    final title = parsed?['title']?.toString() ?? '';
    final gistEn = parsed?['gist_en']?.toString() ?? '';
    final gistKo = parsed?['gist_ko']?.toString() ?? '';
    final summaryEn = parsed?['summary_en']?.toString() ?? '';
    final summaryKo = parsed?['summary_ko']?.toString() ?? '';

    final isHubLike = topic.isNotEmpty ||
        title.isNotEmpty ||
        gistEn.isNotEmpty ||
        gistKo.isNotEmpty ||
        summaryEn.isNotEmpty ||
        summaryKo.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // 헤더 카드
        Card(
          elevation: 1,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID: ${r.id}  •  kind: ${r.kind}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text('created_at: ${r.createdAt}'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _copy(r.inputText, label: 'input_text 복사'),
                        icon: const Icon(Icons.copy),
                        label: const Text('input 복사'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _copy(r.resultText, label: 'result_text 복사'),
                        icon: const Icon(Icons.copy),
                        label: const Text('result 복사'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _copy(r.resultJson, label: 'result_json 복사'),
                        icon: const Icon(Icons.data_object),
                        label: const Text('json 복사'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pushNamed(
                        '/text_analysis_hub',
                        arguments: {
                          'prefillText': r.inputText,
                          'analysisId': r.id,
                          // 필요하면 탭도 지정 가능: 0/1/2
                          // 'tabIndex': 0,
                        },
                      );
                    },
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('허브로 불러오기'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        _section(
          title: 'input_text',
          body: r.inputText,
          onCopy: () => _copy(r.inputText, label: 'input_text 복사'),
        ),

        const SizedBox(height: 10),

        // Hub처럼 파싱되면 섹션화해서 보여주고, 아니면 result_text 원문만
        if (isHubLike) ...[
          _section(title: 'Topic', body: topic),
          const SizedBox(height: 10),
          _section(title: 'Title', body: title),
          const SizedBox(height: 10),
          _section(title: 'Gist (EN)', body: gistEn),
          const SizedBox(height: 10),
          _section(title: 'Gist (KO)', body: gistKo),
          const SizedBox(height: 10),
          _section(title: 'Summary (EN)', body: summaryEn),
          const SizedBox(height: 10),
          _section(title: 'Summary (KO)', body: summaryKo),
          const SizedBox(height: 10),
          _section(
            title: 'result_text (raw)',
            body: r.resultText,
            onCopy: () => _copy(r.resultText, label: 'result_text 복사'),
          ),
        ] else ...[
          _section(
            title: 'result_text',
            body: r.resultText,
            onCopy: () => _copy(r.resultText, label: 'result_text 복사'),
          ),
        ],

        const SizedBox(height: 10),

        _section(
          title: 'result_json (string)',
          body: r.resultJson,
          onCopy: () => _copy(r.resultJson, label: 'result_json 복사'),
          copyIcon: Icons.data_object,
        ),
      ],
    );
  }
}

class BracketColorText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const BracketColorText(this.text, {super.key, this.style});

  Color _colorFor(String open) {
    switch (open) {
      case '[':
        return Colors.blue;
      case '(':
        return Colors.orange;
      case '{':
        return Colors.green;
      default:
        return Colors.black;
    }
  }

  String? _matchingOpen(String ch) {
    if (ch == ']') return '[';
    if (ch == ')') return '(';
    if (ch == '}') return '{';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final spans = <TextSpan>[];

    final stack = <String>[]; // '[', '(', '{'
    final buf = StringBuffer();

    void flushBuf() {
      if (buf.isEmpty) return;
      final currentOpen = stack.isNotEmpty ? stack.last : null;
      final color = currentOpen != null ? _colorFor(currentOpen) : base.color;
      spans.add(
          TextSpan(text: buf.toString(), style: base.copyWith(color: color)));
      buf.clear();
    }

    for (int i = 0; i < text.length; i++) {
      final ch = text[i];

      if (ch == '[' || ch == '(' || ch == '{') {
        flushBuf();
        stack.add(ch);
        spans.add(TextSpan(
            text: ch,
            style: base.copyWith(
                color: _colorFor(ch), fontWeight: FontWeight.w700)));
        continue;
      }

      final open = _matchingOpen(ch);
      if (open != null) {
        flushBuf();
        // 스택 정리(대략적인 방어)
        if (stack.isNotEmpty && stack.last == open) {
          stack.removeLast();
        } else if (stack.contains(open)) {
          while (stack.isNotEmpty && stack.last != open) {
            stack.removeLast();
          }
          if (stack.isNotEmpty) stack.removeLast();
        }
        spans.add(TextSpan(
            text: ch,
            style: base.copyWith(
                color: _colorFor(open), fontWeight: FontWeight.w700)));
        continue;
      }

      buf.write(ch);
    }
    flushBuf();

    return SelectableText.rich(TextSpan(children: spans));
  }
}
