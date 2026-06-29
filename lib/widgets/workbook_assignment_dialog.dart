import 'package:flutter/material.dart';

import '../models/learning_assignment.dart';
import '../models/workbook.dart';
import '../services/learning_assignment_service.dart';

class WorkbookAssignmentDialog extends StatefulWidget {
  const WorkbookAssignmentDialog({
    super.key,
    required this.workbook,
  });

  final Workbook workbook;

  @override
  State<WorkbookAssignmentDialog> createState() =>
      _WorkbookAssignmentDialogState();
}

class _WorkbookAssignmentDialogState extends State<WorkbookAssignmentDialog> {
  static const _primary = Color(0xFF183B56);
  static const _teal = Color(0xFF0F766E);
  static const _surface = Color(0xFFF4F7FA);
  static const _ink = Color(0xFF102A43);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);

  final _service = const LearningAssignmentService();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final Set<int> _selectedIds = {};

  late Future<List<AssignableStudent>> _studentsFuture;
  DateTime? _dueAt;
  bool _isSaving = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _studentsFuture = _service.fetchStudents();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      initialDate: _dueAt ?? now.add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _ink,
              secondary: _teal,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _dueAt = DateTime(picked.year, picked.month, picked.day, 23, 59);
    });
  }

  Future<void> _assign() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('배포할 학생을 선택해 주세요.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final result = await _service.assignWorkbook(
        workbookId: widget.workbook.id,
        studentIds: _selectedIds.toList(),
        title: widget.workbook.title,
        teacherMessage: _messageController.text,
        dueAt: _dueAt,
      );
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('워크북 배포 실패: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(workbook: widget.workbook),
              const SizedBox(height: 14),
              _WorkbookSummary(workbook: widget.workbook),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: '학생 이름 또는 이메일 검색',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _line),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<AssignableStudent>>(
                  future: _studentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('학생 목록 로드 실패: ${snapshot.error}'),
                      );
                    }
                    final students =
                        (snapshot.data ?? const []).where((student) {
                      final q = _query.toLowerCase();
                      if (q.isEmpty) return true;
                      return student.nickname.toLowerCase().contains(q) ||
                          student.email.toLowerCase().contains(q);
                    }).toList();
                    if (students.isEmpty) {
                      return const Center(child: Text('표시할 학생이 없습니다.'));
                    }
                    return Column(
                      children: [
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedIds
                                    ..clear()
                                    ..addAll(
                                      students.map((student) => student.id),
                                    );
                                });
                              },
                              icon: const Icon(Icons.done_all_rounded),
                              label: const Text('전체 선택'),
                            ),
                            TextButton(
                              onPressed: () => setState(_selectedIds.clear),
                              child: const Text('선택 해제'),
                            ),
                            const Spacer(),
                            Text(
                              '${_selectedIds.length}명 선택',
                              style: const TextStyle(
                                color: _muted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: ListView.separated(
                            itemCount: students.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final student = students[index];
                              final selected =
                                  _selectedIds.contains(student.id);
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    if (selected) {
                                      _selectedIds.remove(student.id);
                                    } else {
                                      _selectedIds.add(student.id);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF99F6E4)
                                          : _line,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: selected,
                                        onChanged: (_) {
                                          setState(() {
                                            if (selected) {
                                              _selectedIds.remove(student.id);
                                            } else {
                                              _selectedIds.add(student.id);
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              student.nickname,
                                              style: const TextStyle(
                                                color: _ink,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            if (student.email.isNotEmpty)
                                              Text(
                                                student.email,
                                                style: const TextStyle(
                                                  color: _muted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '선생님 메모 선택',
                  hintText: '학생에게 보여줄 안내를 입력하세요.',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _isSaving ? null : _pickDueDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _line),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded, color: _teal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _dueAt == null
                              ? '마감일 선택'
                              : '마감일 ${_formatDate(_dueAt!)}',
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          _isSaving || _selectedIds.isEmpty ? null : _assign,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(_isSaving ? '배포 중...' : '배포하기'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                      ),
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

class _Header extends StatelessWidget {
  const _Header({required this.workbook});

  final Workbook workbook;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _WorkbookAssignmentDialogState._line),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.send_rounded,
              color: _WorkbookAssignmentDialogState._teal,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '학생에게 워크북 배포',
                  style: TextStyle(
                    color: _WorkbookAssignmentDialogState._ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '선택한 학생의 내 학습 화면에 워크북을 추가합니다.',
                  style: TextStyle(
                    color: _WorkbookAssignmentDialogState._muted,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

class _WorkbookSummary extends StatelessWidget {
  const _WorkbookSummary({required this.workbook});

  final Workbook workbook;

  @override
  Widget build(BuildContext context) {
    final meta = [
      workbook.sourceLabel,
      workbook.folderName,
      workbook.unitLabel,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workbook.title,
            style: const TextStyle(
              color: _WorkbookAssignmentDialogState._ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              meta,
              style: const TextStyle(
                color: _WorkbookAssignmentDialogState._muted,
                fontSize: 12.5,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${workbook.questionCount}문항 · ${workbookStatusLabel(workbook.status)}',
            style: const TextStyle(
              color: _WorkbookAssignmentDialogState._teal,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}.$month.$day';
}
