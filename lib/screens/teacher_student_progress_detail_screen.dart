import 'package:flutter/material.dart';

import '../services/teacher_problem_set_service.dart';
import 'teacher_student_overall_report_screen.dart';

class TeacherStudentProgressDetailScreen extends StatefulWidget {
  const TeacherStudentProgressDetailScreen({
    super.key,
    required this.folderId,
    required this.studentId,
  });

  final int folderId;
  final int studentId;

  @override
  State<TeacherStudentProgressDetailScreen> createState() =>
      _TeacherStudentProgressDetailScreenState();
}

class _TeacherStudentProgressDetailScreenState
    extends State<TeacherStudentProgressDetailScreen> {
  static const blue = Color(0xFF2563EB);
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const surface = Color(0xFFF4F7FB);

  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return TeacherProblemSetService.fetchStudentProgressDetail(
      folderId: widget.folderId,
      studentId: widget.studentId,
    );
  }

  void _reload() {
    setState(() => _future = _load());
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
          '학생 상세 리포트',
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
              title: '상세 리포트를 불러오지 못했습니다.',
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
    final folder = data['folder'] is Map ? data['folder'] as Map : const {};
    final summary = data['summary'] is Map ? data['summary'] as Map : const {};
    final weakTypes =
        _asList(data['weak_types']).map((e) => e.toString()).toList();
    final studentId = _asInt(student['id']);
    final nickname = _asString(student['nickname'], '학생');
    final book = _asString(folder['book_name'], '교재 미지정');
    final unit = _asString(folder['name'], '단원 미지정');

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
                  nickname: nickname,
                  folderLabel: '$book / $unit',
                  finalTouch:
                      '${_asInt(summary['final_touch_viewed'])}/${_asInt(summary['final_touch_total'])}',
                  problemSets:
                      '${_asInt(summary['problem_sets_completed'])}/${_asInt(summary['problem_sets_total'])}',
                  averageScore: '${_score(summary['average_score'])}점',
                  recentAt: _formatDate(summary['recent_study_at']),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: studentId <= 0
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TeacherStudentOverallReportScreen(
                                  studentId: studentId,
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.query_stats_rounded, size: 18),
                    label: const Text('전체 리포트 보기'),
                  ),
                ),
                const SizedBox(height: 14),
                _RecommendationCard(
                  items: _asList(data['recommendations']),
                  studentId: studentId,
                ),
                const SizedBox(height: 14),
                _WeakCard(
                  weakTypes: weakTypes,
                  recommendation: _asString(
                    data['recommendation'],
                    '현재 특별한 약점 유형은 없습니다.',
                  ),
                ),
                const SizedBox(height: 14),
                _ProblemSetSection(items: _asList(data['problem_sets'])),
                const SizedBox(height: 14),
                _TypeStatsSection(items: _asList(data['type_stats'])),
                const SizedBox(height: 14),
                _FinalTouchSection(items: _asList(data['final_touches'])),
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
    required this.folderLabel,
    required this.finalTouch,
    required this.problemSets,
    required this.averageScore,
    required this.recentAt,
  });

  final String nickname;
  final String folderLabel;
  final String finalTouch;
  final String problemSets;
  final String averageScore;
  final String recentAt;

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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_search_rounded,
                    color: _TeacherStudentProgressDetailScreenState.blue,
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
                          color: _TeacherStudentProgressDetailScreenState.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        folderLabel,
                        style: const TextStyle(
                          color: _TeacherStudentProgressDetailScreenState.muted,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: _TeacherStudentProgressDetailScreenState.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _TeacherStudentProgressDetailScreenState.muted,
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
              color: _TeacherStudentProgressDetailScreenState.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.items,
    required this.studentId,
  });

  final List<dynamic> items;
  final int studentId;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '추천 학습',
      subtitle: '미열람 자료, 미응시 세트, 약점 유형을 기준으로 자동 생성됩니다.',
      child: items.isEmpty
          ? const Text(
              '현재 추가 추천이 없습니다.',
              style: TextStyle(
                color: _TeacherStudentProgressDetailScreenState.muted,
                fontWeight: FontWeight.w700,
              ),
            )
          : Column(
              children: items.map((item) {
                final data = item is Map
                    ? Map<String, dynamic>.from(item)
                    : <String, dynamic>{};
                return _RecommendationTile(
                  data: data,
                  studentId: studentId,
                );
              }).toList(),
            ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({
    required this.data,
    required this.studentId,
  });

  final Map<String, dynamic> data;
  final int studentId;

  @override
  Widget build(BuildContext context) {
    final priority = data['priority']?.toString() ?? 'medium';
    final isHigh = priority == 'high';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHigh ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHigh
              ? const Color(0xFFBFDBFE)
              : _TeacherStudentProgressDetailScreenState.line,
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
                ? _TeacherStudentProgressDetailScreenState.blue
                : _TeacherStudentProgressDetailScreenState.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['message']?.toString() ?? '추천 학습을 확인하세요.',
                  style: const TextStyle(
                    color: _TeacherStudentProgressDetailScreenState.ink,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _AssignButton(
                      studentId: studentId,
                      recommendation: data,
                    ),
                    _PriorityBadge(priority: priority),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignButton extends StatefulWidget {
  const _AssignButton({
    required this.studentId,
    required this.recommendation,
  });

  final int studentId;
  final Map<String, dynamic> recommendation;

  @override
  State<_AssignButton> createState() => _AssignButtonState();
}

class _AssignButtonState extends State<_AssignButton> {
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
      return const _AssignedBadge();
    }
    return OutlinedButton(
      onPressed: widget.studentId <= 0 || _isSaving ? null : _assign,
      child: Text(_isSaving ? '배정 중' : '배정'),
    );
  }
}

class _AssignedBadge extends StatelessWidget {
  const _AssignedBadge();

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
          color: _TeacherStudentProgressDetailScreenState.blue,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final isHigh = priority == 'high';
    final label = isHigh
        ? 'HIGH'
        : priority == 'low'
            ? 'LOW'
            : 'MED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isHigh
            ? _TeacherStudentProgressDetailScreenState.blue
            : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isHigh
              ? _TeacherStudentProgressDetailScreenState.blue
              : _TeacherStudentProgressDetailScreenState.line,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isHigh
              ? Colors.white
              : _TeacherStudentProgressDetailScreenState.muted,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WeakCard extends StatelessWidget {
  const _WeakCard({
    required this.weakTypes,
    required this.recommendation,
  });

  final List<String> weakTypes;
  final String recommendation;

  @override
  Widget build(BuildContext context) {
    final text = weakTypes.isEmpty ? '약점 유형 없음' : weakTypes.join(', ');
    return _SectionCard(
      title: '약점 요약',
      subtitle: '틀린 유형을 기준으로 약점을 정리합니다.',
      child: Container(
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
              '약점 유형: $text',
              style: const TextStyle(
                color: _TeacherStudentProgressDetailScreenState.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              recommendation,
              style: const TextStyle(
                color: _TeacherStudentProgressDetailScreenState.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProblemSetSection extends StatelessWidget {
  const _ProblemSetSection({required this.items});

  final List<dynamic> items;

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _asString(dynamic value, [String fallback = '-']) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? fallback : text;
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
      title: '문제세트별 결과',
      subtitle: '해당 폴더 안의 문제세트별 응시 상태입니다.',
      child: items.isEmpty
          ? const Text(
              '표시할 문제세트가 없습니다.',
              style: TextStyle(
                color: _TeacherStudentProgressDetailScreenState.muted,
              ),
            )
          : Column(
              children: items.map((item) {
                final data = item is Map ? item : const {};
                final completed = data['status'] == 'completed';
                final weakTypes = data['weak_types'] is List
                    ? (data['weak_types'] as List)
                        .map((e) => e.toString())
                        .toList()
                    : <String>[];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: completed
                          ? const Color(0xFFBFDBFE)
                          : _TeacherStudentProgressDetailScreenState.line,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        completed
                            ? Icons.check_circle_rounded
                            : Icons.schedule_rounded,
                        color: completed
                            ? _TeacherStudentProgressDetailScreenState.blue
                            : _TeacherStudentProgressDetailScreenState.muted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _asString(data['title']),
                              style: const TextStyle(
                                color: _TeacherStudentProgressDetailScreenState
                                    .ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              completed
                                  ? '${_asInt(data['score'])}점 / ${_asInt(data['correct_count'])}문항 정답 · ${_formatDate(data['submitted_at'])}'
                                  : '미응시',
                              style: const TextStyle(
                                color: _TeacherStudentProgressDetailScreenState
                                    .muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (weakTypes.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                '약점 유형: ${weakTypes.join(', ')}',
                                style: const TextStyle(
                                  color:
                                      _TeacherStudentProgressDetailScreenState
                                          .blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
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
      title: '유형별 정답률',
      subtitle: '이 학생이 해당 폴더에서 푼 문제 기준입니다.',
      child: items.isEmpty
          ? const Text(
              '아직 응시 기록이 없습니다.',
              style: TextStyle(
                color: _TeacherStudentProgressDetailScreenState.muted,
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
                            color: _TeacherStudentProgressDetailScreenState.ink,
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
                              _TeacherStudentProgressDetailScreenState.blue,
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
                                _TeacherStudentProgressDetailScreenState.muted,
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

class _FinalTouchSection extends StatelessWidget {
  const _FinalTouchSection({required this.items});

  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Final Touch 열람 목록',
      subtitle: '상세 화면을 한 번 이상 열면 열람 완료로 표시됩니다.',
      child: items.isEmpty
          ? const Text(
              '표시할 Final Touch가 없습니다.',
              style: TextStyle(
                color: _TeacherStudentProgressDetailScreenState.muted,
              ),
            )
          : Column(
              children: items.map((item) {
                final data = item is Map ? item : const {};
                final viewed = data['viewed'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: viewed
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: viewed
                          ? const Color(0xFFBFDBFE)
                          : _TeacherStudentProgressDetailScreenState.line,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        viewed
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        color: viewed
                            ? _TeacherStudentProgressDetailScreenState.blue
                            : _TeacherStudentProgressDetailScreenState.muted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data['source']?.toString() ?? 'Final Touch',
                          style: const TextStyle(
                            color: _TeacherStudentProgressDetailScreenState.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        viewed ? '열람 완료' : '미열람',
                        style: TextStyle(
                          color: viewed
                              ? _TeacherStudentProgressDetailScreenState.blue
                              : _TeacherStudentProgressDetailScreenState.muted,
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
                color: _TeacherStudentProgressDetailScreenState.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: _TeacherStudentProgressDetailScreenState.muted,
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
        border:
            Border.all(color: _TeacherStudentProgressDetailScreenState.line),
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
                  Icons.info_outline_rounded,
                  color: _TeacherStudentProgressDetailScreenState.blue,
                  size: 34,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _TeacherStudentProgressDetailScreenState.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _TeacherStudentProgressDetailScreenState.muted,
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
