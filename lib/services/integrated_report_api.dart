import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../config/auth_store.dart';
import '../models/integrated_report.dart';

class IntegratedReportApi {
  static Future<IntegratedReport> fetchIntegratedReport() async {
    final response = await http.get(
      ApiConfig.u('/student/problem_sets/integrated-report'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthStore.accessToken}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Integrated report load failed: ${response.statusCode} / ${response.body}',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return IntegratedReport.fromJson(decoded as Map<String, dynamic>);
  }
}
