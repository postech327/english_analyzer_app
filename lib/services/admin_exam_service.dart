import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:english_analyzer_app/config/api.dart';

class AdminExamService {
  // ============================================================
  // A안: 난이도 비율 기반 자동 시험 생성 (관리자용)
  // POST /admin/exams/auto-generate
  // ============================================================
  static Future<int> autoGenerateExam({
    required String title,
    required int questionCount,
    required Map<String, double> distribution,
  }) async {
    final uri = ApiConfig.u('/admin/exams/auto-generate');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'question_count': questionCount,
        'distribution': distribution,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(
        jsonDecode(res.body)['detail'] ?? '시험 생성 실패',
      );
    }

    final data = jsonDecode(res.body);
    return data['problem_set_id'] as int;
  }

  // ============================================================
  // B안: 학생 약점 기반 맞춤 시험 생성
  // POST /admin/students/{user_id}/auto-exam
  // ============================================================
  static Future<Map<String, dynamic>> generateAutoExamForStudent({
    required int userId,
    required String title,
    int questionCount = 20,
  }) async {
    final uri = ApiConfig.u(
      '/admin/students/$userId/auto-exam'
      '?title=$title&question_count=$questionCount',
    );

    final res = await http.post(uri);

    if (res.statusCode != 200) {
      throw Exception(
        jsonDecode(res.body)['detail'] ?? '학생 맞춤 시험 생성 실패',
      );
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ============================================================
  // 시험지 미리보기 (문항 포함 상세 조회)
  // GET /admin/exams/{problem_set_id}
  // ============================================================
  static Future<Map<String, dynamic>> fetchExamDetail(
    int problemSetId,
  ) async {
    final uri = ApiConfig.u('/admin/exams/$problemSetId');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception(
        jsonDecode(res.body)['detail'] ?? '시험지 조회 실패',
      );
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ============================================================
  // 학생에게 시험지 배정
  // POST /admin/exams/{problem_set_id}/assign?user_id=...
  // ============================================================
  static Future<void> assignExamToStudent({
    required int problemSetId,
    required int userId,
  }) async {
    final uri =
        ApiConfig.u('/admin/exams/$problemSetId/assign?user_id=$userId');

    final res = await http.post(uri);

    if (res.statusCode != 200) {
      throw Exception(
        jsonDecode(res.body)['detail'] ?? '시험지 배정 실패',
      );
    }
  }
}
