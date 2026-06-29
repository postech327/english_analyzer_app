import 'package:flutter/material.dart';

import '../../models/problem_set_result_summary.dart';
import '../../services/problem_set_result_api.dart';
import 'student_exam_list_screen.dart';
import 'student_exam_result_screen.dart';

class ProblemSetResultsScreen extends StatefulWidget {
  const ProblemSetResultsScreen({super.key});

  @override
  State<ProblemSetResultsScreen> createState() =>
      _ProblemSetResultsScreenState();
}

class _ProblemSetResultsScreenState extends State<ProblemSetResultsScreen> {
  static const _surface = Color(0xFFF6F8FC);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _blue = Color(0xFF2563EB);
  static const _purple = Color(0xFF7C3AED);
  static const _sky = Color(0xFFEFF6FF);
  static const _line = Color(0xFFE5E7EB);

  late Future<List<ProblemSetResultSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = ProblemSetResultApi.fetchResults();
  }

  void _reload() {
    setState(() => _future = ProblemSetResultApi.fetchResults());
  }

  void _openResult(ProblemSetResultSummary item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentExamResultScreen(
          problemSetId: item.problemSetId,
          totalQuestions: item.totalCount,
          correctAnswers: item.correctCount,
        ),
      ),
    );
  }

  void _openStartExam() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentExamListScreen()),
    );
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
          'Problem Set Results',
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
      body: FutureBuilder<List<ProblemSetResultSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessagePanel(
              icon: Icons.error_outline_rounded,
              title: '결과를 불러오지 못했습니다.',
              message: snapshot.error.toString(),
              actionLabel: '다시 시도',
              onAction: _reload,
            );
          }

          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return _MessagePanel(
              icon: Icons.assignment_outlined,
              title: '아직 풀이한 내신 문제세트 결과가 없습니다.',
              message: 'Start Exam에서 문제를 먼저 풀어 보세요.',
              actionLabel: 'Start Exam으로 이동',
              onAction: _openStartExam,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
              children: [
                const Text(
                  '내신 10문제 세트 결과',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '지문 기반 문제세트의 점수와 오답을 한곳에서 확인합니다.',
                  style: TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ResultCard(
                      item: item,
                      onOpen: () => _openResult(item),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.item,
    required this.onOpen,
  });

  final ProblemSetResultSummary item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final weakTypes = item.weakTypes.isEmpty ? ['뚜렷한 약점 없음'] : item.weakTypes;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _ProblemSetResultsScreenState._line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _ProblemSetResultsScreenState._sky,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.fact_check_rounded,
                    color: _ProblemSetResultsScreenState._blue,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.problemSetName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ProblemSetResultsScreenState._ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                      if (item.source != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.source!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ProblemSetResultsScreenState._muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        '응시일 ${_formatDate(item.submittedAt)}',
                        style: const TextStyle(
                          color: _ProblemSetResultsScreenState._muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.score}점',
                      style: const TextStyle(
                        color: _ProblemSetResultsScreenState._blue,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.correctCount}/${item.totalCount}',
                      style: const TextStyle(
                        color: _ProblemSetResultsScreenState._muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: item.accuracy,
                minHeight: 8,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  _ProblemSetResultsScreenState._blue,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: weakTypes
                  .take(4)
                  .map(
                    (label) => _WeakChip(
                      label: label,
                      empty: item.weakTypes.isEmpty,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.rate_review_rounded, size: 18),
                label: const Text('오답 다시보기'),
                style: FilledButton.styleFrom(
                  backgroundColor: _ProblemSetResultsScreenState._purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '-';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value.split('T').first;
    final local = parsed.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$month.$day $hour:$minute';
  }
}

class _WeakChip extends StatelessWidget {
  const _WeakChip({
    required this.label,
    required this.empty,
  });

  final String label;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final color =
        empty ? const Color(0xFF16A34A) : _ProblemSetResultsScreenState._purple;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
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
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _ProblemSetResultsScreenState._line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _ProblemSetResultsScreenState._sky,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: _ProblemSetResultsScreenState._blue,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ProblemSetResultsScreenState._ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ProblemSetResultsScreenState._muted,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: _ProblemSetResultsScreenState._blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
