import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../config/auth_store.dart';
import '../models/student_assigned_problem_set.dart';

class StudentProblemSetAssignmentService {
  const StudentProblemSetAssignmentService();

  Future<List<StudentAssignedProblemSet>> fetchAssignedProblemSets() async {
    final res = await http.get(
      ApiConfig.u('/student/assignments'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        if (AuthStore.accessToken != null)
          'Authorization': 'Bearer ${AuthStore.accessToken}',
      },
    ).timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'assigned problem set load failed ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    return StudentAssignedProblemSet.listFromJson(decoded);
  }
}
