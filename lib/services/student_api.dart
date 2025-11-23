// lib/services/student_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/student_models.dart';

// TeacherApi와 동일한 주소
const String baseUrl =
    String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:8000');

class StudentApi {
  /// 🔹 특정 problem_set_id에 대한 지문 + 문제 세트 로드
  static Future<StudentQuestionSet> fetchQuestions({
    required int problemSetId,
    bool shuffle = true,
  }) async {
    final uri = Uri.parse('$baseUrl/student/questions').replace(
      queryParameters: {
        'problem_set_id': problemSetId.toString(),
        'shuffle': shuffle.toString(),
      },
    );

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
    final uri = Uri.parse('$baseUrl/student/check-answer');

    final body = jsonEncode({
      'question_id': questionId,
      'selected_option_id': selectedOptionId,
    });

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('정답 확인 실패: ${resp.statusCode} / ${resp.body}');
    }

    final data =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;

    return StudentAnswerCheckResult.fromJson(data);
  }
}
