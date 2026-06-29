import 'package:flutter/material.dart';

import '../services/teacher_mock_exam_service.dart';
import 'teacher_mock_student_report_detail_screen.dart';

class TeacherMockStudentReportListScreen extends StatefulWidget {
  const TeacherMockStudentReportListScreen({super.key});

  @override
  State<TeacherMockStudentReportListScreen> createState() =>
      _TeacherMockStudentReportListScreenState();
}

class _TeacherMockStudentReportListScreenState
    extends State<TeacherMockStudentReportListScreen> {
  static const _blue = Color(0xFF2563EB);
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _surface = Color(0xFFF4F7FB);

  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = TeacherMockExamService.fetchMockStudentReportList();
  }

  void _reload() {
    setState(() {
      _future = TeacherMockExamService.fetchMockStudentReportList();
    });
  }

  void _openDetail(Map<String, dynamic> student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherMockStudentReportDetailScreen(
          studentId: _asInt(student['user_id']),
          nickname: _asText(student['nickname'], '학생'),
        ),
      ),
    );
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
          'Mock Exam 학생 분석',
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
              icon: Icons.error_outline_rounded,
              title: '학생별 리포트를 불러오지 못했습니다.',
              message: snapshot.error.toString(),
              actionLabel: '다시 시도',
              onTap: _reload,
            );
          }
          final students = _asList(snapshot.data?['students']);
          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _HeaderCard(),
                        const SizedBox(height: 16),
                        if (students.isEmpty)
                          _MessagePanel(
                            icon: Icons.people_outline_rounded,
                            title: '응시 기록이 있는 학생이 없습니다.',
                            message: '학생이 Mock Exam을 제출하면 이곳에 누적 리포트가 표시됩니다.',
                            actionLabel: '새로고침',
                            onTap: _reload,
                          )
                        else
                          ...students.map((item) {
                            final data = _asMap(item);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _StudentReportCard(
                                student: data,
                                onTap: () => _openDetail(data),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.groups_2_outlined,
                color: _TeacherMockStudentReportListScreenState._blue,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '학생별 Mock Exam 누적 리포트',
                    style: TextStyle(
                      color: _TeacherMockStudentReportListScreenState._ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '응시 기록이 있는 학생의 평균, 최근 점수, 약점 유형을 확인합니다.',
                    style: TextStyle(
                      color: _TeacherMockStudentReportListScreenState._muted,
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

class _StudentReportCard extends StatelessWidget {
  const _StudentReportCard({
    required this.student,
    required this.onTap,
  });

  final Map<String, dynamic> student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weakTypes = _asList(student['weak_types'])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: _AdminCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _asText(student['nickname'], '학').characters.first,
                  style: const TextStyle(
                    color: _TeacherMockStudentReportListScreenState._blue,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
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
                        color: _TeacherMockStudentReportListScreenState._ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Pill('총 응시 ${_asInt(student['attempt_count'])}회'),
                        _Pill('평균 ${_score(student['average_score'])}점'),
                        _Pill('최고 ${_score(student['highest_score'])}점'),
                        _Pill('최근 ${_score(student['latest_score'])}점'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      weakTypes.isEmpty
                          ? '약점 유형: 아직 없음'
                          : '약점: ${weakTypes.join(', ')}',
                      style: const TextStyle(
                        color: _TeacherMockStudentReportListScreenState._muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '최근 응시일 ${_formatDate(student['latest_submitted_at'])}',
                      style: const TextStyle(
                        color: _TeacherMockStudentReportListScreenState._muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: _TeacherMockStudentReportListScreenState._muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _TeacherMockStudentReportListScreenState._blue,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _TeacherMockStudentReportListScreenState._blue,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _TeacherMockStudentReportListScreenState._ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _TeacherMockStudentReportListScreenState._muted,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onTap,
              child: Text(actionLabel),
            ),
          ],
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
        border:
            Border.all(color: _TeacherMockStudentReportListScreenState._line),
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
