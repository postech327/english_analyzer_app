import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:english_analyzer_app/config/api.dart';

class RecommendationService {
  static Future<List<dynamic>> fetchWeakTypes(int userId) async {
    final uri = ApiConfig.u('/recommendation/students/$userId/weak-types');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('추천 약점 유형 조회 실패');
    }

    final decoded = jsonDecode(res.body);
    return decoded['weak_types'] as List<dynamic>;
  }
}
