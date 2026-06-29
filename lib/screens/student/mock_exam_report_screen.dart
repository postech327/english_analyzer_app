import 'package:flutter/material.dart';

import '../../services/student_mock_exam_service.dart';
import 'mock_exam_attempt_detail_screen.dart';

class StudentMockExamReportScreen extends StatefulWidget {
  const StudentMockExamReportScreen({super.key});

  @override
  State<StudentMockExamReportScreen> createState() =>
      _StudentMockExamReportScreenState();
}

class _StudentMockExamReportScreenState
    extends State<StudentMockExamReportScreen> {
  static const _surface = Color(0xFFF6F8FC);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _blue = Color(0xFF2563EB);
  static const _sky = Color(0xFFEFF6FF);
  static const _line = Color(0xFFE5E7EB);

  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = StudentMockExamService.fetchMockExamReport();
  }

  void _reload() {
    setState(() => _future = StudentMockExamService.fetchMockExamReport());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '나의 모의고사 리포트',
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
              onTap: _reload,
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
    final summary = _asMap(data['summary']);
    final typeStats = _asList(data['type_stats']);
    final recentAttempts = _asList(data['recent_attempts']);
    final trend = _asList(data['score_trend']);

    return RefreshIndicator(
      onRefresh: () async {
        final state = context
            .findAncestorStateOfType<_StudentMockExamReportScreenState>();
        state?._reload();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          _SummaryHero(summary: summary),
          const SizedBox(height: 14),
          _TypeStatsCard(items: typeStats),
          const SizedBox(height: 14),
          _TrendCard(items: trend),
          const SizedBox(height: 14),
          _RecentAttemptsCard(items: recentAttempts),
        ],
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final weakTypes = _asList(summary['weak_types'])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color:
                _StudentMockExamReportScreenState._blue.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mock Exam Results',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_score(summary['average_score'])}점',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '누적 평균 점수',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final cards = [
                _HeroMetric(
                  label: '총 응시',
                  value: '${_asInt(summary['attempt_count'])}회',
                ),
                _HeroMetric(
                  label: '최고',
                  value: '${_score(summary['highest_score'])}점',
                ),
                _HeroMetric(
                  label: '최근',
                  value: '${_score(summary['latest_score'])}점',
                ),
              ];
              if (compact) {
                return Column(
                  children: cards
                      .map((card) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: card,
                          ))
                      .toList(),
                );
              }
              return Row(
                children: cards
                    .map((card) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: card,
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Text(
              weakTypes.isEmpty
                  ? '약점 유형 없음. 지금 흐름이 좋습니다.'
                  : '약점: ${weakTypes.join(', ')}',
              style: const TextStyle(
                color: Colors.white,
                height: 1.45,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeStatsCard extends StatelessWidget {
  const _TypeStatsCard({required this.items});

  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('유형별 누적 정답률', Icons.analytics_outlined),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const _EmptyText('아직 유형별 누적 결과가 없습니다.')
          else
            ...items.map((item) {
              final data = _asMap(item);
              final rate = _asDouble(data['rate']);
              final correct = _asInt(data['correct']);
              final total = _asInt(data['total']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(
                        _asText(data['label'], '-'),
                        style: const TextStyle(
                          color: _StudentMockExamReportScreenState._ink,
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
                          color: _StudentMockExamReportScreenState._blue,
                          backgroundColor:
                              _StudentMockExamReportScreenState._sky,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 96,
                      child: Text(
                        '${_score(rate)}% ($correct/$total)',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: _StudentMockExamReportScreenState._muted,
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
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.items});

  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('점수 추이', Icons.show_chart_rounded),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const _EmptyText('아직 점수 추이가 없습니다.')
          else
            ...items.map((item) {
              final data = _asMap(item);
              final score = _asDouble(data['score']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 86,
                      child: Text(
                        _formatShortDate(data['submitted_at']),
                        style: const TextStyle(
                          color: _StudentMockExamReportScreenState._muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (score / 100).clamp(0, 1),
                          minHeight: 11,
                          color: const Color(0xFF38BDF8),
                          backgroundColor:
                              _StudentMockExamReportScreenState._sky,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${_score(score)}점',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: _StudentMockExamReportScreenState._ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _RecentAttemptsCard extends StatelessWidget {
  const _RecentAttemptsCard({required this.items});

  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('최근 모의고사 결과', Icons.history_rounded),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const _EmptyText('아직 응시한 모의고사가 없습니다.')
          else
            ...items.map((item) {
              final data = _asMap(item);
              final attemptId = _asInt(data['attempt_id']);
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: attemptId <= 0
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentMockExamAttemptDetailScreen(
                              attemptId: attemptId,
                            ),
                          ),
                        );
                      },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _StudentMockExamReportScreenState._line,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _asText(data['title'], '모의고사'),
                              style: const TextStyle(
                                color: _StudentMockExamReportScreenState._ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _StudentMockExamReportScreenState._muted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _pill('${_score(data['score'])}점'),
                          _pill(
                            '${_asInt(data['correct_count'])}/${_asInt(data['total_questions'], 20)}',
                          ),
                          _pill(_formatDate(data['submitted_at'])),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '약점 유형: ${_weakText(data['weak_types'])}',
                        style: const TextStyle(
                          color: _StudentMockExamReportScreenState._muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.title,
    required this.message,
    required this.onTap,
  });

  final String title;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: _card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: _StudentMockExamReportScreenState._blue,
                size: 38,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: _StudentMockExamReportScreenState._ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _StudentMockExamReportScreenState._muted,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('다시 시도'),
              ),
            ],
          ),
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
    return Text(
      text,
      style: const TextStyle(
        color: _StudentMockExamReportScreenState._muted,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

Widget _sectionTitle(String title, IconData icon) {
  return Row(
    children: [
      Icon(icon, color: _StudentMockExamReportScreenState._blue),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          color: _StudentMockExamReportScreenState._ink,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

Widget _card({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _StudentMockExamReportScreenState._line),
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

Widget _pill(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: _StudentMockExamReportScreenState._sky,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0xFFBFDBFE)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: _StudentMockExamReportScreenState._blue,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
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
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return '-';
  final local = date.toLocal();
  return '${local.year}.${_two(local.month)}.${_two(local.day)}';
}

String _formatShortDate(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return '-';
  final local = date.toLocal();
  return '${_two(local.month)}.${_two(local.day)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
