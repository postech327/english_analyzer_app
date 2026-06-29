import 'package:flutter/material.dart';
import '../models/student_models.dart';

class StudentQuizResultScreen extends StatelessWidget {
  final StudentQuestionSet questionSet;
  final List<StudentAnswerCheckResult> results;

  const StudentQuizResultScreen({
    super.key,
    required this.questionSet,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final int totalQuestions = questionSet.questions.length;

    final int correctAnswers = results.where((r) => r.correct).length;

    final int incorrectAnswers = totalQuestions - correctAnswers < 0
        ? 0
        : totalQuestions - correctAnswers;

    final int scorePercent = totalQuestions == 0
        ? 0
        : ((correctAnswers / totalQuestions) * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('시험 결과'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      size: 56,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '시험 결과',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$scorePercent%',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$correctAnswers / $totalQuestions 문제 정답',
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    _resultRow(
                      label: '전체 문항',
                      value: totalQuestions,
                      icon: Icons.list_alt,
                    ),
                    const SizedBox(height: 10),
                    _resultRow(
                      label: '정답 수',
                      value: correctAnswers,
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 10),
                    _resultRow(
                      label: '오답 수',
                      value: incorrectAnswers,
                      icon: Icons.cancel_outlined,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '문항별 결과',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: questionSet.questions.isEmpty
                  ? const Center(
                      child: Text('표시할 문제가 없습니다.'),
                    )
                  : ListView.builder(
                      itemCount: questionSet.questions.length,
                      itemBuilder: (context, index) {
                        final q = questionSet.questions[index];

                        final r = results.firstWhere(
                          (e) => e.questionId == q.id,
                          orElse: () => StudentAnswerCheckResult(
                            questionId: q.id,
                            correct: false,
                            correctOptionId: -1,
                          ),
                        );

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  r.correct ? Colors.green : Colors.red,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              q.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              r.correct ? '정답' : '오답',
                              style: TextStyle(
                                color: r.correct ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Icon(
                              r.correct
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                              color: r.correct ? Colors.green : Colors.red,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('돌아가기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow({
    required String label,
    required int value,
    required IconData icon,
    Color? color,
  }) {
    final Color displayColor = color ?? Colors.black87;

    return Row(
      children: [
        Icon(
          icon,
          color: displayColor,
          size: 24,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 17),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: displayColor,
          ),
        ),
      ],
    );
  }
}
