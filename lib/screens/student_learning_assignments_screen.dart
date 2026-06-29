import 'package:flutter/material.dart';

import '../models/learning_assignment.dart';
import '../models/workbook_attempt.dart';
import '../services/learning_assignment_service.dart';
import '../services/workbook_attempt_service.dart';
import 'final_touch_list_screen.dart';
import 'student_workbook_view_screen.dart';

class StudentLearningAssignmentsScreen extends StatefulWidget {
  const StudentLearningAssignmentsScreen({super.key});

  @override
  State<StudentLearningAssignmentsScreen> createState() =>
      _StudentLearningAssignmentsScreenState();
}

class _StudentLearningAssignmentsScreenState
    extends State<StudentLearningAssignmentsScreen> {
  static const _surface = Color(0xFFF6F8FC);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF64748B);
  static const _blue = Color(0xFF2563EB);
  static const _violet = Color(0xFF7C3AED);
  static const _line = Color(0xFFE2E8F0);

  final _service = const LearningAssignmentService();
  final _attemptService = const WorkbookAttemptService();
  late Future<List<LearningAssignment>> _future;
  Map<int, WorkbookAttempt?> _latestWorkbookAttempts = {};
  String _filter = 'all';
  String _typeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _future = _loadAssignments();
  }

  void _reload() {
    setState(() {
      _future = _loadAssignments();
    });
  }

  Future<List<LearningAssignment>> _loadAssignments() async {
    final items = await _service.fetchStudentAssignments();
    final workbookItems = items.where((item) => item.isWorkbook).toList();
    final entries = await Future.wait(
      workbookItems.map((item) async {
        try {
          final latest = await _attemptService.fetchLatestForStudent(item.id);
          return MapEntry(item.id, latest);
        } catch (_) {
          return MapEntry<int, WorkbookAttempt?>(item.id, null);
        }
      }),
    );
    _latestWorkbookAttempts = Map<int, WorkbookAttempt?>.fromEntries(entries);
    return items;
  }

  List<LearningAssignment> _filtered(List<LearningAssignment> items) {
    Iterable<LearningAssignment> filtered = items;
    if (_typeFilter != 'all') {
      filtered = filtered.where((item) => item.contentType == _typeFilter);
    }
    if (_filter == 'todo') {
      filtered = filtered.where((item) => item.status == 'assigned');
    } else if (_filter == 'in_progress') {
      filtered = filtered.where((item) => item.status == 'in_progress');
    } else if (_filter == 'completed') {
      filtered = filtered.where((item) => item.status == 'completed');
    }
    return filtered.toList();
  }

  Future<void> _openAssignment(LearningAssignment assignment) async {
    var current = assignment;
    if (assignment.status == 'assigned') {
      try {
        current = await _service.startAssignment(assignment.id);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('학습 시작 처리 실패: $error')),
        );
        return;
      }
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => current.isWorkbook
            ? StudentWorkbookViewScreen(assignment: current)
            : FinalTouchDetailScreen(
                id: current.contentId,
                assignment: current,
              ),
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          '내 학습',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<LearningAssignment>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _MessageState(
                icon: Icons.error_outline_rounded,
                title: '내 학습을 불러오지 못했습니다.',
                message: '${snapshot.error}',
                onRetry: _reload,
              );
            }

            final allItems = snapshot.data ?? const [];
            final items = _filtered(allItems);

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 112),
              children: [
                _HeaderCard(total: allItems.length),
                const SizedBox(height: 14),
                _FilterBar(
                  selected: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: 10),
                _TypeFilterBar(
                  selected: _typeFilter,
                  onChanged: (value) => setState(() => _typeFilter = value),
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  const _EmptyAssignments()
                else
                  ...items.map(
                    (item) => _AssignmentCard(
                      assignment: item,
                      latestAttempt: _latestWorkbookAttempts[item.id],
                      onTap: () => _openAssignment(item),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD8E8FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.assignment_ind_rounded,
              color: _StudentLearningAssignmentsScreenState._blue,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '선생님이 배포한 학습',
                  style: TextStyle(
                    color: _StudentLearningAssignmentsScreenState._ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  total > 0
                      ? '배포된 자료 $total개를 확인하고 진행 상태를 관리해요.'
                      : '선생님이 자료를 배포하면 이곳에 표시됩니다.',
                  style: const TextStyle(
                    color: _StudentLearningAssignmentsScreenState._muted,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('all', '전체'),
      ('todo', '해야 할 학습'),
      ('in_progress', '진행 중'),
      ('completed', '완료'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items) ...[
            _FilterChipButton(
              label: item.$2,
              selected: selected == item.$1,
              onTap: () => onChanged(item.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor:
          _StudentLearningAssignmentsScreenState._blue.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        color: selected
            ? _StudentLearningAssignmentsScreenState._blue
            : _StudentLearningAssignmentsScreenState._muted,
        fontWeight: FontWeight.w900,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected
              ? const Color(0xFFBFDBFE)
              : _StudentLearningAssignmentsScreenState._line,
        ),
      ),
    );
  }
}

class _TypeFilterBar extends StatelessWidget {
  const _TypeFilterBar({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('all', '전체'),
      ('workbook', '워크북'),
      ('final_touch', 'Final Touch'),
      ('mock_exam', '모의고사'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items) ...[
            _FilterChipButton(
              label: item.$2,
              selected: selected == item.$1,
              onTap: () => onChanged(item.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.latestAttempt,
    required this.onTap,
  });

  final LearningAssignment assignment;
  final WorkbookAttempt? latestAttempt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final overdue = _isOverdue(assignment);
    final status = overdue ? 'overdue' : assignment.status;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _StudentLearningAssignmentsScreenState._line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TypeChip(contentType: assignment.contentType),
              const SizedBox(width: 8),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            assignment.title.isEmpty
                ? (assignment.isWorkbook ? '워크북 학습' : 'Final Touch 학습')
                : assignment.title,
            style: const TextStyle(
              color: _StudentLearningAssignmentsScreenState._ink,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              if ((assignment.sourceLabel ?? '').isNotEmpty)
                _InfoChip(text: assignment.sourceLabel!),
              if ((assignment.folderName ?? '').isNotEmpty)
                _InfoChip(text: assignment.folderName!),
              _InfoChip(text: '배포 ${_dateText(assignment.assignedAt)}'),
              if ((assignment.dueAt ?? '').isNotEmpty)
                _InfoChip(text: '마감 ${_dateText(assignment.dueAt!)}'),
            ],
          ),
          if ((assignment.teacherName ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '배포한 선생님: ${assignment.teacherName}',
              style: const TextStyle(
                color: _StudentLearningAssignmentsScreenState._muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if ((assignment.teacherMessage ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5EAF3)),
              ),
              child: Text(
                assignment.teacherMessage!,
                style: const TextStyle(
                  color: _StudentLearningAssignmentsScreenState._muted,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (assignment.isWorkbook && assignment.isCompleted) ...[
            const SizedBox(height: 10),
            _WorkbookAttemptSummary(attempt: latestAttempt),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: onTap,
              icon: Icon(_buttonIcon(assignment.status)),
              label: Text(_buttonLabel(assignment)),
              style: FilledButton.styleFrom(
                backgroundColor: assignment.isCompleted
                    ? _StudentLearningAssignmentsScreenState._violet
                    : _StudentLearningAssignmentsScreenState._blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isOverdue(LearningAssignment item) {
    if (item.isCompleted || item.dueAt == null) return false;
    final due = DateTime.tryParse(item.dueAt!);
    if (due == null) return false;
    return due.isBefore(DateTime.now());
  }

  String _buttonLabel(LearningAssignment assignment) {
    final status = assignment.status;
    if (status == 'completed') {
      if (assignment.isWorkbook) {
        return latestAttempt == null ? '다시 풀기' : '결과 보기 / 다시 풀기';
      }
      return '다시 보기';
    }
    if (status == 'in_progress') return '이어하기';
    return '시작하기';
  }

  IconData _buttonIcon(String status) {
    if (status == 'completed') return Icons.replay_rounded;
    if (status == 'in_progress') return Icons.play_arrow_rounded;
    return Icons.flag_rounded;
  }
}

class _WorkbookAttemptSummary extends StatelessWidget {
  const _WorkbookAttemptSummary({required this.attempt});

  final WorkbookAttempt? attempt;

  @override
  Widget build(BuildContext context) {
    final item = attempt;
    if (item == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Text(
          '제출 결과 없음 · 다시 풀기 후 제출하면 결과를 확인할 수 있습니다.',
          style: TextStyle(
            color: Color(0xFF92400E),
            height: 1.35,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근 점수 ${_formatScore(item.scorePercent)}점 · ${item.attemptNo}회차',
            style: const TextStyle(
              color: Color(0xFF166534),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '정답 ${item.correctCount}/${item.totalQuestions} · 최근 제출 ${_dateTimeText(item.submittedAt)}',
            style: const TextStyle(
              color: _StudentLearningAssignmentsScreenState._muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.contentType});

  final String contentType;

  @override
  Widget build(BuildContext context) {
    final color = switch (contentType) {
      'workbook' => const Color(0xFF0F766E),
      'mock_exam' => const Color(0xFF0891B2),
      _ => _StudentLearningAssignmentsScreenState._blue,
    };
    final icon = switch (contentType) {
      'workbook' => Icons.menu_book_rounded,
      'mock_exam' => Icons.assignment_rounded,
      _ => Icons.auto_stories_rounded,
    };
    final label = switch (contentType) {
      'workbook' => 'Workbook',
      'mock_exam' => 'Mock Exam',
      _ => 'Final Touch',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' => const Color(0xFF16A34A),
      'in_progress' => _StudentLearningAssignmentsScreenState._blue,
      'overdue' => const Color(0xFFEA580C),
      _ => _StudentLearningAssignmentsScreenState._muted,
    };
    final label = switch (status) {
      'completed' => '완료',
      'in_progress' => '진행 중',
      'overdue' => '마감 지남',
      _ => '미시작',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _StudentLearningAssignmentsScreenState._muted,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyAssignments extends StatelessWidget {
  const _EmptyAssignments();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _StudentLearningAssignmentsScreenState._line),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: _StudentLearningAssignmentsScreenState._blue,
            size: 38,
          ),
          SizedBox(height: 12),
          Text(
            '아직 배포된 학습 자료가 없습니다.',
            style: TextStyle(
              color: _StudentLearningAssignmentsScreenState._ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7),
          Text(
            '선생님이 자료를 배포하면 이곳에서 확인할 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _StudentLearningAssignmentsScreenState._muted,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 80, 18, 112),
      children: [
        Icon(icon,
            color: _StudentLearningAssignmentsScreenState._blue, size: 42),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _StudentLearningAssignmentsScreenState._ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _StudentLearningAssignmentsScreenState._muted,
            height: 1.4,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onRetry,
            child: const Text('다시 시도'),
          ),
        ],
      ],
    );
  }
}

String _dateText(String raw) {
  final datePart = raw.split(' ').first.split('T').first;
  if (datePart.length >= 10) return datePart;
  return raw;
}

String _dateTimeText(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw.length >= 16 ? raw.substring(0, 16) : raw;
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
