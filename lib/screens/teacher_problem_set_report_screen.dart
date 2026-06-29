import 'package:flutter/material.dart';

import '../services/teacher_problem_set_service.dart';

class TeacherProblemSetReportScreen extends StatefulWidget {
  const TeacherProblemSetReportScreen({
    super.key,
    required this.problemSetId,
  });

  final int problemSetId;

  @override
  State<TeacherProblemSetReportScreen> createState() =>
      _TeacherProblemSetReportScreenState();
}

class _TeacherProblemSetReportScreenState
    extends State<TeacherProblemSetReportScreen> {
  static const _blue = Color(0xFF2563EB);
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _surface = Color(0xFFF4F7FB);

  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = TeacherProblemSetService.fetchProblemSetReport(
      widget.problemSetId,
    );
  }

  void _reload() {
    setState(() {
      _future = TeacherProblemSetService.fetchProblemSetReport(
        widget.problemSetId,
      );
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
          '문제세트 결과 리포트',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _MessagePanel(
              title: '리포트를 불러오지 못했습니다.',
              message: snapshot.error.toString(),
              onPressed: _reload,
            );
          }

          return _ReportBody(data: snapshot.data ?? const {});
        },
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.data});

  final Map<String, dynamic> data;

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _asString(dynamic value, [String fallback = '-']) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? fallback : text;
  }

  List<dynamic> _asList(dynamic value) => value is List ? value : const [];

  @override
  Widget build(BuildContext context) {
    final title = _asString(data['title'], '문제세트');
    final book = _asString(data['book_folder_name'], '교재 미지정');
    final unit = _asString(data['unit_folder_name'], '단원 미지정');
    final questionCount = _asInt(data['question_count']);
    final weakTypes = _asList(data['weak_types'])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(
                  title: title,
                  book: book,
                  unit: unit,
                  questionCount: questionCount,
                ),
                const SizedBox(height: 14),
                _StatsGrid(data: data),
                const SizedBox(height: 14),
                _TypeStatsCard(items: _asList(data['type_stats'])),
                const SizedBox(height: 14),
                _WeakSummaryCard(weakTypes: weakTypes),
                const SizedBox(height: 14),
                _StudentTable(students: _asList(data['students'])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.book,
    required this.unit,
    required this.questionCount,
  });

  final String title;
  final String book;
  final String unit;
  final int questionCount;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: _TeacherProblemSetReportScreenState._blue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _TeacherProblemSetReportScreenState._ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Badge(label: book),
                      _Badge(label: unit),
                      _Badge(label: '$questionCount문항'),
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

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.data});

  final Map<String, dynamic> data;

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _asScore(dynamic value) {
    if (value is num && value % 1 != 0) return value.toStringAsFixed(1);
    return '${_asInt(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ('응시자 수', '${_asInt(data['participant_count'])}명', Icons.people_alt),
      ('평균 점수', '${_asScore(data['average_score'])}점', Icons.trending_up),
      ('최고 점수', '${_asInt(data['highest_score'])}점', Icons.emoji_events),
      ('최저 점수', '${_asInt(data['lowest_score'])}점', Icons.low_priority),
      ('완료율', '${_asInt(data['completion_rate'])}%', Icons.task_alt),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compact ? 2 : 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: compact ? 1.65 : 1.2,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _MetricCard(
              label: item.$1,
              value: item.$2,
              icon: item.$3,
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _TeacherProblemSetReportScreenState._blue),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: _TeacherProblemSetReportScreenState._muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: _TeacherProblemSetReportScreenState._ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeStatsCard extends StatelessWidget {
  const _TypeStatsCard({required this.items});

  final List<dynamic> items;

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: '유형별 정답률',
              subtitle: '응시 학생들의 최신 제출 기준으로 계산합니다.',
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Text(
                '아직 제출된 결과가 없습니다.',
                style: TextStyle(
                    color: _TeacherProblemSetReportScreenState._muted),
              )
            else
              ...items.map((item) {
                final data = item is Map ? item : const {};
                final label = data['label']?.toString() ?? '문제';
                final accuracy = _asInt(data['accuracy']);
                final correct = _asInt(data['correct_count']);
                final total = _asInt(data['total']);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: _TeacherProblemSetReportScreenState._ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: accuracy.clamp(0, 100) / 100,
                            minHeight: 9,
                            backgroundColor: const Color(0xFFEFF6FF),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              _TeacherProblemSetReportScreenState._blue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 88,
                        child: Text(
                          '$accuracy% ($correct/$total)',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: _TeacherProblemSetReportScreenState._muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _WeakSummaryCard extends StatelessWidget {
  const _WeakSummaryCard({required this.weakTypes});

  final List<String> weakTypes;

  @override
  Widget build(BuildContext context) {
    final text = weakTypes.isEmpty ? '아직 약점 유형이 없습니다.' : weakTypes.join(', ');
    final recommendation = weakTypes.isEmpty
        ? '학생 제출이 쌓이면 보충 유형을 자동으로 추천합니다.'
        : '${weakTypes.take(2).join(', ')} 유형 보충 자료를 준비해 보세요.';

    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: '약점 요약',
              subtitle: '반 전체에서 정답률이 낮은 유형입니다.',
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '보충 추천: $text',
                    style: const TextStyle(
                      color: _TeacherProblemSetReportScreenState._ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recommendation,
                    style: const TextStyle(
                      color: _TeacherProblemSetReportScreenState._muted,
                      fontWeight: FontWeight.w700,
                    ),
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

class _StudentTable extends StatelessWidget {
  const _StudentTable({required this.students});

  final List<dynamic> students;

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _asString(dynamic value, [String fallback = '-']) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? fallback : text;
  }

  List<String> _weakTypes(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: '학생별 결과',
              subtitle: '각 학생의 최신 제출 결과입니다.',
            ),
            const SizedBox(height: 14),
            if (students.isEmpty)
              const Text(
                '아직 응시한 학생이 없습니다.',
                style: TextStyle(
                    color: _TeacherProblemSetReportScreenState._muted),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  columns: const [
                    DataColumn(label: Text('학생')),
                    DataColumn(label: Text('점수')),
                    DataColumn(label: Text('정답')),
                    DataColumn(label: Text('제출 시간')),
                    DataColumn(label: Text('약점 유형')),
                  ],
                  rows: students.map((item) {
                    final data = item is Map ? item : const {};
                    final weakTypes = _weakTypes(data['weak_types']);
                    final submittedAt = _asString(data['submitted_at']);
                    return DataRow(
                      cells: [
                        DataCell(Text(_asString(data['nickname']))),
                        DataCell(Text('${_asInt(data['score'])}점')),
                        DataCell(
                          Text(
                            '${_asInt(data['correct_count'])}/${_asInt(data['total_questions'])}',
                          ),
                        ),
                        DataCell(Text(submittedAt.replaceFirst('T', ' '))),
                        DataCell(Text(
                            weakTypes.isEmpty ? '-' : weakTypes.join(', '))),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

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
            color: _TeacherProblemSetReportScreenState._ink,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _TeacherProblemSetReportScreenState._muted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _TeacherProblemSetReportScreenState._blue,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _TeacherProblemSetReportScreenState._line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.title,
    required this.message,
    required this.onPressed,
  });

  final String title;
  final String message;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _AdminCard(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: _TeacherProblemSetReportScreenState._blue,
                  size: 38,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: _TeacherProblemSetReportScreenState._ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _TeacherProblemSetReportScreenState._muted,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: onPressed,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
