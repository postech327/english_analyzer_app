import 'package:english_analyzer_app/screens/final_touch_list_screen.dart';
import 'package:english_analyzer_app/services/student_exam_service.dart';
import 'package:flutter/material.dart';

class StudentExamResultScreen extends StatefulWidget {
  final int problemSetId;
  final int totalQuestions;
  final int correctAnswers;

  const StudentExamResultScreen({
    super.key,
    required this.problemSetId,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  @override
  State<StudentExamResultScreen> createState() =>
      _StudentExamResultScreenState();
}

class _StudentExamResultScreenState extends State<StudentExamResultScreen> {
  static const _blue = Color(0xFF2563EB);
  static const _sky = Color(0xFFEFF6FF);
  static const _surface = Color(0xFFF4F7FB);
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);

  late Future<Map<String, dynamic>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = StudentExamService.fetchResultSummary(widget.problemSetId);
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  List<dynamic> _asList(dynamic value) {
    return value is List ? value : const [];
  }

  Map<String, dynamic> _fallbackSummary() {
    final total = widget.totalQuestions < 0 ? 0 : widget.totalQuestions;
    final correct = widget.correctAnswers < 0 ? 0 : widget.correctAnswers;
    final score = total == 0 ? 0 : ((correct / total) * 100).round();
    return {
      'problem_set_id': widget.problemSetId,
      'my_score': score,
      'total_questions': total,
      'correct_count': correct,
      'incorrect_count': total - correct,
      'participant_count': 1,
      'average_score': score,
      'rank_percentile': 0,
      'above_average': 0,
      'type_results': const [],
      'weak_types': const [],
      'recommendation': '통계가 준비되면 유형별 약점을 함께 표시합니다.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _ink,
        elevation: 0,
        title: const Text(
          '시험 결과',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final hasError = snapshot.hasError;
          final summary = snapshot.data ?? _fallbackSummary();

          return _buildContent(
            context,
            summary,
            note: hasError ? '통계 API를 불러오지 못해 제출 결과만 표시합니다.' : null,
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, dynamic> summary, {
    String? note,
  }) {
    final total = _asInt(summary['total_questions'], widget.totalQuestions);
    final correct = _asInt(summary['correct_count'], widget.correctAnswers);
    final score = _asInt(
      summary['my_score'],
      total == 0 ? 0 : ((correct / total) * 100).round(),
    );
    final incorrect = _asInt(
      summary['incorrect_count'],
      (total - correct).clamp(0, total),
    );
    final participants = _asInt(summary['participant_count'], 1);
    final average = _asInt(summary['average_score'], score);
    final aboveAverage = _asInt(summary['above_average'], score - average);
    final rankPercentile = _asInt(summary['rank_percentile']);
    final finalTouchId = _asNullableInt(
      summary['final_touch_id'] ?? summary['analysis_record_id'],
    );
    final typeResults = _asList(summary['type_results']);
    final wrongQuestions = _asList(summary['wrong_questions']);
    final weakTypes = _asList(
      summary['weak_types'],
    ).map((item) => item.toString()).toList();
    final recommendation = summary['recommendation']?.toString() ??
        (weakTypes.isEmpty
            ? '잘했습니다. 같은 단원의 다른 문제세트로 확장해 보세요.'
            : '${weakTypes.take(2).join(', ')} 유형을 다시 풀어보세요.');

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (note != null) ...[
            _noticeCard(note),
            const SizedBox(height: 12),
          ],
          _scoreHero(score, correct, total),
          const SizedBox(height: 14),
          _statsCard(
            participants: participants,
            average: average,
            score: score,
            aboveAverage: aboveAverage,
            rankPercentile: rankPercentile,
          ),
          const SizedBox(height: 14),
          _typeResultCard(typeResults),
          const SizedBox(height: 14),
          _weakCard(weakTypes, recommendation, incorrect),
          const SizedBox(height: 20),
          _actionButtons(context, wrongQuestions, finalTouchId),
        ],
      ),
    );
  }

  Widget _scoreHero(int score, int correct, int total) {
    final progress = total == 0 ? 0.0 : (correct / total).clamp(0.0, 1.0);

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
            color: _blue.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '나의 점수',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 54,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  '점 / 100점',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.24),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$total문항 중 $correct문항 정답',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsCard({
    required int participants,
    required int average,
    required int score,
    required int aboveAverage,
    required int rankPercentile,
  }) {
    final diffText = aboveAverage >= 0 ? '+$aboveAverage점' : '$aboveAverage점';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('응시 통계', Icons.bar_chart_rounded),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _statPill('응시자', '$participants명'),
              _statPill('평균', '$average점'),
              _statPill('내 점수', '$score점'),
              _statPill('평균 대비', diffText),
              _statPill('내 위치', '상위 $rankPercentile%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeResultCard(List<dynamic> typeResults) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('유형별 결과', Icons.fact_check_rounded),
          const SizedBox(height: 14),
          if (typeResults.isEmpty)
            const Text(
              '유형별 결과는 다음 제출부터 표시됩니다.',
              style: TextStyle(color: _muted, fontWeight: FontWeight.w600),
            )
          else
            Column(
              children: typeResults.map((item) {
                final data = item is Map ? item : const {};
                final label = data['label']?.toString() ?? '문제';
                final correct = data['correct'] == true;
                final correctCount = _asInt(data['correct_count']);
                final total = _asInt(data['total']);
                return _typeRow(
                  label: label,
                  correct: correct,
                  detail: total > 1 ? '$correctCount/$total' : null,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _weakCard(
    List<String> weakTypes,
    String recommendation,
    int incorrect,
  ) {
    final title = weakTypes.isEmpty ? '약점 유형 없음' : weakTypes.join(', ');

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('약점 분석', Icons.lightbulb_rounded),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: weakTypes.isEmpty ? const Color(0xFFF0FDF4) : _sky,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: weakTypes.isEmpty
                    ? const Color(0xFFBBF7D0)
                    : const Color(0xFFBFDBFE),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '약점 유형: $title',
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  incorrect == 0 ? '모든 문제를 맞혔습니다.' : recommendation,
                  style: const TextStyle(
                    color: _muted,
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

  Widget _actionButtons(
    BuildContext context,
    List<dynamic> wrongQuestions,
    int? finalTouchId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () {
            _showWrongAnswers(context, wrongQuestions);
          },
          icon: const Icon(Icons.replay_rounded),
          label: const Text('오답 다시보기'),
          style: FilledButton.styleFrom(
            backgroundColor: _blue,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            _openFinalTouch(context, finalTouchId);
          },
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Final Touch 다시 보기'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _blue,
            side: const BorderSide(color: Color(0xFFBFDBFE)),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/student_exam_list');
            }
          },
          icon: const Icon(Icons.list_alt_rounded),
          label: const Text('시험 목록으로 돌아가기'),
          style: TextButton.styleFrom(
            foregroundColor: _muted,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  void _openFinalTouch(BuildContext context, int? finalTouchId) {
    if (finalTouchId == null || finalTouchId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연결된 Final Touch를 찾지 못해 목록으로 이동합니다.')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FinalTouchListScreen()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinalTouchDetailScreen(id: finalTouchId),
      ),
    );
  }

  void _showWrongAnswers(BuildContext context, List<dynamic> wrongQuestions) {
    if (wrongQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('틀린 문제가 없습니다.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.78,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            builder: (context, controller) {
              return ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '오답 다시보기',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...wrongQuestions.map(_wrongQuestionTile),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _wrongQuestionTile(dynamic item) {
    final data = item is Map ? item : const {};
    final order = _asInt(data['order']);
    final label = data['label']?.toString() ?? '문제';
    final question = data['question_text']?.toString() ?? '';
    final selected = data['selected_text']?.toString() ?? '선택 없음';
    final correct = data['correct_text']?.toString() ?? '정답 정보 없음';
    final explanation = data['explanation']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '문제 $order · $label',
            style: const TextStyle(
              color: _blue,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: const TextStyle(
              color: _ink,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _answerLine('내 답', selected, const Color(0xFFEF4444)),
          const SizedBox(height: 6),
          _answerLine('정답', correct, const Color(0xFF16A34A)),
          if (explanation != null && explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              explanation,
              style: const TextStyle(
                color: _muted,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _answerLine(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _ink,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _noticeCard(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF92400E),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
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

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _sky,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _blue, size: 19),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _statPill(String label, String value) {
    return Container(
      width: 132,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeRow({
    required String label,
    required bool correct,
    String? detail,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: correct ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: correct ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (detail != null) ...[
            Text(
              detail,
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  correct ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
            child: Text(
              correct ? 'O' : 'X',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
