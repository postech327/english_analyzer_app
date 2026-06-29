import 'package:flutter/material.dart';
import '../services/exam_service.dart';

class ExamScreen extends StatefulWidget {
  final int problemSetId;

  const ExamScreen({super.key, required this.problemSetId});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  Map<String, dynamic>? examData;
  bool isLoading = true;

  Map<int, int> selectedAnswers = {}; // questionId : optionId

  @override
  void initState() {
    super.initState();
    loadExam();
  }

  Future<void> loadExam() async {
    try {
      final data = await ExamService.startExam(widget.problemSetId);
      setState(() {
        examData = data;
        isLoading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final questions = examData!["questions"];

    return Scaffold(
      appBar: AppBar(
        title: Text(examData!["name"]),
      ),
      body: ListView.builder(
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = questions[index];
          final questionId = q["question_id"];
          final options = q["options"];

          return Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Q${index + 1}. ${q["content"]}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...options.map<Widget>((option) {
                    return RadioListTile<int>(
                      value: option["option_id"],
                      groupValue: selectedAnswers[questionId],
                      onChanged: (value) {
                        setState(() {
                          selectedAnswers[questionId] = value!;
                        });
                      },
                      title: Text(option["text"]),
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
