import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../config/auth_store.dart';
import '../models/correction_generation_models.dart';

abstract class CorrectionGenerationGateway {
  Future<JsonMap> analyzePassage(String passage);

  Future<CorrectionCandidatesResult> fetchCandidates({
    required JsonMap semantic,
    int limit = 5,
  });

  Future<CorrectionGeneratedQuestion> generate({
    required JsonMap semantic,
    required CorrectionCandidate target,
  });

  Future<CorrectionSaveResult> saveProblemSet({
    required String name,
    required String passage,
    required CorrectionGeneratedQuestion question,
  });
}

class CorrectionGenerationException implements Exception {
  const CorrectionGenerationException({
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

class HttpCorrectionGenerationService implements CorrectionGenerationGateway {
  HttpCorrectionGenerationService({http.Client? client})
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
  Future<CorrectionCandidatesResult> fetchCandidates({
    required JsonMap semantic,
    int limit = 5,
  }) async {
    final response = await _post('/question-generation/correction/candidates', {
      'semantic': semantic,
      'limit': limit,
    });
    return CorrectionCandidatesResult.fromJson(response);
  }

  @override
  Future<CorrectionGeneratedQuestion> generate({
    required JsonMap semantic,
    required CorrectionCandidate target,
  }) async {
    final response = await _post('/question-generation/correction/generate', {
      'semantic': semantic,
      'target': target.raw,
      'options': {'marker_count': 5, 'language': 'ko'},
    });
    return CorrectionGeneratedQuestion.fromJson(response);
  }

  @override
  Future<CorrectionSaveResult> saveProblemSet({
    required String name,
    required String passage,
    required CorrectionGeneratedQuestion question,
  }) async {
    final response = await _post('/teacher/problem_sets/import', {
      'name': name,
      'source': 'Semantic Correction',
      'passage': passage,
      'passage_bracketed': '',
      'questions': const [],
      'semantic_corrections': [
        {'question_no': 1, 'correction': question.raw},
      ],
    });
    return CorrectionSaveResult.fromJson(response);
  }

  Future<JsonMap> _post(String path, JsonMap body) async {
    if (!AuthStore.isTeacher) {
      throw const CorrectionGenerationException(
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
      final detail = _asMap(decoded['detail']);
      throw CorrectionGenerationException(
        code: (error['code'] ?? detail['code'] ?? 'HTTP_${response.statusCode}')
            .toString(),
        message: (error['message'] ??
                detail['message'] ??
                decoded['message'] ??
                '요청을 처리하지 못했습니다.')
            .toString(),
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }
}

JsonMap _decode(List<int> bytes) {
  if (bytes.isEmpty) return <String, dynamic>{};
  final value = jsonDecode(utf8.decode(bytes));
  return _asMap(value);
}

JsonMap _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}
