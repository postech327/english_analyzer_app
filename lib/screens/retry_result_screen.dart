import 'package:flutter/material.dart';

class RetryResultScreen extends StatelessWidget {
  final int total;
  final int correct;
  final double accuracy;

  const RetryResultScreen({
    super.key,
    required this.total,
    required this.correct,
    required this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPerfect = accuracy == 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8EDF6),
      appBar: AppBar(
        title: const Text('재도전 결과'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🎉 아이콘
                  Icon(
                    isPerfect ? Icons.emoji_events : Icons.insights,
                    size: 72,
                    color: isPerfect ? Colors.amber : Colors.deepPurple,
                  ),
                  const SizedBox(height: 16),

                  // 🏆 메시지
                  Text(
                    isPerfect ? '완벽합니다! 🎉' : '확실히 좋아졌어요 👍',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    isPerfect ? '이 유형은 이제 강점이에요.' : '조금만 더 연습하면 완벽해질 수 있어요.',
                    style: const TextStyle(fontSize: 15),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // 📊 결과 요약
                  _resultRow('총 문제 수', '$total문제'),
                  _resultRow('맞힌 문제', '$correct문제'),
                  _resultRow(
                    '정확도',
                    '${accuracy.toStringAsFixed(1)}%',
                    highlight: true,
                  ),

                  const SizedBox(height: 28),

                  // 🔘 버튼들
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text(
                            '다시 한 번 더 풀기',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.deepPurple,
                          ),
                          onPressed: () {
                            Navigator.pop(context); // retry 화면으로 복귀
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.menu_book),
                          label: const Text(
                            '오답 노트로 돌아가기',
                            style: TextStyle(fontSize: 16),
                          ),
                          onPressed: () {
                            Navigator.popUntil(
                              context,
                              (route) => route.settings.name == '/wrong_note',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        child: const Text('학습 종료'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultRow(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.deepPurple : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
