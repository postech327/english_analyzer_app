import 'package:flutter/material.dart';

import '../services/analyzer_service.dart';
import '../models/analyzer_models.dart';

class TextAnalysisHubScreen extends StatefulWidget {
  const TextAnalysisHubScreen({super.key});

  @override
  State<TextAnalysisHubScreen> createState() => _TextAnalysisHubScreenState();
}

class _TextAnalysisHubScreenState extends State<TextAnalysisHubScreen> {
  final _inputController = TextEditingController();
  final _service = AnalyzerService();

  TextAnalysisHubResult? _hubResult;
  bool _loading = false;
  String? _error;

  int? _lastAnalysisId;

  int _tabIndex = 0;
  double _fontSize = 16;
  double _lineHeight = 1.4;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  bool _didPrefill = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didPrefill) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map) {
      // 1) 입력칸 자동 채우기
      final prefill = args['prefillText']?.toString();
      if (prefill != null && prefill.trim().isNotEmpty) {
        _inputController.text = prefill;
      }

      // 2) 마지막 저장 ID 세팅(문제 만들기 버튼용)
      final id = args['analysisId'];
      final parsedId = (id is int) ? id : int.tryParse(id?.toString() ?? '');
      if (parsedId != null) {
        _lastAnalysisId = parsedId;
      }

      // 3) (선택) 탭 이동: 0/1/2
      final tab = args['tabIndex'];
      final tabIndex = (tab is int) ? tab : int.tryParse(tab?.toString() ?? '');
      if (tabIndex != null && tabIndex >= 0 && tabIndex <= 2) {
        _tabIndex = tabIndex;
      }
    }

    _didPrefill = true;

    // 화면에 반영
    setState(() {});
  }

  Future<void> _performAnalyzeAndSave() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = '지문을 먼저 입력해 주세요.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _lastAnalysisId = null;
    });

    try {
      // 1) 허브 분석
      final hub = await _service.analyzeTextAnalysisHub(text);

      setState(() {
        _hubResult = hub;
      });

      // 2) /analyses 저장 후 id 받기
      final int analysisId = await _service.saveTextAnalysisHubToAnalyses(
        inputText: text,
        hub: hub,
      );

      if (!mounted) return;

      setState(() {
        _lastAnalysisId = analysisId;
      });

      // ✅ 저장 완료 스낵바 + "바로 보기"
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('지문 분석 및 저장 완료! (ID: $analysisId)'),
          action: SnackBarAction(
            label: '다음',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                builder: (_) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.visibility_outlined),
                        title: const Text('분석 결과 보기'),
                        onTap: () {
                          Navigator.pop(context); // bottom sheet 닫기
                          Navigator.of(context, rootNavigator: true).pushNamed(
                            '/analyses_list',
                            arguments: {'highlightId': analysisId},
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.quiz_outlined),
                        title: const Text('이 지문으로 문제 만들기'),
                        onTap: () {
                          Navigator.pop(context); // bottom sheet 닫기

                          final hub = _hubResult;
                          final hubMap = hub == null
                              ? null
                              : {
                                  'topic': hub.topic,
                                  'title': hub.title,
                                  'gist_en': hub.gistEn,
                                  'gist_ko': hub.gistKo,
                                  'summary_en': hub.summaryEn,
                                  'summary_ko': hub.summaryKo,
                                };

                          Navigator.of(context, rootNavigator: true).pushNamed(
                            '/qm', // ✅ 여기 통일
                            arguments: {
                              'analysisId': _lastAnalysisId,
                              'text': _inputController.text.trim(),
                              'hub': hubMap,
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = '분석 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  TextStyle get _bodyStyle => TextStyle(
        fontSize: _fontSize,
        height: _lineHeight,
      );

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_hubResult == null) {
      return const Center(child: Text('아직 분석 결과가 없습니다.'));
    }

    final hub = _hubResult!;

    switch (_tabIndex) {
      case 0:
        return _ResultCard(
          child: SingleChildScrollView(
            child: SelectableText(hub.structure, style: _bodyStyle),
          ),
        );

      case 1:
        return _ResultCard(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionBlock(
                    title: 'Topic', text: hub.topic, style: _bodyStyle),
                const SizedBox(height: 12),
                _SectionBlock(
                    title: 'Title', text: hub.title, style: _bodyStyle),
                const SizedBox(height: 12),
                _SectionBlock(
                    title: 'Gist (EN)', text: hub.gistEn, style: _bodyStyle),
                const SizedBox(height: 12),
                _SectionBlock(
                    title: '요지 (Korean)', text: hub.gistKo, style: _bodyStyle),
                const SizedBox(height: 16),
                _SectionBlock(
                    title: 'Summary (EN)',
                    text: hub.summaryEn,
                    style: _bodyStyle),
                const SizedBox(height: 12),
                _SectionBlock(
                    title: '요약 (Korean)',
                    text: hub.summaryKo,
                    style: _bodyStyle),
              ],
            ),
          ),
        );

      case 2:
        return _ResultCard(
          child: SingleChildScrollView(
            child: SelectableText(hub.vocab, style: _bodyStyle),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  static const _sectionTitleStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 15,
    color: Color(0xFF6A1B9A),
  );

  void _goAnalysesList({int? highlightId}) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      '/analyses_list',
      arguments: highlightId == null ? null : {'highlightId': highlightId},
    );
  }

  // ✅ CHANGED: 문제제작 화면으로 이동 (main.dart 라우트에 맞춤)
  void _goQuestionMaker() {
    if (_lastAnalysisId == null) return;

    final hub = _hubResult; // TextAnalysisHubResult?
    final hubMap = hub == null
        ? null
        : {
            'topic': hub.topic,
            'title': hub.title,
            'gist_en': hub.gistEn,
            'gist_ko': hub.gistKo,
            'summary_en': hub.summaryEn,
            'summary_ko': hub.summaryKo,
          };

    Navigator.of(context, rootNavigator: true).pushNamed(
      '/qm',
      arguments: {
        'analysisId': _lastAnalysisId,
        'text': _inputController.text.trim(),
        'hub': hubMap, // ✅ 추가
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EDF6),
      appBar: AppBar(title: const Text('지문 분석 허브')),
      body: Column(
        children: [
          // 입력 영역
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('영어 지문 입력'),
                const SizedBox(height: 8),
                TextField(
                  controller: _inputController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '지문을 여기에 붙여넣으세요.',
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _performAnalyzeAndSave,
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('분석하기'),
                  ),
                ),
                const SizedBox(height: 8),

                // ✅ 저장 기록 보기(단 1개만)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _goAnalysesList(),
                    icon: const Icon(Icons.history),
                    label: const Text('저장 기록 보기'),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 탭 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _TabButton(
                  label: '문단 구조',
                  selected: _tabIndex == 0,
                  onTap: () => setState(() => _tabIndex = 0),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: '주제/제목/요지/요약',
                  selected: _tabIndex == 1,
                  onTap: () => setState(() => _tabIndex = 1),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: '단어/유의어',
                  selected: _tabIndex == 2,
                  onTap: () => setState(() => _tabIndex = 2),
                ),
              ],
            ),
          ),

          // 슬라이더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text('글자'),
                Expanded(
                  child: Slider(
                    min: 12,
                    max: 28,
                    value: _fontSize,
                    onChanged: (v) => setState(() => _fontSize = v),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('간격'),
                Expanded(
                  child: Slider(
                    min: 1.0,
                    max: 2.0,
                    value: _lineHeight,
                    onChanged: (v) => setState(() => _lineHeight = v),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
          const Divider(height: 1),

          // ✅ 문제 만들기 버튼
          if (_lastAnalysisId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _goQuestionMaker, // ✅ CHANGED
                  icon: const Icon(Icons.quiz),
                  label: Text('이 지문으로 문제 만들기 (ID: $_lastAnalysisId)'),
                ),
              ),
            ),

          // 결과 영역
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.deepPurple : Colors.grey.shade400;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Widget child;

  const _ResultCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE6EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final String title;
  final String text;
  final TextStyle style;

  const _SectionBlock({
    required this.title,
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _TextAnalysisHubScreenState._sectionTitleStyle),
        const SizedBox(height: 4),
        SelectableText(text, style: style),
      ],
    );
  }
}
