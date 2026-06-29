import 'package:flutter/material.dart';
import 'package:english_analyzer_app/services/question_api.dart';

class QuestionTestScreen extends StatefulWidget {
  const QuestionTestScreen({super.key});

  @override
  State<QuestionTestScreen> createState() => _QuestionTestScreenState();
}

class _QuestionTestScreenState extends State<QuestionTestScreen> {
  final TextEditingController _controller = TextEditingController();

  List questions = [];
  bool isLoading = false;

  // 🔥 GPT 문제 생성 호출
  void fetchQuestions() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("지문을 입력하세요")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await QuestionApi.generateQuestions(_controller.text);

      setState(() {
        questions = result;
      });
    } catch (e) {
      print("에러: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("에러 발생: $e")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  // 🔥 문제 하나 UI
  Widget buildQuestionItem(Map q) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              q["question_text"],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...q["choices"].map<Widget>((c) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text("${c["number"]}. ${c["text"]}"),
              );
            }).toList(),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("정답 확인"),
                    content: Text(
                      "정답: ${q["answer"]}\n\n해설:\n${q["explanation"]}",
                    ),
                  ),
                );
              },
              child: const Text("정답 보기"),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 전체 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("문제 생성 테스트"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📝 지문 입력
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "지문을 입력하세요",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // 🚀 버튼
            ElevatedButton(
              onPressed: fetchQuestions,
              child: const Text("문제 생성"),
            ),

            const SizedBox(height: 10),

            // ⏳ 로딩
            if (isLoading) const CircularProgressIndicator(),

            const SizedBox(height: 10),

            // 📄 결과
            Expanded(
              child: ListView(
                children: questions.map((q) => buildQuestionItem(q)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
