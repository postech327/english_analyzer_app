import 'package:flutter/material.dart';
import '../models/study_report.dart';
import '../services/study_report_api.dart';

class StudyReportScreen extends StatefulWidget {
  final int userId;

  const StudyReportScreen({
    super.key,
    required this.userId,
  });

  @override
  State<StudyReportScreen> createState() => _StudyReportScreenState();
}

class _StudyReportScreenState extends State<StudyReportScreen> {
  bool _loading = true;
  String? _error;
  List<StudyReport> _reports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await StudyReportApi.fetchReports(widget.userId);
      if (!mounted) return;
      setState(() => _reports = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EDF6),
      appBar: AppBar(
        title: const Text('학습 리포트'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                )
              : _reports.isEmpty
                  ? const Center(child: Text('학습 기록이 없습니다.'))
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (final r in _reports) _reportCard(r),
                      ],
                    ),
    );
  }

  Widget _reportCard(StudyReport r) {
    final progress = r.accuracy / 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏷 유형
            Text(
              r.errorType.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),

            // 📊 정확도 그래프
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              color: progress >= 0.8
                  ? Colors.green
                  : progress >= 0.5
                      ? Colors.orange
                      : Colors.red,
            ),

            const SizedBox(height: 8),

            // 📈 수치
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('시도: ${r.totalAttempts}'),
                Text('오답: ${r.totalIncorrect}'),
                Text(
                  '${r.accuracy.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
