import 'package:flutter/material.dart';

import '../services/teacher_mock_exam_service.dart';
import 'teacher_mock_student_attempt_detail_screen.dart';

class TeacherMockStudentReportDetailScreen extends StatefulWidget {
  const TeacherMockStudentReportDetailScreen({
    super.key,
    required this.studentId,
    required this.nickname,
  });

  final int studentId;
  final String nickname;

  @override
  State<TeacherMockStudentReportDetailScreen> createState() =>
      _TeacherMockStudentReportDetailScreenState();
}

class _TeacherMockStudentReportDetailScreenState
    extends State<TeacherMockStudentReportDetailScreen> {
  static const _blue = Color(0xFF2563EB);
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _surface = Color(0xFFF4F7FB);

  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = TeacherMockExamService.fetchMockStudentReportDetail(
      widget.studentId,
    );
  }

  void _reload() {
    setState(() {
      _future = TeacherMockExamService.fetchMockStudentReportDetail(
        widget.studentId,
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
          '학생 Mock Exam 누적 리포트',
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
          return _DetailBody(data: snapshot.data ?? const {});
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final student = _asMap(data['student']);
    final summary = _asMap(data['summary']);
    final typeStats = _asList(data['type_stats']);
    final recentAttempts = _asList(data['recent_attempts']);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryCard(student: student, summary: summary),
                const SizedBox(height: 14),
                _TypeStatsCard(items: typeStats),
                const SizedBox(height: 14),
                _RecentAttemptsCard(items: recentAttempts, student: student),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.student,
    required this.summary,
  });

  final Map<String, dynamic> student;
  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final weakTypes = _asList(summary['weak_types'])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();

    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_search_rounded,
                    color: _TeacherMockStudentReportDetailScreenState._blue,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _asText(student['nickname'], '학생'),
                        style: const TextStyle(
                          color:
                              _TeacherMockStudentReportDetailScreenState._ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weakTypes.isEmpty
                            ? '누적 약점 유형이 아직 없습니다.'
                            : '약점: ${weakTypes.join(', ')}',
                        style: const TextStyle(
                          color:
                              _TeacherMockStudentReportDetailScreenState._muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final items = [
                  (
                    '총 응시',
                    '${_asInt(summary['attempt_count'])}회',
                    Icons.assignment_turned_in_outlined
                  ),
                  (
                    '평균 점수',
                    '${_score(summary['average_score'])}점',
                    Icons.trending_up_rounded
                  ),
                  (
                    '최고 점수',
                    '${_score(summary['highest_score'])}점',
                    Icons.emoji_events_outlined
                  ),
                  (
                    '최근 점수',
                    '${_score(summary['latest_score'])}점',
                    Icons.history_rounded
                  ),
                ];
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: compact ? 2 : 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: compact ? 1.75 : 1.6,
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
              icon: Icons.stacked_bar_chart_rounded,
              title: '유형별 누적 정답률',
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              const _EmptyText('아직 유형별 통계가 없습니다.')
            else
              ...items.map((item) {
                final data = _asMap(item);
                final rate = _asDouble(data['rate']);
                final total = _asInt(data['total']);
                final correct = _asInt(data['correct']);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _asText(data['label']),
                              style: const TextStyle(
                                color:
                                    _TeacherMockStudentReportDetailScreenState
                                        ._ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            '${_score(rate)}% ($correct/$total)',
                            style: const TextStyle(
                              color: _TeacherMockStudentReportDetailScreenState
                                  ._muted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 9,
                          value: (rate / 100).clamp(0, 1),
                          backgroundColor: const Color(0xFFEFF6FF),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            rate >= 70
                                ? const Color(0xFF16A34A)
                                : _TeacherMockStudentReportDetailScreenState
                                    ._blue,
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

class _RecentAttemptsCard extends StatelessWidget {
  const _RecentAttemptsCard({
    required this.items,
    required this.student,
  });

  final List<dynamic> items;
  final Map<String, dynamic> student;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(icon: Icons.history_rounded, title: '최근 응시 결과'),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const _EmptyText('아직 응시 기록이 없습니다.')
            else
              ...items.map((item) {
                final data = _asMap(item);
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherMockStudentAttemptDetailScreen(
                          studentId: _asInt(student['user_id']),
                          attemptId: _asInt(data['attempt_id']),
                          nickname: _asText(student['nickname'], '학생'),
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _TeacherMockStudentReportDetailScreenState._line,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _score(data['score']),
                            style: const TextStyle(
                              color: _TeacherMockStudentReportDetailScreenState
                                  ._blue,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _asText(data['title'], '모의고사'),
                                style: const TextStyle(
                                  color:
                                      _TeacherMockStudentReportDetailScreenState
                                          ._ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_score(data['score'])}점 · '
                                '${_asInt(data['correct_count'])}/${_asInt(data['total_questions'], 20)} · '
                                '${_formatDate(data['submitted_at'])}',
                                style: const TextStyle(
                                  color:
                                      _TeacherMockStudentReportDetailScreenState
                                          ._muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color:
                              _TeacherMockStudentReportDetailScreenState._muted,
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _TeacherMockStudentReportDetailScreenState._line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _TeacherMockStudentReportDetailScreenState._blue),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: _TeacherMockStudentReportDetailScreenState._ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _TeacherMockStudentReportDetailScreenState._muted,
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
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _TeacherMockStudentReportDetailScreenState._blue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _TeacherMockStudentReportDetailScreenState._ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _AdminCard(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: _TeacherMockStudentReportDetailScreenState._blue,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: _TeacherMockStudentReportDetailScreenState._ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _TeacherMockStudentReportDetailScreenState._muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onPressed,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _TeacherMockStudentReportDetailScreenState._line,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _TeacherMockStudentReportDetailScreenState._muted,
      ),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) => value is List ? value : const [];

String _asText(dynamic value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _score(dynamic value) {
  final number = _asDouble(value);
  return number == number.roundToDouble()
      ? number.toInt().toString()
      : number.toStringAsFixed(1);
}

String _formatDate(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return '-';
  final local = parsed.toLocal();
  return '${local.year}.${local.month.toString().padLeft(2, '0')}.'
      '${local.day.toString().padLeft(2, '0')}';
}
