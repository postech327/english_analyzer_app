import 'package:flutter/material.dart';

import '../models/learning_assignment.dart';
import '../services/learning_assignment_service.dart';
import '../services/teacher_problem_set_service.dart';

class ProblemSetAssignmentDialog extends StatefulWidget {
  const ProblemSetAssignmentDialog({
    super.key,
    required this.problemSetId,
    required this.title,
  });

  final int problemSetId;
  final String title;

  @override
  State<ProblemSetAssignmentDialog> createState() =>
      _ProblemSetAssignmentDialogState();
}

class _ProblemSetAssignmentDialogState
    extends State<ProblemSetAssignmentDialog> {
  final _studentService = const LearningAssignmentService();
  late Future<List<AssignableStudent>> _future;
  final Set<int> _selectedIds = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _studentService.fetchStudents();
  }

  Future<void> _assign() async {
    if (_selectedIds.isEmpty || _saving) return;
    setState(() => _saving = true);

    var success = 0;
    final failed = <String>[];

    for (final studentId in _selectedIds) {
      try {
        await TeacherProblemSetService.assignProblemSetToStudent(
          problemSetId: widget.problemSetId,
          studentId: studentId,
        );
        success += 1;
      } catch (e) {
        failed.add('student$studentId');
      }
    }

    if (!mounted) return;
    Navigator.pop(
      context,
      ProblemSetAssignmentResult(successCount: success, failed: failed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.group_add_rounded,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '학생에게 배포',
                          style: TextStyle(
                            color: Color(0xFF172033),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  _selectedIds.isEmpty
                      ? '배포할 학생을 선택해 주세요.'
                      : '선택 ${_selectedIds.length}명 · 선택한 학생에게 문제세트를 배포합니다.',
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: FutureBuilder<List<AssignableStudent>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _DialogMessage(
                        icon: Icons.error_outline_rounded,
                        message: '학생 목록을 불러오지 못했습니다.\n${snapshot.error}',
                      );
                    }
                    final students = snapshot.data ?? const [];
                    if (students.isEmpty) {
                      return const _DialogMessage(
                        icon: Icons.person_off_outlined,
                        message: '배포 가능한 학생이 없습니다.',
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: students.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final selected = _selectedIds.contains(student.id);
                        return _StudentSelectCard(
                          student: student,
                          selected: selected,
                          onTap: _saving
                              ? null
                              : () {
                                  setState(() {
                                    if (selected) {
                                      _selectedIds.remove(student.id);
                                    } else {
                                      _selectedIds.add(student.id);
                                    }
                                  });
                                },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed:
                          _saving || _selectedIds.isEmpty ? null : _assign,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(_saving ? '배포 중...' : '선택 학생에게 배포'),
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

class ProblemSetAssignmentResult {
  const ProblemSetAssignmentResult({
    required this.successCount,
    required this.failed,
  });

  final int successCount;
  final List<String> failed;
}

class _StudentSelectCard extends StatelessWidget {
  const _StudentSelectCard({
    required this.student,
    required this.selected,
    required this.onTap,
  });

  final AssignableStudent student;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.nickname,
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (student.email.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      student.email,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFDBEAFE)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                selected ? '선택됨' : '배포 가능',
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF475569),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogMessage extends StatelessWidget {
  const _DialogMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF64748B), size: 34),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
