import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../config/auth_store.dart';
import '../models/order_generation_models.dart';

abstract class OrderGenerationGateway {
  Future<JsonMap> analyzePassage(String passage);

  Future<OrderCandidatesResult> fetchCandidates({required JsonMap semantic});

  Future<OrderGeneratedQuestion> generate({
    required JsonMap semantic,
    required OrderGenerationTarget target,
  });

  Future<OrderSaveResult> saveProblemSet({
    required String name,
    required String passage,
    required OrderGeneratedQuestion question,
  });
}

class OrderGenerationException implements Exception {
  const OrderGenerationException({
    required this.code,
    required this.message,
    required this.statusCode,
  });

  final String code;
  final String message;
  final int statusCode;

  @override
  String toString() => '$code: $message';
}

class HttpOrderGenerationService implements OrderGenerationGateway {
  HttpOrderGenerationService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<JsonMap> analyzePassage(String passage) async {
    final response = await _post('/semantic/analyze', {
      'text': passage,
      'source': {'source_type': 'direct'},
      'options': {
        'language': 'en',
        'include_korean': true,
        'force_reanalyze': false,
      },
    });
    return _asMap(response['data']);
  }

  @override
  Future<OrderCandidatesResult> fetchCandidates({
    required JsonMap semantic,
  }) async {
    final response = await _post('/question-generation/order/candidates', {
      'semantic': semantic,
      'options': {
        'block_count': 3,
        'min_score': 0.6,
        'max_candidates': 5,
        'question_mode': 'three_block_order',
      },
    });
    return OrderCandidatesResult.fromJson(response);
  }

  @override
  Future<OrderGeneratedQuestion> generate({
    required JsonMap semantic,
    required OrderGenerationTarget target,
  }) async {
    final response = await _post('/question-generation/order/generate', {
      'semantic': semantic,
      'target': target.raw,
      'options': {'choice_count': 5, 'language': 'ko', 'random_seed': 0},
    });
    return OrderGeneratedQuestion.fromJson(response);
  }

  @override
  Future<OrderSaveResult> saveProblemSet({
    required String name,
    required String passage,
    required OrderGeneratedQuestion question,
  }) async {
    final response = await _post('/teacher/problem_sets/import', {
      'name': name,
      'source': 'Semantic Order',
      'passage': passage,
      'passage_bracketed': '',
      'questions': const [],
      'semantic_orders': [
        {'question_no': 1, 'order': question.raw},
      ],
    });
    return OrderSaveResult.fromJson(response);
  }

  Future<JsonMap> _post(String path, JsonMap body) async {
    if (!AuthStore.isTeacher) {
      throw const OrderGenerationException(
        code: 'TEACHER_REQUIRED',
        message: '교사 계정으로 로그인해 주세요.',
        statusCode: 403,
      );
    }
    final response = await _client.post(
      ApiConfig.u(path),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        if (AuthStore.accessToken != null)
          'Authorization': 'Bearer ${AuthStore.accessToken}',
      },
      body: jsonEncode(body),
    );
    final decoded = _decode(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = _asMap(decoded['error']);
      final detail = decoded['detail'];
      final detailMap = _asMap(detail);
      final detailText = detail is String ? detail : '';
      final code = (error['code'] ?? detailMap['code'] ?? _codeFrom(detailText))
          .toString();
      throw OrderGenerationException(
        code: code.isEmpty ? 'HTTP_${response.statusCode}' : code,
        message:
            (error['message'] ??
                    detailMap['message'] ??
                    (detailText.isEmpty ? null : detailText) ??
                    decoded['message'] ??
                    '요청을 처리하지 못했습니다.')
                .toString(),
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }
}

String _codeFrom(String detail) {
  final match = RegExp(r'([A-Z][A-Z0-9_]+)').firstMatch(detail);
  return match?.group(1) ?? '';
}

JsonMap _decode(List<int> bytes) {
  if (bytes.isEmpty) return <String, dynamic>{};
  return _asMap(jsonDecode(utf8.decode(bytes)));
}

JsonMap _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}
