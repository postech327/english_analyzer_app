import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProblemTakeScreen extends StatefulWidget {
  final int problemSetId;
  final int attemptId;
  final String title;

  const ProblemTakeScreen({
    super.key,
    required this.problemSetId,
    required this.attemptId,
    required this.title,
  });

  @override
  State<ProblemTakeScreen> createState() => _ProblemTakeScreenState();
}

class _ProblemTakeScreenState extends State<ProblemTakeScreen> {
  List questions = [];
  int currentIndex = 0;
  int? selectedIndex;
  bool showAnswer = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    try {
      final data = await ApiService.fetchProblemSet(widget.problemSetId);

      setState(() {
        questions = data["questions"] ?? [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('문제 불러오기 실패: $e')),
      );
    }
  }

  void selectAnswer(int index) {
    if (showAnswer) return;

    setState(() {
      selectedIndex = index;
    });
  }

  Future<void> _submitAnswer() async {
    if (questions.isEmpty) return;

    final q = questions[currentIndex];

    if (selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 보기를 선택하세요!')),
      );
      return;
    }

    final bool isCorrect = selectedIndex == q["answer_index"];

    try {
      setState(() {
        isSubmitting = true;
      });

      await ApiService.submitAnswer(
        attemptId: widget.attemptId,
        questionId: q["id"],
        selectedIndex: selectedIndex!,
        isCorrect: isCorrect,
      );

      if (!mounted) return;

      setState(() {
        showAnswer = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCorrect ? '정답입니다! 🎉' : '오답입니다 😢'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('시험 제출 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void nextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedIndex = null;
        showAnswer = false;
      });
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 문제를 완료했습니다.')),
      );

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: const Color(0xFF4F46E5),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final q = questions[currentIndex];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF4F46E5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 지문
            _passageCard(q),

            const SizedBox(height: 20),

            /// 문제 카드
            _questionCard(q),

            const SizedBox(height: 20),

            /// 선택지
            ...List.generate(q["options"].length, (index) {
              final opt = q["options"][index];
              return _optionTile(index, opt, q["answer_index"]);
            }),

            const Spacer(),

            /// 하단 버튼
            _bottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _passageCard(dynamic q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        q["passage_content"] ?? "",
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey[700],
          height: 1.5,
        ),
      ),
    );
  }

  Widget _questionCard(dynamic q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Text(
        "Q${currentIndex + 1}. ${q["question_text"] ?? q["text"] ?? ""}",
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _optionTile(int index, dynamic opt, int answerIndex) {
    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Color textColor = Colors.black87;

    if (showAnswer) {
      if (index == answerIndex) {
        bgColor = Colors.green.shade100;
        borderColor = Colors.green;
      } else if (index == selectedIndex) {
        bgColor = Colors.red.shade100;
        borderColor = Colors.red;
      }
    } else {
      if (index == selectedIndex) {
        bgColor = Colors.black;
        borderColor = Colors.black;
        textColor = Colors.white;
      }
    }

    return GestureDetector(
      onTap: () => selectAnswer(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              opt["label"],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                opt["text"],
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomButtons() {
    return Column(
      children: [
        if (!showAnswer)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (selectedIndex == null || isSubmitting)
                  ? null
                  : _submitAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "시험 제출하기",
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
        if (showAnswer)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                currentIndex == questions.length - 1 ? "시험 끝내기" : "다음 문제",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }
}
