// lib/services/student_exam_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:english_analyzer_app/config/api.dart';
import 'package:english_analyzer_app/config/auth_store.dart';

class StudentExamService {
  /// ① 내 시험 목록
  static Future<List<dynamic>> fetchMyExams() async {
    final uri = ApiConfig.u('/student/problem_sets');

    final res = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthStore.accessToken}',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('시험 목록 조회 실패: ${res.body}');
    }

    return jsonDecode(res.body) as List<dynamic>;
  }

  /// ✅ ② 시험 상세 (문제 + 지문 가져오기) 🔥 추가
  static Future<Map<String, dynamic>> fetchExamDetail(int problemSetId) async {
    final uri = ApiConfig.u('/student/problem_sets/$problemSetId');

    final res = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthStore.accessToken}',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('시험 문제 조회 실패: ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// ③ 시험 제출
  static Future<Map<String, dynamic>> submitExam({
    required int problemSetId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final uri = ApiConfig.u('/student/answers');

    final payload = {
      'problem_set_id': problemSetId,
      'answers': answers, // ✅ 이미 변환된 상태 그대로
    };

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthStore.accessToken}',
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      throw Exception('시험 제출 실패: ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// 제출 후 결과/통계 요약
  static Future<Map<String, dynamic>> fetchResultSummary(
    int problemSetId,
  ) async {
    final uri =
        ApiConfig.u('/student/problem_sets/$problemSetId/result-summary');

    final res = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthStore.accessToken}',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('결과 통계 조회 실패: ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// ④ 약점 유형 조회
  static Future<Map<String, dynamic>> fetchWeakTypes({
    required int userId,
  }) async {
    final uri = ApiConfig.u('/student/exams/weak-types?user_id=$userId');

    final res = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthStore.accessToken}',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('약점 유형 조회 실패: ${res.body}');
    }

    return jsonDecode(res.body);
  }
}
