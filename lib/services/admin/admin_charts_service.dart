import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:english_analyzer_app/config/api.dart';

class AdminChartsService {
  static Future<List<dynamic>> fetchWeeklyActivity({int weeks = 8}) async {
    final uri = ApiConfig.u('/admin/charts/weekly?weeks=$weeks');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('주간 차트 조회 실패');
    }

    return jsonDecode(res.body) as List<dynamic>;
  }
}
