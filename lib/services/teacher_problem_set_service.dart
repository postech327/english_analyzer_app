import 'dart:convert';

import 'package:english_analyzer_app/config/api.dart';
import 'package:english_analyzer_app/config/auth_store.dart';
import 'package:english_analyzer_app/models/student_models.dart';
import 'package:http/http.dart' as http;

class TeacherProblemSetService {
  static Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (AuthStore.accessToken != null)
        'Authorization': 'Bearer ${AuthStore.accessToken}',
    };
  }

  static Future<int> saveProblemSet({
    required int analysisId,
    required String questionType,
    required String name,
    String? description,
    String createdBy = 'teacher',
    List<String>? typesJson,
    String mode = 'teacher',
    bool isPublished = false,
    required List<Map<String, dynamic>> items,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/teacher/problem_sets');

    final body = <String, dynamic>{
      'analysis_id': analysisId,
      'question_type': questionType,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'types_json': typesJson ?? [questionType],
      'mode': mode,
      'is_published': isPublished,
      'items': items,
    };

    final res = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('save failed ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (!data.containsKey('problem_set_id')) {
      throw Exception('response missing problem_set_id: $data');
    }

    return (data['problem_set_id'] as num).toInt();
  }

  static Future<Map<String, dynamic>> fetchProblemSet(int problemSetId) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/teacher/problem_sets/$problemSetId');

    final res = await http.get(uri, headers: _headers());

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('fetch failed ${res.statusCode}: ${res.body}');
    }

    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<List<StudentExamFolder>> fetchFolders({int? parentId}) async {
    final query = <String, String>{};
    if (parentId != null) query['parent_id'] = '$parentId';
    final uri = Uri.parse('${ApiConfig.baseUrl}/teacher/problem_sets/folders')
        .replace(queryParameters: query.isEmpty ? null : query);

    final res = await http.get(uri, headers: _headers());

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('folder load failed ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final List items = decoded is Map<String, dynamic>
        ? decoded['items'] as List? ?? const []
        : decoded is List
            ? decoded
            : const [];

    return items
        .map((e) => StudentExamFolder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<StudentExamSummary>> fetchProblemSets({
    int? folderId,
    bool unfiled = false,
  }) async {
    final query = <String, String>{};
    if (folderId != null) query['folder_id'] = '$folderId';
    if (unfiled) query['unfiled'] = 'true';
    final uri = Uri.parse('${ApiConfig.baseUrl}/teacher/problem_sets/list')
        .replace(queryParameters: query.isEmpty ? null : query);

    final res = await http.get(uri, headers: _headers());

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('problem set load failed ${res.statusCode}: ${res.body}');
    }

    final List data = jsonDecode(utf8.decode(res.bodyBytes));
    return data
        .map((e) => StudentExamSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> fetchProblemSetReport(
    int problemSetId,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/teacher/problem_sets/$problemSetId/report',
    );

    final res = await http.get(uri, headers: _headers());

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('report load failed ${res.statusCode}: ${res.body}');
    }

    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> fetchFolderProgressReport(
    int folderId,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/teacher/folders/$folderId/progress-report',
    );

    final res = await http.get(uri, headers: _headers());

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'folder progress load failed ${res.statusCode}: ${res.body}',
      );
    }

    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> fetchStudentProgressDetail({
    required int folderId,
    required int studentId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/teacher/folders/$folderId/students/$studentId/progress-detail',
    );

    final res = await http.get(uri, headers: _headers());

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'student progress detail load failed ${res.statusCode}: ${res.body}',
      );
    }

    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> fetchStudentOverallReport(
    int studentId,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/teacher/students/$studentId/overall-report',
    );

    final res = await http.get(uri, headers: _headers());

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'student overall report load failed ${res.statusCode}: ${res.body}',
      );
    }

    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> assignStudentRecommendation({
    required int studentId,
    required Map<String, dynamic> recommendation,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/teacher/students/$studentId/recommendations',
    );

    final type = (recommendation['type'] ??
            recommendation['recommendation_type'] ??
            'custom')
        .toString();
    final route =
        (recommendation['target_route'] ?? recommendation['route'])?.toString();

    final body = <String, dynamic>{
      'recommendation_type': type,
      'message': (recommendation['message'] ?? '').toString(),
      'priority': (recommendation['priority'] ?? 'medium').toString(),
      'target_route': route,
      'book_folder_id': recommendation['book_folder_id'],
      'unit_folder_id': recommendation['unit_folder_id'],
      'problem_set_id': recommendation['problem_set_id'],
      'analysis_record_id': recommendation['analysis_record_id'],
    };

    final res = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'recommendation assign failed ${res.statusCode}: ${res.body}',
      );
    }

    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }
}
