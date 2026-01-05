import 'package:flutter/material.dart';

import '../../services/admin_exam_service.dart';
import '../teacher/teacher_problem_set_preview_screen.dart';

class AdminExamAutoGenerateScreen extends StatefulWidget {
  const AdminExamAutoGenerateScreen({super.key});

  @override
  State<AdminExamAutoGenerateScreen> createState() =>
      _AdminExamAutoGenerateScreenState();
}

class _AdminExamAutoGenerateScreenState
    extends State<AdminExamAutoGenerateScreen> {
  final _titleCtrl = TextEditingController(text: '자동 생성 시험지');

  int _questionCount = 20;
  double easy = 0.2;
  double medium = 0.3;
  double hard = 0.5;

  bool _loading = false;

  double get total => easy + medium + hard;

  void _normalize() {
    final sum = total;
    if (sum == 0) return;
    easy /= sum;
    medium /= sum;
    hard /= sum;
  }

  Future<void> _generate() async {
    if (total == 0) return;

    _normalize();

    setState(() => _loading = true);

    try {
      final id = await AdminExamService.autoGenerateExam(
        title: _titleCtrl.text.trim(),
        questionCount: _questionCount,
        distribution: {
          'easy': easy,
          'medium': medium,
          'hard': hard,
        },
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherProblemSetPreviewScreen(problemSetId: id),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _slider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label ${(value * 100).toStringAsFixed(0)}%'),
        Slider(
          value: value,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('시험지 자동 생성')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: '시험지 제목'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _questionCount,
              items: const [
                DropdownMenuItem(value: 10, child: Text('10문제')),
                DropdownMenuItem(value: 20, child: Text('20문제')),
                DropdownMenuItem(value: 30, child: Text('30문제')),
              ],
              onChanged: (v) => setState(() => _questionCount = v!),
              decoration: const InputDecoration(labelText: '문제 수'),
            ),
            const SizedBox(height: 24),
            _slider('Easy', easy, (v) => setState(() => easy = v)),
            _slider('Medium', medium, (v) => setState(() => medium = v)),
            _slider('Hard', hard, (v) => setState(() => hard = v)),
            const Spacer(),
            FilledButton(
              onPressed: _loading ? null : _generate,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('자동 시험지 생성'),
            ),
          ],
        ),
      ),
    );
  }
}
