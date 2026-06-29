import 'package:flutter/material.dart';

import '../models/learning_assignment.dart';
import '../models/workbook.dart';
import '../models/workbook_attempt.dart';
import '../services/learning_assignment_service.dart';
import '../services/workbook_attempt_service.dart';
import '../services/workbook_service.dart';
import '../widgets/workbook_assignment_dialog.dart';
import '../widgets/workbook_question_editor_dialog.dart';
import 'teacher_workbook_import_screen.dart';

class TeacherWorkbookDetailScreen extends StatefulWidget {
  const TeacherWorkbookDetailScreen({super.key, required this.workbookId});

  final int workbookId;

  @override
  State<TeacherWorkbookDetailScreen> createState() =>
      _TeacherWorkbookDetailScreenState();
}

class _TeacherWorkbookDetailScreenState
    extends State<TeacherWorkbookDetailScreen> {
  static const _primary = Color(0xFF183B56);
  static const _teal = Color(0xFF0F766E);
  static const _surface = Color(0xFFF4F7FA);
  static const _ink = Color(0xFF102A43);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);

  final _service = const WorkbookService();
  final _assignmentService = const LearningAssignmentService();
  late Future<Workbook> _future;
  late Future<List<LearningAssignment>> _assignmentFuture;
  final Set<int> _recentImportedQuestionIds = {};
  bool _showRecentImportedOnly = false;
  bool _deletingRecentImport = false;
  int? _selectedSectionId;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchWorkbook(
      widget.workbookId,
      sectionId: _selectedSectionId,
    );
    _assignmentFuture =
        _assignmentService.fetchTeacherWorkbookStatus(widget.workbookId);
  }

  void _reload() {
    setState(() {
      _future = _service.fetchWorkbook(
        widget.workbookId,
        sectionId: _selectedSectionId,
      );
      _assignmentFuture =
          _assignmentService.fetchTeacherWorkbookStatus(widget.workbookId);
    });
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

  Future<void> _deleteRecentImport() async {
    if (_recentImportedQuestionIds.isEmpty || _deletingRecentImport) return;
    final total = _recentImportedQuestionIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('방금 가져온 문제 삭제'),
        content: Text(
          '방금 가져온 문제 $total개를 삭제할까요?\n\n'
          '학생에게 배포하기 전 잘못 가져온 문제를 되돌릴 때 사용합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingRecentImport = true);
    final failedIds = <int>[];
    var deleted = 0;
    for (final questionId in _recentImportedQuestionIds.toList()) {
      try {
        await _service.deleteQuestion(
          workbookId: widget.workbookId,
          questionId: questionId,
        );
        deleted++;
      } catch (_) {
        failedIds.add(questionId);
      }
    }
    if (!mounted) return;
    setState(() {
      _deletingRecentImport = false;
      _recentImportedQuestionIds
        ..clear()
        ..addAll(failedIds);
      if (_recentImportedQuestionIds.isEmpty) {
        _showRecentImportedOnly = false;
      }
      _future = _service.fetchWorkbook(
        widget.workbookId,
        sectionId: _selectedSectionId,
      );
      _assignmentFuture =
          _assignmentService.fetchTeacherWorkbookStatus(widget.workbookId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failedIds.isEmpty
              ? '방금 가져온 문제 $deleted개를 삭제했습니다.'
              : '$deleted개 삭제, ${failedIds.length}개는 삭제하지 못했습니다.',
        ),
      ),
    );
  }

  Future<void> _addQuestion(Workbook workbook, String type) async {
    final draft = await showDialog<WorkbookQuestionDraft>(
      context: context,
      builder: (_) => WorkbookQuestionEditorDialog(
        questionType: type,
        workbookSourceLabel: workbook.sourceLabel,
        workbookFolderName: workbook.folderName,
        workbookUnitLabel: workbook.unitLabel,
        sections: workbook.sections,
        initialSectionId: _selectedSectionId != null && _selectedSectionId! > 0
            ? _selectedSectionId
            : null,
      ),
    );
    if (draft == null) return;
    try {
      var sectionId = draft.sectionId;
      final newSectionTitle = draft.newSectionTitle?.trim();
      if (newSectionTitle != null && newSectionTitle.isNotEmpty) {
        WorkbookSection? matchedSection;
        for (final section in workbook.sections) {
          if (section.title.trim().toLowerCase() ==
              newSectionTitle.toLowerCase()) {
            matchedSection = section;
            break;
          }
        }
        matchedSection ??= await _service.createWorkbookSection(
          widget.workbookId,
          title: _sectionTitle(newSectionTitle),
          unitLabel: _sectionTitle(newSectionTitle),
          sectionKey: _sectionKey(newSectionTitle),
        );
        sectionId = matchedSection.id;
      }
      await _service.createQuestion(
        workbookId: widget.workbookId,
        questionType: draft.questionType,
        prompt: draft.prompt,
        sectionId: sectionId,
        passageText: draft.passageText,
        choices: draft.choices,
        answer: draft.answer,
        explanation: draft.explanation,
        points: draft.points,
      );
      if (!mounted) return;
      if (sectionId != null) {
        setState(() {
          _selectedSectionId = sectionId;
          _future = _service.fetchWorkbook(
            widget.workbookId,
            sectionId: sectionId,
          );
          _assignmentFuture =
              _assignmentService.fetchTeacherWorkbookStatus(widget.workbookId);
        });
      } else {
        _reload();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문제를 추가했습니다.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('문제 추가 실패: $error')),
      );
    }
  }

  String _sectionTitle(String input) {
    final trimmed = input.trim();
    final unitMatch = RegExp(
      r'^(?:unit\s*)?(\d+)\s*(?:강)?$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (unitMatch != null) return '${unitMatch.group(1)}강';
    if (trimmed.toLowerCase() == 'test') return 'Test';
    return trimmed;
  }

  String _sectionKey(String input) {
    final title = _sectionTitle(input);
    final unitMatch = RegExp(r'^(\d+)강$').firstMatch(title);
    if (unitMatch != null) return 'unit_${unitMatch.group(1)}';
    if (title.toLowerCase() == 'test') return 'test';
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9가-힣_-]'), '');
    return 'custom_${slug.isEmpty ? 'section' : slug}';
  }

  Future<void> _importQuestions(Workbook workbook) async {
    final result = await Navigator.push<WorkbookImportSaveResult>(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherWorkbookImportScreen(workbook: workbook),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _recentImportedQuestionIds
        ..clear()
        ..addAll(result.savedQuestionIds);
      _showRecentImportedOnly = false;
      _future = _service.fetchWorkbook(
        widget.workbookId,
        sectionId: _selectedSectionId,
      );
      _assignmentFuture =
          _assignmentService.fetchTeacherWorkbookStatus(widget.workbookId);
    });
    final failed = result.failures.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failed == 0
              ? '${result.savedCount}개 문제를 가져왔습니다.'
              : '${result.savedCount}개 저장, $failed개 실패했습니다.',
        ),
      ),
    );
  }

  Future<void> _editQuestion(
    Workbook workbook,
    WorkbookQuestion question,
  ) async {
    final draft = await showDialog<WorkbookQuestionDraft>(
      context: context,
      builder: (_) => WorkbookQuestionEditorDialog(
        questionType: workbookEditorTypeForQuestion(question),
        initial: question,
        workbookSourceLabel: workbook.sourceLabel,
        workbookFolderName: workbook.folderName,
        workbookUnitLabel: workbook.unitLabel,
        sections: workbook.sections,
        initialSectionId: question.sectionId,
      ),
    );
    if (draft == null) return;
    try {
      await _service.updateQuestion(
        workbookId: widget.workbookId,
        questionId: question.id,
        questionType: question.questionType,
        prompt: draft.prompt,
        sectionId: question.sectionId,
        passageText: draft.passageText,
        choices: draft.choices,
        answer: draft.answer,
        explanation: draft.explanation,
        points: draft.points,
      );
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문제를 수정했습니다.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('문제 수정 실패: $error')),
      );
    }
  }

  Future<void> _deleteQuestion(WorkbookQuestion question) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문제를 삭제할까요?'),
        content: Text('${question.orderIndex}번 문제입니다. 삭제하면 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.deleteQuestion(
        workbookId: widget.workbookId,
        questionId: question.id,
      );
      if (!mounted) return;
      _recentImportedQuestionIds.remove(question.id);
      if (_recentImportedQuestionIds.isEmpty) {
        _showRecentImportedOnly = false;
      }
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문제를 삭제했습니다.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('문제 삭제 실패: $error')),
      );
    }
  }

  Future<void> _changeStatus(Workbook workbook, String status) async {
    try {
      await _service.updateWorkbook(workbook.id, status: status);
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상태 변경 실패: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('워크북 상세/편집'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<Workbook>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _StateCard(
              title: '워크북을 불러오지 못했습니다.',
              message: '${snapshot.error}',
              onRetry: _reload,
            );
          }
          final workbook = snapshot.data;
          if (workbook == null) {
            return _StateCard(
              title: '워크북을 찾을 수 없습니다.',
              message: '목록으로 돌아가 다시 선택해 주세요.',
              onRetry: _reload,
            );
          }
          final visibleQuestions = _showRecentImportedOnly
              ? workbook.questions
                  .where(
                    (question) =>
                        _recentImportedQuestionIds.contains(question.id),
                  )
                  .toList()
              : workbook.questions;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              _WorkbookInfoCard(
                workbook: workbook,
                onStatusChanged: (value) => _changeStatus(workbook, value),
              ),
              const SizedBox(height: 14),
              _WorkbookAssignmentPanel(
                future: _assignmentFuture,
                onAssign: () => _assignWorkbook(workbook),
                workbook: workbook,
              ),
              const SizedBox(height: 14),
              _AddQuestionPanel(
                onAdd: (type) => _addQuestion(workbook, type),
                onImport: () => _importQuestions(workbook),
              ),
              if (_recentImportedQuestionIds.isNotEmpty) ...[
                const SizedBox(height: 14),
                _RecentImportCard(
                  count: _recentImportedQuestionIds.length,
                  showRecentOnly: _showRecentImportedOnly,
                  deleting: _deletingRecentImport,
                  onShowRecentOnly: () {
                    setState(() => _showRecentImportedOnly = true);
                  },
                  onShowAll: () {
                    setState(() => _showRecentImportedOnly = false);
                  },
                  onDelete: _deleteRecentImport,
                ),
              ],
              const SizedBox(height: 14),
              _WorkbookSectionFilter(
                workbook: workbook,
                selectedSectionId: _selectedSectionId,
                onChanged: (sectionId) {
                  setState(() {
                    _selectedSectionId = sectionId;
                    _showRecentImportedOnly = false;
                    _future = _service.fetchWorkbook(
                      widget.workbookId,
                      sectionId: sectionId,
                    );
                    _assignmentFuture = _assignmentService
                        .fetchTeacherWorkbookStatus(widget.workbookId);
                  });
                },
              ),
              const SizedBox(height: 14),
              _SectionTitle(
                title: '문제 목록',
                subtitle: _showRecentImportedOnly
                    ? '방금 가져온 문제 ${visibleQuestions.length}개를 표시합니다.'
                    : '본문 선택형, 확인학습, T/F 문제를 직접 입력하고 관리합니다.',
              ),
              const SizedBox(height: 10),
              if (visibleQuestions.isEmpty)
                const _EmptyQuestionCard()
              else
                ...visibleQuestions.map(
                  (question) => _QuestionCard(
                    question: question,
                    isRecentImport:
                        _recentImportedQuestionIds.contains(question.id),
                    onEdit: () => _editQuestion(workbook, question),
                    onDelete: () => _deleteQuestion(question),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _WorkbookSectionFilter extends StatelessWidget {
  const _WorkbookSectionFilter({
    required this.workbook,
    required this.selectedSectionId,
    required this.onChanged,
  });

  final Workbook workbook;
  final int? selectedSectionId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final sections = workbook.sections;
    final sectionQuestionCount = sections.fold<int>(
      0,
      (sum, section) => sum + section.questionCount,
    );
    final unclassifiedCount =
        (workbook.totalQuestionCount - sectionQuestionCount)
            .clamp(0, 1 << 30)
            .toInt();
    if (sections.isEmpty && unclassifiedCount == 0) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _TeacherWorkbookDetailScreenState._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '섹션별 보기',
            style: TextStyle(
              color: _TeacherWorkbookDetailScreenState._ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '강 또는 Test 단위로 문제를 나누어 확인합니다.',
            style: TextStyle(
              color: _TeacherWorkbookDetailScreenState._muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SectionChoiceChip(
                label: '전체',
                count: workbook.totalQuestionCount,
                selected: selectedSectionId == null,
                onSelected: () => onChanged(null),
              ),
              for (final section in sections)
                _SectionChoiceChip(
                  label: section.title,
                  count: section.questionCount,
                  selected: selectedSectionId == section.id,
                  onSelected: () => onChanged(section.id),
                ),
              if (unclassifiedCount > 0)
                _SectionChoiceChip(
                  label: '미분류',
                  count: unclassifiedCount,
                  selected: selectedSectionId == 0,
                  onSelected: () => onChanged(0),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionChoiceChip extends StatelessWidget {
  const _SectionChoiceChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text('$label · $count문항'),
      onSelected: (_) => onSelected(),
      selectedColor: const Color(0xFFE0F2F1),
      backgroundColor: const Color(0xFFF8FAFC),
      side: BorderSide(
        color: selected
            ? _TeacherWorkbookDetailScreenState._teal
            : const Color(0xFFDDE7F0),
      ),
      labelStyle: TextStyle(
        color: selected
            ? _TeacherWorkbookDetailScreenState._teal
            : _TeacherWorkbookDetailScreenState._ink,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _WorkbookInfoCard extends StatelessWidget {
  const _WorkbookInfoCard({
    required this.workbook,
    required this.onStatusChanged,
  });

  final Workbook workbook;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final meta = _joinMetadata([
      workbook.sourceLabel,
      workbook.folderName,
      workbook.unitLabel,
      if (workbook.finalTouchId != null)
        'Final Touch #${workbook.finalTouchId}',
    ]);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _TeacherWorkbookDetailScreenState._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: _TeacherWorkbookDetailScreenState._teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  workbook.title,
                  style: const TextStyle(
                    color: _TeacherWorkbookDetailScreenState._ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              DropdownButton<String>(
                value: workbook.status,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('초안')),
                  DropdownMenuItem(value: 'published', child: Text('게시')),
                  DropdownMenuItem(value: 'archived', child: Text('보관')),
                ],
                onChanged: (value) {
                  if (value != null && value != workbook.status) {
                    onStatusChanged(value);
                  }
                },
              ),
            ],
          ),
          if ((workbook.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              workbook.description!,
              style: const TextStyle(
                color: _TeacherWorkbookDetailScreenState._muted,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(text: '${workbook.questionCount}문항'),
              _Chip(text: workbookStatusLabel(workbook.status)),
              if (meta.isNotEmpty) _Chip(text: meta),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '학생에게 배포하면 학생의 내 학습 화면에 워크북이 표시됩니다.',
            style: TextStyle(
              color: _TeacherWorkbookDetailScreenState._muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkbookAssignmentPanel extends StatelessWidget {
  const _WorkbookAssignmentPanel({
    required this.future,
    required this.onAssign,
    required this.workbook,
  });

  final Future<List<LearningAssignment>> future;
  final VoidCallback onAssign;
  final Workbook workbook;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _TeacherWorkbookDetailScreenState._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '학생 배포 현황',
                      style: TextStyle(
                        color: _TeacherWorkbookDetailScreenState._ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '워크북 시작/완료 상태를 학생별로 확인합니다. 답안 저장과 채점은 다음 단계에서 연결합니다.',
                      style: TextStyle(
                        color: _TeacherWorkbookDetailScreenState._muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onAssign,
                icon: const Icon(Icons.send_rounded),
                label: const Text('학생에게 배포'),
                style: FilledButton.styleFrom(
                  backgroundColor: _TeacherWorkbookDetailScreenState._primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<LearningAssignment>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 3),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  '배포 현황을 불러오지 못했습니다. ${snapshot.error}',
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w700,
                  ),
                );
              }
              final items = snapshot.data ?? const [];
              final assigned =
                  items.where((item) => item.status == 'assigned').length;
              final inProgress =
                  items.where((item) => item.status == 'in_progress').length;
              final completed =
                  items.where((item) => item.status == 'completed').length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(text: '총 ${items.length}명'),
                      _Chip(text: '미시작 $assigned명'),
                      _Chip(text: '진행 중 $inProgress명'),
                      _Chip(text: '완료 $completed명'),
                    ],
                  ),
                  if (items.isEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      '아직 배포된 학생이 없습니다.',
                      style: TextStyle(
                        color: _TeacherWorkbookDetailScreenState._muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    ...items.map(
                      (item) => _AssignmentStudentRow(
                        assignment: item,
                        workbookTitle: workbook.title,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AssignmentStudentRow extends StatelessWidget {
  const _AssignmentStudentRow({
    required this.assignment,
    required this.workbookTitle,
  });

  final LearningAssignment assignment;
  final String workbookTitle;

  @override
  Widget build(BuildContext context) {
    final status = assignment.displayStatus ?? assignment.status;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  assignment.studentName ?? 'student${assignment.studentId}',
                  style: const TextStyle(
                    color: _TeacherWorkbookDetailScreenState._ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _Chip(text: _assignmentStatusLabel(status)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _SmallMeta(text: '배포 ${_dateText(assignment.assignedAt)}'),
              _SmallMeta(text: '시작 ${_dateOrDash(assignment.startedAt)}'),
              _SmallMeta(text: '완료 ${_dateOrDash(assignment.completedAt)}'),
              _SmallMeta(text: '마감 ${_dateOrDash(assignment.dueAt)}'),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _showWorkbookResultDialog(
                context,
                assignment: assignment,
                workbookTitle: workbookTitle,
              ),
              icon: const Icon(Icons.insights_rounded, size: 17),
              label: const Text('결과 보기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallMeta extends StatelessWidget {
  const _SmallMeta({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _TeacherWorkbookDetailScreenState._muted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _RecentImportCard extends StatelessWidget {
  const _RecentImportCard({
    required this.count,
    required this.showRecentOnly,
    required this.deleting,
    required this.onShowRecentOnly,
    required this.onShowAll,
    required this.onDelete,
  });

  final int count;
  final bool showRecentOnly;
  final bool deleting;
  final VoidCallback onShowRecentOnly;
  final VoidCallback onShowAll;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.new_releases_outlined, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                '방금 가져온 문제',
                style: TextStyle(
                  color: _TeacherWorkbookDetailScreenState._ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('$count개 문제가 추가되었습니다.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: showRecentOnly ? null : onShowRecentOnly,
                icon: const Icon(Icons.filter_alt_outlined),
                label: const Text('방금 가져온 문제만 보기'),
              ),
              OutlinedButton.icon(
                onPressed: showRecentOnly ? onShowAll : null,
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('전체 문제 보기'),
              ),
              FilledButton.icon(
                onPressed: deleting ? null : onDelete,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                ),
                icon: deleting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.undo_rounded),
                label: Text(deleting ? '삭제 중...' : '방금 가져온 문제 삭제'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddQuestionPanel extends StatelessWidget {
  const _AddQuestionPanel({required this.onAdd, required this.onImport});

  final ValueChanged<String> onAdd;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _TeacherWorkbookDetailScreenState._line),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _AddQuestionButton(
            onPressed: onImport,
            icon: const Icon(Icons.content_paste_go_rounded),
            label: '문제 묶음 가져오기',
          ),
          _AddQuestionButton(
            onPressed: () => onAdd('inline_choice'),
            icon: const Icon(Icons.radio_button_checked_rounded),
            label: '본문 선택형 추가',
          ),
          _AddQuestionButton(
            onPressed: () => onAdd('check_learning_set'),
            icon: const Icon(Icons.fact_check_outlined),
            label: '확인학습 추가',
          ),
          _AddQuestionButton(
            onPressed: () => onAdd('true_false_en'),
            icon: const Icon(Icons.rule_rounded),
            label: '영어 T/F 추가',
          ),
          _AddQuestionButton(
            onPressed: () => onAdd('true_false_ko'),
            icon: const Icon(Icons.translate_rounded),
            label: '한글 T/F 추가',
          ),
          _AddQuestionButton(
            onPressed: () => onAdd('initial_blank'),
            icon: const Icon(Icons.short_text_rounded),
            label: '첫 글자 빈칸 추가',
          ),
          _AddQuestionButton(
            onPressed: () => onAdd('sentence_insertion'),
            icon: const Icon(Icons.input_rounded),
            label: '문장 삽입 추가',
          ),
          _AddQuestionButton(
            onPressed: () => onAdd('paragraph_order'),
            icon: const Icon(Icons.reorder_rounded),
            label: '문단 배열 추가',
          ),
        ],
      ),
    );
  }
}

class _AddQuestionButton extends StatelessWidget {
  const _AddQuestionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFEFF6FF),
        foregroundColor: _TeacherWorkbookDetailScreenState._primary,
        side: const BorderSide(color: Color(0xFFBFDBFE)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.isRecentImport,
    required this.onEdit,
    required this.onDelete,
  });

  final WorkbookQuestion question;
  final bool isRecentImport;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final contentPassage = _asString(question.answer['passage_text']);
    final passage = (question.passageText ?? '').isNotEmpty
        ? question.passageText!
        : contentPassage;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isRecentImport ? const Color(0xFFF8FBFF) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRecentImport
              ? const Color(0xFF93C5FD)
              : _TeacherWorkbookDetailScreenState._line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRecentImport) ...[
            const _Chip(text: '방금 가져옴'),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              _Chip(text: '${question.orderIndex}번'),
              const SizedBox(width: 6),
              _Chip(text: workbookQuestionDisplayLabel(question)),
              const Spacer(),
              IconButton(
                tooltip: '수정',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: '삭제',
                onPressed: onDelete,
                icon:
                    const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.prompt,
            style: const TextStyle(
              color: _TeacherWorkbookDetailScreenState._ink,
              fontWeight: FontWeight.w900,
              height: 1.4,
            ),
          ),
          if (passage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              passage,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _TeacherWorkbookDetailScreenState._muted,
                height: 1.35,
              ),
            ),
          ],
          if (question.choices.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...question.choices.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${entry.key + 1}. ${entry.value}',
                      style: const TextStyle(
                        color: _TeacherWorkbookDetailScreenState._muted,
                      ),
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 8),
          Text(
            '구성: ${workbookAnswerSummary(question)}',
            style: const TextStyle(
              color: _TeacherWorkbookDetailScreenState._teal,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (question.questionType == 'true_false' &&
              question.answer['items'] is List) ...[
            const SizedBox(height: 8),
            _TeacherTrueFalseSummary(question: question),
          ],
          if ((question.explanation ?? '').isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              '해설: ${question.explanation}',
              style: const TextStyle(
                color: _TeacherWorkbookDetailScreenState._muted,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeacherTrueFalseSummary extends StatelessWidget {
  const _TeacherTrueFalseSummary({required this.question});

  final WorkbookQuestion question;

  @override
  Widget build(BuildContext context) {
    final rawItems = question.answer['items'];
    if (rawItems is! List) return const SizedBox.shrink();
    final items = rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'T/F 정답·해설',
            style: TextStyle(
              color: _TeacherWorkbookDetailScreenState._ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          ...items.take(5).map((item) {
            final number = item['number'] ?? '';
            final statement = (item['statement'] ?? '').toString();
            final answer = item['answer'] == true ? 'T' : 'F';
            final explanation = (item['explanation'] ?? '').toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '$number. $statement\n정답: $answer'
                '${explanation.isEmpty ? '' : ' · 해설: $explanation'}',
                style: const TextStyle(
                  color: _TeacherWorkbookDetailScreenState._muted,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _TeacherWorkbookDetailScreenState._ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style:
              const TextStyle(color: _TeacherWorkbookDetailScreenState._muted),
        ),
      ],
    );
  }
}

class _EmptyQuestionCard extends StatelessWidget {
  const _EmptyQuestionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _TeacherWorkbookDetailScreenState._line),
      ),
      child: const Text(
        '아직 문제가 없습니다. 본문 선택형, 확인학습, T/F 문제를 직접 추가해 주세요.',
        style: TextStyle(color: _TeacherWorkbookDetailScreenState._muted),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_outlined,
              color: _TeacherWorkbookDetailScreenState._teal,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: _TeacherWorkbookDetailScreenState._ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _TeacherWorkbookDetailScreenState._muted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _TeacherWorkbookDetailScreenState._muted,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
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

String _assignmentStatusLabel(String status) {
  return switch (status) {
    'completed' => '완료',
    'in_progress' => '진행 중',
    'overdue' => '마감 지남',
    _ => '미시작',
  };
}

void _showWorkbookResultDialog(
  BuildContext context, {
  required LearningAssignment assignment,
  required String workbookTitle,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _TeacherWorkbookDetailScreenState._line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A0F172A),
                blurRadius: 28,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: FutureBuilder<TeacherWorkbookAttemptReport>(
            future: const WorkbookAttemptService()
                .fetchTeacherAssignmentReport(assignment.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return _TeacherAttemptError(
                  message: '${snapshot.error}',
                  assignment: assignment,
                  workbookTitle: workbookTitle,
                );
              }
              final report = snapshot.data;
              if (report == null) {
                return _TeacherAttemptError(
                  message: '표시할 결과가 없습니다.',
                  assignment: assignment,
                  workbookTitle: workbookTitle,
                );
              }
              return _TeacherAttemptReportContent(report: report);
            },
          ),
        ),
      ),
    ),
  );
}

class _TeacherAttemptError extends StatelessWidget {
  const _TeacherAttemptError({
    required this.message,
    required this.assignment,
    required this.workbookTitle,
  });

  final String message;
  final LearningAssignment assignment;
  final String workbookTitle;

  @override
  Widget build(BuildContext context) {
    final status = assignment.displayStatus ?? assignment.status;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TeacherAttemptDialogTitle(),
        const SizedBox(height: 16),
        _ResultLine(
          label: '학생',
          value: assignment.studentName ?? 'student${assignment.studentId}',
        ),
        _ResultLine(label: '워크북', value: workbookTitle),
        _ResultLine(label: '상태', value: _assignmentStatusLabel(status)),
        const SizedBox(height: 12),
        Text(
          message,
          style: const TextStyle(
            color: _TeacherWorkbookDetailScreenState._muted,
            height: 1.45,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: _TeacherWorkbookDetailScreenState._primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('닫기'),
          ),
        ),
      ],
    );
  }
}

class _TeacherAttemptReportContent extends StatelessWidget {
  const _TeacherAttemptReportContent({required this.report});

  final TeacherWorkbookAttemptReport report;

  @override
  Widget build(BuildContext context) {
    final latest = report.latestAttempt;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TeacherAttemptDialogTitle(),
          const SizedBox(height: 16),
          _ResultLine(label: '학생', value: report.studentName),
          _ResultLine(label: '워크북', value: report.workbookTitle),
          _ResultLine(
            label: '상태',
            value: _assignmentStatusLabel(report.assignmentStatus),
          ),
          _ResultLine(label: '완료일', value: _dateOrDash(report.completedAt)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5EAF3)),
            ),
            child: latest == null
                ? const Text(
                    '아직 제출된 워크북 attempt가 없습니다.',
                    style: TextStyle(
                      color: _TeacherWorkbookDetailScreenState._muted,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Wrap(
                    spacing: 18,
                    runSpacing: 12,
                    children: [
                      _TeacherResultMetric(
                        label: '최근 점수',
                        value: '${_formatScore(latest.scorePercent)}점',
                      ),
                      _TeacherResultMetric(
                        label: '정답',
                        value:
                            '${latest.correctCount}/${latest.totalQuestions}',
                      ),
                      _TeacherResultMetric(
                        label: '시도',
                        value: '${report.attemptCount}회',
                      ),
                      _TeacherResultMetric(
                        label: '최근 제출',
                        value: _dateOrDash(latest.submittedAt),
                      ),
                    ],
                  ),
          ),
          if (report.attempts.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              '시도 기록',
              style: TextStyle(
                color: _TeacherWorkbookDetailScreenState._ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ...report.attempts.map(_TeacherAttemptRow.new),
          ],
          if (latest != null) ...[
            const SizedBox(height: 14),
            const Text(
              '최근 문항별 결과',
              style: TextStyle(
                color: _TeacherWorkbookDetailScreenState._ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            if (latest.results.isEmpty)
              const Text(
                '표시할 문항별 결과가 없습니다.',
                style:
                    TextStyle(color: _TeacherWorkbookDetailScreenState._muted),
              )
            else
              ...latest.results.map(_TeacherAttemptAnswerTile.new),
          ],
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: _TeacherWorkbookDetailScreenState._primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('닫기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherAttemptDialogTitle extends StatelessWidget {
  const _TeacherAttemptDialogTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.assignment_turned_in_rounded,
            color: _TeacherWorkbookDetailScreenState._teal,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            '워크북 결과',
            style: TextStyle(
              color: _TeacherWorkbookDetailScreenState._ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _TeacherResultMetric extends StatelessWidget {
  const _TeacherResultMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _TeacherWorkbookDetailScreenState._muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: _TeacherWorkbookDetailScreenState._ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherAttemptRow extends StatelessWidget {
  const _TeacherAttemptRow(this.attempt);

  final WorkbookAttempt attempt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${attempt.attemptNo}회차 · ${_dateOrDash(attempt.submittedAt)}',
              style: const TextStyle(
                color: _TeacherWorkbookDetailScreenState._ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '${_formatScore(attempt.scorePercent)}점',
            style: const TextStyle(
              color: _TeacherWorkbookDetailScreenState._teal,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherAttemptAnswerTile extends StatelessWidget {
  const _TeacherAttemptAnswerTile(this.result);

  final WorkbookAttemptAnswerResult result;

  @override
  Widget build(BuildContext context) {
    final color =
        result.isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final titleNumber =
        result.itemNumber == null ? '' : ' ${result.itemNumber}번';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.isCorrect
            ? const Color(0xFFEFFDF5)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                result.isCorrect ? 'O' : 'X',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_questionTypeLabel(result.questionType)}$titleNumber',
                  style: const TextStyle(
                    color: _TeacherWorkbookDetailScreenState._ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '학생 답: ${_emptyDash(result.studentAnswer)}',
            style: const TextStyle(
              color: _TeacherWorkbookDetailScreenState._ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '정답: ${_emptyDash(result.correctAnswer)}',
            style: const TextStyle(
              color: _TeacherWorkbookDetailScreenState._ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          if ((result.explanation ?? '').trim().isNotEmpty)
            Text(
              '해설: ${result.explanation!.trim()}',
              style: const TextStyle(
                color: _TeacherWorkbookDetailScreenState._muted,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: _TeacherWorkbookDetailScreenState._muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _TeacherWorkbookDetailScreenState._ink,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _dateOrDash(String? value) {
  if (value == null || value.trim().isEmpty) return '-';
  return _dateText(value);
}

String _dateText(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value.length >= 16 ? value.substring(0, 16) : value;
  }
  final local = parsed.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _formatScore(double value) {
  return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
}

String _emptyDash(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? '미응답' : text;
}

String _questionTypeLabel(String type) {
  return switch (type) {
    'inline_choice' => '본문 선택형',
    'true_false' => 'T/F',
    'multiple_choice' => '선택형',
    'check_learning_set' => '확인학습',
    'initial_blank' => '첫 글자 빈칸',
    'sentence_insertion' => '문장 삽입',
    'paragraph_order' => '문단 배열',
    'check_learning_set:A' => '확인학습',
    'check_learning_set:B' => '확인학습',
    'check_learning_set:C' => '확인학습',
    _ => type,
  };
}

String _asString(dynamic value) {
  if (value == null) return '';
  final text = value.toString();
  return text == 'null' ? '' : text;
}
