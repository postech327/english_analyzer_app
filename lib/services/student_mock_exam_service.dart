import 'dart:convert';

import 'package:english_analyzer_app/config/api.dart';
import 'package:english_analyzer_app/config/auth_store.dart';
import 'package:http/http.dart' as http;

class StudentMockExamService {
  static Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      if (AuthStore.accessToken != null)
        'Authorization': 'Bearer ${AuthStore.accessToken}',
    };
  }

  static Future<List<dynamic>> fetchMockExams({
    String? grade,
    int? year,
    int? month,
  }) async {
    final query = <String, String>{};
    if (grade != null && grade.isNotEmpty) query['grade'] = grade;
    if (year != null) query['year'] = '$year';
    if (month != null) query['month'] = '$month';

    final uri = ApiConfig.u('/student/mock-exams').replace(
      queryParameters: query.isEmpty ? null : query,
    );

    final res = await http.get(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('모의고사 목록 조회 실패: ${res.body}');
    }

    return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> fetchMockExamDetail(
      int mockExamId) async {
    final uri = ApiConfig.u('/student/mock-exams/$mockExamId');

    final res = await http.get(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('모의고사 문항 조회 실패: ${res.body}');
    }

    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> fetchMockExamReport() async {
    final uri = ApiConfig.u('/student/mock-exams/report');

    final res = await http.get(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('모의고사 리포트 조회 실패: ${res.body}');
    }

    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> fetchMockExamAttemptDetail(
    int attemptId,
  ) async {
    final uri = ApiConfig.u('/student/mock-exams/attempts/$attemptId');

    final res = await http.get(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('모의고사 상세 결과 조회 실패: ${res.body}');
    }

    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> submitMockExam({
    required int mockExamId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final uri = ApiConfig.u('/student/mock-exams/$mockExamId/submit');

    final res = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'answers': answers}),
    );

    if (res.statusCode != 200) {
      throw Exception('모의고사 제출 실패: ${res.body}');
    }

    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }
}
