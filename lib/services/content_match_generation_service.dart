import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../config/auth_store.dart';
import '../models/content_match_generation_models.dart';

abstract class ContentMatchGenerationGateway {
  Future<JsonMap> analyzePassage(String passage);

  Future<ContentMatchCandidatesResult> fetchCandidates({
    required JsonMap semantic,
    required String questionMode,
  });

  Future<ContentMatchGeneratedQuestion> generate({
    required JsonMap semantic,
    required ContentMatchGenerationTarget target,
  });

  Future<ContentMatchSaveResult> saveProblemSet({
    required String name,
    required String passage,
    required ContentMatchGeneratedQuestion question,
  });
}

class ContentMatchGenerationException implements Exception {
  const ContentMatchGenerationException({
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

class HttpContentMatchGenerationService
    implements ContentMatchGenerationGateway {
  HttpContentMatchGenerationService({http.Client? client})
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
  Future<ContentMatchCandidatesResult> fetchCandidates({
    required JsonMap semantic,
    required String questionMode,
  }) async {
    final response = await _post(
      '/question-generation/content-match/candidates',
      {
        'semantic': semantic,
        'options': {
          'min_score': 0.6,
          'max_claims': 10,
          'target_claim_count': 6,
          'question_mode': questionMode,
        },
      },
    );
    return ContentMatchCandidatesResult.fromJson(response);
  }

  @override
  Future<ContentMatchGeneratedQuestion> generate({
    required JsonMap semantic,
    required ContentMatchGenerationTarget target,
  }) async {
    final response = await _post(
      '/question-generation/content-match/generate',
      {
        'semantic': semantic,
        'target': target.raw,
        'options': {
          'choice_count': 6,
          'language': 'ko',
          'max_generation_attempts': 2,
        },
      },
    );
    return ContentMatchGeneratedQuestion.fromJson(response);
  }

  @override
  Future<ContentMatchSaveResult> saveProblemSet({
    required String name,
    required String passage,
    required ContentMatchGeneratedQuestion question,
  }) async {
    final response = await _post('/teacher/problem_sets/import', {
      'name': name,
      'source': 'Semantic Content Match',
      'passage': passage,
      'passage_bracketed': '',
      'questions': const [],
      'semantic_content_matches': [
        {'question_no': 1, 'content_match': question.raw, 'passage': passage},
      ],
    });
    return ContentMatchSaveResult.fromJson(response);
  }

  Future<JsonMap> _post(String path, JsonMap body) async {
    if (!AuthStore.isTeacher) {
      throw const ContentMatchGenerationException(
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
      throw ContentMatchGenerationException(
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
