// lib/screens/analyses_list_screen.dart
import 'package:flutter/material.dart';
import '../services/analyzer_service.dart';
import '../models/analysis_record_model.dart';

class AnalysesListScreen extends StatefulWidget {
  const AnalysesListScreen({super.key});

  @override
  State<AnalysesListScreen> createState() => _AnalysesListScreenState();
}

class _AnalysesListScreenState extends State<AnalysesListScreen> {
  final _service = AnalyzerService();
  final _scroll = ScrollController();

  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;

  List<AnalysisRecord> _items = [];
  int? _highlightId;

  // kind 필터 (선택된 것만 보여줌). 비어있으면 전체
  final Set<String> _selectedKinds = {};

  // 정렬: true = 최신(내림차순), false = 오래된(오름차순)
  bool _sortDesc = true;

  // highlight 스크롤용 key
  final GlobalKey _highlightKey = GlobalKey();
  bool _didAutoScroll = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ 라우트 arguments 받기: {'highlightId': 30}
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['highlightId'] != null) {
      final dynamic v = args['highlightId'];
      _highlightId = v is int ? v : int.tryParse(v.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {}); // 검색어 입력 즉시 반영
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _service.fetchAnalyses(limit: 200); // 넉넉히
      setState(() {
        _items = items;
      });

      // ✅ highlightId가 있으면 해당 위치로 스크롤 (정확)
      if (_highlightId != null && !_didAutoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          // highlightKey가 붙은 위젯이 build 된 이후에만 동작
          final ctx = _highlightKey.currentContext;
          if (ctx != null) {
            _didAutoScroll = true;
            await Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              alignment: 0.2,
            );
          }
        });
      }
    } catch (e) {
      setState(() => _error = '조회 실패: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ✅ kind 목록 (현재 아이템 기반으로 자동 생성)
  List<String> get _kinds {
    final s = <String>{};
    for (final it in _items) {
      if (it.kind.trim().isNotEmpty) s.add(it.kind.trim());
    }
    final list = s.toList();
    list.sort();
    return list;
  }

  // ✅ 필터 + 검색 + 정렬 적용된 리스트
  List<AnalysisRecord> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();

    Iterable<AnalysisRecord> list = _items;

    // kind 필터
    if (_selectedKinds.isNotEmpty) {
      list = list.where((e) => _selectedKinds.contains(e.kind));
    }

    // 검색 (ID / input_text / result_text)
    if (q.isNotEmpty) {
      list = list.where((e) {
        final idStr = e.id.toString();
        final a = e.inputText.toLowerCase();
        final b = e.resultText.toLowerCase();
        return idStr.contains(q) || a.contains(q) || b.contains(q);
      });
    }

    final out = list.toList();

    // 정렬: id 기준 (보통 증가)
    out.sort((a, b) => _sortDesc ? (b.id - a.id) : (a.id - b.id));
    return out;
  }

  void _toggleKind(String kind) {
    setState(() {
      if (_selectedKinds.contains(kind)) {
        _selectedKinds.remove(kind);
      } else {
        _selectedKinds.add(kind);
      }
      // highlight 스크롤은 1회만 수행하도록 유지
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedKinds.clear();
      _searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF8EDF6),
      appBar: AppBar(
        title: const Text('저장된 분석 기록 (/analyses)'),
        actions: [
          // 정렬 토글
          IconButton(
            tooltip: _sortDesc ? '최신순' : '오래된순',
            onPressed: () => setState(() => _sortDesc = !_sortDesc),
            icon: Icon(_sortDesc ? Icons.arrow_downward : Icons.arrow_upward),
          ),
          IconButton(
            tooltip: '새로고침',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ 검색창 + 필터 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'ID / input_text / result_text 검색',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: '지우기',
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchCtrl.clear(),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),

                // kind 칩들
                if (_kinds.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // 전체/초기화
                      ActionChip(
                        label: const Text('필터 초기화'),
                        onPressed: _clearFilters,
                        avatar: const Icon(Icons.tune, size: 18),
                      ),
                      ..._kinds.map((k) {
                        final selected = _selectedKinds.contains(k);
                        return FilterChip(
                          label: Text(k),
                          selected: selected,
                          onSelected: (_) => _toggleKind(k),
                        );
                      }),
                    ],
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : items.isEmpty
                        ? const Center(child: Text('저장된 기록이 없습니다.'))
                        : ListView.separated(
                            controller: _scroll,
                            padding: const EdgeInsets.all(12),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final it = items[i];
                              final preview = it.inputText.length > 80
                                  ? '${it.inputText.substring(0, 80)}...'
                                  : it.inputText;

                              final isHighlight = (_highlightId != null &&
                                  it.id == _highlightId);

                              return Card(
                                key: isHighlight ? _highlightKey : null,
                                elevation: 1,
                                color: isHighlight
                                    ? Colors.amber.shade100
                                    : Colors.white,
                                child: ListTile(
                                  title:
                                      Text('ID: ${it.id}  •  kind: ${it.kind}'),
                                  subtitle: Text(preview),
                                  trailing:
                                      const Icon(Icons.chevron_right_rounded),
                                  onTap: () {
                                    Navigator.pushNamed(
                                        context, '/analysis_detail',
                                        arguments: {'id': it.id});
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
