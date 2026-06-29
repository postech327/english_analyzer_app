import 'package:flutter/material.dart';

import '../services/teacher_mock_exam_service.dart';

class TeacherMockExamReportScreen extends StatefulWidget {
  const TeacherMockExamReportScreen({
    super.key,
    required this.mockExamId,
  });

  final int mockExamId;

  @override
  State<TeacherMockExamReportScreen> createState() =>
      _TeacherMockExamReportScreenState();
}

class _TeacherMockExamReportScreenState
    extends State<TeacherMockExamReportScreen> {
  static const _blue = Color(0xFF2563EB);
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _surface = Color(0xFFF4F7FB);

  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = TeacherMockExamService.fetchMockExamReport(widget.mockExamId);
  }

  void _reload() {
    setState(() {
      _future = TeacherMockExamService.fetchMockExamReport(widget.mockExamId);
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
          '모의고사 응시 결과',
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

  @override
  Widget build(BuildContext context) {
    final exam = _asMap(data['mock_exam']);
    final stats = _asMap(data['stats']);
    final typeStats = _asList(data['type_stats']);
    final students = _asList(data['students']);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(exam: exam),
                const SizedBox(height: 14),
                _StatsGrid(stats: stats),
                const SizedBox(height: 14),
                _TypeStatsCard(items: typeStats),
                const SizedBox(height: 14),
                _StudentResultsCard(students: students),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.exam});

  final Map<String, dynamic> exam;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: _TeacherMockExamReportScreenState._blue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _asText(exam['title'], '모의고사'),
                    style: const TextStyle(
                      color: _TeacherMockExamReportScreenState._ink,
                      fontSize: 21,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Badge(label: _asText(exam['grade'])),
                      _Badge(
                        label:
                            '${_asInt(exam['year'])}년 ${_asInt(exam['month'])}월',
                      ),
                      _Badge(label: '${_asInt(exam['total_questions'], 20)}문항'),
                      _Badge(
                        label: exam['is_complete'] == true ? '완료' : '미완성',
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

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('응시자 수', '${_asInt(stats['attempt_count'])}명', Icons.people_alt),
      ('평균 점수', '${_score(stats['average_score'])}점', Icons.trending_up),
      ('최고 점수', '${_score(stats['highest_score'])}점', Icons.emoji_events),
      ('최저 점수', '${_score(stats['lowest_score'])}점', Icons.low_priority),
      ('완료율', '${_score(stats['completion_rate'])}%', Icons.task_alt),
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
            childAspectRatio: compact ? 1.65 : 1.18,
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
          children: [
            Icon(icon, color: _TeacherMockExamReportScreenState._blue),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: _TeacherMockExamReportScreenState._ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: _TeacherMockExamReportScreenState._muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
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
              subtitle: '학생별 최신 제출 기록만 기준으로 계산합니다.',
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const _EmptyText('아직 유형별 결과가 없습니다.')
            else
              ...items.map((item) {
                final data = _asMap(item);
                final rate = _asDouble(data['rate']);
                final correct = _asInt(data['correct']);
                final total = _asInt(data['total']);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 96,
                            child: Text(
                              _asText(data['label'], '-'),
                              style: const TextStyle(
                                color: _TeacherMockExamReportScreenState._ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: (rate / 100).clamp(0, 1),
                                minHeight: 10,
                                color: _TeacherMockExamReportScreenState._blue,
                                backgroundColor: const Color(0xFFEFF6FF),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 104,
                            child: Text(
                              '${_score(rate)}% ($correct/$total)',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: _TeacherMockExamReportScreenState._muted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
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

class _StudentResultsCard extends StatelessWidget {
  const _StudentResultsCard({required this.students});

  final List<dynamic> students;

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
              subtitle: '같은 학생이 여러 번 제출한 경우 가장 최근 제출만 표시합니다.',
            ),
            const SizedBox(height: 14),
            if (students.isEmpty)
              const _EmptyText('아직 제출한 학생이 없습니다.')
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 760) {
                    return Column(
                      children: students
                          .map((item) => _StudentResultTile(
                                data: _asMap(item),
                              ))
                          .toList(),
                    );
                  }
                  return Column(
                    children: [
                      const _StudentTableHeader(),
                      const Divider(
                        height: 1,
                        color: _TeacherMockExamReportScreenState._line,
                      ),
                      ...students.map((item) => _StudentResultRow(
                            data: _asMap(item),
                          )),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StudentTableHeader extends StatelessWidget {
  const _StudentTableHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 2, child: _HeaderText('학생')),
          Expanded(child: _HeaderText('점수')),
          Expanded(child: _HeaderText('정답 수')),
          Expanded(flex: 2, child: _HeaderText('제출 시간')),
          Expanded(flex: 2, child: _HeaderText('약점 유형')),
        ],
      ),
    );
  }
}

class _StudentResultRow extends StatelessWidget {
  const _StudentResultRow({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(flex: 2, child: _StrongText(_asText(data['nickname']))),
          Expanded(child: Text('${_score(data['score'])}점')),
          Expanded(
            child: Text(
              '${_asInt(data['correct_count'])}/${_asInt(data['total_questions'], 20)}',
            ),
          ),
          Expanded(flex: 2, child: Text(_formatDate(data['submitted_at']))),
          Expanded(flex: 2, child: Text(_weakText(data['weak_types']))),
        ],
      ),
    );
  }
}

class _StudentResultTile extends StatelessWidget {
  const _StudentResultTile({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _TeacherMockExamReportScreenState._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StrongText(_asText(data['nickname'])),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(label: '${_score(data['score'])}점'),
              _Badge(
                label:
                    '${_asInt(data['correct_count'])}/${_asInt(data['total_questions'], 20)}',
              ),
              _Badge(label: _formatDate(data['submitted_at'])),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '약점 유형: ${_weakText(data['weak_types'])}',
            style: const TextStyle(
              color: _TeacherMockExamReportScreenState._muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
            color: _TeacherMockExamReportScreenState._ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _TeacherMockExamReportScreenState._muted,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _TeacherMockExamReportScreenState._muted,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _StrongText extends StatelessWidget {
  const _StrongText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _TeacherMockExamReportScreenState._ink,
        fontWeight: FontWeight.w900,
      ),
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
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _TeacherMockExamReportScreenState._blue,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _TeacherMockExamReportScreenState._line),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _TeacherMockExamReportScreenState._muted),
      ),
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: _TeacherMockExamReportScreenState._blue,
                  size: 36,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: _TeacherMockExamReportScreenState._ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _TeacherMockExamReportScreenState._muted,
                  ),
                ),
                const SizedBox(height: 16),
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

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _TeacherMockExamReportScreenState._line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map<String, dynamic> ? value : const {};

List<dynamic> _asList(dynamic value) => value is List ? value : const [];

String _asText(dynamic value, [String fallback = '-']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _score(dynamic value) {
  final number = _asDouble(value);
  if (number % 1 == 0) return number.round().toString();
  return number.toStringAsFixed(1);
}

String _weakText(dynamic value) {
  final items = _asList(value)
      .map((item) => item.toString())
      .where((item) => item.isNotEmpty)
      .toList();
  return items.isEmpty ? '-' : items.join(', ');
}

String _formatDate(dynamic value) {
  final raw = value?.toString() ?? '';
  final date = DateTime.tryParse(raw);
  if (date == null) return '-';
  final local = date.toLocal();
  return '${local.year}-${_two(local.month)}-${_two(local.day)} '
      '${_two(local.hour)}:${_two(local.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
