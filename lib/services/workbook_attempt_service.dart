import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../config/auth_store.dart';
import '../models/workbook_attempt.dart';

class WorkbookAttemptService {
  const WorkbookAttemptService();

  Future<WorkbookAttempt> submit({
    required int assignmentId,
    required int workbookId,
    required List<Map<String, dynamic>> answers,
    int? sectionId,
    List<int>? questionIds,
  }) async {
    final decoded = await _send(
      'POST',
      ApiConfig.u('/student/workbook-attempts/submit'),
      body: {
        'assignment_id': assignmentId,
        'workbook_id': workbookId,
        if (sectionId != null) 'section_id': sectionId,
        if (questionIds != null) 'question_ids': questionIds,
        'answers': answers,
      },
    );
    return WorkbookAttempt.fromJson(decoded as Map<String, dynamic>);
  }

  Future<WorkbookAttempt?> fetchLatestForStudent(int assignmentId) async {
    final decoded = await _get(
      ApiConfig.u('/student/workbook-attempts/latest/$assignmentId'),
    );
    if (decoded is Map<String, dynamic>) {
      if (decoded['has_attempt'] == false) return null;
      final latest = decoded['latest_attempt'];
      if (latest is Map) {
        return WorkbookAttempt.fromJson(Map<String, dynamic>.from(latest));
      }
      if (decoded['attempt_id'] != null || decoded['id'] != null) {
        return WorkbookAttempt.fromJson(decoded);
      }
    }
    return null;
  }

  Future<List<WorkbookAttempt>> fetchStudentAttempts(int assignmentId) async {
    final uri = ApiConfig.u('/student/workbook-attempts').replace(
      queryParameters: {'assignment_id': assignmentId.toString()},
    );
    final decoded = await _get(uri);
    final items = decoded is Map<String, dynamic> ? decoded['items'] : decoded;
    return WorkbookAttempt.listFromJson(items);
  }

  Future<TeacherWorkbookAttemptReport> fetchTeacherAssignmentReport(
    int assignmentId,
  ) async {
    final decoded = await _get(
      ApiConfig.u('/teacher/workbook-attempts/assignment/$assignmentId'),
    );
    return TeacherWorkbookAttemptReport.fromJson(
      decoded as Map<String, dynamic>,
    );
  }

  Future<dynamic> _get(Uri uri) async {
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));
    return _decode(res);
  }

  Future<dynamic> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final encoded = body == null ? null : jsonEncode(body);
    final res = switch (method) {
      'POST' => await http
          .post(uri, headers: _headers(), body: encoded)
          .timeout(const Duration(seconds: 20)),
      _ => throw ArgumentError('Unsupported method $method'),
    };
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final text = utf8.decode(res.bodyBytes);
    final decoded = text.trim().isEmpty ? null : jsonDecode(text);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final message = decoded is Map && decoded['detail'] != null
          ? decoded['detail'].toString()
          : text;
      throw Exception('워크북 결과 API 오류 ${res.statusCode}: $message');
    }
    return decoded;
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      if (AuthStore.accessToken != null)
        'Authorization': 'Bearer ${AuthStore.accessToken}',
    };
  }
}
