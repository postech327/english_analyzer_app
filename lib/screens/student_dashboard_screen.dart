// lib/screens/student_dashboard_screen.dart

import 'package:flutter/material.dart';

import '../config/auth_store.dart';
import '../models/learning_assignment.dart';
import '../services/api_service.dart';
import '../services/learning_assignment_service.dart';
import 'final_touch_list_screen.dart';
import 'student/mock_exam_list_screen.dart';
import 'student/student_exam_list_screen.dart';
import 'student/student_results_hub_screen.dart';
import 'student_learning_assignments_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  Map<String, dynamic>? dashboard;
  bool isLoading = true;
  final _assignmentService = const LearningAssignmentService();
  late Future<List<LearningAssignment>> _workbookAssignmentsFuture;

  @override
  void initState() {
    super.initState();
    _workbookAssignmentsFuture =
        _assignmentService.fetchStudentAssignments(contentType: 'workbook');
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final workbookFuture =
        _assignmentService.fetchStudentAssignments(contentType: 'workbook');
    if (isLoading) {
      _workbookAssignmentsFuture = workbookFuture;
    } else {
      setState(() {
        _workbookAssignmentsFuture = workbookFuture;
      });
    }
    try {
      final data = await ApiService.fetchDashboard();

      if (!mounted) return;

      setState(() {
        dashboard = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('dashboard load error: $e');

      if (!mounted) return;

      setState(() {
        dashboard = {
          'best_score': null,
          'latest_attempt_score': null,
          'weakest_type': null,
          'recommendations': [],
        };
        isLoading = false;
      });
    }
  }

  int? _safeNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  double? _safeNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _safeText(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  List<dynamic> _safeList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  bool _hasUsefulWeakType(String value) {
    final normalized = value.trim();
    return normalized.isNotEmpty && normalized != '-' && normalized != '아직 없음';
  }

  String _scoreText(int? score) {
    if (score == null) return '-';
    return '$score';
  }

  String _percentText(double? value) {
    if (value == null) return '-';
    final rounded = value.round();
    return '$rounded%';
  }

  String _dateText(dynamic value) {
    final raw = _safeText(value, fallback: '');
    if (raw.isEmpty) return '기록 없음';
    final datePart = raw.split(' ').first.split('T').first;
    if (datePart.length >= 10) return datePart;
    return raw;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || dashboard == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F8FC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = dashboard!;
    final totalAttempts = _safeNullableInt(data['total_attempts']) ?? 0;
    final totalQuestionsSolved =
        _safeNullableInt(data['total_questions_solved']) ?? 0;
    final hasAttempts = totalAttempts > 0;
    final bestScore = hasAttempts ? _safeNullableInt(data['best_score']) : null;
    final latestScore =
        hasAttempts ? _safeNullableInt(data['latest_attempt_score']) : null;
    final averageScore =
        hasAttempts ? _safeNullableDouble(data['average_score']) : null;
    final accuracy =
        totalQuestionsSolved > 0 ? _safeNullableDouble(data['accuracy']) : null;
    final weakType = _safeText(
      data['weakest_type'],
      fallback: '아직 없음',
    );
    final trendDirection = _safeText(
      data['trend_direction'],
      fallback: '기록 없음',
    );
    final recentResults = _safeList(data['recent_results']);
    final recommendations = _safeList(data['recommendations']);
    final nickname = _safeText(
      AuthStore.nickname,
      fallback: 'Student',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FC),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          '오늘의 학습',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showSnack('알림 기능은 다음 단계에서 연결됩니다.');
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadDashboard,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 112),
          children: [
            _learningSummaryHeader(
              nickname: nickname,
              totalAttempts: totalAttempts,
              latestScore: latestScore,
            ),
            const SizedBox(height: 16),
            _todayLearningCard(),
            const SizedBox(height: 16),
            _workbookLearningCard(),
            const SizedBox(height: 16),
            _learningStatusCard(
              totalAttempts: totalAttempts,
              bestScore: bestScore,
              latestScore: latestScore,
              averageScore: averageScore,
              accuracy: accuracy,
              weakType: weakType,
              recentResults: recentResults,
            ),
            const SizedBox(height: 16),
            _recentLearningCard(recentResults: recentResults),
            const SizedBox(height: 16),
            _recommendedReviewCard(
              weakType: weakType,
              recommendations: recommendations,
            ),
            const SizedBox(height: 16),
            _growthCard(
              totalAttempts: totalAttempts,
              trendDirection: trendDirection,
              latestScore: latestScore,
              averageScore: averageScore,
            ),
            const SizedBox(height: 16),
            _mainShortcutsCard(),
          ],
        ),
      ),
    );
  }

  Widget _learningSummaryHeader({
    required String nickname,
    required int totalAttempts,
    required int? latestScore,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '$nickname님',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.24),
                            ),
                          ),
                          child: const Text(
                            '학생 계정',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '안녕하세요! 오늘도 한 걸음씩 성장해 볼까요?',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Text(
              totalAttempts > 0
                  ? '최근 점수 ${_scoreText(latestScore)}점까지 기록했어요. 오늘은 복습과 실전 중 하나를 골라 이어가면 좋아요.'
                  : '아직 학습 기록이 없습니다. Final Touch 복습이나 모의고사로 첫 기록을 만들어 보세요.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _todayLearningCard() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.today_rounded,
            title: '오늘의 학습',
            subtitle: '바로 이어서 공부할 수 있는 핵심 메뉴입니다.',
            color: Color(0xFF2563EB),
          ),
          const SizedBox(height: 14),
          _LearningActionTile(
            icon: Icons.edit_note_rounded,
            title: 'Final Touch 복습',
            subtitle: '저장된 분석 자료와 핵심 문장을 복습해요.',
            color: const Color(0xFF7C3AED),
            onTap: _openFinalTouch,
          ),
          const SizedBox(height: 10),
          _LearningActionTile(
            icon: Icons.assignment_ind_rounded,
            title: '내 학습',
            subtitle: '선생님이 배포한 학습 자료를 확인해요.',
            color: const Color(0xFF2563EB),
            onTap: _openLearningAssignments,
          ),
          const SizedBox(height: 10),
          _LearningActionTile(
            icon: Icons.assignment_turned_in_rounded,
            title: '모의고사 풀기',
            subtitle: '20문항 실전 모의고사를 풀고 결과를 확인해요.',
            color: const Color(0xFF0891B2),
            onTap: _openMockExam,
          ),
        ],
      ),
    );
  }

  Widget _workbookLearningCard() {
    return FutureBuilder<List<LearningAssignment>>(
      future: _workbookAssignmentsFuture,
      builder: (context, snapshot) {
        final assignments = snapshot.data ?? const <LearningAssignment>[];
        final active = assignments
            .where((item) => item.status != 'completed')
            .toList()
          ..sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
        final latest = active.isNotEmpty
            ? active.first
            : (assignments.isNotEmpty ? assignments.first : null);
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final status = latest?.status ?? 'none';

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEFF6FF), Color(0xFFF0FDFA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFBFDBFE)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '워크북 학습',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isLoading
                              ? '배포된 워크북을 확인하는 중입니다.'
                              : active.isEmpty
                                  ? '지금 바로 진행할 워크북은 없습니다.'
                                  : '진행해야 할 워크북 ${active.length}개가 있습니다.',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _WorkbookStatusChip(status: status),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDCEBFF)),
                ),
                child: Text(
                  latest == null
                      ? '선생님이 워크북을 배포하면 이곳에 바로 표시됩니다.'
                      : latest.title.isEmpty
                          ? '제목 없는 워크북'
                          : latest.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openLearningAssignments,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(active.isEmpty ? '내 학습으로 이동' : '바로가기'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _learningStatusCard({
    required int totalAttempts,
    required int? bestScore,
    required int? latestScore,
    required double? averageScore,
    required double? accuracy,
    required String weakType,
    required List<dynamic> recentResults,
  }) {
    final latestDate = recentResults.isNotEmpty && recentResults.first is Map
        ? _dateText((recentResults.first as Map)['created_at'])
        : '기록 없음';

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.emoji_events_rounded,
            title: '학습 상태 요약',
            subtitle: '쌓인 기록을 기준으로 현재 상태를 보여줍니다.',
            color: Color(0xFF6D4AFF),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 4 : 2;
              final items = [
                _StatusData(
                  label: '최고 점수',
                  value: bestScore == null ? '-' : '${_scoreText(bestScore)}점',
                  helper: bestScore == null ? '기록 없음' : '가장 높은 점수',
                  icon: Icons.star_rounded,
                  color: const Color(0xFF2563EB),
                ),
                _StatusData(
                  label: '최근 점수',
                  value:
                      latestScore == null ? '-' : '${_scoreText(latestScore)}점',
                  helper: latestScore == null ? '기록 없음' : '최근 응시 결과',
                  icon: Icons.bolt_rounded,
                  color: const Color(0xFF7C3AED),
                ),
                _StatusData(
                  label: '정답률',
                  value: _percentText(accuracy),
                  helper: accuracy == null ? '기록 없음' : '누적 풀이 기준',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF0F766E),
                ),
                _StatusData(
                  label: '약점 유형',
                  value: _hasUsefulWeakType(weakType) ? weakType : '아직 없음',
                  helper: _hasUsefulWeakType(weakType) ? '보완 추천' : '데이터 대기',
                  icon: Icons.psychology_alt_rounded,
                  color: const Color(0xFFEA580C),
                ),
              ];

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: columns == 4 ? 1.65 : 1.45,
                ),
                itemBuilder: (context, index) =>
                    _StatusTile(data: items[index]),
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SoftInfoChip(
                icon: Icons.flag_rounded,
                text: '응시 $totalAttempts회',
                color: const Color(0xFF2563EB),
              ),
              _SoftInfoChip(
                icon: Icons.insights_rounded,
                text: averageScore == null
                    ? '평균 기록 없음'
                    : '평균 ${averageScore.toStringAsFixed(1)}점',
                color: const Color(0xFF7C3AED),
              ),
              _SoftInfoChip(
                icon: Icons.calendar_month_rounded,
                text: '최근 학습 $latestDate',
                color: const Color(0xFF0F766E),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentLearningCard({required List<dynamic> recentResults}) {
    final recentItems = recentResults
        .whereType<Map>()
        .take(3)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.history_rounded,
            title: '최근 학습',
            subtitle: '학습 기록이 쌓이면 최근 흐름이 이곳에 표시됩니다.',
            color: Color(0xFF0F766E),
          ),
          const SizedBox(height: 14),
          if (recentItems.isEmpty)
            const _EmptyNotice(
              icon: Icons.auto_graph_rounded,
              message:
                  '아직 최근 학습 기록이 없습니다.\nFinal Touch 복습이나 모의고사를 완료하면 이곳에 표시됩니다.',
            )
          else
            ...recentItems.map(
              (item) => _RecentLearningTile(
                title: '내신 문제세트',
                score: _safeNullableInt(item['score']),
                correctCount: _safeNullableInt(item['correct_count']),
                totalQuestions: _safeNullableInt(item['total_questions']),
                dateText: _dateText(item['created_at']),
              ),
            ),
        ],
      ),
    );
  }

  Widget _recommendedReviewCard({
    required String weakType,
    required List<dynamic> recommendations,
  }) {
    final hasWeakType = _hasUsefulWeakType(weakType);
    final hasRecommendations = recommendations.isNotEmpty;
    final firstRecommendation =
        hasRecommendations && recommendations.first is Map
            ? _safeText(
                (recommendations.first as Map)['message'],
                fallback: '',
              )
            : '';

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.track_changes_rounded,
            title: '추천 복습',
            subtitle: '점수와 약점 유형을 바탕으로 다음 복습을 제안합니다.',
            color: Color(0xFFEA580C),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasWeakType
                  ? const Color(0xFFFFFBEB)
                  : const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasWeakType
                    ? const Color(0xFFFDE68A)
                    : const Color(0xFFDDD6FE),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasWeakType ? '최근 약점 유형: $weakType' : '아직 뚜렷한 약점 유형이 없습니다.',
                  style: const TextStyle(
                    color: Color(0xFF4C1D95),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  firstRecommendation.isNotEmpty
                      ? firstRecommendation
                      : hasWeakType
                          ? '오답 다시보기에서 $weakType 유형을 먼저 확인해 보세요.'
                          : '모의고사나 문제세트를 풀면 추천 복습이 더 정확하게 표시됩니다.',
                  style: const TextStyle(
                    color: Color(0xFF5B21B6),
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PrimaryButton(
                  icon: Icons.fact_check_rounded,
                  label: '오답 다시보기',
                  onTap: _openResults,
                ),
              ),
              if (hasRecommendations) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _OutlineButton(
                    icon: Icons.list_alt_rounded,
                    label: '추천 전체 보기',
                    onTap: () => _showRecommendations(recommendations),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _growthCard({
    required int totalAttempts,
    required String trendDirection,
    required int? latestScore,
    required double? averageScore,
  }) {
    final hasGrowthData = totalAttempts >= 2;
    final message = hasGrowthData
        ? '최근 흐름은 $trendDirection입니다. 최근 점수 ${_scoreText(latestScore)}점, 평균 ${averageScore?.toStringAsFixed(1) ?? '-'}점을 기준으로 다음 복습을 고르면 좋아요.'
        : '학습 기록이 쌓이면 최근 변화와 성장 흐름을 확인할 수 있습니다.';

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.local_florist_rounded,
            title: '나의 성장',
            subtitle: '가짜 그래프 없이 실제 기록이 쌓일 때 흐름을 보여줍니다.',
            color: Color(0xFF10B981),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.ssid_chart_rounded,
                  color: Color(0xFF059669),
                  size: 23,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF065F46),
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainShortcutsCard() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.grid_view_rounded,
            title: '바로가기',
            subtitle: '자주 쓰는 학습 메뉴를 빠르게 열 수 있습니다.',
            color: Color(0xFF2563EB),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 680 ? 4 : 2;
              final shortcuts = [
                _ShortcutData(
                  icon: Icons.assignment_ind_rounded,
                  title: '내 학습',
                  subtitle: '배포 자료',
                  color: const Color(0xFF0F766E),
                  onTap: _openLearningAssignments,
                ),
                _ShortcutData(
                  icon: Icons.edit_note_rounded,
                  title: 'Final Touch',
                  subtitle: '분석 자료',
                  color: const Color(0xFF7C3AED),
                  onTap: _openFinalTouch,
                ),
                _ShortcutData(
                  icon: Icons.assignment_rounded,
                  title: '모의고사',
                  subtitle: '20문항 실전',
                  color: const Color(0xFF0891B2),
                  onTap: _openMockExam,
                ),
                _ShortcutData(
                  icon: Icons.replay_circle_filled_rounded,
                  title: '오답 다시보기',
                  subtitle: '결과 복습',
                  color: const Color(0xFFEA580C),
                  onTap: _openResults,
                ),
              ];

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: shortcuts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: constraints.maxWidth >= 680 ? 1.08 : 1.28,
                ),
                itemBuilder: (context, index) {
                  return _ShortcutCard(data: shortcuts[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _openFinalTouch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FinalTouchListScreen()),
    );
  }

  void _openMockExam() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MockExamListScreen()),
    );
  }

  void _openResults() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentResultsHubScreen()),
    );
  }

  void _openLearningAssignments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StudentLearningAssignmentsScreen(),
      ),
    );
  }

  void _showRecommendations(List<dynamic> recommendations) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.72;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.track_changes_rounded,
                        color: Color(0xFF2563EB),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '오늘의 추천 학습',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (recommendations.isEmpty)
                    const Text(
                      '현재 추가 추천이 없습니다. Final Touch 복습이나 모의고사를 완료하면 더 정확한 추천이 표시됩니다.',
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    )
                  else
                    ...recommendations.map(
                      (item) => _recommendationTile(
                        item,
                        closeSheet: true,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openRecommendation(dynamic item, {bool closeSheet = false}) {
    final data = item is Map ? item : const <String, dynamic>{};
    final route = _safeText(
      data['route'] ?? data['target_route'],
      fallback: '',
    );
    final type =
        _safeText(data['type'] ?? data['recommendation_type'], fallback: '');
    final bookFolderId = _safeNullableInt(data['book_folder_id']);
    final unitFolderId = _safeNullableInt(data['unit_folder_id']);
    final bookFolderName = _safeText(data['book_folder_name'], fallback: '');
    final unitFolderName = _safeText(data['unit_folder_name'], fallback: '');

    if (closeSheet) {
      Navigator.pop(context);
    }

    if (route == '/student/final-touch' || type == 'final_touch') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FinalTouchListScreen(
            initialBookFolderId: bookFolderId,
            initialBookFolderName:
                bookFolderName.isEmpty ? null : bookFolderName,
            initialUnitFolderId: unitFolderId,
            initialUnitFolderName:
                unitFolderName.isEmpty ? null : unitFolderName,
          ),
        ),
      );
      return;
    }

    if (route == '/student/exams' ||
        type == 'problem_set' ||
        type == 'weak_type' ||
        type == 'start' ||
        type == 'stale') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentExamListScreen(
            initialBookFolderId: bookFolderId,
            initialBookFolderName:
                bookFolderName.isEmpty ? null : bookFolderName,
            initialUnitFolderId: unitFolderId,
            initialUnitFolderName:
                unitFolderName.isEmpty ? null : unitFolderName,
          ),
        ),
      );
      return;
    }

    if (type == 'review') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FinalTouchListScreen(
            initialBookFolderId: bookFolderId,
            initialBookFolderName:
                bookFolderName.isEmpty ? null : bookFolderName,
            initialUnitFolderId: unitFolderId,
            initialUnitFolderName:
                unitFolderName.isEmpty ? null : unitFolderName,
          ),
        ),
      );
      return;
    }

    _showSnack('추천 학습 이동 경로를 준비 중입니다.');
  }

  String _recommendationActionLabel(dynamic item) {
    final data = item is Map ? item : const <String, dynamic>{};
    final actionLabel = _safeText(data['action_label'], fallback: '');
    if (actionLabel.isNotEmpty) return actionLabel;

    final route = _safeText(
      data['route'] ?? data['target_route'],
      fallback: '',
    );
    final type =
        _safeText(data['type'] ?? data['recommendation_type'], fallback: '');

    if (route == '/student/final-touch' ||
        type == 'final_touch' ||
        type == 'review') {
      return 'Final Touch 보기';
    }
    if (route == '/student/exams' ||
        type == 'problem_set' ||
        type == 'weak_type' ||
        type == 'start' ||
        type == 'stale') {
      return '시험 보러가기';
    }
    return '바로가기';
  }

  Widget _recommendationTile(dynamic item, {bool closeSheet = false}) {
    final data = item is Map ? item : const <String, dynamic>{};
    final message = _safeText(
      data['message'],
      fallback: '추천 학습을 확인하세요.',
    );
    final priority = _safeText(data['priority'], fallback: 'medium');
    final isHigh = priority == 'high';
    final actionLabel = _recommendationActionLabel(item);
    final isTeacherAssigned = data['is_teacher_assigned'] == true ||
        data['source'] == 'teacher' ||
        data['assigned_recommendation_id'] != null;

    return InkWell(
      onTap: () => _openRecommendation(item, closeSheet: closeSheet),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isTeacherAssigned
              ? const Color(0xFFEFF6FF)
              : isHigh
                  ? const Color(0xFFFFF7ED)
                  : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTeacherAssigned
                ? const Color(0xFF93C5FD)
                : isHigh
                    ? const Color(0xFFFED7AA)
                    : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isTeacherAssigned
                  ? Icons.school_rounded
                  : isHigh
                      ? Icons.priority_high_rounded
                      : Icons.check_circle_rounded,
              size: 19,
              color: isTeacherAssigned
                  ? const Color(0xFF2563EB)
                  : isHigh
                      ? const Color(0xFFEA580C)
                      : const Color(0xFF16A34A),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (isTeacherAssigned)
                        const _RecommendationBadge(
                          label: '선생님 추천',
                          backgroundColor: Color(0xFFDBEAFE),
                          textColor: Color(0xFF1D4ED8),
                        )
                      else if (isHigh)
                        const _RecommendationBadge(
                          label: '자동 추천',
                          backgroundColor: Color(0xFFE5E7EB),
                          textColor: Color(0xFF4B5563),
                        ),
                    ],
                  ),
                  if (isTeacherAssigned || isHigh) const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    actionLabel,
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF2563EB),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkbookStatusChip extends StatelessWidget {
  const _WorkbookStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' => const Color(0xFF16A34A),
      'in_progress' => const Color(0xFF2563EB),
      'assigned' => const Color(0xFF7C3AED),
      _ => const Color(0xFF64748B),
    };
    final label = switch (status) {
      'completed' => '완료',
      'in_progress' => '진행 중',
      'assigned' => '미시작',
      _ => '대기',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusData {
  const _StatusData({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.data});

  final _StatusData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: data.color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: data.color, size: 18),
              ),
              const Spacer(),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftInfoChip extends StatelessWidget {
  const _SoftInfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentLearningTile extends StatelessWidget {
  const _RecentLearningTile({
    required this.title,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.dateText,
  });

  final String title;
  final int? score;
  final int? correctCount;
  final int? totalQuestions;
  final String dateText;

  @override
  Widget build(BuildContext context) {
    final resultText = correctCount != null && totalQuestions != null
        ? '$correctCount / $totalQuestions'
        : '정답 기록 없음';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF0284C7),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${score ?? '-'}점 · $resultText · $dateText',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
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

class _LearningActionTile extends StatelessWidget {
  const _LearningActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotice extends StatelessWidget {
  const _EmptyNotice({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2563EB),
          side: const BorderSide(color: Color(0xFFBFDBFE)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _ShortcutData {
  const _ShortcutData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.data});

  final _ShortcutData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, color: data.color, size: 21),
              ),
              const Spacer(),
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationBadge extends StatelessWidget {
  const _RecommendationBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
