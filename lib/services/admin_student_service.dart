// lib/services/admin_student_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:english_analyzer_app/config/api.dart';

class AdminStudentService {
  // ─────────────────────────
  // ① 학생 요약 목록
  // ─────────────────────────
  static Future<List<dynamic>> fetchStudentSummary({
    String? week,
    int? days,
  }) async {
    String path = '/admin/students/summary';

    if (week != null) {
      path += '?week=$week';
    } else if (days != null) {
      path += '?days=$days';
    }

    final uri = ApiConfig.u(path);
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('학생 요약 조회 실패');
    }

    return jsonDecode(res.body) as List<dynamic>;
  }

  // ─────────────────────────
  // ② 학생 개별 풀이 이력
  // ─────────────────────────
  static Future<List<dynamic>> fetchStudentHistory(int userId) async {
    final uri = ApiConfig.u('/admin/students/$userId/history');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('학생 풀이 기록 조회 실패');
    }

    return jsonDecode(res.body) as List<dynamic>;
  }

  // ─────────────────────────
  // ③ 학생 유형별 약점 분석
  // ─────────────────────────
  static Future<List<dynamic>> fetchStudentWeakTypes(int userId) async {
    final uri = ApiConfig.u('/admin/students/$userId/weak-types');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('학생 약점 유형 조회 실패');
    }

    return jsonDecode(res.body) as List<dynamic>;
  }

  // ─────────────────────────
  // ④ 🔥 학생 맞춤 시험 자동 생성
  // ─────────────────────────
  static Future<Map<String, dynamic>> generateAutoExamForStudent({
    required int userId,
    String title = '학생 맞춤 시험지',
    int questionCount = 20,
  }) async {
    final uri = ApiConfig.u(
      '/admin/students/$userId/auto-exam'
      '?title=$title&question_count=$questionCount',
    );

    final res = await http.post(uri);

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['detail'] ?? '시험지 생성 실패');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
