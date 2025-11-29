// lib/screens/student_mode.dart
import 'package:flutter/material.dart';

import 'student_quiz_screen.dart';
import 'student_set_list_screen.dart'; // 🔹 새로 추가: 세트 목록 화면

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

  /// 🔹 기존 방식: problem_set_id 를 직접 입력해서 퀴즈 시작
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

  /// 🔹 새 방식: 문제 세트 목록에서 선택해서 시작
  void _openSetList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StudentSetListScreen(),
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
              '아래에서 문제 세트를 선택하거나, problem_set_id 를 직접 입력할 수 있습니다.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // ───── 문제 세트 목록에서 선택하기 버튼 ─────
            ElevatedButton.icon(
              onPressed: _openSetList,
              icon: const Icon(Icons.list),
              label: const Text('문제 세트 목록에서 선택하기'),
            ),

            const SizedBox(height: 24),

            // ───── 기존: ID 직접 입력해서 시작하는 방식 ─────
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
              '※ 현재는 테스트용으로 ID를 직접 입력하는 방식도 남겨 두었습니다.\n'
              '   위의 [문제 세트 목록에서 선택하기] 버튼을 통해\n'
              '   유형별로 정리된 세트 중 하나를 골라 풀 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
