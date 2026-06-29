import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../models/workbook.dart';
import 'auth_service.dart';

class WorkbookService {
  const WorkbookService();

  Future<List<Workbook>> fetchWorkbooks({String? status}) async {
    final query = <String, String>{};
    if (status != null && status.isNotEmpty && status != 'all') {
      query['status'] = status;
    }
    final uri = ApiConfig.u('/teacher/workbooks')
        .replace(queryParameters: query.isEmpty ? null : query);
    final decoded = await _get(uri);
    final items = decoded is Map<String, dynamic> ? decoded['items'] : decoded;
    return Workbook.listFromJson(items);
  }

  Future<Workbook> fetchWorkbook(int id, {int? sectionId}) async {
    final query = <String, String>{};
    if (sectionId != null) query['section_id'] = '$sectionId';
    final uri = ApiConfig.u('/teacher/workbooks/$id')
        .replace(queryParameters: query.isEmpty ? null : query);
    final decoded = await _get(uri);
    return Workbook.fromJson(decoded as Map<String, dynamic>);
  }

  Future<Workbook> fetchStudentWorkbook(int id, {int? sectionId}) async {
    final query = <String, String>{};
    if (sectionId != null) query['section_id'] = '$sectionId';
    final uri = ApiConfig.u('/student/workbooks/$id')
        .replace(queryParameters: query.isEmpty ? null : query);
    final decoded = await _get(uri);
    return Workbook.fromJson(decoded as Map<String, dynamic>);
  }

  Future<Workbook> createWorkbook({
    required String title,
    String? description,
    String? sourceLabel,
    String? folderName,
    String? unitLabel,
    int? finalTouchId,
  }) async {
    final body = {
      'title': title,
      if (_hasText(description)) 'description': description!.trim(),
      if (_hasText(sourceLabel)) 'source_label': sourceLabel!.trim(),
      if (_hasText(folderName)) 'folder_name': folderName!.trim(),
      if (_hasText(unitLabel)) 'unit_label': unitLabel!.trim(),
      if (finalTouchId != null) 'final_touch_id': finalTouchId,
    };
    final decoded = await _send(
      'POST',
      ApiConfig.u('/teacher/workbooks'),
      body: body,
    );
    return Workbook.fromJson(decoded as Map<String, dynamic>);
  }

  Future<Workbook> updateWorkbook(
    int id, {
    String? title,
    String? description,
    String? sourceLabel,
    String? folderName,
    String? unitLabel,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (sourceLabel != null) body['source_label'] = sourceLabel;
    if (folderName != null) body['folder_name'] = folderName;
    if (unitLabel != null) body['unit_label'] = unitLabel;
    if (status != null) body['status'] = status;
    final decoded = await _send(
      'PATCH',
      ApiConfig.u('/teacher/workbooks/$id'),
      body: body,
    );
    return Workbook.fromJson(decoded as Map<String, dynamic>);
  }

  Future<Workbook> archiveWorkbook(int id) async {
    final decoded = await _send(
      'PATCH',
      ApiConfig.u('/teacher/workbooks/$id/archive'),
    );
    return Workbook.fromJson(decoded as Map<String, dynamic>);
  }

  Future<void> deleteWorkbook(int id) async {
    await _send(
      'DELETE',
      ApiConfig.u('/teacher/workbooks/$id'),
    );
  }

  Future<List<WorkbookSection>> fetchWorkbookSections(int workbookId) async {
    final decoded =
        await _get(ApiConfig.u('/teacher/workbooks/$workbookId/sections'));
    final items = decoded is Map<String, dynamic> ? decoded['items'] : decoded;
    return WorkbookSection.listFromJson(items);
  }

  Future<WorkbookSection> createWorkbookSection(
    int workbookId, {
    required String title,
    String? sourceLabel,
    String? unitLabel,
    String? sectionKey,
    int? sortOrder,
  }) async {
    final decoded = await _send(
      'POST',
      ApiConfig.u('/teacher/workbooks/$workbookId/sections'),
      body: {
        'title': title,
        if (_hasText(sourceLabel)) 'source_label': sourceLabel!.trim(),
        if (_hasText(unitLabel)) 'unit_label': unitLabel!.trim(),
        if (_hasText(sectionKey)) 'section_key': sectionKey!.trim(),
        if (sortOrder != null) 'sort_order': sortOrder,
      },
    );
    return WorkbookSection.fromJson(decoded as Map<String, dynamic>);
  }

  Future<WorkbookSection> updateWorkbookSection(
    int workbookId,
    int sectionId, {
    String? title,
    String? sourceLabel,
    String? unitLabel,
    String? sectionKey,
    int? sortOrder,
  }) async {
    final decoded = await _send(
      'PATCH',
      ApiConfig.u('/teacher/workbooks/$workbookId/sections/$sectionId'),
      body: {
        if (title != null) 'title': title,
        if (sourceLabel != null) 'source_label': sourceLabel,
        if (unitLabel != null) 'unit_label': unitLabel,
        if (sectionKey != null) 'section_key': sectionKey,
        if (sortOrder != null) 'sort_order': sortOrder,
      },
    );
    return WorkbookSection.fromJson(decoded as Map<String, dynamic>);
  }

  Future<void> deleteWorkbookSection(int workbookId, int sectionId) async {
    await _send(
      'DELETE',
      ApiConfig.u('/teacher/workbooks/$workbookId/sections/$sectionId'),
    );
  }

  Future<WorkbookQuestion> createQuestion({
    required int workbookId,
    required String questionType,
    required String prompt,
    int? sectionId,
    String? sectionKey,
    String? sectionTitle,
    String? passageText,
    List<String>? choices,
    required Map<String, dynamic> answer,
    String? explanation,
    int points = 1,
  }) async {
    final decoded = await _send(
      'POST',
      ApiConfig.u('/teacher/workbooks/$workbookId/questions'),
      body: _questionBody(
        questionType: questionType,
        prompt: prompt,
        sectionId: sectionId,
        sectionKey: sectionKey,
        sectionTitle: sectionTitle,
        passageText: passageText,
        choices: choices,
        answer: answer,
        explanation: explanation,
        points: points,
      ),
    );
    return WorkbookQuestion.fromJson(decoded as Map<String, dynamic>);
  }

  Future<WorkbookQuestion> updateQuestion({
    required int workbookId,
    required int questionId,
    required String questionType,
    required String prompt,
    int? sectionId,
    String? sectionKey,
    String? sectionTitle,
    String? passageText,
    List<String>? choices,
    required Map<String, dynamic> answer,
    String? explanation,
    int points = 1,
  }) async {
    final decoded = await _send(
      'PATCH',
      ApiConfig.u('/teacher/workbooks/$workbookId/questions/$questionId'),
      body: _questionBody(
        questionType: questionType,
        prompt: prompt,
        sectionId: sectionId,
        sectionKey: sectionKey,
        sectionTitle: sectionTitle,
        passageText: passageText,
        choices: choices,
        answer: answer,
        explanation: explanation,
        points: points,
      )..remove('question_type'),
    );
    return WorkbookQuestion.fromJson(decoded as Map<String, dynamic>);
  }

  Future<void> deleteQuestion({
    required int workbookId,
    required int questionId,
  }) async {
    await _send(
      'DELETE',
      ApiConfig.u('/teacher/workbooks/$workbookId/questions/$questionId'),
    );
  }

  Map<String, dynamic> _questionBody({
    required String questionType,
    required String prompt,
    int? sectionId,
    String? sectionKey,
    String? sectionTitle,
    String? passageText,
    List<String>? choices,
    required Map<String, dynamic> answer,
    String? explanation,
    int points = 1,
  }) {
    return {
      'question_type': questionType,
      'prompt': prompt,
      if (sectionId != null) 'section_id': sectionId,
      if (_hasText(sectionKey)) 'section_key': sectionKey!.trim(),
      if (_hasText(sectionTitle)) 'section_title': sectionTitle!.trim(),
      if (_hasText(passageText)) 'passage_text': passageText!.trim(),
      if (choices != null) 'choices': choices,
      'answer': answer,
      if (_hasText(explanation)) 'explanation': explanation!.trim(),
      'points': points,
    };
  }

  Future<dynamic> _get(Uri uri) async {
    final res = await _requestWithAuth(
      (headers) =>
          http.get(uri, headers: headers).timeout(const Duration(seconds: 20)),
    );
    return _decode(res);
  }

  Future<dynamic> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final encoded = body == null ? null : jsonEncode(body);
    final res = await _requestWithAuth(
      (headers) => switch (method) {
        'POST' => http
            .post(uri, headers: headers, body: encoded)
            .timeout(const Duration(seconds: 20)),
        'PATCH' => http
            .patch(uri, headers: headers, body: encoded)
            .timeout(const Duration(seconds: 20)),
        'DELETE' => http
            .delete(uri, headers: headers, body: encoded)
            .timeout(const Duration(seconds: 20)),
        _ => throw ArgumentError('Unsupported method $method'),
      },
    );
    return _decode(res);
  }

  Future<http.Response> _requestWithAuth(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var response = await request(await _headers());
    if (response.statusCode != 401) return response;

    String? refreshedToken;
    try {
      refreshedToken = await AuthService.instance.refreshAccessToken();
    } catch (_) {
      refreshedToken = null;
    }
    if (refreshedToken == null || refreshedToken.isEmpty) return response;
    response = await request(await _headers());
    return response;
  }

  dynamic _decode(http.Response res) {
    final text = utf8.decode(res.bodyBytes);
    final decoded = text.trim().isEmpty ? null : jsonDecode(text);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      if (res.statusCode == 401) {
        throw Exception('로그인 정보가 만료되었습니다. 다시 로그인해 주세요.');
      }
      final message = decoded is Map && decoded['detail'] != null
          ? decoded['detail'].toString()
          : text;
      throw Exception('워크북 API 오류 ${res.statusCode}: $message');
    }
    return decoded;
  }

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.instance.currentAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}
