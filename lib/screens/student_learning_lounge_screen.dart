import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'final_touch_list_screen.dart';
import 'student/mock_exam_list_screen.dart';
import 'student/student_results_hub_screen.dart';

class StudentLearningLoungeScreen extends StatefulWidget {
  const StudentLearningLoungeScreen({super.key});

  @override
  State<StudentLearningLoungeScreen> createState() =>
      _StudentLearningLoungeScreenState();
}

class _StudentLearningLoungeScreenState
    extends State<StudentLearningLoungeScreen> {
  static const _surface = Color(0xFFF6F8FC);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF64748B);
  static const _blue = Color(0xFF2563EB);
  static const _violet = Color(0xFF7C3AED);
  static const _mint = Color(0xFF0F766E);
  static const _line = Color(0xFFE2E8F0);

  Map<String, dynamic>? _dashboard;
  bool _isLoading = true;

  final List<_StudyTip> _tips = const [
    _StudyTip(
      title: '주제문은 첫 문장에만 있지 않아요',
      body: '마지막 문장이나 반복되는 핵심 표현도 함께 확인하면 주제와 제목 선택이 더 쉬워집니다.',
    ),
    _StudyTip(
      title: '빈칸은 연결어부터 보세요',
      body: 'however, therefore, for example 같은 연결어가 앞뒤 논리를 빠르게 보여줍니다.',
    ),
    _StudyTip(
      title: '오답은 이유까지 확인해요',
      body: '정답만 보는 것보다 왜 틀렸는지 한 줄로 남기면 같은 유형을 다시 만났을 때 훨씬 강해집니다.',
    ),
    _StudyTip(
      title: '긴 문장은 절과 구로 나누세요',
      body: '괄호 구조 분석처럼 절, 구, 준동사구를 나누면 복잡한 문장도 한 덩어리씩 읽을 수 있습니다.',
    ),
    _StudyTip(
      title: '제목은 전체를 덮어야 해요',
      body: '일부 문장에만 맞는 선택지보다 글 전체의 핵심 방향을 포함하는 표현을 고르세요.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await ApiService.fetchDashboard();
      if (!mounted) return;
      setState(() {
        _dashboard = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('learning lounge dashboard load error: $e');
      if (!mounted) return;
      setState(() {
        _dashboard = const {};
        _isLoading = false;
      });
    }
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  String _asText(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  String _dateText(dynamic value) {
    final raw = _asText(value);
    if (raw.isEmpty) return '날짜 기록 없음';
    final datePart = raw.split(' ').first.split('T').first;
    if (datePart.length >= 10) return datePart;
    return raw;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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

  @override
  Widget build(BuildContext context) {
    final tip = _tips[DateTime.now().day % _tips.length];
    final recentResults = _asList(_dashboard?['recent_results'])
        .whereType<Map>()
        .take(2)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          '커뮤니티',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 112),
          children: [
            _heroCard(),
            const SizedBox(height: 16),
            _noticeCard(),
            const SizedBox(height: 16),
            _tipCard(tip),
            const SizedBox(height: 16),
            _recommendationCard(),
            const SizedBox(height: 16),
            _recentLearningCard(recentResults),
            const SizedBox(height: 16),
            _comingSoonCard(),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD8E8FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _blue.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.groups_2_rounded,
              color: _blue,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '학습 라운지',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  '오늘의 학습 안내와 복습 자료를 확인해 보세요. 실제 커뮤니티 기능은 다음 단계에서 연결됩니다.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13.5,
                    height: 1.45,
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

  Widget _noticeCard() {
    const notices = [
      _NoticeItem(
        icon: Icons.edit_note_rounded,
        title: 'Final Touch 복습 안내',
        body: '저장된 분석 자료와 문장 조립 연습으로 핵심 내용을 다시 확인해 보세요.',
        color: _violet,
      ),
      _NoticeItem(
        icon: Icons.assignment_turned_in_rounded,
        title: '모의고사 학습 안내',
        body: '모의고사를 완료하면 점수, 오답, 약점 유형을 결과 화면에서 확인할 수 있어요.',
        color: _blue,
      ),
      _NoticeItem(
        icon: Icons.fact_check_rounded,
        title: '오답 다시보기 안내',
        body: '틀린 문제는 정답만 확인하지 말고 해설과 유형까지 함께 복습해 보세요.',
        color: _mint,
      ),
    ];

    return _LoungeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.campaign_rounded,
            title: '학습 안내',
            subtitle: '지금 사용할 수 있는 학습 기능을 정리했어요.',
            color: _blue,
          ),
          const SizedBox(height: 14),
          ...notices.map((notice) => _NoticeTile(item: notice)),
        ],
      ),
    );
  }

  Widget _tipCard(_StudyTip tip) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘의 학습 팁',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  tip.title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tip.body,
                  style: const TextStyle(
                    color: Color(0xFF78350F),
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendationCard() {
    final actions = [
      _LoungeAction(
        icon: Icons.edit_note_rounded,
        title: 'Final Touch 복습',
        subtitle: '분석 자료와 핵심 문장',
        color: _violet,
        onTap: _openFinalTouch,
      ),
      _LoungeAction(
        icon: Icons.assignment_rounded,
        title: '모의고사 풀기',
        subtitle: '20문항 실전 연습',
        color: _blue,
        onTap: _openMockExam,
      ),
      _LoungeAction(
        icon: Icons.replay_circle_filled_rounded,
        title: '오답 다시보기',
        subtitle: '틀린 문제 복습',
        color: const Color(0xFFEA580C),
        onTap: _openResults,
      ),
      _LoungeAction(
        icon: Icons.insights_rounded,
        title: '학습 리포트',
        subtitle: '점수와 약점 확인',
        color: _mint,
        onTap: _openResults,
      ),
    ];

    return _LoungeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.auto_awesome_rounded,
            title: '추천 학습',
            subtitle: '라운지에서 바로 복습 화면으로 이동할 수 있어요.',
            color: _violet,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720
                  ? 4
                  : constraints.maxWidth >= 420
                      ? 2
                      : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: columns == 1 ? 3.2 : 1.5,
                ),
                itemBuilder: (context, index) {
                  return _LoungeActionCard(action: actions[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _recentLearningCard(List<Map<String, dynamic>> recentResults) {
    return _LoungeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.history_rounded,
            title: '최근 학습',
            subtitle: '최근 완료한 학습이 있으면 이곳에서 다시 확인합니다.',
            color: _mint,
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(),
              ),
            )
          else if (recentResults.isEmpty)
            const _EmptyState(
              icon: Icons.auto_graph_rounded,
              message:
                  '아직 최근 학습 자료가 없습니다.\nFinal Touch 복습이나 모의고사를 완료하면 이곳에 표시됩니다.',
            )
          else
            ...recentResults.map(
              (item) => _RecentStudyTile(
                score: _asInt(item['score']),
                correctCount: _asInt(item['correct_count']),
                totalQuestions: _asInt(item['total_questions']),
                dateText: _dateText(item['created_at']),
              ),
            ),
        ],
      ),
    );
  }

  Widget _comingSoonCard() {
    const labels = ['학습 질문', '자료 공유', '공지', '댓글'];

    return _LoungeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.construction_rounded,
            title: '준비 중 기능',
            subtitle: '더 다양한 학습 소통 기능을 준비하고 있습니다.',
            color: _muted,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: labels
                .map(
                  (label) => InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _showSnack('$label 기능은 준비 중입니다.'),
                    child: _ComingSoonChip(label),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _LoungeCard extends StatelessWidget {
  const _LoungeCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _StudentLearningLoungeScreenState._line),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
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
                  color: _StudentLearningLoungeScreenState._ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _StudentLearningLoungeScreenState._muted,
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

class _NoticeItem {
  const _NoticeItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({required this.item});

  final _NoticeItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '학습 안내',
                    style: TextStyle(
                      color: item.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  item.title,
                  style: const TextStyle(
                    color: _StudentLearningLoungeScreenState._ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: const TextStyle(
                    color: _StudentLearningLoungeScreenState._muted,
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
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

class _StudyTip {
  const _StudyTip({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

class _LoungeAction {
  const _LoungeAction({
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

class _LoungeActionCard extends StatelessWidget {
  const _LoungeActionCard({required this.action});

  final _LoungeAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5EAF3)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _StudentLearningLoungeScreenState._ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      action.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _StudentLearningLoungeScreenState._muted,
                        fontSize: 11.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: action.color,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentStudyTile extends StatelessWidget {
  const _RecentStudyTile({
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.dateText,
  });

  final int? score;
  final int? correctCount;
  final int? totalQuestions;
  final String dateText;

  @override
  Widget build(BuildContext context) {
    final answerText = correctCount != null && totalQuestions != null
        ? '$correctCount / $totalQuestions'
        : '정답 기록 없음';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF3)),
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
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '최근 내신 문제세트',
                  style: TextStyle(
                    color: _StudentLearningLoungeScreenState._ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${score ?? '-'}점 · $answerText · $dateText',
                  style: const TextStyle(
                    color: _StudentLearningLoungeScreenState._muted,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF94A3B8),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _StudentLearningLoungeScreenState._muted,
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

class _ComingSoonChip extends StatelessWidget {
  const _ComingSoonChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _StudentLearningLoungeScreenState._line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '준비 중',
            style: TextStyle(
              color: _StudentLearningLoungeScreenState._blue,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _StudentLearningLoungeScreenState._muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
