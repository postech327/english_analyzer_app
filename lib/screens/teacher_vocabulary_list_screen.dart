import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import '../models/learning_assignment.dart';
import '../services/learning_assignment_service.dart';
import '../services/vocabulary_file_picker.dart';
import '../services/vocabulary_service.dart';
import '../utils/vocabulary_file_text_extractor.dart';
import '../utils/vocabulary_import_parser.dart';

const _vocabularyPurple = Color(0xFF6D5CE7);
const _vocabularySurface = Color(0xFFF6F5FC);
const _vocabularyInk = Color(0xFF1F2937);
const _vocabularyMuted = Color(0xFF64748B);

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
  final Set<int> _changingStatus = {};
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

  Future<void> _togglePublished(VocabularySet vocabularySet) async {
    if (_changingStatus.contains(vocabularySet.id)) return;
    final nextStatus =
        vocabularySet.status == 'published' ? 'draft' : 'published';
    setState(() => _changingStatus.add(vocabularySet.id));
    try {
      await _service.updateSet(
        vocabularySet.id,
        {'status': nextStatus},
      );
      if (!mounted) return;
      setState(() {
        _changingStatus.remove(vocabularySet.id);
        _reload();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextStatus == 'published' ? '단어장을 게시했습니다.' : '단어장을 초안으로 전환했습니다.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _changingStatus.remove(vocabularySet.id));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _openAssignmentDialog(VocabularySet vocabularySet) async {
    if (vocabularySet.status != 'published') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시된 단어장만 배포할 수 있습니다.')),
      );
      return;
    }
    final result = await showDialog<VocabularyAssignResult>(
      context: context,
      builder: (_) => _VocabularyAssignmentDialog(
        vocabularySet: vocabularySet,
      ),
    );
    if (result == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.assignedCount}명에게 배포했습니다.'
          '${result.skippedCount > 0 ? ' (${result.skippedCount}명은 이미 배포됨)' : ''}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _vocabularySurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          '단어장 관리',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
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
        backgroundColor: _vocabularyPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '단어장 제목을 검색해 보세요',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => setState(_reload),
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => setState(_reload),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final entry in const {
                      'all': '전체',
                      'draft': '초안',
                      'published': '게시',
                      'archived': '보관',
                    }.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _status == entry.key,
                        selectedColor:
                            _vocabularyPurple.withValues(alpha: 0.16),
                        onSelected: (_) => setState(() {
                          _status = entry.key;
                          _reload();
                        }),
                      ),
                  ],
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
                  return const _VocabularyEmptyState();
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                        side: const BorderSide(color: Color(0xFFE7E5F4)),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.translate_rounded),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                _VocabularyStatusBadge(status: item.status),
                              ],
                            ),
                            subtitle: Text(
                              [
                                item.sourceLabel,
                                item.unitLabel,
                                item.gradeLabel,
                                '${item.itemCount}개',
                              ].whereType<String>().join(' · '),
                            ),
                            onTap: () => _openEditor(item),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') _openEditor(item);
                                if (value == 'delete') _delete(item);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('상세/편집'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('삭제'),
                                ),
                              ],
                            ),
                          ),
                          if ((item.description ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _vocabularyMuted,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          if (item.status != 'archived')
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: SizedBox(
                                width: double.infinity,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: item.status == 'published'
                                            ? () => _openAssignmentDialog(item)
                                            : null,
                                        icon: const Icon(Icons.send_rounded),
                                        label: Text(
                                          item.status == 'published'
                                              ? '배포'
                                              : '게시 후 배포',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: item.status == 'published'
                                          ? OutlinedButton.icon(
                                              onPressed: _changingStatus
                                                      .contains(item.id)
                                                  ? null
                                                  : () =>
                                                      _togglePublished(item),
                                              icon: const Icon(
                                                Icons.visibility_off_outlined,
                                              ),
                                              label: Text(
                                                _changingStatus
                                                        .contains(item.id)
                                                    ? '변경 중...'
                                                    : '초안 전환',
                                              ),
                                            )
                                          : FilledButton.icon(
                                              onPressed: _changingStatus
                                                      .contains(item.id)
                                                  ? null
                                                  : () =>
                                                      _togglePublished(item),
                                              icon: const Icon(
                                                Icons.publish_rounded,
                                              ),
                                              label: Text(
                                                _changingStatus
                                                        .contains(item.id)
                                                    ? '변경 중...'
                                                    : '게시하기',
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
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
  bool _loadingDetail = false;
  String? _detailError;
  bool _pickingFile = false;
  String? _importedFileName;
  String? _fileImportMessage;
  bool _fileImportFailed = false;

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
      _loadingDetail = true;
      _loadDetail(item.id);
    }
  }

  Future<void> _loadDetail(int id) async {
    setState(() {
      _loadingDetail = true;
      _detailError = null;
    });
    try {
      final detail = await _service.fetchTeacherSet(id);
      if (!mounted) return;
      _title.text = detail.title;
      _description.text = detail.description ?? '';
      _source.text = detail.sourceLabel ?? '';
      _unit.text = detail.unitLabel ?? '';
      _grade.text = detail.gradeLabel ?? '';
      _status = detail.status;
      _paste.text = detail.items
          .map((item) => '${item.word}\t${item.meaningKo}')
          .join('\n');
      setState(() {
        _parsed = parseVocabularyPaste(_paste.text);
        _loadingDetail = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingDetail = false;
        _detailError = '$error';
      });
    }
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

  Future<void> _pickImportFile() async {
    if (_pickingFile) return;
    setState(() {
      _pickingFile = true;
      _fileImportMessage = null;
      _fileImportFailed = false;
    });
    try {
      final picked = await pickVocabularyImportFile();
      if (picked == null) {
        if (mounted) setState(() => _pickingFile = false);
        return;
      }
      if (mounted) setState(() => _importedFileName = picked.name);
      final extracted = extractVocabularyFileText(picked.name, picked.bytes);
      final parsed = parseVocabularyPaste(extracted.text);
      if (!mounted) return;
      _paste.text = extracted.text;
      setState(() {
        _pickingFile = false;
        _importedFileName = picked.name;
        _parsed = parsed;
        _fileImportMessage = '${extracted.format} 텍스트 추출 완료 · '
            '정상 ${parsed.validRows.length}개 · 경고 ${parsed.warningCount}개';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pickingFile = false;
        _fileImportFailed = true;
        _fileImportMessage =
            error is FormatException ? error.message : '파일을 가져오지 못했습니다: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _parsed?.rows ?? const <VocabularyImportRow>[];
    return Scaffold(
      backgroundColor: _vocabularySurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(widget.vocabularySet == null ? '새 단어장' : '단어장 편집'),
      ),
      body: _loadingDetail
          ? const Center(child: CircularProgressIndicator())
          : _detailError != null
              ? _EditorLoadError(
                  message: _detailError!,
                  onRetry: () => _loadDetail(widget.vocabularySet!.id),
                )
              : LayoutBuilder(
                  builder: (context, constraints) => Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: constraints.maxWidth > 920
                          ? 920
                          : constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 2, 4, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.vocabularySet == null
                                      ? '학생용 단어장을 만들어 보세요'
                                      : '단어장 정보와 단어 목록을 수정합니다',
                                  style: const TextStyle(
                                    color: _vocabularyInk,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  widget.vocabularySet == null
                                      ? '단어를 붙여넣어 빠르게 학습 자료를 구성할 수 있어요.'
                                      : '기존 내용을 확인하고 필요한 부분을 편집해 주세요.',
                                  style: const TextStyle(
                                    color: _vocabularyMuted,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _EditorSectionCard(
                            icon: Icons.info_outline_rounded,
                            title: '기본 정보',
                            subtitle: '학생에게 보일 단어장 정보를 입력해 주세요.',
                            child: Column(
                              children: [
                                TextField(
                                  controller: _title,
                                  decoration: _editorInputDecoration('제목 *'),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _description,
                                  maxLines: 2,
                                  decoration: _editorInputDecoration('설명'),
                                ),
                                const SizedBox(height: 12),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final narrow = constraints.maxWidth < 640;
                                    final fields = [
                                      TextField(
                                        controller: _source,
                                        decoration:
                                            _editorInputDecoration('교재/출처'),
                                      ),
                                      TextField(
                                        controller: _unit,
                                        decoration:
                                            _editorInputDecoration('단원/강'),
                                      ),
                                      TextField(
                                        controller: _grade,
                                        decoration:
                                            _editorInputDecoration('학년'),
                                      ),
                                    ];
                                    return narrow
                                        ? Column(
                                            children: [
                                              for (var i = 0;
                                                  i < fields.length;
                                                  i++) ...[
                                                fields[i],
                                                if (i < fields.length - 1)
                                                  const SizedBox(height: 10),
                                              ],
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              for (var i = 0;
                                                  i < fields.length;
                                                  i++) ...[
                                                Expanded(child: fields[i]),
                                                if (i < fields.length - 1)
                                                  const SizedBox(width: 10),
                                              ],
                                            ],
                                          );
                                  },
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _status,
                                  decoration: _editorInputDecoration('상태'),
                                  items: [
                                    const DropdownMenuItem(
                                      value: 'draft',
                                      child: Text('초안'),
                                    ),
                                    const DropdownMenuItem(
                                      value: 'published',
                                      child: Text('게시'),
                                    ),
                                    if (widget.vocabularySet != null)
                                      const DropdownMenuItem(
                                        value: 'archived',
                                        child: Text('보관'),
                                      ),
                                  ],
                                  onChanged: (value) => setState(
                                      () => _status = value ?? 'draft'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _EditorSectionCard(
                            icon: Icons.upload_file_rounded,
                            title: '파일에서 가져오기',
                            subtitle: 'HWPX 또는 UTF-8 TXT 파일을 브라우저에서만 읽습니다.',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFD8D5E8),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.lock_outline_rounded,
                                        color: _vocabularyPurple,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '원본 파일은 서버에 업로드하지 않습니다. '
                                          '최대 30MB까지 가져올 수 있어요.',
                                          style: TextStyle(
                                            color: _vocabularyMuted,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed:
                                      _pickingFile ? null : _pickImportFile,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _vocabularyPurple,
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                  icon: _pickingFile
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.file_open_rounded,
                                        ),
                                  label: Text(
                                    _pickingFile
                                        ? '파일 읽는 중...'
                                        : 'HWPX/TXT 파일 선택',
                                  ),
                                ),
                                if (_importedFileName != null ||
                                    _fileImportMessage != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                      color: _fileImportFailed
                                          ? const Color(0xFFFEF2F2)
                                          : const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: _fileImportFailed
                                            ? const Color(0xFFFECACA)
                                            : const Color(0xFFBBF7D0),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          _fileImportFailed
                                              ? Icons.error_outline_rounded
                                              : Icons.check_circle_outline,
                                          color: _fileImportFailed
                                              ? const Color(0xFFDC2626)
                                              : const Color(0xFF16A34A),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (_importedFileName != null)
                                                Text(
                                                  _importedFileName!,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              if (_fileImportMessage != null)
                                                Text(
                                                  _fileImportMessage!,
                                                  style: const TextStyle(
                                                    height: 1.4,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _EditorSectionCard(
                            icon: Icons.content_paste_go_rounded,
                            title: '단어 붙여넣기',
                            subtitle: '한 줄에 영어 단어와 우리말 뜻을 함께 입력하세요.',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _paste,
                                  minLines: 8,
                                  maxLines: 16,
                                  decoration: _editorInputDecoration(
                                    '단어 목록',
                                    hint:
                                        '예: goal 목표\n예: recently 최근에\n예: provide 제공하다',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: () => setState(
                                    () => _parsed =
                                        parseVocabularyPaste(_paste.text),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _vocabularyPurple,
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                  icon: const Icon(Icons.auto_fix_high),
                                  label: const Text('붙여넣은 단어 분석하기'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _EditorSectionCard(
                            icon: Icons.fact_check_outlined,
                            title: '분석 결과',
                            subtitle: rows.isEmpty
                                ? '분석하기를 누르면 저장할 단어를 미리 확인할 수 있어요.'
                                : '정상 ${_parsed!.validRows.length}개 · 경고 ${_parsed!.warningCount}개',
                            child: rows.isEmpty
                                ? const _AnalysisEmptyState()
                                : Column(
                                    children: [
                                      for (final row in rows)
                                        _VocabularyAnalysisRow(row: row),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE7E5F4))),
          ),
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 888),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _vocabularyPurple,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _saving
                        ? '저장 중...'
                        : widget.vocabularySet == null
                            ? '단어장 저장'
                            : '변경사항 저장',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VocabularyAssignmentDialog extends StatefulWidget {
  const _VocabularyAssignmentDialog({required this.vocabularySet});

  final VocabularySet vocabularySet;

  @override
  State<_VocabularyAssignmentDialog> createState() =>
      _VocabularyAssignmentDialogState();
}

InputDecoration _editorInputDecoration(String label, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFFAFAFD),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFD8D5E8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFD8D5E8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _vocabularyPurple, width: 1.5),
    ),
  );
}

class _EditorSectionCard extends StatelessWidget {
  const _EditorSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E5F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _vocabularyPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _vocabularyPurple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _vocabularyInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _vocabularyMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _AnalysisEmptyState extends StatelessWidget {
  const _AnalysisEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.table_rows_outlined, size: 38, color: Color(0xFF94A3B8)),
            SizedBox(height: 8),
            Text(
              '아직 분석된 단어가 없습니다.',
              style: TextStyle(color: _vocabularyMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorLoadError extends StatelessWidget {
  const _EditorLoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              '단어장을 불러오지 못했습니다.',
              style: TextStyle(
                color: _vocabularyInk,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _vocabularyMuted),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VocabularyAnalysisRow extends StatelessWidget {
  const _VocabularyAnalysisRow({required this.row});

  final VocabularyImportRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: row.warning == null
            ? const Color(0xFFF8FAFC)
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: row.warning == null
              ? const Color(0xFFE2E8F0)
              : const Color(0xFFFED7AA),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${row.lineNumber}',
              style: const TextStyle(
                color: _vocabularyMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.isValid ? row.word : '파싱 실패',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  row.warning ?? row.meaningKo,
                  style: TextStyle(
                    color: row.warning == null
                        ? _vocabularyMuted
                        : const Color(0xFFC2410C),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            row.warning == null
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
            color: row.warning == null
                ? const Color(0xFF16A34A)
                : const Color(0xFFF97316),
          ),
        ],
      ),
    );
  }
}

class _VocabularyEmptyState extends StatelessWidget {
  const _VocabularyEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 52,
              color: _vocabularyPurple,
            ),
            SizedBox(height: 12),
            Text(
              '아직 단어장이 없습니다.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 6),
            Text(
              '새 단어장으로 시작해 보세요.',
              style: TextStyle(color: _vocabularyMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _VocabularyAssignmentDialogState
    extends State<_VocabularyAssignmentDialog> {
  final _vocabularyService = const VocabularyService();
  final _assignmentService = const LearningAssignmentService();
  final Set<int> _selected = {};
  List<AssignableStudent> _students = const [];
  Set<int> _assignedStudentIds = const {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final students = await _assignmentService.fetchStudents();
      final assignments =
          await _vocabularyService.fetchAssignments(widget.vocabularySet.id);
      if (!mounted) return;
      setState(() {
        _students = students;
        _assignedStudentIds =
            assignments.map((assignment) => assignment.studentId).toSet();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _assign() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);
    try {
      final result = await _vocabularyService.assignSet(
        widget.vocabularySet.id,
        _selected.toList(),
      );
      if (mounted) Navigator.pop(context, result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableCount = _students.length - _assignedStudentIds.length;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6D5CE7), Color(0xFF8B7CF6)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.vocabularySet.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '배포할 학생을 선택해 주세요.',
                          style: TextStyle(color: Color(0xFFEDE9FE)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!_loading && _error == null && _students.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AssignmentSummaryPill(
                      label: '선택',
                      count: _selected.length,
                      color: _vocabularyPurple,
                    ),
                    _AssignmentSummaryPill(
                      label: '배포됨',
                      count: _assignedStudentIds.length,
                      color: const Color(0xFF16A34A),
                    ),
                    _AssignmentSummaryPill(
                      label: '배포 가능',
                      count: availableCount,
                      color: const Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _AssignmentDialogMessage(
                            icon: Icons.error_outline,
                            message: _error!,
                          )
                        : _students.isEmpty
                            ? const _AssignmentDialogMessage(
                                icon: Icons.group_off_outlined,
                                message: '배포할 학생이 없습니다.',
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: _students.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 9),
                                itemBuilder: (context, index) {
                                  final student = _students[index];
                                  final assigned =
                                      _assignedStudentIds.contains(student.id);
                                  final selected =
                                      _selected.contains(student.id);
                                  return _AssignmentStudentRow(
                                    student: student,
                                    assigned: assigned,
                                    selected: selected,
                                    onTap: assigned
                                        ? null
                                        : () => setState(() {
                                              if (selected) {
                                                _selected.remove(student.id);
                                              } else {
                                                _selected.add(student.id);
                                              }
                                            }),
                                  );
                                },
                              ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFD),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28)),
                border: Border(top: BorderSide(color: Color(0xFFE7E5F4))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_loading && _error == null && availableCount == 0) ...[
                    const Text(
                      '모든 학생에게 이미 배포되었습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _vocabularyMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _saving ? null : () => Navigator.pop(context),
                          child: const Text('취소'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed:
                              _saving || _selected.isEmpty ? null : _assign,
                          style: FilledButton.styleFrom(
                            backgroundColor: _vocabularyPurple,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: const Icon(Icons.send_rounded),
                          label: Text(
                            _saving
                                ? '배포 중...'
                                : '선택 ${_selected.length}명에게 배포',
                          ),
                        ),
                      ),
                    ],
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

class _VocabularyStatusBadge extends StatelessWidget {
  const _VocabularyStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'published' => const Color(0xFF15803D),
      'archived' => const Color(0xFF64748B),
      _ => const Color(0xFFB45309),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AssignmentSummaryPill extends StatelessWidget {
  const _AssignmentSummaryPill({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        '$label $count명',
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _AssignmentStudentRow extends StatelessWidget {
  const _AssignmentStudentRow({
    required this.student,
    required this.assigned,
    required this.selected,
    required this.onTap,
  });

  final AssignableStudent student;
  final bool assigned;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = assigned
        ? const Color(0xFF16A34A)
        : selected
            ? _vocabularyPurple
            : const Color(0xFF94A3B8);
    return Material(
      color: assigned
          ? const Color(0xFFF0FDF4)
          : selected
              ? const Color(0xFFF3F0FF)
              : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accent.withValues(alpha: assigned || selected ? 0.6 : 0.3),
              width: assigned || selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.13),
                child: Text(
                  student.nickname.isEmpty
                      ? '?'
                      : student.nickname.characters.first.toUpperCase(),
                  style: TextStyle(color: accent, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.nickname,
                      style: const TextStyle(
                        color: _vocabularyInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      student.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _vocabularyMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  assigned
                      ? '배포됨'
                      : selected
                          ? '선택됨'
                          : '선택 가능',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                assigned
                    ? Icons.check_circle
                    : selected
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                color: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentDialogMessage extends StatelessWidget {
  const _AssignmentDialogMessage({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: _vocabularyMuted),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _vocabularyMuted),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(String status) => switch (status) {
      'published' => '게시',
      'archived' => '보관',
      _ => '초안',
    };
