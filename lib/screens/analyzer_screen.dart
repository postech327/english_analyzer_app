import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api.dart';
import 'chat_screen.dart';
import 'student_quiz_screen.dart';

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
  String _passageHubResult = ''; // 🔥 지문 분석 허브 결과
  bool _busy = false;

  // 공통 POST 유틸
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

  // ① 문장 구조 분석
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

  // ② 주제/제목/요지 분석
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

  // ③ 단어 뜻/유의어
  Future<void> _wordSynonyms() async {
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

  // ④ 🔥 지문 분석 허브 + 저장
  //    /teacher/passage/analyze_and_save 호출
  Future<void> _analyzePassageAndSave() async {
    await _post(
      ApiConfig.u(ApiConfig.passageAnalyzeAndSave),
      {
        'title': '앱 입력 지문', // 필요하면 나중에 TextField 하나 만들어서 제목 입력받기
        'content': _input.text, // 현재 입력 문단을 지문으로 사용
        'source': 'Flutter App',
        'level': '',
        'created_by': 'test@example.com', // 나중에 로그인한 유저 정보로 교체
      },
      (text) {
        try {
          final m = jsonDecode(text) as Map<String, dynamic>;
          final analysis = m['analysis'] as Map<String, dynamic>?;

          if (analysis != null) {
            _passageHubResult = [
              'Passage ID: ${m['passage_id']}',
              'Topic(EN): ${analysis['topic_en'] ?? ''}',
              '주제(KO): ${analysis['topic_ko'] ?? ''}',
              'Title(EN): ${analysis['title_en'] ?? ''}',
              '제목(KO): ${analysis['title_ko'] ?? ''}',
              'Gist(EN): ${analysis['gist_en'] ?? ''}',
              '요지(KO): ${analysis['gist_ko'] ?? ''}',
              'Summary(EN): ${analysis['summary_en'] ?? ''}',
              '요약(KO): ${analysis['summary_ko'] ?? ''}',
            ].join('\n');
          } else {
            _passageHubResult = text;
          }
        } catch (_) {
          _passageHubResult = text;
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

            // 구조/주제 버튼
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
            const SizedBox(height: 12),

            // 🔥 지문 분석 허브 + 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _analyzePassageAndSave,
                child: const Text('지문 분석 허브 + 저장'),
              ),
            ),
            const SizedBox(height: 16),

            // 결과 카드들
            const Text('• 문장 구조 분석 결과'),
            const SizedBox(height: 4),
            _ResultCard(text: _structureResult),
            const SizedBox(height: 16),

            const Text('• 주제 · 제목 · 요지 분석 결과'),
            const SizedBox(height: 4),
            _ResultCard(text: _topicTitleSummaryResult),
            const SizedBox(height: 16),

            const Text('• 지문 분석 허브 결과'),
            const SizedBox(height: 4),
            _ResultCard(text: _passageHubResult),
            const SizedBox(height: 24),

            // 단어 분석
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

            // 학생 모드 버튼
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
