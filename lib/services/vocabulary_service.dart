import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../models/vocabulary.dart';
import 'auth_service.dart';

class VocabularyService {
  const VocabularyService();

  Future<List<VocabularySet>> fetchTeacherSets({
    String status = 'all',
    String search = '',
  }) async {
    final query = <String, String>{};
    if (status != 'all') query['status'] = status;
    if (search.trim().isNotEmpty) query['search'] = search.trim();
    final uri = ApiConfig.u('/teacher/vocabulary-sets')
        .replace(queryParameters: query.isEmpty ? null : query);
    final decoded = await _get(uri);
    return VocabularySet.listFromJson(
      decoded is Map<String, dynamic> ? decoded['items'] : decoded,
    );
  }

  Future<VocabularySet> createSet(Map<String, dynamic> body) async {
    final decoded =
        await _send('POST', ApiConfig.u('/teacher/vocabulary-sets'), body);
    return VocabularySet.fromJson(decoded as Map<String, dynamic>);
  }

  Future<VocabularySet> fetchTeacherSet(int id) async {
    final decoded = await _get(ApiConfig.u('/teacher/vocabulary-sets/$id'));
    return VocabularySet.fromJson(decoded as Map<String, dynamic>);
  }

  Future<VocabularySet> updateSet(
    int id,
    Map<String, dynamic> body,
  ) async {
    final decoded = await _send(
      'PATCH',
      ApiConfig.u('/teacher/vocabulary-sets/$id'),
      body,
    );
    return VocabularySet.fromJson(decoded as Map<String, dynamic>);
  }

  Future<void> deleteSet(int id) async {
    await _send('DELETE', ApiConfig.u('/teacher/vocabulary-sets/$id'), null);
  }

  Future<VocabularySet> bulkSaveItems(
    int id,
    List<Map<String, dynamic>> items, {
    bool replace = true,
  }) async {
    final decoded = await _send(
      'POST',
      ApiConfig.u('/teacher/vocabulary-sets/$id/items/bulk'),
      {'replace': replace, 'items': items},
    );
    return VocabularySet.fromJson(decoded as Map<String, dynamic>);
  }

  Future<List<VocabularyAssignment>> fetchAssignments(int setId) async {
    final decoded = await _get(
      ApiConfig.u('/teacher/vocabulary-sets/$setId/assignments'),
    );
    return VocabularyAssignment.listFromJson(
      decoded is Map<String, dynamic> ? decoded['items'] : decoded,
    );
  }

  Future<VocabularyAssignResult> assignSet(
    int setId,
    List<int> studentIds,
  ) async {
    final decoded = await _send(
      'POST',
      ApiConfig.u('/teacher/vocabulary-sets/$setId/assign'),
      {'student_ids': studentIds},
    );
    return VocabularyAssignResult.fromJson(
      decoded as Map<String, dynamic>,
    );
  }

  Future<List<VocabularySet>> fetchStudentSets() async {
    final decoded = await _get(ApiConfig.u('/student/vocabulary-sets'));
    return VocabularySet.listFromJson(
      decoded is Map<String, dynamic> ? decoded['items'] : decoded,
    );
  }

  Future<VocabularySet> fetchStudentSet(int id) async {
    final decoded = await _get(ApiConfig.u('/student/vocabulary-sets/$id'));
    return VocabularySet.fromJson(decoded as Map<String, dynamic>);
  }

  Future<VocabularyAttempt> submitMeaningQuiz(
    int setId,
    Map<int, String> answers, {
    String? rangeLabel,
    String? rangeType,
  }) async {
    final decoded = await _send(
      'POST',
      ApiConfig.u('/student/vocabulary-attempts/submit'),
      {
        'set_id': setId,
        'mode': 'meaning_quiz',
        if ((rangeLabel ?? '').isNotEmpty) 'range_label': rangeLabel,
        if ((rangeType ?? '').isNotEmpty) 'range_type': rangeType,
        'answers': [
          for (final entry in answers.entries)
            {'item_id': entry.key, 'student_answer': entry.value},
        ],
      },
    );
    return VocabularyAttempt.fromJson(decoded as Map<String, dynamic>);
  }

  Future<List<VocabularyAttempt>> fetchStudentAttempts(int setId) async {
    final decoded = await _get(
      ApiConfig.u('/student/vocabulary-sets/$setId/attempts'),
    );
    return VocabularyAttempt.listFromJson(
      decoded is Map<String, dynamic> ? decoded['items'] : decoded,
    );
  }

  Future<VocabularyAttempt> fetchStudentAttempt(int attemptId) async {
    final decoded = await _get(
      ApiConfig.u('/student/vocabulary-attempts/$attemptId'),
    );
    return VocabularyAttempt.fromJson(decoded as Map<String, dynamic>);
  }

  Future<List<VocabularyStudentResultSummary>> fetchTeacherResults(
    int setId,
  ) async {
    final decoded = await _get(
      ApiConfig.u('/teacher/vocabulary-sets/$setId/results'),
    );
    return VocabularyStudentResultSummary.listFromJson(
      decoded is Map<String, dynamic> ? decoded['items'] : decoded,
    );
  }

  Future<List<VocabularyAttempt>> fetchTeacherStudentResults(
    int setId,
    int studentId,
  ) async {
    final decoded = await _get(
      ApiConfig.u('/teacher/vocabulary-sets/$setId/results/$studentId'),
    );
    return VocabularyAttempt.listFromJson(
      decoded is Map<String, dynamic> ? decoded['attempts'] : null,
    );
  }

  Future<dynamic> _get(Uri uri) async {
    final response = await _requestWithAuth(
      (headers) =>
          http.get(uri, headers: headers).timeout(const Duration(seconds: 20)),
    );
    return _decode(response);
  }

  Future<dynamic> _send(
    String method,
    Uri uri,
    Map<String, dynamic>? body,
  ) async {
    final encoded = body == null ? null : jsonEncode(body);
    final response = await _requestWithAuth(
      (headers) => switch (method) {
        'POST' => http
            .post(uri, headers: headers, body: encoded)
            .timeout(const Duration(seconds: 20)),
        'PATCH' => http
            .patch(uri, headers: headers, body: encoded)
            .timeout(const Duration(seconds: 20)),
        'DELETE' => http
            .delete(uri, headers: headers)
            .timeout(const Duration(seconds: 20)),
        _ => throw ArgumentError('Unsupported method $method'),
      },
    );
    return _decode(response);
  }

  Future<http.Response> _requestWithAuth(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var response = await request(await _headers());
    if (response.statusCode != 401) return response;
    try {
      await AuthService.instance.refreshAccessToken();
    } catch (_) {
      return response;
    }
    return request(await _headers());
  }

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.instance.currentAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes);
    final decoded = text.trim().isEmpty ? null : jsonDecode(text);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map && decoded['detail'] != null
          ? decoded['detail'].toString()
          : text;
      throw Exception('단어장 API 오류 ${response.statusCode}: $message');
    }
    return decoded;
  }
}
