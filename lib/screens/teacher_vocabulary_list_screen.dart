import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import '../services/vocabulary_service.dart';
import '../utils/vocabulary_import_parser.dart';

class TeacherVocabularyListScreen extends StatefulWidget {
  const TeacherVocabularyListScreen({super.key});

  @override
  State<TeacherVocabularyListScreen> createState() =>
      _TeacherVocabularyListScreenState();
}

class _TeacherVocabularyListScreenState
    extends State<TeacherVocabularyListScreen> {
  final _service = const VocabularyService();
  final _searchController = TextEditingController();
  String _status = 'all';
  late Future<List<VocabularySet>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    _future = _service.fetchTeacherSets(
      status: _status,
      search: _searchController.text,
    );
  }

  Future<void> _openEditor([VocabularySet? vocabularySet]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TeacherVocabularyEditorScreen(vocabularySet: vocabularySet),
      ),
    );
    if (changed == true && mounted) setState(_reload);
  }

  Future<void> _delete(VocabularySet vocabularySet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('단어장 삭제'),
        content: Text('${vocabularySet.title}을(를) 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteSet(vocabularySet.id);
      if (mounted) setState(_reload);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('단어장 관리'),
        actions: [
          IconButton(
              onPressed: () => setState(_reload),
              icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('새 단어장'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: '제목 검색',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => setState(_reload),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('전체')),
                    DropdownMenuItem(value: 'draft', child: Text('초안')),
                    DropdownMenuItem(value: 'published', child: Text('게시')),
                    DropdownMenuItem(value: 'archived', child: Text('보관')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _status = value;
                      _reload();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<VocabularySet>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('${snapshot.error}'));
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return const Center(child: Text('등록된 단어장이 없습니다.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.translate_rounded),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          [
                            item.sourceLabel,
                            item.unitLabel,
                            '${item.itemCount}개',
                            _statusLabel(item.status),
                          ].whereType<String>().join(' · '),
                        ),
                        onTap: () => _openEditor(item),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') _openEditor(item);
                            if (value == 'delete') _delete(item);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('상세/편집')),
                            PopupMenuItem(value: 'delete', child: Text('삭제')),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TeacherVocabularyEditorScreen extends StatefulWidget {
  const TeacherVocabularyEditorScreen({super.key, this.vocabularySet});

  final VocabularySet? vocabularySet;

  @override
  State<TeacherVocabularyEditorScreen> createState() =>
      _TeacherVocabularyEditorScreenState();
}

class _TeacherVocabularyEditorScreenState
    extends State<TeacherVocabularyEditorScreen> {
  final _service = const VocabularyService();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _source = TextEditingController();
  final _unit = TextEditingController();
  final _grade = TextEditingController();
  final _paste = TextEditingController();
  String _status = 'draft';
  VocabularyImportResult? _parsed;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.vocabularySet;
    if (item != null) {
      _title.text = item.title;
      _description.text = item.description ?? '';
      _source.text = item.sourceLabel ?? '';
      _unit.text = item.unitLabel ?? '';
      _grade.text = item.gradeLabel ?? '';
      _status = item.status;
      _loadDetail(item.id);
    }
  }

  Future<void> _loadDetail(int id) async {
    try {
      final detail = await _service.fetchTeacherSet(id);
      if (!mounted) return;
      _paste.text = detail.items
          .map((item) => '${item.word}\t${item.meaningKo}')
          .join('\n');
      setState(() => _parsed = parseVocabularyPaste(_paste.text));
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _description,
      _source,
      _unit,
      _grade,
      _paste,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('제목을 입력해 주세요.')));
      return;
    }
    final parsed = parseVocabularyPaste(_paste.text);
    if (parsed.validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장할 단어를 분석해 주세요.')),
      );
      return;
    }
    setState(() {
      _saving = true;
      _parsed = parsed;
    });
    try {
      final body = {
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'source_type': 'custom',
        'source_label': _source.text.trim(),
        'unit_label': _unit.text.trim(),
        'grade_label': _grade.text.trim(),
        'status': _status,
      };
      final saved = widget.vocabularySet == null
          ? await _service.createSet(body)
          : await _service.updateSet(widget.vocabularySet!.id, body);
      await _service.bulkSaveItems(
        saved.id,
        [
          for (final row in parsed.validRows)
            {'word': row.word, 'meaning_ko': row.meaningKo},
        ],
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _parsed?.rows ?? const <VocabularyImportRow>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vocabularySet == null ? '새 단어장' : '단어장 편집'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: '제목 *'),
          ),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: '설명'),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _source,
                  decoration: const InputDecoration(labelText: '교재/출처'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _unit,
                  decoration: const InputDecoration(labelText: '단원/강'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _grade,
                  decoration: const InputDecoration(labelText: '학년'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(labelText: '상태'),
            items: const [
              DropdownMenuItem(value: 'draft', child: Text('초안')),
              DropdownMenuItem(value: 'published', child: Text('게시')),
              DropdownMenuItem(value: 'archived', child: Text('보관')),
            ],
            onChanged: (value) => setState(() => _status = value ?? 'draft'),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _paste,
            minLines: 8,
            maxLines: 16,
            decoration: const InputDecoration(
              labelText: '단어 붙여넣기',
              hintText: 'goal 목표\nrecently 최근에',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => _parsed = parseVocabularyPaste(_paste.text)),
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('분석하기'),
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '분석 결과 ${_parsed!.validRows.length}개 · 경고 ${_parsed!.warningCount}개',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            for (final row in rows)
              ListTile(
                dense: true,
                leading: Text('${row.lineNumber}'),
                title: Text(row.isValid ? row.word : '파싱 실패'),
                subtitle: Text(row.warning ?? row.meaningKo),
                trailing: row.warning == null
                    ? const Icon(Icons.check, color: Colors.green)
                    : const Icon(Icons.warning_amber, color: Colors.orange),
              ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_saving ? '저장 중...' : '단어장 저장'),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(String status) => switch (status) {
      'published' => '게시',
      'archived' => '보관',
      _ => '초안',
    };
