import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // 약점 TOP
  static Future<List<dynamic>> fetchWeakTop(int userId, {int limit = 3}) async {
    final url = Uri.parse(
        '$baseUrl/study-reports/weak-top?user_id=$userId&limit=$limit');
    final res = await http.get(url);
    if (res.statusCode != 200) throw Exception('Failed to load weak types');
    return json.decode(res.body)['weak_types'];
  }

  // 개념 조회 (없으면 서버에서 자동 생성)
  static Future<Map<String, dynamic>> fetchConcept(String errorType) async {
    final url =
        Uri.parse('$baseUrl/concepts/by-error-type?error_type=$errorType');
    final res = await http.get(url);
    if (res.statusCode != 200) throw Exception('Failed to load concept');
    return json.decode(res.body);
  }

  // 특정 개념 기반 추천 문제
  static Future<Map<String, dynamic>> fetchRecommendedQuestions({
    required int userId,
    required String errorType,
  }) async {
    final url = Uri.parse(
      '$baseUrl/student/exams/recommend?user_id=$userId&error_type=$errorType',
    );
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('추천 문제 로드 실패');
    }
    return json.decode(res.body);
  }
}
