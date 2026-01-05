import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class StudentLearningService {
  static Future<List<dynamic>> fetchExamPreview(int problemSetId) async {
    final uri = ApiConfig.u('/student/learning/start/$problemSetId');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('시험지 조회 실패');
    }

    return jsonDecode(res.body) as List<dynamic>;
  }
}
