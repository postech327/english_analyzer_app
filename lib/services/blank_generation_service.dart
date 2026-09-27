import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../config/auth_store.dart';
import '../models/blank_generation_models.dart';

abstract class BlankGenerationGateway {
  Future<JsonMap> analyzePassage(String passage);

  Future<BlankCandidatesResult> fetchCandidates({required JsonMap semantic});

  Future<BlankGeneratedQuestion> generate({
    required JsonMap semantic,
    required BlankGenerationTarget target,
  });

  Future<BlankSaveResult> saveProblemSet({
    required String name,
    required String passage,
    required BlankGeneratedQuestion question,
  });
}

class BlankGenerationException implements Exception {
  const BlankGenerationException({
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

class HttpBlankGenerationService implements BlankGenerationGateway {
  HttpBlankGenerationService({http.Client? client})
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
  Future<BlankCandidatesResult> fetchCandidates({
    required JsonMap semantic,
  }) async {
    final response = await _post('/question-generation/blank/candidates', {
      'semantic': semantic,
      'options': {
        'min_score': 0.6,
        'max_candidates': 10,
        'question_mode': 'blank_inference',
      },
    });
    return BlankCandidatesResult.fromJson(response);
  }

  @override
  Future<BlankGeneratedQuestion> generate({
    required JsonMap semantic,
    required BlankGenerationTarget target,
  }) async {
    final response = await _post('/question-generation/blank/generate', {
      'semantic': semantic,
      'target': target.raw,
      'options': {
        'choice_count': 5,
        'language': 'ko',
        'max_generation_attempts': 2,
      },
    });
    return BlankGeneratedQuestion.fromJson(response);
  }

  @override
  Future<BlankSaveResult> saveProblemSet({
    required String name,
    required String passage,
    required BlankGeneratedQuestion question,
  }) async {
    final response = await _post('/teacher/problem_sets/import', {
      'name': name,
      'source': 'Semantic Blank',
      'passage': passage,
      'passage_bracketed': '',
      'questions': const [],
      'semantic_blanks': [
        {'question_no': 1, 'blank': question.raw},
      ],
    });
    return BlankSaveResult.fromJson(response);
  }

  Future<JsonMap> _post(String path, JsonMap body) async {
    if (!AuthStore.isTeacher) {
      throw const BlankGenerationException(
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
      throw BlankGenerationException(
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
