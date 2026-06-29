// lib/screens/exam_result_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:english_analyzer_app/models/exam_summary.dart';
import 'package:english_analyzer_app/services/student_exam_api.dart';

class ExamResultSummaryScreen extends StatefulWidget {
  final int problemSetId;
  final int userId;

  const ExamResultSummaryScreen({
    super.key,
    required this.problemSetId,
    required this.userId,
  });

  @override
  State<ExamResultSummaryScreen> createState() =>
      _ExamResultSummaryScreenState();
}

class _ExamResultSummaryScreenState extends State<ExamResultSummaryScreen> {
  bool _loading = true;
  String? _error;
  ExamSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final ExamSummary data = await StudentExamApi.fetchExamSummary(
        problemSetId: widget.problemSetId,
      );

      if (!mounted) return;

      setState(() {
        _summary = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _accuracyColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }

  double _safeAccuracyRate(double rate) {
    if (rate.isNaN || rate.isInfinite) return 0;
    if (rate < 0) return 0;
    if (rate > 100) return 100;
    return rate;
  }

  int _inferTotalQuestions(ExamSummary s) {
    final int correct = s.correctCount;
    final int serverIncorrect = s.incorrectCount;
    final double rate = _safeAccuracyRate(s.accuracyRate);

    // 서버가 오답 수를 정상으로 주는 경우
    final int serverTotal = correct + serverIncorrect;

    // 정확도가 있고, 정답 수가 있으면 정확도로 전체 문항 수 추정
    // 예: correct 2, accuracyRate 20% → total 10
    if (rate > 0 && correct > 0) {
      final int inferredTotal = (correct / (rate / 100)).round();

      if (inferredTotal >= correct) {
        return inferredTotal;
      }
    }

    // 정확도가 100이고 정답 수가 있으면 전체 문항 수 = 정답 수
    if (rate == 100 && correct > 0) {
      return correct;
    }

    // 서버에서 정답 + 오답 합계가 있으면 그것을 사용
    if (serverTotal > 0) {
      return serverTotal;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('시험 결과 요약'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : _summary == null
                  ? const Center(child: Text('시험 결과가 없습니다.'))
                  : _buildBody(),
    );
  }

  Widget _buildBody() {
    final ExamSummary s = _summary!;

    final double accuracyRate = _safeAccuracyRate(s.accuracyRate);
    final Color color = _accuracyColor(accuracyRate);

    final int correctCount = s.correctCount;
    final int totalQuestions = _inferTotalQuestions(s);

    final int incorrectCount =
        totalQuestions - correctCount < 0 ? 0 : totalQuestions - correctCount;

    final String accuracyText = accuracyRate % 1 == 0
        ? accuracyRate.toInt().toString()
        : accuracyRate.toStringAsFixed(1);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        /// 🟦 시험 요약 카드
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  s.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$accuracyText%',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$correctCount / $totalQuestions 문제 정답',
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                _summaryRow(
                  icon: Icons.list_alt,
                  label: '전체 문항',
                  value: totalQuestions,
                  color: Colors.black87,
                ),
                const SizedBox(height: 10),
                _summaryRow(
                  icon: Icons.check_circle_outline,
                  label: '정답 수',
                  value: correctCount,
                  color: Colors.green,
                ),
                const SizedBox(height: 10),
                _summaryRow(
                  icon: Icons.cancel_outlined,
                  label: '오답 수',
                  value: incorrectCount,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        /// 🎯 정확도 시각화
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: accuracyRate / 100,
                  minHeight: 10,
                  color: color,
                  backgroundColor: Colors.grey.shade300,
                ),
                const SizedBox(height: 10),
                const Text(
                  '정확도',
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        /// ⚠️ 약점 유형
        const Text(
          '취약 유형',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        if (s.weakTypes.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('취약 유형이 없습니다. 👍'),
            ),
          )
        else
          ...s.weakTypes.map(
            (e) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                ),
                title: Text(e[0].toString()),
                trailing: Text('${e[1]}회'),
              ),
            ),
          ),

        const SizedBox(height: 30),

        /// 🔘 액션 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('오답 다시 풀기'),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/student/retry',
                arguments: {
                  'problemSetId': widget.problemSetId,
                  'userId': widget.userId,
                },
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.menu_book),
            label: const Text('개념 학습'),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/student/concepts',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _summaryRow({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
