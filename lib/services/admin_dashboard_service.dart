import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:english_analyzer_app/config/api.dart';

class AdminDashboardService {
  /// 📊 대시보드 요약
  static Future<Map<String, dynamic>> fetchOverview() async {
    final uri = ApiConfig.u('/admin/dashboard/overview');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('대시보드 조회 실패');
    }

    return jsonDecode(res.body);
  }

  /// 📊 유형별 정답률
  static Future<List<dynamic>> fetchAccuracyByType({String? week}) async {
    final uri = week == null
        ? ApiConfig.u('/admin/dashboard/by-type')
        : ApiConfig.u('/admin/dashboard/by-type?week=$week');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('유형별 정답률 조회 실패');
    }

    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<List<dynamic>> fetchTypeDetail(String type) async {
    final uri = ApiConfig.u(
      '/admin/dashboard/by-type/detail?type=$type',
    );

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('유형 상세 조회 실패');
    }

    return jsonDecode(res.body) as List<dynamic>;
  }
}
