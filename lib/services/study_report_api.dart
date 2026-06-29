import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/study_report.dart';

class StudyReportApi {
  static const _baseUrl = 'http://127.0.0.1:8000';

  static Future<List<StudyReport>> fetchReports(int userId) async {
    final url = Uri.parse('$_baseUrl/student/reports?user_id=$userId');
    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception('학습 리포트 불러오기 실패');
    }

    final List data = jsonDecode(res.body);
    return data.map((e) => StudyReport.fromJson(e)).toList();
  }
}
