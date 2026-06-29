import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class QuestionApi {
  static Future<List<dynamic>> generateQuestions(String passage) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/question_maker/generate_basic');

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "passage": passage,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["questions"];
    } else {
      throw Exception("문제 생성 실패: ${response.body}");
    }
  }
}
