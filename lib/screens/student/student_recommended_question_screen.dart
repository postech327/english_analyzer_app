// lib/screens/student_recommended_question_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api.dart';

class StudentRecommendedQuestionScreen extends StatefulWidget {
  final int userId;

  const StudentRecommendedQuestionScreen({
    super.key,
    required this.userId,
  });

  @override
  State<StudentRecommendedQuestionScreen> createState() =>
      _StudentRecommendedQuestionScreenState();
}

class _StudentRecommendedQuestionScreenState
    extends State<StudentRecommendedQuestionScreen> {
  List<dynamic> questions = [];
  List<int> selectedQuestionIds = [];

  @override
  void initState() {
    super.initState();
    fetchRecommendedQuestions();
  }

  // 🔹 추천 문제 가져오기
  Future<void> fetchRecommendedQuestions() async {
    final response = await http.get(
      ApiConfig.u('/recommend').replace(
        queryParameters: {'user_id': '${widget.userId}'},
      ),
    );

    if (response.statusCode == 200) {
      setState(() {
        questions = jsonDecode(response.body);
      });
    } else {
      print("추천 문제 로딩 실패");
    }
  }

  // 🔹 시험 생성
  Future<void> createExam() async {
    if (selectedQuestionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("문제를 선택해주세요")),
      );
      return;
    }

    final response = await http.post(
      ApiConfig.u('/exam/create'),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "question_ids": selectedQuestionIds,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final examId = data['exam_id'];

      // 🔥 시험 화면 이동
      Navigator.pushNamed(
        context,
        '/exam',
        arguments: examId,
      );
    } else {
      print("시험 생성 실패");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Recommended Practice',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: questions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final q = questions[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: CheckboxListTile(
                          value: selectedQuestionIds.contains(q['id']),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedQuestionIds.add(q['id']);
                              } else {
                                selectedQuestionIds.remove(q['id']);
                              }
                            });
                          },
                          title: Text(q['question_text'] ?? '문제'),
                        ),
                      );
                    },
                  ),
          ),

          // 🔥 시험 시작 버튼
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: createExam,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("시험 시작"),
            ),
          ),
        ],
      ),
    );
  }
}
