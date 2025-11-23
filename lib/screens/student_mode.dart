// lib/screens/student_mode.dart
import 'package:flutter/material.dart';

import 'student_quiz_screen.dart';

class StudentModePage extends StatefulWidget {
  const StudentModePage({super.key});

  @override
  State<StudentModePage> createState() => _StudentModePageState();
}

class _StudentModePageState extends State<StudentModePage> {
  final TextEditingController _idController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  void _startQuiz() {
    final text = _idController.text.trim();
    if (text.isEmpty) return;

    final id = int.tryParse(text);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('숫자로 된 problem_set_id 를 입력해 주세요.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentQuizScreen(
          problemSetId: id,
          questionType: null, // null이면 모든 유형
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('학생 모드'),
      ),
      backgroundColor: cs.surface,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '학생 모드: 저장된 지문 + 문제 세트를 불러와서 퀴즈를 풉니다.\n'
              '아래에 problem_set_id 를 입력한 뒤 퀴즈 시작 버튼을 눌러 주세요.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _idController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'problem_set_id',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _startQuiz,
              icon: const Icon(Icons.play_arrow),
              label: const Text('이 ID로 퀴즈 시작하기'),
            ),
            const SizedBox(height: 12),
            const Text(
              '※ 현재는 테스트용으로 ID를 직접 입력하는 방식입니다.\n'
              ' 나중에 선생님 모드에서 저장한 ID를 자동으로 넘겨줄 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
