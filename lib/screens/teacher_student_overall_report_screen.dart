import 'package:flutter/material.dart';

import '../services/teacher_problem_set_service.dart';

class TeacherStudentOverallReportScreen extends StatefulWidget {
  const TeacherStudentOverallReportScreen({
    super.key,
    required this.studentId,
  });

  final int studentId;

  @override
  State<TeacherStudentOverallReportScreen> createState() =>
      _TeacherStudentOverallReportScreenState();
}

class _TeacherStudentOverallReportScreenState
    extends State<TeacherStudentOverallReportScreen> {
  static const blue = Color(0xFF2563EB);
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const surface = Color(0xFFF4F7FB);

  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = TeacherProblemSetService.fetchStudentOverallReport(
      widget.studentId,
    );
  }

  void _reload() {
    setState(() {
      _future = TeacherProblemSetService.fetchStudentOverallReport(
        widget.studentId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          '전체 누적 리포트',
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
              message: snapshot.error.toString(),
              onPressed: _reload,
            );
          }
          return _OverallBody(data: snapshot.data ?? const {});
        },
      ),
    );
  }
}

class _OverallBody extends StatelessWidget {
  const _OverallBody({required this.data});

  final Map<String, dynamic> data;

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _asString(dynamic value, [String fallback = '-']) {
    final text = value?.toString() ?? '';
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  List<dynamic> _asList(dynamic value) => value is List ? value : const [];

  String _score(dynamic value) {
    if (value == null) return '-';
    if (value is num && value % 1 != 0) return value.toStringAsFixed(1);
    return '${_asInt(value)}';
  }

  String _formatDate(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '-';
    final now = DateTime.now();
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';
    if (parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day) {
      return '오늘 $time';
    }
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '$month.$day $time';
  }

  @override
  Widget build(BuildContext context) {
    final student = data['student'] is Map ? data['student'] as Map : const {};
    final summary = data['summary'] is Map ? data['summary'] as Map : const {};
    final weakTypes =
        _asList(summary['weak_types']).map((e) => e.toString()).toList();
    final studentId = _asInt(student['id']);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryCard(
                  nickname: _asString(student['nickname'], '학생'),
                  finalTouch:
                      '${_asInt(summary['final_touch_viewed'])}/${_asInt(summary['final_touch_total'])}',
                  problemSets:
                      '${_asInt(summary['problem_sets_completed'])}/${_asInt(summary['problem_sets_total'])}',
                  averageScore: '${_score(summary['average_score'])}점',
                  recentAt: _formatDate(summary['recent_study_at']),
                  weakTypes: weakTypes,
                ),
                const SizedBox(height: 14),
                _RecommendationSection(
                  items: _asList(data['recommendations']),
                  studentId: studentId,
                ),
                const SizedBox(height: 14),
                _TypeStatsSection(items: _asList(data['type_stats'])),
                const SizedBox(height: 14),
                _FolderProgressSection(items: _asList(data['folder_progress'])),
                const SizedBox(height: 14),
                _RecentResultsSection(items: _asList(data['recent_results'])),
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
    required this.nickname,
    required this.finalTouch,
    required this.problemSets,
    required this.averageScore,
    required this.recentAt,
    required this.weakTypes,
  });

  final String nickname;
  final String finalTouch;
  final String problemSets;
  final String averageScore;
  final String recentAt;
  final List<String> weakTypes;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: _TeacherStudentOverallReportScreenState.blue,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname,
                        style: const TextStyle(
                          color: _TeacherStudentOverallReportScreenState.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '전체 학습 누적 현황',
                        style: TextStyle(
                          color: _TeacherStudentOverallReportScreenState.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricPill(label: 'Final Touch', value: finalTouch),
                _MetricPill(label: '문제세트', value: problemSets),
                _MetricPill(label: '평균 점수', value: averageScore),
                _MetricPill(label: '최근 학습일', value: recentAt),
                _MetricPill(
                  label: '약점 유형',
                  value: weakTypes.isEmpty ? '-' : weakTypes.join(', '),
                  wide: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    this.wide = false,
  });

  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? 250 : 150,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _TeacherStudentOverallReportScreenState.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _TeacherStudentOverallReportScreenState.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _TeacherStudentOverallReportScreenState.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection({
    required this.items,
    required this.studentId,
  });

  final List<dynamic> items;
  final int studentId;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '추천 학습',
      subtitle: '전체 누적 기록을 기준으로 자동 생성한 보충 방향입니다.',
      child: items.isEmpty
          ? const Text(
              '현재 추가 추천이 없습니다.',
              style: TextStyle(
                color: _TeacherStudentOverallReportScreenState.muted,
                fontWeight: FontWeight.w700,
              ),
            )
          : Column(
              children: items.map((item) {
                final data = item is Map
                    ? Map<String, dynamic>.from(item)
                    : <String, dynamic>{};
                final priority = data['priority']?.toString() ?? 'medium';
                final isHigh = priority == 'high';
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isHigh
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isHigh
                          ? const Color(0xFFBFDBFE)
                          : _TeacherStudentOverallReportScreenState.line,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isHigh
                            ? Icons.priority_high_rounded
                            : Icons.tips_and_updates_rounded,
                        color: isHigh
                            ? _TeacherStudentOverallReportScreenState.blue
                            : _TeacherStudentOverallReportScreenState.muted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data['message']?.toString() ?? '추천 학습을 확인하세요.',
                          style: const TextStyle(
                            color: _TeacherStudentOverallReportScreenState.ink,
                            height: 1.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _OverallAssignButton(
                        studentId: studentId,
                        recommendation: data,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _OverallAssignButton extends StatefulWidget {
  const _OverallAssignButton({
    required this.studentId,
    required this.recommendation,
  });

  final int studentId;
  final Map<String, dynamic> recommendation;

  @override
  State<_OverallAssignButton> createState() => _OverallAssignButtonState();
}

class _OverallAssignButtonState extends State<_OverallAssignButton> {
  bool _isSaving = false;

  bool get _assigned =>
      widget.recommendation['is_assigned'] == true ||
      widget.recommendation['assigned_recommendation_id'] != null;

  Future<void> _assign() async {
    setState(() => _isSaving = true);
    try {
      final assignedData =
          await TeacherProblemSetService.assignStudentRecommendation(
        studentId: widget.studentId,
        recommendation: widget.recommendation,
      );
      widget.recommendation['is_assigned'] = true;
      widget.recommendation['assigned_recommendation_id'] = assignedData['id'];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('추천을 배정했습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('배정 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_assigned) {
      return const _OverallAssignedBadge();
    }
    return OutlinedButton(
      onPressed: widget.studentId <= 0 || _isSaving ? null : _assign,
      child: Text(_isSaving ? '배정 중' : '배정'),
    );
  }
}

class _OverallAssignedBadge extends StatelessWidget {
  const _OverallAssignedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Text(
        '배정됨',
        style: TextStyle(
          color: _TeacherStudentOverallReportScreenState.blue,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TypeStatsSection extends StatelessWidget {
  const _TypeStatsSection({required this.items});

  final List<dynamic> items;

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '전체 유형별 누적 정답률',
      subtitle: '학생이 지금까지 푼 모든 문제세트를 기준으로 계산했습니다.',
      child: items.isEmpty
          ? const Text(
              '아직 응시 기록이 없습니다.',
              style: TextStyle(
                color: _TeacherStudentOverallReportScreenState.muted,
              ),
            )
          : Column(
              children: items.map((item) {
                final data = item is Map ? item : const {};
                final accuracy = _asInt(data['accuracy']);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: Text(
                          data['label']?.toString() ?? '문제',
                          style: const TextStyle(
                            color: _TeacherStudentOverallReportScreenState.ink,
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
                              _TeacherStudentOverallReportScreenState.blue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 92,
                        child: Text(
                          '$accuracy% (${_asInt(data['correct'])}/${_asInt(data['total'])})',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color:
                                _TeacherStudentOverallReportScreenState.muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _FolderProgressSection extends StatelessWidget {
  const _FolderProgressSection({required this.items});

  final List<dynamic> items;

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _score(dynamic value) {
    if (value == null) return '-';
    if (value is num && value % 1 != 0) return value.toStringAsFixed(1);
    return '${_asInt(value)}';
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '교재/단원별 진행 현황',
      subtitle: '교재 폴더와 단원 폴더 기준으로 누적 진행률을 보여줍니다.',
      child: items.isEmpty
          ? const Text(
              '표시할 폴더 기록이 없습니다.',
              style: TextStyle(
                color: _TeacherStudentOverallReportScreenState.muted,
              ),
            )
          : Column(
              children: items.map((item) {
                final data = item is Map ? item : const {};
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _TeacherStudentOverallReportScreenState.line,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.folder_rounded,
                        color: _TeacherStudentOverallReportScreenState.blue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data['book_folder'] ?? '-'} / ${data['unit_folder'] ?? '-'}',
                              style: const TextStyle(
                                color:
                                    _TeacherStudentOverallReportScreenState.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Final Touch ${_asInt(data['final_touch_viewed'])}/${_asInt(data['final_touch_total'])} · 문제세트 ${_asInt(data['problem_sets_completed'])}/${_asInt(data['problem_sets_total'])} · 평균 ${_score(data['average_score'])}점',
                              style: const TextStyle(
                                color: _TeacherStudentOverallReportScreenState
                                    .muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _RecentResultsSection extends StatelessWidget {
  const _RecentResultsSection({required this.items});

  final List<dynamic> items;

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatDate(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '-';
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$month.$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '최근 문제세트 결과',
      subtitle: '최근 응시한 문제세트 5개를 표시합니다.',
      child: items.isEmpty
          ? const Text(
              '아직 최근 응시 기록이 없습니다.',
              style: TextStyle(
                color: _TeacherStudentOverallReportScreenState.muted,
              ),
            )
          : Column(
              children: items.map((item) {
                final data = item is Map ? item : const {};
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _TeacherStudentOverallReportScreenState.line,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.assignment_turned_in_rounded,
                        color: _TeacherStudentOverallReportScreenState.blue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data['title']?.toString() ?? '문제세트',
                          style: const TextStyle(
                            color: _TeacherStudentOverallReportScreenState.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${_asInt(data['score'])}점 · ${_formatDate(data['submitted_at'])}',
                        style: const TextStyle(
                          color: _TeacherStudentOverallReportScreenState.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _TeacherStudentOverallReportScreenState.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: _TeacherStudentOverallReportScreenState.muted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            child,
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _TeacherStudentOverallReportScreenState.line),
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
    required this.message,
    required this.onPressed,
  });

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
                  Icons.info_outline_rounded,
                  color: _TeacherStudentOverallReportScreenState.blue,
                  size: 34,
                ),
                const SizedBox(height: 10),
                const Text(
                  '전체 리포트를 불러오지 못했습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _TeacherStudentOverallReportScreenState.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _TeacherStudentOverallReportScreenState.muted,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: onPressed,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
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
