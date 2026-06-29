import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../config/auth_store.dart';
import '../models/final_touch.dart';
import '../models/final_touch_practice_result.dart';

class FinalTouchPracticeResultService {
  const FinalTouchPracticeResultService();

  Future<FinalTouchPracticeResult> saveResult({
    required FinalTouchDetail detail,
    required int totalQuestions,
    required int correctCount,
    required List<String> practicedTypes,
    required List<String> wrongTypes,
  }) async {
    final accuracyRate =
        totalQuestions == 0 ? 0 : (correctCount / totalQuestions * 100);

    final res = await http
        .post(
          ApiConfig.u('/student/final-touch-practice-results'),
          headers: _headers(),
          body: jsonEncode({
            'final_touch_id': detail.id,
            'passage_id': detail.passageId,
            'source_label': detail.source,
            'total_questions': totalQuestions,
            'correct_count': correctCount,
            'accuracy_rate': double.parse(accuracyRate.toStringAsFixed(1)),
            'practiced_types': practicedTypes,
            'wrong_types': wrongTypes,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final decoded = _decode(res);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_errorMessage(decoded, res.statusCode));
    }

    final result = decoded is Map<String, dynamic> ? decoded['result'] : null;
    if (result is! Map) {
      throw Exception('연습 결과 저장 응답이 올바르지 않습니다.');
    }
    return FinalTouchPracticeResult.fromJson(
      Map<String, dynamic>.from(result),
    );
  }

  Future<FinalTouchPracticeResult?> fetchLatest(int finalTouchId) async {
    final res = await http
        .get(
          ApiConfig.u(
            '/student/final-touch-practice-results/latest/$finalTouchId',
          ),
          headers: _headers(),
        )
        .timeout(const Duration(seconds: 20));

    final decoded = _decode(res);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_errorMessage(decoded, res.statusCode));
    }

    final result = decoded is Map<String, dynamic> ? decoded['result'] : null;
    if (result == null) return null;
    if (result is! Map) {
      throw Exception('최근 연습 결과 응답이 올바르지 않습니다.');
    }
    return FinalTouchPracticeResult.fromJson(
      Map<String, dynamic>.from(result),
    );
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      if (AuthStore.accessToken != null)
        'Authorization': 'Bearer ${AuthStore.accessToken}',
    };
  }

  dynamic _decode(http.Response res) {
    if (res.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      return utf8.decode(res.bodyBytes);
    }
  }

  String _errorMessage(dynamic decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      final detail = decoded['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return '연습 결과 요청 실패 $statusCode: $detail';
      }
      if (detail != null) {
        return '연습 결과 요청 실패 $statusCode: $detail';
      }
    }
    if (decoded is String && decoded.trim().isNotEmpty) {
      return '연습 결과 요청 실패 $statusCode: $decoded';
    }
    return '연습 결과 요청 실패 $statusCode';
  }
}
