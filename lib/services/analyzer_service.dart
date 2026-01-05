// lib/services/analyzer_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../config/api.dart';
import '../models/analyzer_models.dart';
import '../models/dashboard_models.dart';
import '../models/analysis_record_model.dart';

class AnalyzerService {
  // ─────────────────────────────────────────────
  // ① 문단 분석
  // ─────────────────────────────────────────────
  Future<ParagraphResponse> analyzeParagraph(String text) async {
    final uri = ApiConfig.u(ApiConfig.analyzeParagraph);

    final res = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return ParagraphResponse.fromJson(data);
  }

  // ─────────────────────────────────────────────
  // ② 단문 구조 분석
  // ─────────────────────────────────────────────
  Future<SentenceResult> analyzeStructure(String text) async {
    final uri = ApiConfig.u(ApiConfig.analyzeStructure);

    final res = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
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

  // ─────────────────────────────────────────────
  // ③ 주제 / 제목 / 요지 / 요약
  // ─────────────────────────────────────────────
  Future<TopicTitleSummary> analyzeTopicTitleSummary(String text) async {
    final uri = ApiConfig.u(ApiConfig.analyzeTopicTitleSummary);

    final res = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return TopicTitleSummary.fromJson(data);
  }

  // ─────────────────────────────────────────────
  // ④ 단어 뜻/유의어 — 단어 리스트 버전
  // ─────────────────────────────────────────────
  Future<WordSynonymsResult> wordSynonyms(List<String> words) async {
    final uri = ApiConfig.u(ApiConfig.wordSynonyms);

    final res = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'words': words}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return WordSynonymsResult.fromJson(data);
  }

  // ─────────────────────────────────────────────
  // ⑤ (옵션) 지문 전체 기반 단어/유의어 분석
  // ─────────────────────────────────────────────
  Future<WordSynonymsResult> fetchWordSynonyms(String text) async {
    final uri = ApiConfig.u(ApiConfig.wordSynonyms);

    final res = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('WordSynonyms Error: ${res.statusCode} / ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return WordSynonymsResult.fromJson(map);
  }

  // ─────────────────────────────────────────────
  // ⑥ 챗봇
  // ─────────────────────────────────────────────
  Future<String> chat(String question) async {
    final uri = ApiConfig.u(ApiConfig.chat);

    final res = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'question': question}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['챗봇 응답'] ?? data['answer'] ?? '').toString();
  }

  // ─────────────────────────────────────────────
  // ⑦ 단어 MCQ — 텍스트 버전
  // ─────────────────────────────────────────────
  Future<String> generateWordMcq(String word) async {
    final uri = ApiConfig.u(ApiConfig.wordMcq);

    final res = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'word': word}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['text'] ?? '').toString();
  }

  // ─────────────────────────────────────────────
  // ⑧ 단어 MCQ — 구조화(AnalyzerMcqItem)
  // ─────────────────────────────────────────────
  Future<AnalyzerMcqItem> generateWordMcqStruct(String word) async {
    final uri = ApiConfig.u(ApiConfig.wordMcqStruct);

    final res = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'word': word}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return AnalyzerMcqItem(
      stem: (map['stem'] ?? '') as String,
      choices:
          (map['choices'] as List? ?? []).map((e) => e.toString()).toList(),
      answerIndex: (map['answer_index'] ?? map['answerIndex'] ?? 0) as int,
      explanation: (map['explanation'] ?? '') as String,
    );
  }

  // ─────────────────────────────────────────────
  // ⑨ 대시보드
  // ─────────────────────────────────────────────
  Future<DashboardData> fetchDashboard({String period = '7d'}) async {
    final uri = ApiConfig.u('${ApiConfig.dashboard}?period=$period');

    final res = await http.get(uri).timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception('dashboard error: ${res.statusCode} / ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return DashboardData.fromJson(map);
  }

  // ─────────────────────────────────────────────
  // 🔟 (기존) 지문 분석 + 저장
  // ─────────────────────────────────────────────
  Future<PassageAnalysisResult> analyzeAndSavePassage({
    required String title,
    required String content,
    String? source,
    String? level,
    String? createdBy,
  }) async {
    final uri = ApiConfig.u(ApiConfig.passageAnalyzeAndSave);

    final body = <String, dynamic>{
      'title': title,
      'content': content,
      if (source != null && source.isNotEmpty) 'source': source,
      if (level != null && level.isNotEmpty) 'level': level,
      if (createdBy != null && createdBy.isNotEmpty) 'created_by': createdBy,
    };

    final res = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'analyzeAndSavePassage error: ${res.statusCode} / ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return PassageAnalysisResult.fromJson(map);
  }

  // ─────────────────────────────────────────────
  // 11. (신규) 통합 지문 분석 허브 호출 (※ 여기서는 저장 안 함)
  // ─────────────────────────────────────────────
  Future<TextAnalysisHubResult> analyzeTextAnalysisHub(String text) async {
    final uri = ApiConfig.u(ApiConfig.textAnalysisHub);

    final res = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('textAnalysisHub HTTP ${res.statusCode}: ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return TextAnalysisHubResult.fromJson(map);
  }

  // ─────────────────────────────────────────────
  // 12. (신규) 지문 분석 허브 결과를 /analyses 에 저장 (id 리턴)
  // ─────────────────────────────────────────────
  Future<int> saveTextAnalysisHubToAnalyses({
    required String inputText,
    required TextAnalysisHubResult hub,
  }) async {
    final uri = ApiConfig.u(ApiConfig.analyses);

    final payload = {
      'kind': 'text_hub',
      'input_text': inputText,
      'result_text': [
        'Topic: ${hub.topic}',
        'Title: ${hub.title}',
        'Gist EN: ${hub.gistEn}',
        'Gist KO: ${hub.gistKo}',
        'Summary EN: ${hub.summaryEn}',
        'Summary KO: ${hub.summaryKo}',
      ].join('\n'),
      // ✅ 서버가 string을 기대하므로 JSON을 문자열로
      'result_json': jsonEncode(hub.toJson()),
    };

    final res = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'saveTextAnalysisHubToAnalyses HTTP ${res.statusCode}: ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;

    // ✅ 타입 안전하게 id 파싱 (int / String 모두 대응)
    final dynamic rawId = map['id'] ?? map['analysis_id'];
    final int analysisId = rawId is int ? rawId : int.parse(rawId.toString());

    debugPrint('Saved hub analysis as AnalysisRecord id=$analysisId');
    return analysisId;
  }

  // ✅ /analyses 목록 조회
  Future<List<AnalysisRecord>> fetchAnalyses({int limit = 50}) async {
    final uri = ApiConfig.u('${ApiConfig.analyses}?limit=$limit');

    final res = await http.get(uri, headers: const {
      'Content-Type': 'application/json'
    }).timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('fetchAnalyses HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    // 서버가 배열로 주는 경우: [ {...}, {...} ]
    if (decoded is List) {
      return decoded
          .map((e) => AnalysisRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // 서버가 {"items":[...]} 형태로 주는 경우도 대비
    if (decoded is Map<String, dynamic>) {
      final items = (decoded['items'] as List? ?? []);
      return items
          .map((e) => AnalysisRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

// ✅ /analyses/{id} 단건 조회 (있으면 편함)
  Future<AnalysisRecord> fetchAnalysisById(int id) async {
    final uri = ApiConfig.u('${ApiConfig.analyses}/$id');

    final res = await http.get(uri, headers: const {
      'Content-Type': 'application/json'
    }).timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('fetchAnalysisById HTTP ${res.statusCode}: ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return AnalysisRecord.fromJson(map);
  }
}
