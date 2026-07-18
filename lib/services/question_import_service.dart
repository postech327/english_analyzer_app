import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../config/auth_store.dart';
import '../models/problem_set_import_draft.dart';
import '../models/question_import_draft.dart';

class QuestionImportSaveResult {
  const QuestionImportSaveResult({
    required this.problemSetId,
    required this.passageId,
    required this.savedQuestionCount,
    required this.skippedQuestionCount,
    required this.warnings,
  });

  final int problemSetId;
  final int passageId;
  final int savedQuestionCount;
  final int skippedQuestionCount;
  final List<String> warnings;

  factory QuestionImportSaveResult.fromJson(Map<String, dynamic> json) {
    return QuestionImportSaveResult(
      problemSetId: _asInt(json['problem_set_id']),
      passageId: _asInt(json['passage_id']),
      savedQuestionCount: _asInt(json['saved_question_count']),
      skippedQuestionCount: _asInt(json['skipped_question_count']),
      warnings: (json['warnings'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class QuestionImportService {
  const QuestionImportService();

  Future<QuestionImportSaveResult> saveSingleChoiceProblemSet({
    required ProblemSetImportDraft draft,
    required List<QuestionImportDraft> questions,
  }) async {
    final uri = ApiConfig.u('/teacher/problem_sets/import');
    final body = {
      'name': draft.name,
      'source': draft.source,
      'textbook_folder_name': draft.textbookFolderName,
      'unit_folder_name': draft.unitFolderName,
      'passage': draft.passage,
      'passage_bracketed': '',
      'questions':
          questions.map((question) => question.toRequestJson()).toList(),
    };
    debugPrint(
      '[QuestionImportService] save endpoint=$uri questions=${questions.length}',
    );
    for (var index = 0; index < questions.length; index++) {
      final question = questions[index];
      debugPrint(
        '[QuestionImportPayload] index=$index '
        'no=${question.questionNo} '
        'type=${question.questionType} '
        'passage="${_preview(question.passage)}"',
      );
    }
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        if (AuthStore.accessToken != null)
          'Authorization': 'Bearer ${AuthStore.accessToken}',
      },
      body: jsonEncode(body),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('문제 HWPX Import 저장 실패: ${res.statusCode} / ${res.body}');
    }
    return QuestionImportSaveResult.fromJson(
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _preview(String text) {
  final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.length <= 80) return compact;
  return '${compact.substring(0, 80)}...';
}
