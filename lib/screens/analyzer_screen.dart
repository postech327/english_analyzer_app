import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../services/question_api.dart';

class AnalyzerScreen extends StatefulWidget {
  const AnalyzerScreen({super.key});

  @override
  State<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends State<AnalyzerScreen> {
  final _input = TextEditingController();

  String _structureResult = '';
  String _topicResult = '';
  List<dynamic> _questions = [];

  bool _busy = false;

  /// 공통 POST 함수
  Future<void> _post(
    Uri uri,
    Map<String, dynamic> body,
    void Function(String) onSuccess,
  ) async {
    setState(() => _busy = true);

    try {
      final res = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        onSuccess(utf8.decode(res.bodyBytes));
      } else {
        onSuccess('❌ ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      onSuccess('❌ 오류: $e');
    }

    setState(() => _busy = false);
  }

  /// 구조 분석
  Future<void> _analyzeStructure() async {
    await _post(
      ApiConfig.u(ApiConfig.analyzeStructure),
      {'text': _input.text},
      (text) {
        _structureResult = text;
        setState(() {});
      },
    );
  }

  /// 주제 분석
  Future<void> _analyzeTopic() async {
    await _post(
      ApiConfig.u(ApiConfig.analyzeTopicTitleSummary),
      {'text': _input.text},
      (text) {
        _topicResult = text;
        setState(() {});
      },
    );
  }

  /// 🔥 핵심: 문제 생성 (여기 중요)
  Future<void> _generateQuestions() async {
    setState(() => _busy = true);

    try {
      print("🔥 버튼 클릭됨");

      final qs = await QuestionApi.generateQuestions(_input.text);

      print("🔥 문제 생성 성공");
      print("🔥 결과: $qs");

      setState(() {
        _questions = qs;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("문제 생성 성공")),
      );
    } catch (e) {
      print("❌ 문제 생성 실패: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("문제 생성 실패")),
      );
    }

    setState(() => _busy = false);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('지문 분석 허브')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 📥 입력창
            const Text('지문 입력'),
            const SizedBox(height: 8),
            TextField(
              controller: _input,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            /// 🔍 분석 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : _analyzeStructure,
                    child: const Text('구조 분석'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : _analyzeTopic,
                    child: const Text('주제 분석'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// 🔥 문제 생성 버튼 (핵심)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _generateQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '🔥 문제 만들기',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 📘 결과 영역
            const Text(
              '📘 생성된 문제',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (_questions.isEmpty)
              const Text('문제가 아직 없습니다.')
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _questions.map((q) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q['question_text'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          /// 선택지
                          ...(q['choices'] as List).map((c) {
                            return Text(" - ${c['text']}");
                          }),

                          const SizedBox(height: 8),

                          /// 정답
                          Text(
                            "정답: ${q['answer']}",
                            style: const TextStyle(color: Colors.blue),
                          ),

                          const SizedBox(height: 4),

                          /// 해설
                          Text("해설: ${q['explanation']}"),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
