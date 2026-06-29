import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/auth_store.dart';

class DashboardService {
  static const String baseUrl =
      String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:8000');

  static Future<Map<String, dynamic>> fetchDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/dashboard'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AuthStore.accessToken}",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load dashboard");
    }
  }
}
