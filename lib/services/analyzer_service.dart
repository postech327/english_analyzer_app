// lib/services/analyzer_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../models/analyzer_models.dart';
import '../models/dashboard_models.dart';
// ⬇️ 구조화 MCQ 모델을 따로 두셨다면 import 경로만 맞춰 주세요.
// (예: ../models/mcq_models.dart)
import '../models/analyzer_models.dart' show McqItem;

class AnalyzerService {
  // 문단 분석
  Future<ParagraphResponse> analyzeParagraph(String text) async {
    final res = await http
        .post(
          Uri.parse(ApiConfig.analyzeParagraph),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return ParagraphResponse.fromJson(data);
  }

  // 단문 구조 분석(옵션)
  Future<SentenceResult> analyzeStructure(String text) async {
    final res = await http
        .post(
          Uri.parse(ApiConfig.analyzeStructure),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final r = (data['result'] ?? data['문장 구조 분석 결과'] ?? const {})
        as Map<String, dynamic>;
    return SentenceResult(
      index: 1,
      text: (r['text'] ?? '') as String,
      analyzedText: (r['analyzed_text'] ?? r['result'] ?? '') as String,
      spans: (r['spans'] as List? ?? [])
          .map((e) => Span.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // 주제/제목/요지
  Future<TopicTitleSummary> analyzeTopicTitleSummary(String text) async {
    final res = await http
        .post(
          Uri.parse(ApiConfig.analyzeTopicTitleSummary),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return TopicTitleSummary.fromJson(data);
  }

  // 단어 뜻/유의어
  Future<WordSynonymsResult> wordSynonyms(List<String> words) async {
    final res = await http
        .post(
          Uri.parse(ApiConfig.wordSynonyms),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'words': words}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return WordSynonymsResult.fromJson(data);
  }

  // 챗봇
  Future<String> chat(String question) async {
    final res = await http
        .post(
          Uri.parse(ApiConfig.chat),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'question': question}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['챗봇 응답'] ?? data['answer'] ?? '').toString();
  }

  /// 단어 객관식(빈칸) 문제 생성 — 문자열 포맷
  Future<String> generateWordMcq(String word) async {
    final res = await http
        .post(
          Uri.parse(ApiConfig.wordMcq),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'word': word}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['text'] ?? '').toString();
  }

  /// 단어 객관식(빈칸) 문제 생성 — 구조화 포맷
  /// 백엔드 스키마:
  /// { "stem": "...", "choices": ["...","...","...","...","..."], "answer_index": 2, "explanation": "..." }
  Future<McqItem> generateWordMcqStruct(String word) async {
    final res = await http
        .post(
          Uri.parse(ApiConfig.wordMcqStruct),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'word': word}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    // 모델 키명이 다르면 여기서 매핑만 조정하세요.
    return McqItem(
      stem: (map['stem'] ?? '') as String,
      choices:
          (map['choices'] as List? ?? []).map((e) => e.toString()).toList(),
      answerIndex: (map['answer_index'] ?? map['answerIndex'] ?? 0) as int,
      explanation: (map['explanation'] ?? '') as String,
    );
  }

  /// 대시보드(모델 반환)
  /// {
  ///   "streakDays": 23, "totalAnalyses": 157, "learnedWords": 132, "level": "B2",
  ///   "wrongTypes": [{"label":"시제","count":4}, ...],
  ///   "ratios": [{"label":"어법 정확성","value":40}, ...]
  /// }
  Future<DashboardData> fetchDashboard({String period = '7d'}) async {
    final uri = Uri.parse('${ApiConfig.dashboard}?period=$period');
    final res = await http.get(uri).timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception('dashboard error: ${res.statusCode}');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return DashboardData.fromJson(map);
  }
}
