// lib/screens/question_from_hub_screen.dart

import 'package:flutter/material.dart';
import '../services/question_api.dart';
import '../models/analyzer_models.dart';

class QuestionFromHubScreen extends StatefulWidget {
  final int hubId;
  final String passageText;
  final TextAnalysisHubResult hub;

  const QuestionFromHubScreen({
    super.key,
    required this.hubId,
    required this.passageText,
    required this.hub,
  });

  @override
  State<QuestionFromHubScreen> createState() => _QuestionFromHubScreenState();
}

class _QuestionFromHubScreenState extends State<QuestionFromHubScreen> {
  List questions = [];
  bool isLoading = false;

  /// 🔥 핵심: 문제 생성
  Future<void> fetchQuestions() async {
    setState(() {
      isLoading = true;
    });

    try {
      print("🔥 버튼 클릭됨 (Hub)");
      print("🔥 지문 길이: ${widget.passageText.length}");

      final result = await QuestionApi.generateQuestions(widget.passageText);

      print("🔥 문제 생성 성공");
      print("🔥 결과: $result");

      setState(() {
        questions = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("문제 생성 성공")),
      );
    } catch (e) {
      print("❌ 문제 생성 실패: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("문제 생성 실패: $e")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('문제 만들기 (Hub ID: ${widget.hubId})'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 📘 지문
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  widget.passageText,
                  style: const TextStyle(height: 1.4),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// 🔥 버튼 (핵심)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : fetchQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "🔥 문제 만들기",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// 🔄 로딩
            if (isLoading) const CircularProgressIndicator(),

            /// 🧠 결과 출력
            if (!isLoading && questions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final q = questions[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// 질문
                            Text(
                              "Q${index + 1}. ${q["question_text"]}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            /// 선택지
                            ...q["choices"].map<Widget>((c) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  "${c["number"]}. ${c["text"]}",
                                ),
                              );
                            }).toList(),

                            const SizedBox(height: 8),

                            /// 정답
                            Text(
                              "👉 정답: ${q["answer"]}",
                              style: const TextStyle(color: Colors.blue),
                            ),

                            /// 해설
                            Text("💡 ${q["explanation"]}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
