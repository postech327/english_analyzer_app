import 'package:flutter/material.dart';
import 'package:english_analyzer_app/services/student_exam_api.dart';
import 'retry_quiz_screen.dart';

class WrongNoteScreen extends StatefulWidget {
  final int problemSetId;
  final int userId;

  const WrongNoteScreen({
    super.key,
    required this.problemSetId,
    required this.userId,
  });

  @override
  State<WrongNoteScreen> createState() => _WrongNoteScreenState();
}

class _WrongNoteScreenState extends State<WrongNoteScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data; // ✅ Map 기반

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await StudentExamApi.fetchRetryQuestions(
        problemSetId: widget.problemSetId,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List items = _data?['questions'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8EDF6),
      appBar: AppBar(
        title: const Text('오답 노트'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : items.isEmpty
                  ? const Center(
                      child: Text(
                        '오답이 없습니다 🎉',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return _wrongCard(items[index]);
                      },
                    ),

      // 🔁 재도전 버튼
      bottomNavigationBar: items.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text(
                  '이 유형 다시 풀기',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.deepPurple,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RetryQuizScreen(
                        problemSetId: widget.problemSetId,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  // ===============================
  // 🔴 오답 카드
  // ===============================
  Widget _wrongCard(Map<String, dynamic> item) {
    final List options = item['options'] ?? [];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏷 문제 유형
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                (item['question_type'] ?? '').toString().toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ❓ 문제
            Text(
              item['question_text'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 10),

            // 📄 보기
            for (int i = 0; i < options.length; i++)
              _optionLine(
                index: i,
                text: options[i],
                selected: i == item['selected_index'],
                correct: i == item['correct_index'],
              ),

            const SizedBox(height: 6),
            const Divider(),

            // 🧠 GPT 해설
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'GPT 오답 해설',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    (item['gpt_explanation'] ?? '').toString().trim().isNotEmpty
                        ? item['gpt_explanation']
                        : '해설이 제공되지 않았습니다.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===============================
  // 🅰️ 보기 한 줄
  // ===============================
  Widget _optionLine({
    required int index,
    required String text,
    required bool selected,
    required bool correct,
  }) {
    Color color = Colors.black;
    FontWeight weight = FontWeight.normal;

    if (correct) {
      color = Colors.green;
      weight = FontWeight.bold;
    } else if (selected && !correct) {
      color = Colors.red;
      weight = FontWeight.bold;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '${String.fromCharCode(65 + index)}. $text',
        style: TextStyle(
          color: color,
          fontWeight: weight,
        ),
      ),
    );
  }
}
