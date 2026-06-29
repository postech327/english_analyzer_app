import 'package:flutter/material.dart';

import '../models/learning_assignment.dart';
import '../models/workbook.dart';
import '../services/workbook_service.dart';
import '../widgets/workbook_assignment_dialog.dart';
import 'teacher_workbook_detail_screen.dart';

class TeacherWorkbookListScreen extends StatefulWidget {
  const TeacherWorkbookListScreen({super.key});

  @override
  State<TeacherWorkbookListScreen> createState() =>
      _TeacherWorkbookListScreenState();
}

class _TeacherWorkbookListScreenState extends State<TeacherWorkbookListScreen> {
  static const _primary = Color(0xFF183B56);
  static const _teal = Color(0xFF0F766E);
  static const _surface = Color(0xFFF4F7FA);
  static const _ink = Color(0xFF102A43);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);

  final _service = const WorkbookService();
  final _searchController = TextEditingController();
  late Future<List<Workbook>> _future;
  String _status = 'all';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _service.fetchWorkbooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _service.fetchWorkbooks(status: _status);
    });
  }

  List<Workbook> _filter(List<Workbook> items) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items.where((item) {
      final target = [
        item.title,
        item.description,
        item.sourceLabel,
        item.folderName,
        item.unitLabel,
        workbookStatusLabel(item.status),
      ].whereType<String>().join(' ').toLowerCase();
      return target.contains(query);
    }).toList();
  }

  Future<void> _createWorkbook() async {
    final draft = await showDialog<_WorkbookCreateDraft>(
      context: context,
      builder: (_) => const _WorkbookCreateDialog(),
    );
    if (draft == null) return;

    try {
      final workbook = await _service.createWorkbook(
        title: draft.title,
        description: draft.description,
        sourceLabel: draft.sourceLabel,
        folderName: draft.folderName,
        unitLabel: draft.unitLabel,
        finalTouchId: draft.finalTouchId,
      );
      if (!mounted) return;
      _reload();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherWorkbookDetailScreen(workbookId: workbook.id),
        ),
      );
      if (mounted) _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('워크북 생성 실패: $error')),
      );
    }
  }

  Future<void> _archive(Workbook workbook) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _line),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0F172A),
                  blurRadius: 28,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: _teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '워크북 보관',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '"${workbook.title}" 워크북을 보관 처리할까요?',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '보관된 워크북은 보관 필터에서 다시 확인할 수 있습니다.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          foregroundColor: _muted,
                          side: const BorderSide(color: _line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          backgroundColor: _teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('보관'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await _service.archiveWorkbook(workbook.id);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('워크북을 보관 처리했습니다.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('보관 실패: $error')),
      );
    }
  }

  Future<void> _deleteWorkbook(Workbook workbook) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFECACA)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0F172A),
                  blurRadius: 28,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '워크북을 삭제할까요?',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '“${workbook.title}” 워크북을 삭제합니다.',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '문항 수  ${workbook.questionCount}개',
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '문항도 함께 삭제되며 이 작업은 되돌릴 수 없습니다.',
                        style: TextStyle(color: _muted, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '이미 배포되었거나 학생 결과가 있는 워크북은 삭제할 수 없습니다. 이 경우 보관을 사용해 주세요.',
                  style: TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          foregroundColor: _muted,
                          side: const BorderSide(color: _line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('삭제'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.deleteWorkbook(workbook.id);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('워크북을 삭제했습니다.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${_readableError(error)}')),
      );
    }
  }

  Future<void> _assignWorkbook(Workbook workbook) async {
    final result = await showDialog<AssignmentCreateResult>(
      context: context,
      builder: (_) => WorkbookAssignmentDialog(workbook: workbook),
    );
    if (result == null || !mounted) return;
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.skippedCount > 0
              ? '워크북 배포 완료: ${result.createdCount}명 배포, ${result.skippedCount}명 중복 제외'
              : '워크북을 ${result.createdCount}명에게 배포했습니다.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('워크북 관리'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '새로고침',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createWorkbook,
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('새 워크북'),
      ),
      body: FutureBuilder<List<Workbook>>(
        future: _future,
        builder: (context, snapshot) {
          final rawItems = snapshot.data ?? const <Workbook>[];
          final items = _filter(rawItems);
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 96),
            children: [
              _Header(total: rawItems.length),
              const SizedBox(height: 14),
              _Toolbar(
                controller: _searchController,
                query: _query,
                status: _status,
                onQueryChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
                onClear: () {
                  _searchController.clear();
                  setState(() {
                    _query = '';
                  });
                },
                onStatusChanged: (value) {
                  setState(() {
                    _status = value;
                  });
                  _reload();
                },
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _StateCard(
                  icon: Icons.hourglass_empty_rounded,
                  title: '워크북을 불러오는 중입니다.',
                  message: '잠시만 기다려 주세요.',
                )
              else if (snapshot.hasError)
                _StateCard(
                  icon: Icons.error_outline_rounded,
                  title: '워크북을 불러오지 못했습니다.',
                  message: '${snapshot.error}',
                  actionLabel: '다시 시도',
                )
              else if (rawItems.isEmpty)
                _StateCard(
                  icon: Icons.menu_book_outlined,
                  title: '아직 만든 워크북이 없습니다.',
                  message: 'Final Touch 자료와 직접 입력 문제를 묶어 워크북을 만들어 보세요.',
                  actionLabel: '새 워크북 만들기',
                  onAction: _createWorkbook,
                )
              else if (items.isEmpty)
                const _StateCard(
                  icon: Icons.search_off_rounded,
                  title: '검색 결과가 없습니다.',
                  message: '다른 검색어 또는 상태 필터를 사용해 보세요.',
                )
              else
                ...items.map(
                  (item) => _WorkbookCard(
                    workbook: item,
                    onOpen: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TeacherWorkbookDetailScreen(workbookId: item.id),
                        ),
                      );
                      if (mounted) _reload();
                    },
                    onAssign: () => _assignWorkbook(item),
                    onArchive:
                        item.status == 'archived' ? null : () => _archive(item),
                    onDelete: () => _deleteWorkbook(item),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _TeacherWorkbookListScreenState._line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: _TeacherWorkbookListScreenState._teal,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '워크북 관리',
                  style: TextStyle(
                    color: _TeacherWorkbookListScreenState._ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '선택형, 확인학습, T/F 문제를 직접 입력해 학생용 학습지를 구성합니다.',
                  style: TextStyle(
                    color: _TeacherWorkbookListScreenState._muted,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          _MiniChip(text: '총 $total개'),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.controller,
    required this.query,
    required this.status,
    required this.onQueryChanged,
    required this.onClear,
    required this.onStatusChanged,
  });

  final TextEditingController controller;
  final String query;
  final String status;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('all', '전체'),
      ('draft', '초안'),
      ('published', '게시'),
      ('archived', '보관'),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _TeacherWorkbookListScreenState._line),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: '워크북 제목, 교재/출처, 단원/강으로 검색',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: _TeacherWorkbookListScreenState._teal,
                  width: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in filters)
                  ChoiceChip(
                    label: Text(item.$2),
                    selected: status == item.$1,
                    onSelected: (_) => onStatusChanged(item.$1),
                    selectedColor: const Color(0xFFE0F2F1),
                    labelStyle: TextStyle(
                      color: status == item.$1
                          ? _TeacherWorkbookListScreenState._teal
                          : _TeacherWorkbookListScreenState._muted,
                      fontWeight: FontWeight.w800,
                    ),
                    side: BorderSide(
                      color: status == item.$1
                          ? const Color(0xFF5EEAD4)
                          : _TeacherWorkbookListScreenState._line,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkbookCard extends StatelessWidget {
  const _WorkbookCard({
    required this.workbook,
    required this.onOpen,
    required this.onAssign,
    required this.onArchive,
    required this.onDelete,
  });

  final Workbook workbook;
  final VoidCallback onOpen;
  final VoidCallback onAssign;
  final VoidCallback? onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final meta = _joinMetadata([
      workbook.sourceLabel,
      workbook.folderName,
      workbook.unitLabel,
    ]);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _TeacherWorkbookListScreenState._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  workbook.title,
                  style: const TextStyle(
                    color: _TeacherWorkbookListScreenState._ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusChip(status: workbook.status),
            ],
          ),
          if ((workbook.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              workbook.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _TeacherWorkbookListScreenState._muted,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniChip(text: '${workbook.questionCount}문항'),
              if (meta.isNotEmpty) _MiniChip(text: meta),
              if (workbook.createdAt != null)
                _MiniChip(text: _formatDate(workbook.createdAt!)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('상세/편집'),
                style: FilledButton.styleFrom(
                  backgroundColor: _TeacherWorkbookListScreenState._primary,
                  foregroundColor: Colors.white,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onAssign,
                icon: const Icon(Icons.send_rounded),
                label: const Text('배포'),
              ),
              OutlinedButton.icon(
                onPressed: onArchive,
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('보관'),
              ),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('삭제'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkbookCreateDialog extends StatefulWidget {
  const _WorkbookCreateDialog();

  @override
  State<_WorkbookCreateDialog> createState() => _WorkbookCreateDialogState();
}

class _WorkbookCreateDialogState extends State<_WorkbookCreateDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sourceController = TextEditingController();
  final _folderController = TextEditingController();
  final _unitController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _sourceController.dispose();
    _folderController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('워크북 제목을 입력해 주세요.')),
      );
      return;
    }
    Navigator.pop(
      context,
      _WorkbookCreateDraft(
        title: title,
        description: _emptyToNull(_descriptionController.text),
        sourceLabel: _emptyToNull(_sourceController.text),
        folderName: _emptyToNull(_folderController.text),
        unitLabel: _emptyToNull(_unitController.text),
        finalTouchId: null,
      ),
    );
  }

  void _showFinalTouchPreparing() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('다음 단계에서 Final Touch 자료 선택 기능을 연결합니다.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: _TeacherWorkbookListScreenState._surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '새 워크북 만들기',
                style: TextStyle(
                  color: _TeacherWorkbookListScreenState._ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '샘플 양식은 나중에 확정하고, 지금은 직접 입력 가능한 기본 구조로 저장합니다.',
                style: TextStyle(color: _TeacherWorkbookListScreenState._muted),
              ),
              const SizedBox(height: 16),
              _DialogField(controller: _titleController, label: '워크북 제목'),
              _DialogField(
                controller: _descriptionController,
                label: '설명 선택',
                minLines: 2,
              ),
              Row(
                children: [
                  Expanded(
                    child: _DialogField(
                      controller: _sourceController,
                      label: '교재/출처',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DialogField(
                      controller: _folderController,
                      label: '단원/강',
                    ),
                  ),
                ],
              ),
              _DialogField(
                controller: _unitController,
                label: '세부 번호',
              ),
              _FinalTouchOptionalBox(onSelect: _showFinalTouchPreparing),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            _TeacherWorkbookListScreenState._primary,
                      ),
                      child: const Text('생성'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    this.minLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: minLines + 3,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }
}

class _FinalTouchOptionalBox extends StatelessWidget {
  const _FinalTouchOptionalBox({required this.onSelect});

  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_fix_high_rounded,
              color: Color(0xFF0F766E),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Final Touch 자료 연결',
                  style: TextStyle(
                    color: Color(0xFF102A43),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '선택된 자료 없음 · 한글파일/엑셀 기반 워크북은 연결 없이 생성할 수 있습니다.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onSelect,
            child: const Text('자료 선택하기'),
          ),
        ],
      ),
    );
  }
}

class _WorkbookCreateDraft {
  const _WorkbookCreateDraft({
    required this.title,
    this.description,
    this.sourceLabel,
    this.folderName,
    this.unitLabel,
    this.finalTouchId,
  });

  final String title;
  final String? description;
  final String? sourceLabel;
  final String? folderName;
  final String? unitLabel;
  final int? finalTouchId;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'published' => const Color(0xFF16A34A),
      'archived' => const Color(0xFF64748B),
      _ => _TeacherWorkbookListScreenState._teal,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        workbookStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _TeacherWorkbookListScreenState._line),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _TeacherWorkbookListScreenState._muted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _TeacherWorkbookListScreenState._line),
      ),
      child: Column(
        children: [
          Icon(icon, color: _TeacherWorkbookListScreenState._teal, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: _TeacherWorkbookListScreenState._ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: _TeacherWorkbookListScreenState._muted),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

String? _emptyToNull(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

String _readableError(Object error) {
  var text = error.toString().replaceFirst('Exception: ', '');
  final apiPrefix = RegExp(r'^워크북 API 오류 \d+:\s*');
  text = text.replaceFirst(apiPrefix, '');
  return text;
}

String _joinMetadata(List<String?> values) {
  final seen = <String>{};
  final parts = <String>[];
  for (final value in values) {
    final text = value?.trim();
    if (text == null || text.isEmpty) continue;
    if (seen.add(text)) parts.add(text);
  }
  return parts.join(' · ');
}

String _formatDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${parsed.year}.${two(parsed.month)}.${two(parsed.day)}';
}
