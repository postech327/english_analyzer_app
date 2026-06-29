import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../config/auth_store.dart';
import '../models/problem_set_result_summary.dart';

class ProblemSetResultApi {
  static Future<List<ProblemSetResultSummary>> fetchResults() async {
    final response = await http.get(
      ApiConfig.u('/student/problem-set-results'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthStore.accessToken}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Problem set results load failed: ${response.statusCode} / ${response.body}',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final items = decoded is List ? decoded : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ProblemSetResultSummary.fromJson)
        .toList();
  }
}
