import 'package:flutter/material.dart';

import '../models/integrated_learning_report.dart';
import '../services/integrated_learning_report_service.dart';

class TeacherIntegratedLearningReportScreen extends StatefulWidget {
  const TeacherIntegratedLearningReportScreen({super.key});

  @override
  State<TeacherIntegratedLearningReportScreen> createState() =>
      _TeacherIntegratedLearningReportScreenState();
}

class _TeacherIntegratedLearningReportScreenState
    extends State<TeacherIntegratedLearningReportScreen> {
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
  bool _reviewOnly = false;
  bool _staleOnly = false;

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
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          '통합 학습 리포트',
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
              icon: Icons.error_outline,
              title: '통합 리포트를 불러오지 못했습니다.',
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
                        _HeroSummary(report: report),
                        const SizedBox(height: 14),
                        if (report.warnings.isNotEmpty)
                          _WarningPanel(warnings: report.warnings),
                        if (report.warnings.isNotEmpty)
                          const SizedBox(height: 14),
                        _FilterPanel(
                          controller: _searchController,
                          reviewOnly: _reviewOnly,
                          staleOnly: _staleOnly,
                          onReviewOnlyChanged: (value) =>
                              setState(() => _reviewOnly = value),
                          onStaleOnlyChanged: (value) =>
                              setState(() => _staleOnly = value),
                        ),
                        const SizedBox(height: 14),
                        if (students.isEmpty)
                          const _EmptyState()
                        else
                          ...students.map(
                            (student) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _StudentReportCard(
                                student: student,
                                onOpen: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TeacherStudentIntegratedReportDetailScreen(
                                      student: student,
                                      generatedAt: report.generatedAt,
                                    ),
                                  ),
                                ),
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
      ),
    );
  }

  List<StudentIntegratedLearningReport> _filteredStudents(
    List<StudentIntegratedLearningReport> students,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    return students.where((student) {
      if (query.isNotEmpty) {
        final haystack =
            '${student.studentName} ${student.email} ${student.studentId}'.toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      if (_reviewOnly && !student.needsReview) return false;
      if (_staleOnly && !_isStale(student.lastStudyAt)) return false;
      return true;
    }).toList();
  }

  static bool _isStale(DateTime? date) {
    if (date == null) return true;
    return DateTime.now().difference(date).inDays >= 7;
  }
}

class TeacherStudentIntegratedReportDetailScreen extends StatelessWidget {
  const TeacherStudentIntegratedReportDetailScreen({
    super.key,
    required this.student,
    required this.generatedAt,
  });

  final StudentIntegratedLearningReport student;
  final DateTime generatedAt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _TeacherIntegratedLearningReportScreenState._surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _TeacherIntegratedLearningReportScreenState._ink,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          '${student.studentName} 통합 리포트',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StudentDetailHeader(student: student),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 900;
                        final cards = [
                          _WorkbookDetailCard(summary: student.workbook),
                          _VocabularyDetailCard(summary: student.vocabulary),
                          _FinalTouchDetailCard(summary: student.finalTouch),
                        ];
                        if (!wide) {
                          return Column(
                            children: [
                              for (final card in cards) ...[
                                card,
                                if (card != cards.last) const SizedBox(height: 12),
                              ],
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final card in cards) ...[
                              Expanded(child: card),
                              if (card != cards.last) const SizedBox(width: 12),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _RecommendedActionSection(
                      actions: student.recommendedActions,
                    ),
                    const SizedBox(height: 14),
                    _InfoNote(
                      text:
                          '생성 시각: ${_dateText(generatedAt)} · 기존 Workbook/Vocabulary/Final Touch 데이터를 조합한 MVP 리포트입니다.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({required this.report});

  final IntegratedLearningReport report;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: _TeacherIntegratedLearningReportScreenState._blue,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workbook · Vocabulary · Final Touch 통합 현황',
                        style: TextStyle(
                          color: _TeacherIntegratedLearningReportScreenState._ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '학생별 학습 현황과 복습 필요 항목을 한눈에 확인합니다.',
                        style: TextStyle(
                          color: _TeacherIntegratedLearningReportScreenState._muted,
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
                  color: _TeacherIntegratedLearningReportScreenState._blue,
                ),
                _MetricPill(
                  label: '학습 기록 있음',
                  value: '${report.activeStudentCount}명',
                  color: _TeacherIntegratedLearningReportScreenState._teal,
                ),
                _MetricPill(
                  label: '복습 필요',
                  value: '${report.needsReviewStudentCount}명',
                  color: _TeacherIntegratedLearningReportScreenState._orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.controller,
    required this.reviewOnly,
    required this.staleOnly,
    required this.onReviewOnlyChanged,
    required this.onStaleOnlyChanged,
  });

  final TextEditingController controller;
  final bool reviewOnly;
  final bool staleOnly;
  final ValueChanged<bool> onReviewOnlyChanged;
  final ValueChanged<bool> onStaleOnlyChanged;

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
                  hintText: '학생명 / ID 검색',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            FilterChip(
              selected: reviewOnly,
              onSelected: onReviewOnlyChanged,
              label: const Text('복습 필요만 보기'),
              avatar: const Icon(Icons.priority_high_rounded, size: 18),
            ),
            FilterChip(
              selected: staleOnly,
              onSelected: onStaleOnlyChanged,
              label: const Text('최근 7일 학습 없음'),
              avatar: const Icon(Icons.history_toggle_off_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentReportCard extends StatelessWidget {
  const _StudentReportCard({
    required this.student,
    required this.onOpen,
  });

  final StudentIntegratedLearningReport student;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final completion = (student.overallCompletionRate * 100).round();
    return _Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFEFF6FF),
                    foregroundColor:
                        _TeacherIntegratedLearningReportScreenState._blue,
                    child: Text(_initial(student.studentName)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.studentName,
                          style: const TextStyle(
                            color: _TeacherIntegratedLearningReportScreenState._ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'ID ${student.studentId}'
                          '${student.email.isNotEmpty ? ' · ${student.email}' : ''}',
                          style: const TextStyle(
                            color: _TeacherIntegratedLearningReportScreenState._muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(
                    label: student.needsReview ? '복습 필요' : '양호',
                    color: student.needsReview
                        ? _TeacherIntegratedLearningReportScreenState._orange
                        : _TeacherIntegratedLearningReportScreenState._teal,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(label: '전체 완료율', value: '$completion%'),
                  _InfoChip(label: '최근 학습', value: _dateText(student.lastStudyAt)),
                  _InfoChip(label: '미완료', value: '${student.incompleteCount}개'),
                  _InfoChip(label: '복습 항목', value: '${student.reviewItemCount}개'),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  final children = [
                    _AreaMiniSummary(
                      title: 'Workbook',
                      value:
                          '${student.workbook.completedCount}/${student.workbook.totalCount} 완료',
                      subtitle:
                          '평균 ${_scoreText(student.workbook.averageScore)} · 약점 ${student.workbook.weakTypes.length}개',
                      color: _TeacherIntegratedLearningReportScreenState._teal,
                    ),
                    _AreaMiniSummary(
                      title: 'Vocabulary',
                      value:
                          '${student.vocabulary.completedBookCount}/${student.vocabulary.assignedBookCount} 학습',
                      subtitle:
                          '학습 ${student.vocabulary.studiedWordCount}단어 · 오답 ${student.vocabulary.wrongWordCount}개',
                      color: _TeacherIntegratedLearningReportScreenState._purple,
                    ),
                    _AreaMiniSummary(
                      title: 'Final Touch',
                      value:
                          '${student.finalTouch.viewedCount}/${student.finalTouch.totalCount} 복습',
                      subtitle:
                          '미열람 ${student.finalTouch.notViewedCount}개 · 문장 조립 ${student.finalTouch.sentenceAssemblyCompletedCount}회',
                      color: _TeacherIntegratedLearningReportScreenState._blue,
                    ),
                  ];
                  if (!wide) {
                    return Column(
                      children: [
                        for (final child in children) ...[
                          child,
                          if (child != children.last) const SizedBox(height: 8),
                        ],
                      ],
                    );
                  }
                  return Row(
                    children: [
                      for (final child in children) ...[
                        Expanded(child: child),
                        if (child != children.last) const SizedBox(width: 8),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      student.recommendedActions.isEmpty
                          ? '추천: 현재 우선 복습 항목이 없습니다.'
                          : '추천: ${student.recommendedActions.first.message}',
                      style: const TextStyle(
                        color: _TeacherIntegratedLearningReportScreenState._muted,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('상세 보기'),
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

class _StudentDetailHeader extends StatelessWidget {
  const _StudentDetailHeader({required this.student});

  final StudentIntegratedLearningReport student;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student.studentName,
              style: const TextStyle(
                color: _TeacherIntegratedLearningReportScreenState._ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label: '전체 완료율',
                  value: '${(student.overallCompletionRate * 100).round()}%',
                ),
                _InfoChip(label: '최근 학습', value: _dateText(student.lastStudyAt)),
                _InfoChip(label: '미완료', value: '${student.incompleteCount}개'),
                _InfoChip(label: '복습 필요', value: '${student.reviewItemCount}개'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkbookDetailCard extends StatelessWidget {
  const _WorkbookDetailCard({required this.summary});

  final WorkbookReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return _AreaDetailCard(
      title: 'Workbook',
      icon: Icons.menu_book_outlined,
      color: _TeacherIntegratedLearningReportScreenState._teal,
      rows: [
        ('완료 / 전체', '${summary.completedCount} / ${summary.totalCount}'),
        ('미완료', '${summary.incompleteCount}개'),
        ('평균 정답률', _scoreText(summary.averageScore)),
        ('최근 학습일', _dateText(summary.lastStudyAt)),
        ('약점 유형', summary.weakTypes.isEmpty ? '기록 없음' : summary.weakTypes.join(', ')),
      ],
      footer: summary.incompleteTitles.isEmpty
          ? '미완료 Workbook 기록이 없습니다.'
          : '미완료: ${summary.incompleteTitles.join(', ')}',
    );
  }
}

class _VocabularyDetailCard extends StatelessWidget {
  const _VocabularyDetailCard({required this.summary});

  final VocabularyReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return _AreaDetailCard(
      title: 'Vocabulary',
      icon: Icons.translate_rounded,
      color: _TeacherIntegratedLearningReportScreenState._purple,
      rows: [
        ('학습 완료 / 배정', '${summary.completedBookCount} / ${summary.assignedBookCount}'),
        ('총 학습 단어', '${summary.studiedWordCount}개'),
        ('오답 단어', '${summary.wrongWordCount}개'),
        ('최근 학습일', _dateText(summary.lastStudyAt)),
      ],
      footer: summary.wrongWordCount > 0
          ? '추천: 오답만 다시 풀기를 안내해 보세요.'
          : '오답 단어 기록이 없습니다.',
    );
  }
}

class _FinalTouchDetailCard extends StatelessWidget {
  const _FinalTouchDetailCard({required this.summary});

  final FinalTouchReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return _AreaDetailCard(
      title: 'Final Touch',
      icon: Icons.auto_fix_high_outlined,
      color: _TeacherIntegratedLearningReportScreenState._blue,
      rows: [
        ('복습 완료 / 전체', '${summary.viewedCount} / ${summary.totalCount}'),
        ('미열람', '${summary.notViewedCount}개'),
        ('문장 조립 완료', '${summary.sentenceAssemblyCompletedCount}회'),
        ('최근 열람일', _dateText(summary.lastViewedAt)),
      ],
      footer: summary.notViewedTitles.isEmpty
          ? '미열람 Final Touch 자료가 없습니다.'
          : '미열람: ${summary.notViewedTitles.join(', ')}',
    );
  }
}

class _RecommendedActionSection extends StatelessWidget {
  const _RecommendedActionSection({required this.actions});

  final List<RecommendedLearningAction> actions;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '선생님 추천 액션',
              style: TextStyle(
                color: _TeacherIntegratedLearningReportScreenState._ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            if (actions.isEmpty)
              const Text(
                '현재 우선 추천 액션이 없습니다.',
                style: TextStyle(
                  color: _TeacherIntegratedLearningReportScreenState._muted,
                ),
              )
            else
              for (final action in actions) ...[
                _ActionTile(action: action),
                if (action != actions.last) const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

class _AreaDetailCard extends StatelessWidget {
  const _AreaDetailCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.rows,
    required this.footer,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<(String, String)> rows;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: _TeacherIntegratedLearningReportScreenState._ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final row in rows) _DetailRow(label: row.$1, value: row.$2),
            const Divider(height: 22),
            Text(
              footer,
              style: const TextStyle(
                color: _TeacherIntegratedLearningReportScreenState._muted,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaMiniSummary extends StatelessWidget {
  const _AreaMiniSummary({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _TeacherIntegratedLearningReportScreenState._ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: _TeacherIntegratedLearningReportScreenState._muted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
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
                    color: _TeacherIntegratedLearningReportScreenState._ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final warning in warnings.take(3))
              Text(
                '· $warning',
                style: const TextStyle(
                  color: _TeacherIntegratedLearningReportScreenState._muted,
                  height: 1.45,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});

  final RecommendedLearningAction action;

  @override
  Widget build(BuildContext context) {
    final color = switch (action.priority) {
      ReportActionPriority.high => _TeacherIntegratedLearningReportScreenState._orange,
      ReportActionPriority.medium => _TeacherIntegratedLearningReportScreenState._blue,
      ReportActionPriority.low => _TeacherIntegratedLearningReportScreenState._muted,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_outlined, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${action.area} · ${action.title}',
                  style: const TextStyle(
                    color: _TeacherIntegratedLearningReportScreenState._ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  action.message,
                  style: const TextStyle(
                    color: _TeacherIntegratedLearningReportScreenState._muted,
                    height: 1.45,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

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
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: _TeacherIntegratedLearningReportScreenState._muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _TeacherIntegratedLearningReportScreenState._ink,
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
        border: Border.all(color: _TeacherIntegratedLearningReportScreenState._line),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: _TeacherIntegratedLearningReportScreenState._ink,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
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

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _TeacherIntegratedLearningReportScreenState._muted,
        fontSize: 12,
        height: 1.5,
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _TeacherIntegratedLearningReportScreenState._line),
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
              color: _TeacherIntegratedLearningReportScreenState._muted,
            ),
            SizedBox(height: 10),
            Text(
              '표시할 학생 리포트가 없습니다.',
              style: TextStyle(
                color: _TeacherIntegratedLearningReportScreenState._ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '검색어나 필터를 조정해 보세요.',
              style: TextStyle(
                color: _TeacherIntegratedLearningReportScreenState._muted,
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
                Icon(icon, size: 42, color: _TeacherIntegratedLearningReportScreenState._orange),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _TeacherIntegratedLearningReportScreenState._ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _TeacherIntegratedLearningReportScreenState._muted,
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
