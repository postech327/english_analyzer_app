// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/auth_store.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://127.0.0.1:8000',
  );

  // 🔐 공통 헤더
  static Map<String, String> _headers() {
    return {
      "Content-Type": "application/json",
      if (AuthStore.accessToken != null)
        "Authorization": "Bearer ${AuthStore.accessToken}",
    };
  }

  // =====================================================
  // 📌 1. 약점 TOP
  // =====================================================
  static Future<List<dynamic>> fetchWeakTop(int userId, {int limit = 3}) async {
    final url = Uri.parse(
        '$baseUrl/study-reports/weak-top?user_id=$userId&limit=$limit');

    final res = await http.get(url, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('Failed to load weak types');
    }

    return json.decode(res.body)['weak_types'];
  }

  // =====================================================
  // 📌 2. 개념 조회
  // =====================================================
  static Future<Map<String, dynamic>> fetchConcept(String errorType) async {
    final url =
        Uri.parse('$baseUrl/concepts/by-error-type?error_type=$errorType');

    final res = await http.get(url, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('Failed to load concept');
    }

    return json.decode(res.body);
  }

  // =====================================================
  // 📌 3. 추천 문제
  // =====================================================
  static Future<Map<String, dynamic>> fetchRecommendedQuestions({
    required int userId,
    required String errorType,
  }) async {
    final url = Uri.parse(
      '$baseUrl/student/exams/recommend?user_id=$userId&error_type=$errorType',
    );

    final res = await http.get(url, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('추천 문제 로드 실패');
    }

    return json.decode(res.body);
  }

  // =====================================================
  // 🔥 4. 문제 자동 생성 + 저장 (핵심)
  // =====================================================
  static Future<Map<String, dynamic>> generateProblemSet({
    required String passage,
  }) async {
    final url = Uri.parse('$baseUrl/problem_sets/commit');

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "passage": passage,
        "name": "자동 생성 문제",
      }),
    );

    print("📦 문제 생성 STATUS: ${res.statusCode}");
    print("📦 문제 생성 BODY: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception('문제 생성 실패');
    }

    return jsonDecode(res.body);
  }

  // =====================================================
  // 🔥 5. 문제 생성 미리보기 (선택)
  // =====================================================
  static Future<Map<String, dynamic>> previewProblemSet({
    required int analysisId,
    required String name,
  }) async {
    final url =
        Uri.parse('$baseUrl/teacher/problem_sets/auto-generate/preview');

    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        "analysis_id": analysisId,
        "name": name,
        "total_questions": 5,
        "distribution": {
          "topic": 0.5,
          "gist": 0.5,
        }
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('미리보기 실패');
    }

    return json.decode(res.body);
  }

  static Future<Map<String, dynamic>> analyzeText(
    String text, {
    int? folderId,
  }) async {
    final url = Uri.parse('$baseUrl/analyze/summary_flow');

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "passage": text,
        "force_analyze": true,
        "folder_id": folderId,
      }),
    );

    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception('분석 실패');
    }

    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getFolders() async {
    final res = await http.get(
      Uri.parse('$baseUrl/folders/'),
      headers: _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('폴더 불러오기 실패');
    }

    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getPassagesByFolder(int folderId) async {
    final url = Uri.parse('$baseUrl/folders/$folderId/passages');

    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception('지문 불러오기 실패');
    }

    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getProblemSets(int passageId) async {
    final url = Uri.parse('$baseUrl/problem_sets/by_passage/$passageId');

    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception('문제 불러오기 실패');
    }

    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getQuestionsByProblemSet(
      int problemSetId) async {
    final url =
        Uri.parse('$baseUrl/teacher/problem_sets/$problemSetId/questions');

    final res = await http.get(url, headers: _headers());

    print("🔥 QUESTIONS STATUS: ${res.statusCode}");
    print("🔥 QUESTIONS BODY: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception('문제 불러오기 실패');
    }

    return jsonDecode(res.body);
  }

  static Future<void> submitAnswer({
    required int attemptId,
    required int questionId,
    required int selectedIndex,
    required bool isCorrect,
  }) async {
    final url = Uri.parse('$baseUrl/student/answers');

    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        "attempt_id": attemptId,
        "question_id": questionId,
        "selected_index": selectedIndex,
        "is_correct": isCorrect,
      }),
    );

    // 👇 여기 추가
    print("🔥 STATUS: ${res.statusCode}");
    print("🔥 BODY: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception('답안 저장 실패');
    }
  }

  // =====================================================
// 🔥 6. 학생 대시보드
// =====================================================
  static Future<Map<String, dynamic>> fetchDashboard() async {
    final url = Uri.parse('$baseUrl/student/dashboard');

    final res = await http.get(url, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('대시보드 로드 실패');
    }

    return json.decode(res.body);
  }

// =====================================================
// 🔥 7. 추천 문제 (새 구조)
// =====================================================
  static Future<List<dynamic>> fetchRecommendNew() async {
    final url = Uri.parse('$baseUrl/student/recommend');

    final res = await http.get(url, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('추천 문제 로드 실패');
    }

    final data = json.decode(res.body);
    return data["recommended_questions"];
  }

// 🔥 8. 오답 조회
  static Future<List<dynamic>> fetchWrongAnswers() async {
    final url = Uri.parse('$baseUrl/student/wrong_answers');

    final res = await http.get(url, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('오답 조회 실패');
    }

    final data = json.decode(res.body);
    return data["wrong_answers"];
  }

// =====================================================
// 🔥 9. 시험 시작 (🔥 핵심)
// =====================================================
  static Future<int> startExam(int problemSetId) async {
    final url = Uri.parse('$baseUrl/student/exams/start/$problemSetId');

    final res = await http.post(url, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('시험 시작 실패');
    }

    final data = jsonDecode(res.body);

    return data["attempt_id"];
  }

  // =====================================================
// 🔥 10. 문제셋 상세 조회
// =====================================================
  static Future<Map<String, dynamic>> fetchProblemSet(int problemSetId) async {
    final url = Uri.parse('$baseUrl/teacher/problem_sets/$problemSetId');

    final res = await http.get(url, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('문제셋 조회 실패');
    }

    return jsonDecode(res.body);
  }
}
