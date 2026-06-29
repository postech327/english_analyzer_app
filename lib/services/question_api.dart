// lib/services/question_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class QuestionApi {
  static Future<List<dynamic>> generateQuestions(String passage) async {
    final url = ApiConfig.u(ApiConfig.generateBasic);

    print("🔥 요청 URL: $url"); // 디버깅 핵심

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "passage": passage,
        "items": 3, // 🔥 중요
      }),
    );

    print("📡 STATUS: ${response.statusCode}");
    print("📦 BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["questions"];
    } else {
      throw Exception("문제 생성 실패: ${response.body}");
    }
  }
}
