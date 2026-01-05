// lib/services/student_exam_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:english_analyzer_app/config/api.dart';

class StudentExamService {
  // ① 내 시험 목록
  static Future<List<dynamic>> fetchMyExams({
    required int userId,
  }) async {
    final uri = ApiConfig.u('/student/exams?user_id=$userId');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('시험 목록 조회 실패');
    }

    return jsonDecode(res.body) as List<dynamic>;
  }

  // ② 시험 문제
  static Future<Map<String, dynamic>> fetchExamDetail(
    int problemSetId,
  ) async {
    final uri = ApiConfig.u('/student/exams/$problemSetId');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('시험 문제 조회 실패: ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ③ 시험 제출
  static Future<Map<String, dynamic>> submitExam({
    required int problemSetId,
    required int userId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final uri = ApiConfig.u('/student/exams/$problemSetId/submit');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'answers': answers,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('시험 제출 실패');
    }

    return jsonDecode(res.body);
  }

  // ④ 시험 결과 다시 보기
  static Future<Map<String, dynamic>> fetchExamResult({
    required int problemSetId,
    required int userId,
  }) async {
    final uri =
        ApiConfig.u('/student/exams/$problemSetId/result?user_id=$userId');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('시험 결과 조회 실패');
    }

    return jsonDecode(res.body);
  }

  // ⑤ 약점 유형
  static Future<Map<String, dynamic>> fetchWeakTypes({
    required int userId,
  }) async {
    final uri = ApiConfig.u('/student/exams/weak-types?user_id=$userId');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('약점 유형 조회 실패');
    }

    return jsonDecode(res.body);
  }

  // ⑥ 추천 문제
  static Future<List<dynamic>> fetchRecommendedQuestions({
    required int userId,
  }) async {
    final uri = ApiConfig.u('/student/exams/recommend?user_id=$userId');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('추천 문제 조회 실패');
    }

    final data = jsonDecode(res.body);
    return data['questions'] as List<dynamic>;
  }

  // ⑦ 추천 문제 제출 + GPT 해설
  static Future<Map<String, dynamic>> submitRecommendedAnswers({
    required int userId,
    required Map<int, int> answers,
  }) async {
    final uri = ApiConfig.u('/student/exams/recommended/submit');

    final payload = {
      'user_id': userId,
      'answers': answers.entries
          .map((e) => {
                'question_id': e.key,
                'selected_index': e.value,
              })
          .toList(),
    };

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      throw Exception('추천 문제 제출 실패');
    }

    return jsonDecode(res.body);
  }
}
