// lib/services/student_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/student_models.dart';

const String baseUrl =
    String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:8000');

class StudentApi {
  /// 🔹 문제 세트 목록 조회
  /// Swagger: GET /student/problem_sets
  static Future<List<StudentProblemSetSummary>> fetchProblemSets({
    String? questionType,
  }) async {
    final queryParams = <String, String>{};

    if (questionType != null &&
        questionType.isNotEmpty &&
        questionType != 'all') {
      queryParams['question_type'] = questionType;
    }

    final uri = Uri.parse('$baseUrl/student/problem_sets')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final resp = await http.get(uri);

    if (resp.statusCode != 200) {
      throw Exception(
        '문제 세트 목록 로드 실패: ${resp.statusCode} / ${resp.body}',
      );
    }

    final raw = jsonDecode(utf8.decode(resp.bodyBytes)) as List<dynamic>;

    return raw
        .map(
          (e) => StudentProblemSetSummary.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// 🔹 특정 시험(problem_set_id) 로드
  /// ✅ Swagger: GET /student/exams/{problem_set_id}
  static Future<StudentQuestionSet> fetchQuestions({
    required int problemSetId,
  }) async {
    final uri = Uri.parse('$baseUrl/student/exams/$problemSetId');

    final resp = await http.get(uri);

    if (resp.statusCode != 200) {
      throw Exception('문항 로드 실패: ${resp.statusCode} / ${resp.body}');
    }

    final data =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;

    return StudentQuestionSet.fromJson(data);
  }

  /// 🔹 정답 체크
  static Future<StudentAnswerCheckResult> checkAnswer({
    required int questionId,
    required int selectedOptionId,
  }) async {
    final uri = Uri.parse('$baseUrl/student/exams/check-answer');

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'question_id': questionId,
        'selected_option_id': selectedOptionId,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('정답 확인 실패');
    }

    return StudentAnswerCheckResult.fromJson(
      jsonDecode(utf8.decode(resp.bodyBytes)),
    );
  }
}
