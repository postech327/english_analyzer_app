import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RecommendedQuestionScreen extends StatefulWidget {
  final int userId;
  final String errorType;

  const RecommendedQuestionScreen({
    super.key,
    required this.userId,
    required this.errorType,
  });

  @override
  State<RecommendedQuestionScreen> createState() =>
      _RecommendedQuestionScreenState();
}

class _RecommendedQuestionScreenState extends State<RecommendedQuestionScreen> {
  late Future<Map<String, dynamic>> _future;
  final Map<int, int> _answers = {};

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchRecommendedQuestions(
      userId: widget.userId,
      errorType: widget.errorType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('개념 문제 다시 풀기'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }

          final questions = snapshot.data!['questions'];

          if (questions.isEmpty) {
            return const Center(child: Text('추천 문제가 없습니다.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (var q in questions)
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q['text'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        for (var opt in q['options'])
                          RadioListTile<int>(
                            value: opt['index'],
                            groupValue: _answers[q['id']],
                            title: Text(opt['text']),
                            onChanged: (v) {
                              setState(() {
                                _answers[q['id']] = v!;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: _answers.length == questions.length
                    ? () {
                        // 👉 다음 단계(B-5)에서 submit 연결
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('제출 기능은 다음 단계에서 연결됩니다'),
                          ),
                        );
                      }
                    : null,
                child: const Text('제출'),
              ),
            ],
          );
        },
      ),
    );
  }
}
