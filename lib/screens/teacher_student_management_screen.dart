import 'package:flutter/material.dart';

import '../models/integrated_learning_report.dart';
import '../services/integrated_learning_report_service.dart';
import 'teacher_integrated_learning_report_screen.dart';

enum _StudentFilter { all, active, needsReview, noRecord }

class TeacherStudentManagementScreen extends StatefulWidget {
  const TeacherStudentManagementScreen({super.key});

  @override
  State<TeacherStudentManagementScreen> createState() =>
      _TeacherStudentManagementScreenState();
}

class _TeacherStudentManagementScreenState
    extends State<TeacherStudentManagementScreen> {
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _surface = Color(0xFFF4F7FB);
  static const _blue = Color(0xFF2563EB);
  static const _teal = Color(0xFF0F766E);
  static const _orange = Color(0xFFEA580C);
  static const _purple = Color(0xFF7C3AED);

  final _service = const IntegratedLearningReportService();
  final _searchController = TextEditingController();
  late Future<IntegratedLearningReport> _future;
  _StudentFilter _filter = _StudentFilter.all;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchReport();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _service.fetchReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          '학생 관리',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<IntegratedLearningReport>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.error_outline_rounded,
              title: '학생 정보를 불러오지 못했습니다.',
              message: '${snapshot.error}',
              buttonLabel: '다시 불러오기',
              onPressed: _reload,
            );
          }

          final report = snapshot.data ??
              IntegratedLearningReport(
                generatedAt: DateTime.now(),
                students: const [],
              );
          final students = _filteredStudents(report.students);

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SummaryHeader(report: report),
                        const SizedBox(height: 14),
                        if (report.warnings.isNotEmpty) ...[
                          _WarningPanel(warnings: report.warnings),
                          const SizedBox(height: 14),
                        ],
                        _Toolbar(
                          controller: _searchController,
                          filter: _filter,
                          onFilterChanged: (value) {
                            setState(() => _filter = value);
                          },
                        ),
                        const SizedBox(height: 14),
                        if (students.isEmpty)
                          const _EmptyState()
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final useGrid = constraints.maxWidth >= 860;
                              if (!useGrid) {
                                return Column(
                                  children: [
                                    for (final student in students) ...[
                                      _StudentManagementCard(
                                        student: student,
                                        generatedAt: report.generatedAt,
                                      ),
                                      if (student != students.last)
                                        const SizedBox(height: 12),
                                    ],
                                  ],
                                );
                              }
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: students.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.2,
                                ),
                                itemBuilder: (context, index) {
                                  return _StudentManagementCard(
                                    student: students[index],
                                    generatedAt: report.generatedAt,
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<StudentIntegratedLearningReport> _filteredStudents(
    List<StudentIntegratedLearningReport> students,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = students.where((student) {
      if (query.isNotEmpty) {
        final haystack =
            '${student.studentName} ${student.email} ${student.studentId}'
                .toLowerCase();
        if (!haystack.contains(query)) return false;
      }

      return switch (_filter) {
        _StudentFilter.all => true,
        _StudentFilter.active => student.hasAnyStudyRecord,
        _StudentFilter.needsReview => student.needsReview,
        _StudentFilter.noRecord => !student.hasAnyStudyRecord,
      };
    }).toList();

    filtered.sort((a, b) {
      final reviewCompare =
          (b.needsReview ? 1 : 0).compareTo(a.needsReview ? 1 : 0);
      if (reviewCompare != 0) return reviewCompare;
      final dateCompare = _compareLatestDesc(a.lastStudyAt, b.lastStudyAt);
      if (dateCompare != 0) return dateCompare;
      return a.studentName.compareTo(b.studentName);
    });
    return filtered;
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.report});

  final IntegratedLearningReport report;

  @override
  Widget build(BuildContext context) {
    final noRecordCount = report.students
        .where((student) => !student.hasAnyStudyRecord)
        .length;

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                _HeaderIcon(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '학생 관리 MVP',
                        style: TextStyle(
                          color: _TeacherStudentManagementScreenState._ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '통합 학습 리포트 데이터를 재사용해 학생별 학습 상태를 관리합니다.',
                        style: TextStyle(
                          color: _TeacherStudentManagementScreenState._muted,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricPill(
                  label: '전체 학생',
                  value: '${report.totalStudents}명',
                  color: _TeacherStudentManagementScreenState._blue,
                ),
                _MetricPill(
                  label: '학습 기록',
                  value: '${report.activeStudentCount}명',
                  color: _TeacherStudentManagementScreenState._teal,
                ),
                _MetricPill(
                  label: '복습 필요',
                  value: '${report.needsReviewStudentCount}명',
                  color: _TeacherStudentManagementScreenState._orange,
                ),
                _MetricPill(
                  label: '기록 없음',
                  value: '$noRecordCount명',
                  color: _TeacherStudentManagementScreenState._muted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.groups_outlined,
        color: _TeacherStudentManagementScreenState._blue,
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.controller,
    required this.filter,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final _StudentFilter filter;
  final ValueChanged<_StudentFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: '학생명 / 이메일 / ID 검색',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            _FilterButton(
              selected: filter == _StudentFilter.all,
              label: '전체',
              icon: Icons.list_alt_rounded,
              onTap: () => onFilterChanged(_StudentFilter.all),
            ),
            _FilterButton(
              selected: filter == _StudentFilter.active,
              label: '학습 기록',
              icon: Icons.check_circle_outline_rounded,
              onTap: () => onFilterChanged(_StudentFilter.active),
            ),
            _FilterButton(
              selected: filter == _StudentFilter.needsReview,
              label: '복습 필요',
              icon: Icons.priority_high_rounded,
              onTap: () => onFilterChanged(_StudentFilter.needsReview),
            ),
            _FilterButton(
              selected: filter == _StudentFilter.noRecord,
              label: '기록 없음',
              icon: Icons.history_toggle_off_rounded,
              onTap: () => onFilterChanged(_StudentFilter.noRecord),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentManagementCard extends StatelessWidget {
  const _StudentManagementCard({
    required this.student,
    required this.generatedAt,
  });

  final StudentIntegratedLearningReport student;
  final DateTime generatedAt;

  @override
  Widget build(BuildContext context) {
    final completion = (student.overallCompletionRate * 100).round();
    final status = _studentStatus(student);

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: _TeacherStudentManagementScreenState._blue,
                  child: Text(_initial(student.studentName)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _TeacherStudentManagementScreenState._ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'ID ${student.studentId}'
                        '${student.email.isNotEmpty ? ' · ${student.email}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _TeacherStudentManagementScreenState._muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(label: status.label, color: status.color),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(label: '완료율', value: '$completion%'),
                _InfoChip(label: '최근 학습', value: _dateText(student.lastStudyAt)),
                _InfoChip(label: '미완료', value: '${student.incompleteCount}개'),
              ],
            ),
            const SizedBox(height: 14),
            _LearningBars(student: student),
            const SizedBox(height: 12),
            Text(
              _managementNote(student),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _TeacherStudentManagementScreenState._muted,
                height: 1.4,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showStudentSnapshot(context, student),
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: const Text('요약 보기'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherStudentIntegratedReportDetailScreen(
                          student: student,
                          generatedAt: generatedAt,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('상세'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningBars extends StatelessWidget {
  const _LearningBars({required this.student});

  final StudentIntegratedLearningReport student;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AreaProgressLine(
          label: 'Workbook',
          value:
              '${student.workbook.completedCount}/${student.workbook.totalCount}',
          ratio: _ratio(
            student.workbook.completedCount,
            student.workbook.totalCount,
          ),
          color: _TeacherStudentManagementScreenState._teal,
        ),
        const SizedBox(height: 8),
        _AreaProgressLine(
          label: 'Vocabulary',
          value:
              '${student.vocabulary.completedBookCount}/${student.vocabulary.assignedBookCount}',
          ratio: _ratio(
            student.vocabulary.completedBookCount,
            student.vocabulary.assignedBookCount,
          ),
          color: _TeacherStudentManagementScreenState._purple,
        ),
        const SizedBox(height: 8),
        _AreaProgressLine(
          label: 'Final Touch',
          value:
              '${student.finalTouch.viewedCount}/${student.finalTouch.totalCount}',
          ratio: _ratio(
            student.finalTouch.viewedCount,
            student.finalTouch.totalCount,
          ),
          color: _TeacherStudentManagementScreenState._blue,
        ),
      ],
    );
  }
}

class _AreaProgressLine extends StatelessWidget {
  const _AreaProgressLine({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  final String label;
  final String value;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              color: _TeacherStudentManagementScreenState._ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: ratio,
              backgroundColor: const Color(0xFFE2E8F0),
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 46,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _TeacherStudentManagementScreenState._muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(icon, size: 18),
      label: Text(label),
      labelStyle: TextStyle(
        color: selected
            ? _TeacherStudentManagementScreenState._blue
            : _TeacherStudentManagementScreenState._ink,
        fontWeight: FontWeight.w800,
      ),
      selectedColor: const Color(0xFFEFF6FF),
      backgroundColor: const Color(0xFFF8FAFC),
      side: BorderSide(
        color: selected
            ? _TeacherStudentManagementScreenState._blue
            : _TeacherStudentManagementScreenState._line,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _TeacherStudentManagementScreenState._line),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: _TeacherStudentManagementScreenState._ink,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _WarningPanel extends StatelessWidget {
  const _WarningPanel({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFFEA580C)),
                SizedBox(width: 8),
                Text(
                  '일부 데이터는 fallback으로 표시됩니다',
                  style: TextStyle(
                    color: _TeacherStudentManagementScreenState._ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final warning in warnings.take(3))
              Text(
                '- $warning',
                style: const TextStyle(
                  color: _TeacherStudentManagementScreenState._muted,
                  height: 1.45,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const _Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.manage_search_rounded,
              size: 42,
              color: _TeacherStudentManagementScreenState._muted,
            ),
            SizedBox(height: 10),
            Text(
              '표시할 학생이 없습니다.',
              style: TextStyle(
                color: _TeacherStudentManagementScreenState._ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '검색어나 필터를 조정해 보세요.',
              style: TextStyle(
                color: _TeacherStudentManagementScreenState._muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 42,
                  color: _TeacherStudentManagementScreenState._orange,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _TeacherStudentManagementScreenState._ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _TeacherStudentManagementScreenState._muted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onPressed,
                  child: Text(buttonLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _TeacherStudentManagementScreenState._line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

void _showStudentSnapshot(
  BuildContext context,
  StudentIntegratedLearningReport student,
) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text('${student.studentName} 학습 요약'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SnapshotRow(
                label: 'Workbook',
                value:
                    '${student.workbook.completedCount}/${student.workbook.totalCount} 완료, 평균 ${_scoreText(student.workbook.averageScore)}',
              ),
              _SnapshotRow(
                label: 'Vocabulary',
                value:
                    '${student.vocabulary.completedBookCount}/${student.vocabulary.assignedBookCount} 학습, 오답 ${student.vocabulary.wrongWordCount}개',
              ),
              _SnapshotRow(
                label: 'Final Touch',
                value:
                    '${student.finalTouch.viewedCount}/${student.finalTouch.totalCount} 복습, 문장 조립 ${student.finalTouch.sentenceAssemblyCompletedCount}회',
              ),
              _SnapshotRow(
                label: '최근 학습',
                value: _dateText(student.lastStudyAt),
              ),
              const SizedBox(height: 10),
              Text(
                _managementNote(student),
                style: const TextStyle(
                  color: _TeacherStudentManagementScreenState._muted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      );
    },
  );
}

class _SnapshotRow extends StatelessWidget {
  const _SnapshotRow({required this.label, required this.value});

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
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                color: _TeacherStudentManagementScreenState._muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _TeacherStudentManagementScreenState._ink,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

({String label, Color color}) _studentStatus(
  StudentIntegratedLearningReport student,
) {
  if (!student.hasAnyStudyRecord) {
    return (
      label: '기록 없음',
      color: _TeacherStudentManagementScreenState._muted,
    );
  }
  if (student.needsReview) {
    return (
      label: '복습 필요',
      color: _TeacherStudentManagementScreenState._orange,
    );
  }
  return (
    label: '진행 양호',
    color: _TeacherStudentManagementScreenState._teal,
  );
}

String _managementNote(StudentIntegratedLearningReport student) {
  if (!student.hasAnyStudyRecord) {
    return '아직 학습 기록이 없습니다. 배정된 학습이 있는지 확인해 주세요.';
  }
  if (student.recommendedActions.isNotEmpty) {
    return student.recommendedActions.first.message;
  }
  return 'Workbook, Vocabulary, Final Touch 학습 흐름이 안정적으로 진행 중입니다.';
}

double _ratio(int done, int total) {
  if (total <= 0) return 0;
  final value = done / total;
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}

String _initial(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 'S';
  return trimmed.substring(0, 1).toUpperCase();
}

String _scoreText(double value) {
  if (value <= 0) return '기록 없음';
  return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}%';
}

String _dateText(DateTime? date) {
  if (date == null) return '기록 없음';
  final local = date.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year.$month.$day';
}

int _compareLatestDesc(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}
