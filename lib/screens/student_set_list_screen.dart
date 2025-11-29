// lib/screens/student_set_list_screen.dart
import 'package:flutter/material.dart';

import '../services/student_api.dart';
import '../models/student_models.dart';
import 'student_quiz_screen.dart'; // 기존 퀴즈 화면 import (경로는 프로젝트 구조에 맞게)

class StudentSetListScreen extends StatefulWidget {
  const StudentSetListScreen({super.key});

  @override
  State<StudentSetListScreen> createState() => _StudentSetListScreenState();
}

class _StudentSetListScreenState extends State<StudentSetListScreen> {
  String _selectedType = 'all'; // 전체 기본
  bool _isLoading = false;
  String? _error;
  List<StudentProblemSetSummary> _sets = [];

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final type = _selectedType; // 'all' 이면 API에서 필터 안 걸리게 됨
      final data = await StudentApi.fetchProblemSets(
        questionType: type,
      );
      setState(() {
        _sets = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학생 모드 - 문제 세트 선택'),
      ),
      body: Column(
        children: [
          // ───── 상단 유형 필터 드롭다운 ─────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('유형: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedType,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('전체')),
                    DropdownMenuItem(value: 'topic', child: Text('주제')),
                    DropdownMenuItem(value: 'title', child: Text('제목')),
                    DropdownMenuItem(value: 'gist', child: Text('요지')),
                    DropdownMenuItem(value: 'summary', child: Text('요약')),
                    DropdownMenuItem(value: 'cloze', child: Text('빈칸')),
                    DropdownMenuItem(value: 'insertion', child: Text('삽입')),
                    DropdownMenuItem(value: 'order', child: Text('순서')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedType = value);
                    _loadSets();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ───── 세트 리스트 영역 ─────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          '오류: $_error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : _sets.isEmpty
                        ? const Center(child: Text('해당 유형의 문제 세트가 없습니다.'))
                        : ListView.builder(
                            itemCount: _sets.length,
                            itemBuilder: (context, index) {
                              final ps = _sets[index];
                              return ListTile(
                                title: Text(ps.title),
                                subtitle: Text(
                                  '${_korLabel(ps.questionType)} · 문제 ${ps.numQuestions}개',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StudentQuizScreen(
                                        problemSetId: ps.id,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  String _korLabel(String type) {
    switch (type) {
      case 'topic':
        return '주제';
      case 'title':
        return '제목';
      case 'gist':
        return '요지';
      case 'summary':
        return '요약';
      case 'cloze':
        return '빈칸';
      case 'insertion':
        return '삽입';
      case 'order':
        return '순서';
      default:
        return type;
    }
  }
}
