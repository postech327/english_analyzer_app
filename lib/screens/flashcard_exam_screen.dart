import 'package:flutter/material.dart';

class FlashcardExamScreen extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final String passage;

  const FlashcardExamScreen({
    super.key,
    required this.questions,
    required this.passage,
  });

  @override
  State<FlashcardExamScreen> createState() => _FlashcardExamScreenState();
}

class _FlashcardExamScreenState extends State<FlashcardExamScreen> {
  final Map<int, int> selectedAnswers = {};
  final Map<int, bool> showAnswer = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("문제 풀이")),
      body: Column(
        children: [
          /// 🔥 지문 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Text(widget.passage),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: widget.questions.length,
              itemBuilder: (context, index) {
                final q = widget.questions[index];
                final selected = selectedAnswers[index];

                return Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Q${index + 1}. ${q['question_text']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 10),

                        /// 🔥 보기 (①②③④⑤)
                        ...q['choices'].asMap().entries.map((entry) {
                          int i = entry.key;
                          var c = entry.value;

                          final circled = ["①", "②", "③", "④", "⑤"][i];

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedAnswers[index] = c['number'];
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: selected == c['number']
                                        ? Colors.blue
                                        : Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text("$circled ${c['text']}"),
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 10),

                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              showAnswer[index] = true;
                            });
                          },
                          child: const Text("정답 보기"),
                        ),

                        if (showAnswer[index] == true) ...[
                          const SizedBox(height: 10),
                          Text("👉 정답: ${q['answer']}"),
                          Text("💡 ${q['explanation']}"),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
