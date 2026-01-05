import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:english_analyzer_app/config/api.dart';

class TeacherProblemSetService {
  /// ✅ 문제 세트 저장
  /// 성공 시 problem_set_id 반환
  static Future<int> saveProblemSet({
    required int analysisId,
    required String questionType,
    required String name,
    String? description,
    String createdBy = 'teacher',
    List<String>? typesJson,
    String mode = 'teacher',
    bool isPublished = false,
    required List<Map<String, dynamic>> items,
  }) async {
    // ✅ 핵심 수정 포인트 (ApiConfig.u() 사용 ❌)
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/teacher/problem_sets',
    );

    final body = <String, dynamic>{
      'analysis_id': analysisId,
      'question_type': questionType,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'types_json': typesJson ?? [questionType],
      'mode': mode,
      'is_published': isPublished,
      'items': items,
    };

    // 🔍 디버깅 로그 (매우 중요)
    print('📦 POST /teacher/problem_sets');
    print('➡️ URI: $uri');
    print('➡️ BODY: ${jsonEncode(body)}');

    try {
      final res = await http.post(
        uri,
        headers: const {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('📡 STATUS: ${res.statusCode}');
      print('📡 RESPONSE: ${res.body}');

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('❌ save failed ${res.statusCode}: ${res.body}');
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (!data.containsKey('problem_set_id')) {
        throw Exception('❌ response missing problem_set_id: $data');
      }

      return (data['problem_set_id'] as num).toInt();
    } catch (e) {
      // 🔥 여기로 오면 대부분 CORS / URI 문제
      throw Exception('❌ HTTP POST error: $e');
    }
  }

  /// ✅ 문제 세트 미리보기 조회
  static Future<Map<String, dynamic>> fetchProblemSet(int problemSetId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/teacher/problem_sets/$problemSetId',
    );

    print('📦 GET /teacher/problem_sets/$problemSetId');
    print('➡️ URI: $uri');

    try {
      final res = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );

      print('📡 STATUS: ${res.statusCode}');
      print('📡 RESPONSE: ${res.body}');

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('❌ fetch failed ${res.statusCode}: ${res.body}');
      }

      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('❌ HTTP GET error: $e');
    }
  }
}
