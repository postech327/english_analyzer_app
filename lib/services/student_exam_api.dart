// lib/services/student_exam_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../config/auth_store.dart';
import '../models/student_models.dart';
import '../models/exam_summary.dart';

class StudentExamApi {
  // =====================================================
  // 🔐 공통 Authorization 헤더
  // =====================================================
  static Map<String, String> _authHeaders() {
    final token = AuthStore.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('로그인이 필요합니다. (토큰 없음)');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // =====================================================
  // ① 학생용 문제 세트 목록
  // GET /student/problem_sets
  // =====================================================
  static Future<List<StudentProblemSetSummary>> fetchProblemSets({
    String? questionType,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/student/problem_sets'
      '${(questionType != null && questionType != 'all') ? '?question_type=$questionType' : ''}',
    );

    final res = await http.get(uri, headers: _authHeaders());

    if (res.statusCode != 200) {
      throw Exception('문제 세트 목록 불러오기 실패');
    }

    final List list = jsonDecode(utf8.decode(res.bodyBytes));
    return list.map((e) => StudentProblemSetSummary.fromJson(e)).toList();
  }

  // =====================================================
  // ② 시험 문제 로드
  // GET /student/exams/{problem_set_id}
  // =====================================================
  static Future<StudentQuestionSet> fetchQuestions({
    required int problemSetId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/student/exams/$problemSetId',
    );

    final res = await http.get(uri, headers: _authHeaders());

    if (res.statusCode != 200) {
      throw Exception('시험 문제 로드 실패');
    }

    final json = jsonDecode(utf8.decode(res.bodyBytes));
    return StudentQuestionSet.fromJson(json);
  }

  // =====================================================
  // ③ 답안 제출 / 채점
  // POST /student/answers/check
  // =====================================================
  static Future<StudentAnswerCheckResult> checkAnswer({
    required int questionId,
    required int selectedOptionId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/student/answers/check',
    );

    final res = await http.post(
      uri,
      headers: _authHeaders(),
      body: jsonEncode({
        'question_id': questionId,
        'selected_option_id': selectedOptionId,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('답안 제출 실패');
    }

    final json = jsonDecode(utf8.decode(res.bodyBytes));
    return StudentAnswerCheckResult.fromJson(json);
  }

  // =====================================================
  // ④ 시험 결과 요약
  // GET /student/exams/{problem_set_id}/summary
  // =====================================================
  static Future<ExamSummary> fetchExamSummary({
    required int problemSetId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/student/exams/$problemSetId/summary',
    );

    final res = await http.get(uri, headers: _authHeaders());

    if (res.statusCode != 200) {
      throw Exception('시험 결과 요약 불러오기 실패');
    }

    final json = jsonDecode(utf8.decode(res.bodyBytes));
    return ExamSummary.fromJson(json);
  }

  // =====================================================
  // ⑤ 오답 재도전 문제
  // GET /student/exams/{problem_set_id}/retry?limit=5
  // =====================================================
  static Future<Map<String, dynamic>> fetchRetryQuestions({
    required int problemSetId,
    int limit = 5,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/student/exams/$problemSetId/retry?limit=$limit',
    );

    final res = await http.get(uri, headers: _authHeaders());

    if (res.statusCode != 200) {
      throw Exception('재도전 문제 불러오기 실패');
    }

    return jsonDecode(utf8.decode(res.bodyBytes));
  }
}
