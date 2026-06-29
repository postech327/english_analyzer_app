// lib/services/student_api.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../config/auth_store.dart';
import '../models/student_models.dart';

const String baseUrl =
    String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:8000');

class StudentApi {
  static Future<List<StudentProblemSetSummary>> fetchProblemSets({
    String? questionType,
  }) async {
    final queryParams = <String, String>{};

    if (questionType != null &&
        questionType.isNotEmpty &&
        questionType != 'all') {
      queryParams['question_type'] = questionType;
    }

    final uri = Uri.parse('$baseUrl/student/problem_sets')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final resp = await http.get(uri);

    if (resp.statusCode != 200) {
      throw Exception(
        'Problem set list load failed: ${resp.statusCode} / ${resp.body}',
      );
    }

    final raw = jsonDecode(utf8.decode(resp.bodyBytes)) as List<dynamic>;

    return raw
        .map(
          (e) => StudentProblemSetSummary.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<StudentQuestionSet> fetchQuestions({
    required int problemSetId,
  }) async {
    final uri = Uri.parse('$baseUrl/student/exams/$problemSetId/start');

    final resp = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthStore.accessToken}',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception(
          'Question load failed: ${resp.statusCode} / ${resp.body}');
    }

    final decoded = jsonDecode(utf8.decode(resp.bodyBytes));

    return StudentQuestionSet.fromJson(decoded);
  }

  static Future<List<StudentExamSummary>> fetchMyExams({
    int? folderId,
    bool unfiled = false,
  }) async {
    final query = <String, String>{};
    if (folderId != null) query['folder_id'] = '$folderId';
    if (unfiled) query['unfiled'] = 'true';
    final uri = Uri.parse('$baseUrl/student/problem_sets')
        .replace(queryParameters: query.isEmpty ? null : query);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthStore.accessToken}',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => StudentExamSummary.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load exams');
    }
  }

  static Future<List<StudentExamFolder>> fetchExamFolders(
      {int? parentId}) async {
    final query = <String, String>{};
    if (parentId != null) query['parent_id'] = '$parentId';
    final uri = Uri.parse('$baseUrl/student/problem_sets/folders')
        .replace(queryParameters: query.isEmpty ? null : query);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthStore.accessToken}',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final List data = decoded is Map<String, dynamic>
          ? decoded['items'] as List? ?? const []
          : decoded is List
              ? decoded
              : const [];
      return data
          .map((e) => StudentExamFolder.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load exam folders');
    }
  }

  static Future<StudentAnswerCheckResult> checkAnswer({
    required int questionId,
    required int selectedOptionId,
  }) async {
    final uri = ApiConfig.u('/student/check-answer');

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthStore.accessToken}',
      },
      body: jsonEncode({
        'question_id': questionId,
        'selected_option_id': selectedOptionId,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Answer check failed: ${res.statusCode} / ${res.body}');
    }

    return StudentAnswerCheckResult.fromJson(
      jsonDecode(res.body),
    );
  }
}
