import 'package:flutter/material.dart';

import '../../models/integrated_report.dart';
import '../../services/integrated_report_api.dart';
import '../../utils/integrated_report_pdf_generator.dart';
import 'mock_exam_list_screen.dart';
import 'student_exam_list_screen.dart';

class IntegratedReportScreen extends StatefulWidget {
  const IntegratedReportScreen({super.key});

  @override
  State<IntegratedReportScreen> createState() => _IntegratedReportScreenState();
}

class _IntegratedReportScreenState extends State<IntegratedReportScreen> {
  static const _surface = Color(0xFFF6F8FC);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _blue = Color(0xFF2563EB);
  static const _purple = Color(0xFF7C3AED);
  static const _sky = Color(0xFFEFF6FF);
  static const _line = Color(0xFFE5E7EB);

  late Future<IntegratedReport> _future;
  IntegratedReport? _currentReport;
  bool _isPdfBusy = false;

  @override
  void initState() {
    super.initState();
    _future = _loadReport();
  }

  void _reload() {
    setState(() => _future = _loadReport());
  }

  Future<IntegratedReport> _loadReport() async {
    final report = await IntegratedReportApi.fetchIntegratedReport();
    if (mounted) {
      setState(() => _currentReport = report);
    } else {
      _currentReport = report;
    }
    return report;
  }

  Future<void> _printPdf() async {
    final report = _currentReport;
    if (report == null || _isPdfBusy) return;

    setState(() => _isPdfBusy = true);
    try {
      await IntegratedReportPdfGenerator.previewOrPrint(report);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('통합 리포트 PDF 생성 중 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _isPdfBusy = false);
    }
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
          '통합 학습 리포트',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'PDF 출력',
            onPressed: _isPdfBusy || _currentReport == null ? null : _printPdf,
            icon: _isPdfBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_rounded),
          ),
          IconButton(
            tooltip: '새로고침',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<IntegratedReport>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessagePanel(
              title: '통합 리포트를 불러오지 못했습니다.',
              message: snapshot.error.toString(),
              primaryLabel: '다시 시도',
              onPrimary: _reload,
            );
          }

          final report = snapshot.data;
          if (report == null || !report.hasAnyResult) {
            return _MessagePanel(
              title: '아직 충분한 학습 결과가 없습니다.',
              message: '내신 문제세트나 Mock Exam을 먼저 풀어 보세요.',
              primaryLabel: 'Start Exam',
              onPrimary: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentExamListScreen(),
                  ),
                );
              },
              secondaryLabel: 'Mock Exam',
              onSecondary: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MockExamListScreen(),
                  ),
                );
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                const Text(
                  '통합 학습 리포트',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '내신 대비와 모의고사 대비 결과를 함께 확인해 보세요.',
                  style: TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                _OverallSummary(report: report),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 760;
                    final children = [
                      _TrackSummaryCard(
                        title: '내신 대비',
                        accent: _purple,
                        attemptCount: report.problemSetAttemptCount,
                        averageScore: report.problemSetAverageScore,
                        latestScore: report.latestProblemSetScore,
                        weakTypes: report.problemSetWeakTypes,
                      ),
                      _TrackSummaryCard(
                        title: '모의고사 대비',
                        accent: _blue,
                        attemptCount: report.mockExamAttemptCount,
                        averageScore: report.mockExamAverageScore,
                        latestScore: report.latestMockExamScore,
                        weakTypes: report.mockExamWeakTypes,
                      ),
                    ];
                    if (!twoColumns) {
                      return Column(
                        children: [
                          children[0],
                          const SizedBox(height: 14),
                          children[1],
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: children[0]),
                        const SizedBox(width: 14),
                        Expanded(child: children[1]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                _CommonWeakCard(types: report.commonWeakTypes),
                const SizedBox(height: 14),
                _RecommendationCard(items: report.recommendations),
                const SizedBox(height: 14),
                _RecentResultsCard(
                  title: '최근 내신 결과',
                  items: report.recentProblemSetResults,
                  emptyMessage: '아직 풀이한 내신 문제세트가 없습니다.',
                ),
                const SizedBox(height: 14),
                _RecentResultsCard(
                  title: '최근 모의고사 결과',
                  items: report.recentMockExamResults,
                  emptyMessage: '아직 응시한 Mock Exam이 없습니다.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverallSummary extends StatelessWidget {
  const _OverallSummary({required this.report});

  final IntegratedReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _IntegratedReportScreenState._blue.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '전체 요약',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _score(report.overallAverageScore),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  '점 평균',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: '내신 응시',
                  value: '${report.problemSetAttemptCount}회',
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  label: '모의고사 응시',
                  value: '${report.mockExamAttemptCount}회',
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  label: '내신/Mock 평균',
                  value:
                      '${_score(report.problemSetAverageScore)} / ${_score(report.mockExamAverageScore)}',
                ),
              ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackSummaryCard extends StatelessWidget {
  const _TrackSummaryCard({
    required this.title,
    required this.accent,
    required this.attemptCount,
    required this.averageScore,
    required this.latestScore,
    required this.weakTypes,
  });

  final String title;
  final Color accent;
  final int attemptCount;
  final double averageScore;
  final int? latestScore;
  final List<String> weakTypes;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.insights_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _IntegratedReportScreenState._ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(label: '응시', value: '$attemptCount회'),
              ),
              Expanded(
                child:
                    _MiniMetric(label: '평균', value: '${_score(averageScore)}점'),
              ),
              Expanded(
                child: _MiniMetric(
                  label: '최근',
                  value: latestScore == null ? '-' : '$latestScore점',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ChipWrap(
            title: '약점 유형',
            items: weakTypes,
            emptyText: '뚜렷한 약점 없음',
            color: accent,
          ),
        ],
      ),
    );
  }
}

class _CommonWeakCard extends StatelessWidget {
  const _CommonWeakCard({required this.types});

  final List<String> types;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: _ChipWrap(
        title: '공통 약점',
        items: types,
        emptyText: '공통으로 반복되는 약점 유형은 아직 없습니다.',
        color: _IntegratedReportScreenState._purple,
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _IntegratedReportScreenState._sky,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: _IntegratedReportScreenState._blue,
              ),
              SizedBox(width: 8),
              Text(
                '추천 학습 방향',
                style: TextStyle(
                  color: _IntegratedReportScreenState._ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Icon(
                      Icons.circle,
                      size: 7,
                      color: _IntegratedReportScreenState._blue,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: _IntegratedReportScreenState._ink,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentResultsCard extends StatelessWidget {
  const _RecentResultsCard({
    required this.title,
    required this.items,
    required this.emptyMessage,
  });

  final String title;
  final List<RecentResultItem> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _IntegratedReportScreenState._ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              emptyMessage,
              style: const TextStyle(
                color: _IntegratedReportScreenState._muted,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...items.map((item) => _RecentResultTile(item: item)),
        ],
      ),
    );
  }
}

class _RecentResultTile extends StatelessWidget {
  const _RecentResultTile({required this.item});

  final RecentResultItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _IntegratedReportScreenState._line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _IntegratedReportScreenState._ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (item.source != null) item.source!,
                    _formatDate(item.submittedAt),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _IntegratedReportScreenState._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${item.score}점',
            style: const TextStyle(
              color: _IntegratedReportScreenState._blue,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.correctCount}/${item.totalCount}',
            style: const TextStyle(
              color: _IntegratedReportScreenState._muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _IntegratedReportScreenState._line),
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

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _IntegratedReportScreenState._muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _IntegratedReportScreenState._ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({
    required this.title,
    required this.items,
    required this.emptyText,
    required this.color,
  });

  final String title;
  final List<String> items;
  final String emptyText;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final displayItems = items.isEmpty ? [emptyText] : items;
    final isEmpty = items.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _IntegratedReportScreenState._muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: displayItems
              .map(
                (item) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: (isEmpty ? const Color(0xFF16A34A) : color)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      color: isEmpty ? const Color(0xFF16A34A) : color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: _ReportCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _IntegratedReportScreenState._sky,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.query_stats_rounded,
                  color: _IntegratedReportScreenState._blue,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _IntegratedReportScreenState._ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _IntegratedReportScreenState._muted,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onPrimary,
                      style: FilledButton.styleFrom(
                        backgroundColor: _IntegratedReportScreenState._blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        primaryLabel,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  if (secondaryLabel != null && onSecondary != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onSecondary,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _IntegratedReportScreenState._blue,
                          side: const BorderSide(
                            color: _IntegratedReportScreenState._line,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          secondaryLabel!,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _score(num value) {
  final score = value.toDouble();
  return score == score.roundToDouble()
      ? score.round().toString()
      : score.toStringAsFixed(1);
}

String _formatDate(String? value) {
  if (value == null || value.isEmpty) return '-';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value.split('T').first;
  final local = parsed.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$month.$day';
}
