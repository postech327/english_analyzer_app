// lib/screens/teacher_problem_sets_screen.dart
import 'package:flutter/material.dart';

import '../models/student_models.dart';
import '../services/student_api.dart';
import 'student_quiz_screen.dart';

class TeacherProblemSetsScreen extends StatefulWidget {
  const TeacherProblemSetsScreen({super.key});

  @override
  State<TeacherProblemSetsScreen> createState() =>
      _TeacherProblemSetsScreenState();
}

class _TeacherProblemSetsScreenState extends State<TeacherProblemSetsScreen> {
  bool _loading = false;
  String? _error;
  List<StudentProblemSetSummary> _items = [];
  String _selectedType = 'all';

  final Map<String, String> _typeLabel = const {
    'all': '전체',
    'topic': '주제',
    'title': '제목',
    'gist': '요지',
    'summary': '요약',
    'cloze': '빈칸',
    'insertion': '삽입',
    'order': '순서',
  };

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final qType = _selectedType == 'all' ? null : _selectedType;
      final list = await StudentApi.fetchProblemSets(
        questionType: qType,
      );
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '문제 세트 로드 실패: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('저장된 문제 세트 목록'),
      ),
      backgroundColor: cs.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 유형 필터
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text('유형: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedType,
                  items: _typeLabel.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _selectedType = v;
                    });
                    _loadSets();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _buildListBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildListBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('현재 저장된 문제 세트가 없습니다.'),
      );
    }

    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _items[index];
        final typeLabel = _typeLabel[item.questionType] ?? item.questionType;

        return ListTile(
          title: Text(item.title),
          subtitle: Text('$typeLabel · 문제 ${item.numQuestions}개'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentQuizScreen(
                  problemSetId: item.id,
                  questionType: item.questionType,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
