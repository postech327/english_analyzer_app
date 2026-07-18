import 'package:flutter/material.dart';

import '../../models/student_assigned_problem_set.dart';
import '../../services/student_problem_set_assignment_service.dart';
import 'student_exam_take_screen.dart';

class StudentAssignedProblemSetsScreen extends StatefulWidget {
  const StudentAssignedProblemSetsScreen({super.key});

  @override
  State<StudentAssignedProblemSetsScreen> createState() =>
      _StudentAssignedProblemSetsScreenState();
}

class _StudentAssignedProblemSetsScreenState
    extends State<StudentAssignedProblemSetsScreen> {
  static const _surface = Color(0xFFF6F8FC);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _blue = Color(0xFF2563EB);
  static const _line = Color(0xFFE5E7EB);

  final _service = const StudentProblemSetAssignmentService();
  late Future<List<StudentAssignedProblemSet>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchAssignedProblemSets();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.fetchAssignedProblemSets();
    });
    await _future;
  }

  void _openExam(StudentAssignedProblemSet item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentExamTakeScreen(problemSetId: item.problemSetId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: _surface,
        title: const Text(
          '선생님 배포 문제세트',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<StudentAssignedProblemSet>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _MessageList(
                icon: Icons.error_outline_rounded,
                title: '배포 문제세트를 불러오지 못했습니다.',
                message: snapshot.error.toString(),
              );
            }
            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
              return const _MessageList(
                icon: Icons.assignment_outlined,
                title: '아직 배포된 문제세트가 없습니다.',
                message: '선생님이 문제세트를 배포하면 이곳에 표시됩니다.',
              );
            }
            final incomplete = items.where((item) => !item.isCompleted).length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                _HeaderCard(total: items.length, incomplete: incomplete),
                const SizedBox(height: 16),
                for (final item in items) ...[
                  _AssignedProblemSetCard(
                    item: item,
                    onTap: () => _openExam(item),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.total, required this.incomplete});

  final int total;
  final int incomplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.assignment_turned_in_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '선생님이 배포한 문제세트',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '전체 $total개 · 미완료 $incomplete개',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
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

class _AssignedProblemSetCard extends StatelessWidget {
  const _AssignedProblemSetCard({required this.item, required this.onTap});

  final StudentAssignedProblemSet item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = item.isCompleted;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: _StudentAssignedProblemSetsScreenState._line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: completed
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                completed
                    ? Icons.check_circle_outline_rounded
                    : Icons.quiz_outlined,
                color: completed
                    ? const Color(0xFF059669)
                    : _StudentAssignedProblemSetsScreenState._blue,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: _StudentAssignedProblemSetsScreenState._ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _Chip(text: item.folderName),
                      _Chip(text: '${item.questionCount}문항'),
                      _Chip(text: completed ? '완료' : '미시작'),
                      if (item.teacherName.isNotEmpty)
                        _Chip(text: item.teacherName),
                    ],
                  ),
                  if (item.assignedAt.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '배포 ${_dateText(item.assignedAt)}',
                      style: const TextStyle(
                        color: _StudentAssignedProblemSetsScreenState._muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: _StudentAssignedProblemSetsScreenState._muted,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        Icon(icon,
            size: 42, color: _StudentAssignedProblemSetsScreenState._blue),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _StudentAssignedProblemSetsScreenState._ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _StudentAssignedProblemSetsScreenState._muted,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

String _dateText(String raw) {
  final first = raw.split('T').first.split(' ').first;
  return first.isEmpty ? raw : first;
}
