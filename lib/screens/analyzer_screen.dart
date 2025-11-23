import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api.dart';
import 'chat_screen.dart';
import 'student_quiz_screen.dart'; // ✅ 이 줄 추가

class AnalyzerScreen extends StatefulWidget {
  const AnalyzerScreen({super.key});

  @override
  State<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends State<AnalyzerScreen> {
  final _input = TextEditingController(text: 'The boy who has a pen is happy.');
  final _words = TextEditingController(text: 'happy, pen, finished');

  String _structureResult = '';
  String _topicTitleSummaryResult = '';
  String _wordResult = '';
  bool _busy = false;

  Future<void> _post(
    Uri uri,
    Map<String, dynamic> body,
    void Function(String) onSuccess,
  ) async {
    setState(() => _busy = true);
    try {
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        onSuccess(utf8.decode(res.bodyBytes));
      } else {
        onSuccess('❌ 오류: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      onSuccess('네트워크 오류: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _analyzeStructure() async {
    await _post(
      ApiConfig.u(ApiConfig.analyzeStructure),
      {'text': _input.text},
      (text) {
        try {
          final json = jsonDecode(text) as Map<String, dynamic>;
          _structureResult = json['문장 구조 분석 결과']?.toString() ?? text;
        } catch (_) {
          _structureResult = text;
        }
        setState(() {});
      },
    );
  }

  Future<void> _analyzeTopicTitleSummary() async {
    await _post(
      ApiConfig.u(ApiConfig.analyzeTopicTitleSummary),
      {'text': _input.text},
      (text) {
        try {
          final m = jsonDecode(text) as Map<String, dynamic>;
          _topicTitleSummaryResult =
              'Topic: ${m['topic']}\nTitle: ${m['title']}\nGist(EN): ${m['gist_en']}\nKorean Gist: ${m['gist_ko']}';
        } catch (_) {
          _topicTitleSummaryResult = text;
        }
        setState(() {});
      },
    );
  }

  Future<void> _wordSynonyms() async {
    // 입력값을 , 로 구분 → 공백 제거
    final list = _words.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    await _post(
      ApiConfig.u(ApiConfig.wordSynonyms),
      {'words': list},
      (text) {
        try {
          final m = jsonDecode(text) as Map<String, dynamic>;
          _wordResult = m['단어 분석 결과']?.toString() ?? text;
        } catch (_) {
          _wordResult = text;
        }
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _input.dispose();
    _words.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EDF6),
      appBar: AppBar(
        title: const Text('문단 분석기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('영어 문단을 입력하세요'),
            const SizedBox(height: 8),
            TextField(
              controller: _input,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : _analyzeStructure,
                    child: const Text('구조 분석'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : _analyzeTopicTitleSummary,
                    child: const Text('주제/요지 분석'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('• 문장 구조 분석 결과'),
            const SizedBox(height: 4),
            _ResultCard(text: _structureResult),
            const SizedBox(height: 16),
            const Text('• 주제 · 제목 · 요지 분석 결과'),
            const SizedBox(height: 4),
            _ResultCard(text: _topicTitleSummaryResult),
            const SizedBox(height: 24),
            const Text('단어 뜻/유의어'),
            const SizedBox(height: 8),
            TextField(
              controller: _words,
              decoration: const InputDecoration(
                hintText: '단어들을 쉼표/공백으로 구분해 입력 (예: happy, pen, finished)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _busy ? null : _wordSynonyms,
                child: const Text('단어 분석'),
              ),
            ),
            const SizedBox(height: 8),
            const Text('• 단어 분석 결과'),
            const SizedBox(height: 4),
            _ResultCard(text: _wordResult),

            // 🔽🔽 여기부터 학생 모드 버튼 추가 🔽🔽
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentQuizScreen(
                        problemSetId: 1, // 테스트용 세트 ID
                        questionType: null, // null이면 전체 유형
                      ),
                    ),
                  );
                },
                child: const Text('학생 모드 시작'),
              ),
            ),
            // 🔼🔼 여기까지 추가 🔼🔼
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String text;
  const _ResultCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE6EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text.isEmpty ? '결과 없음' : text),
    );
  }
}
