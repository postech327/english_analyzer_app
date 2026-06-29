import 'dart:convert';

import 'package:english_analyzer_app/config/api.dart';
import 'package:english_analyzer_app/config/auth_store.dart';
import 'package:http/http.dart' as http;

class TeacherMockExamService {
  static Map<String, String> _headers({bool json = true}) {
    return {
      if (json) 'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (AuthStore.accessToken != null)
        'Authorization': 'Bearer ${AuthStore.accessToken}',
    };
  }

  static Future<List<dynamic>> fetchMockExams() async {
    final res = await http.get(
      ApiConfig.u('/teacher/mock-exams'),
      headers: _headers(),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('모의고사 목록 조회 실패 ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createMockExam({
    required String grade,
    required int year,
    required int month,
    required String title,
    bool hasListening = false,
  }) async {
    final res = await http.post(
      ApiConfig.u('/teacher/mock-exams'),
      headers: _headers(),
      body: jsonEncode({
        'grade': grade,
        'year': year,
        'month': month,
        'title': title,
        'has_listening': hasListening,
      }),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('모의고사 생성 실패 ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> fetchMockExamDetail(
    int mockExamId,
  ) async {
    final res = await http.get(
      ApiConfig.u('/teacher/mock-exams/$mockExamId'),
      headers: _headers(),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('모의고사 상세 조회 실패 ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> fetchMockExamReport(
    int mockExamId,
  ) async {
    final res = await http.get(
      ApiConfig.u('/teacher/mock-exams/$mockExamId/report'),
      headers: _headers(),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('모의고사 리포트 조회 실패 ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> fetchMockStudentReportList() async {
    final res = await http.get(
      ApiConfig.u('/teacher/mock-exams/students/report'),
      headers: _headers(),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('학생별 리포트 조회 실패 ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> fetchMockStudentReportDetail(
    int studentId,
  ) async {
    final res = await http.get(
      ApiConfig.u('/teacher/mock-exams/students/$studentId/report'),
      headers: _headers(),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('학생 누적 리포트 조회 실패 ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> fetchMockStudentAttemptDetail({
    required int studentId,
    required int attemptId,
  }) async {
    final res = await http.get(
      ApiConfig.u(
          '/teacher/mock-exams/students/$studentId/attempts/$attemptId'),
      headers: _headers(),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('학생 응시 상세 조회 실패 ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<void> deleteMockExam(int mockExamId) async {
    final res = await http.delete(
      ApiConfig.u('/teacher/mock-exams/$mockExamId'),
      headers: _headers(),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('모의고사 삭제 실패 ${res.statusCode}: ${res.body}');
    }
  }

  static Future<Map<String, dynamic>> uploadQuestions({
    required int mockExamId,
    required String filename,
    required List<int> bytes,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      ApiConfig.u('/teacher/mock-exams/$mockExamId/questions/upload'),
    );
    request.headers.addAll(_headers(json: false));
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('업로드 실패 ${res.statusCode}: ${_errorMessage(res)}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateQuestion({
    required int mockExamId,
    required int questionId,
    required Map<String, dynamic> payload,
  }) async {
    final res = await http.patch(
      ApiConfig.u('/teacher/mock-exams/$mockExamId/questions/$questionId'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('문항 수정 실패 ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<void> deleteQuestion({
    required int mockExamId,
    required int questionId,
  }) async {
    final res = await http.delete(
      ApiConfig.u('/teacher/mock-exams/$mockExamId/questions/$questionId'),
      headers: _headers(),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('문항 삭제 실패 ${res.statusCode}: ${res.body}');
    }
  }

  static String _errorMessage(http.Response res) {
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final detail = decoded is Map<String, dynamic> ? decoded['detail'] : null;
      if (detail is Map<String, dynamic>) {
        final errors = detail['errors'];
        if (errors is List && errors.isNotEmpty) return errors.join('\n');
        final message = detail['message']?.toString();
        final missing = detail['missing_columns'];
        final received = detail['received_columns'];
        if (message == 'Missing required columns') {
          final buffer = StringBuffer('필수 컬럼이 부족합니다.');
          if (missing is List && missing.isNotEmpty) {
            buffer.write('\n부족한 컬럼: ${missing.join(', ')}');
          }
          if (received is List && received.isNotEmpty) {
            buffer.write('\n읽힌 컬럼: ${received.join(', ')}');
          }
          return buffer.toString();
        }
        final firstRows = detail['received_first_rows'];
        final examples = detail['column_examples'];
        if (firstRows is List && firstRows.isNotEmpty) {
          final buffer = StringBuffer(message ?? '엑셀 컬럼명 행을 찾지 못했습니다.');
          if (examples != null) {
            buffer.write('\n필요한 컬럼 예시: $examples');
          }
          final first = firstRows.first;
          if (first is Map) {
            final values = first['values'];
            if (values is List) {
              buffer.write('\n현재 읽힌 첫 행: ${values.join(', ')}');
            }
          }
          return buffer.toString();
        }
        return message ?? res.body;
      }
      return detail?.toString() ?? res.body;
    } catch (_) {
      return res.body;
    }
  }
}
