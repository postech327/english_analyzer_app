import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../config/auth_store.dart';
import '../models/learning_assignment.dart';

class LearningAssignmentService {
  const LearningAssignmentService();

  Future<List<AssignableStudent>> fetchStudents() async {
    final res = await http
        .get(
          ApiConfig.u('/teacher/learning-assignments/students'),
          headers: _headers(),
        )
        .timeout(const Duration(seconds: 20));

    final decoded = _decode(res);
    final items = decoded is Map<String, dynamic> ? decoded['items'] : decoded;
    return AssignableStudent.listFromJson(items);
  }

  Future<AssignmentCreateResult> assignFinalTouch({
    required int finalTouchId,
    required List<int> studentIds,
    required String title,
    String? teacherMessage,
    DateTime? dueAt,
  }) async {
    final body = {
      'student_ids': studentIds,
      'content_type': 'final_touch',
      'content_id': finalTouchId,
      'title': title,
      if (teacherMessage != null && teacherMessage.trim().isNotEmpty)
        'teacher_message': teacherMessage.trim(),
      if (dueAt != null) 'due_at': dueAt.toIso8601String(),
    };

    final res = await http
        .post(
          ApiConfig.u('/teacher/learning-assignments'),
          headers: _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    final decoded = _decode(res);
    return AssignmentCreateResult.fromJson(decoded as Map<String, dynamic>);
  }

  Future<AssignmentCreateResult> assignWorkbook({
    required int workbookId,
    required List<int> studentIds,
    required String title,
    String? teacherMessage,
    DateTime? dueAt,
  }) async {
    final body = {
      'student_ids': studentIds,
      'content_type': 'workbook',
      'content_id': workbookId,
      'title': title,
      if (teacherMessage != null && teacherMessage.trim().isNotEmpty)
        'teacher_message': teacherMessage.trim(),
      if (dueAt != null) 'due_at': dueAt.toIso8601String(),
    };

    final res = await http
        .post(
          ApiConfig.u('/teacher/learning-assignments'),
          headers: _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    final decoded = _decode(res);
    return AssignmentCreateResult.fromJson(decoded as Map<String, dynamic>);
  }

  Future<List<LearningAssignment>> fetchTeacherFinalTouchStatus(
    int finalTouchId,
  ) async {
    final decoded = await _get(
      '/teacher/learning-assignments/final-touch/$finalTouchId',
    );
    final items = decoded is Map<String, dynamic> ? decoded['items'] : decoded;
    return LearningAssignment.listFromJson(items);
  }

  Future<List<LearningAssignment>> fetchTeacherWorkbookStatus(
    int workbookId,
  ) async {
    final uri = ApiConfig.u('/teacher/learning-assignments').replace(
      queryParameters: {
        'content_type': 'workbook',
        'content_id': workbookId.toString(),
      },
    );
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(res);
    final items = decoded is Map<String, dynamic> ? decoded['items'] : decoded;
    return LearningAssignment.listFromJson(items);
  }

  Future<void> cancelTeacherAssignment(int assignmentId) async {
    final res = await http
        .delete(
          ApiConfig.u('/teacher/learning-assignments/$assignmentId'),
          headers: _headers(),
        )
        .timeout(const Duration(seconds: 20));
    _decode(res);
  }

  Future<List<LearningAssignment>> fetchStudentAssignments({
    String? status,
    String? contentType,
  }) async {
    final query = <String, String>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (contentType != null && contentType.isNotEmpty) {
      query['content_type'] = contentType;
    }
    final uri = ApiConfig.u('/student/learning-assignments')
        .replace(queryParameters: query);
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(res);
    final items = decoded is Map<String, dynamic> ? decoded['items'] : decoded;
    return LearningAssignment.listFromJson(items);
  }

  Future<LearningAssignment> startAssignment(int assignmentId) async {
    return _postAssignment('/student/learning-assignments/$assignmentId/start');
  }

  Future<LearningAssignment> completeAssignment(int assignmentId) async {
    return _postAssignment(
      '/student/learning-assignments/$assignmentId/complete',
    );
  }

  Future<LearningAssignment> _postAssignment(String path) async {
    final res = await http
        .post(ApiConfig.u(path), headers: _headers())
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(res);
    return LearningAssignment.fromJson(decoded as Map<String, dynamic>);
  }

  Future<dynamic> _get(String path) async {
    final res = await http
        .get(ApiConfig.u(path), headers: _headers())
        .timeout(const Duration(seconds: 20));
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final text = utf8.decode(res.bodyBytes);
    final decoded = text.trim().isEmpty ? null : jsonDecode(text);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final message = decoded is Map && decoded['detail'] != null
          ? decoded['detail'].toString()
          : text;
      throw Exception('학습 배포 API 오류 ${res.statusCode}: $message');
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
