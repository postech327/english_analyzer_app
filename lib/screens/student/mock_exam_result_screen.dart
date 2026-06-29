import 'package:flutter/material.dart';

import '../../models/mock_exam_result_report.dart';
import '../../utils/mock_exam_pdf_generator.dart';
import 'mock_exam_attempt_detail_screen.dart';
import 'mock_exam_list_screen.dart';
import 'mock_exam_report_screen.dart';

class MockExamResultScreen extends StatelessWidget {
  const MockExamResultScreen({
    super.key,
    required this.title,
    required this.result,
  });

  final String title;
  final Map<String, dynamic> result;

  static const _surface = Color(0xFFF6F8FC);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _blue = Color(0xFF2563EB);
  static const _sky = Color(0xFFEFF6FF);
  static const _line = Color(0xFFE5E7EB);
  static const _green = Color(0xFF16A34A);
  static const _red = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final report =
        MockExamResultReport.fromSubmit(title: title, result: result);

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '모의고사 결과지',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            _ReportHeader(report: report),
            const SizedBox(height: 14),
            _ScoreCard(report: report),
            const SizedBox(height: 14),
            _TypeSummaryCard(report: report),
            const SizedBox(height: 14),
            _WeakAndRecommendCard(report: report),
            const SizedBox(height: 14),
            _QuestionSummaryCard(report: report),
            const SizedBox(height: 18),
            _ActionButtons(report: report),
          ],
        ),
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.report});

  final MockExamResultReport report;

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: MockExamResultScreen._sky,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.assignment_turned_in_rounded,
              color: MockExamResultScreen._blue,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mock Exam Result',
                  style: TextStyle(
                    color: MockExamResultScreen._blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  report.examTitle,
                  style: const TextStyle(
                    color: MockExamResultScreen._ink,
                    fontSize: 20,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '응시일 ${_formatDateTime(report.submittedAt)}',
                  style: const TextStyle(
                    color: MockExamResultScreen._muted,
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

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.report});

  final MockExamResultReport report;

  @override
  Widget build(BuildContext context) {
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
            color: MockExamResultScreen._blue.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '점수',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${report.score}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 58,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 9),
                child: Text(
                  '점 / 100점',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (report.percent / 100).clamp(0, 1),
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.24),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${report.correctCount} / ${report.totalCount} 정답 · ${_score(report.percent)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Text(
              report.scoreComment,
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

class _TypeSummaryCard extends StatelessWidget {
  const _TypeSummaryCard({required this.report});

  final MockExamResultReport report;

  @override
  Widget build(BuildContext context) {
    final items = report.typeSummary.values.toList();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('유형별 분석', Icons.analytics_outlined),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const _EmptyText('유형별 결과가 없습니다.')
          else
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Row(
                  children: [
                    SizedBox(
                      width: 82,
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: MockExamResultScreen._ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (item.rate / 100).clamp(0, 1),
                          minHeight: 10,
                          color: item.rate >= 70
                              ? MockExamResultScreen._green
                              : MockExamResultScreen._blue,
                          backgroundColor: MockExamResultScreen._sky,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 68,
                      child: Text(
                        '${item.correct}/${item.total}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: MockExamResultScreen._muted,
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

class _WeakAndRecommendCard extends StatelessWidget {
  const _WeakAndRecommendCard({required this.report});

  final MockExamResultReport report;

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('약점 유형과 추천 학습', Icons.lightbulb_rounded),
          const SizedBox(height: 14),
          if (report.weakTypes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Text(
                '뚜렷한 약점 유형이 없습니다.',
                style: TextStyle(
                  color: MockExamResultScreen._ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  report.weakTypes.map((type) => _WeakChip(type)).toList(),
            ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MockExamResultScreen._sky,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Text(
              report.recommendation,
              style: const TextStyle(
                color: MockExamResultScreen._ink,
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

class _QuestionSummaryCard extends StatelessWidget {
  const _QuestionSummaryCard({required this.report});

  final MockExamResultReport report;

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('문항별 O/X 요약', Icons.grid_view_rounded),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: report.questionResults.map((item) {
              return Container(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: item.correct
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: item.correct
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFFECACA),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${item.number}',
                      style: const TextStyle(
                        color: MockExamResultScreen._ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.correct ? 'O' : 'X',
                      style: TextStyle(
                        color: item.correct
                            ? MockExamResultScreen._green
                            : MockExamResultScreen._red,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.report});

  final MockExamResultReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilledButton.icon(
          onPressed: report.attemptId <= 0
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentMockExamAttemptDetailScreen(
                        attemptId: report.attemptId,
                      ),
                    ),
                  );
                },
          icon: const Icon(Icons.rate_review_rounded),
          label: const Text('오답 다시보기'),
          style: FilledButton.styleFrom(
            backgroundColor: MockExamResultScreen._blue,
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StudentMockExamReportScreen(),
              ),
            );
          },
          icon: const Icon(Icons.stacked_bar_chart_rounded),
          label: const Text('나의 누적 리포트 보기'),
          style: OutlinedButton.styleFrom(
            foregroundColor: MockExamResultScreen._blue,
            minimumSize: const Size.fromHeight(50),
            side: const BorderSide(color: Color(0xFFBFDBFE)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () async {
            try {
              await MockExamPdfGenerator.previewOrPrint(report);
            } catch (_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF 생성 중 오류가 발생했습니다.')),
              );
            }
          },
          icon: const Icon(Icons.picture_as_pdf_rounded),
          label: const Text('PDF 출력'),
          style: OutlinedButton.styleFrom(
            foregroundColor: MockExamResultScreen._ink,
            minimumSize: const Size.fromHeight(50),
            side: const BorderSide(color: MockExamResultScreen._line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MockExamListScreen()),
              (route) => route.isFirst,
            );
          },
          icon: const Icon(Icons.list_alt_rounded),
          label: const Text('시험 목록으로 돌아가기'),
        ),
      ],
    );
  }
}

class _WeakChip extends StatelessWidget {
  const _WeakChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFC2410C),
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
    return Text(
      text,
      style: const TextStyle(
        color: MockExamResultScreen._muted,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

Widget _sectionTitle(String title, IconData icon) {
  return Row(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: MockExamResultScreen._sky,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: MockExamResultScreen._blue, size: 19),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: const TextStyle(
          color: MockExamResultScreen._ink,
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
      border: Border.all(color: MockExamResultScreen._line),
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

String _score(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

String _formatDateTime(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return '-';
  final local = parsed.toLocal();
  return '${local.year}.${local.month.toString().padLeft(2, '0')}.'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
