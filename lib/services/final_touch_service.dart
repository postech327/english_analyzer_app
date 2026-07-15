import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../config/auth_store.dart';
import '../models/final_touch.dart';
import '../models/final_touch_import_draft.dart';

class FinalTouchService {
  const FinalTouchService();

  Future<List<FinalTouchSummary>> fetchFinalTouches({
    int limit = 50,
    int? folderId,
    bool unfiled = false,
  }) async {
    final query = <String, String>{'limit': '$limit'};
    if (folderId != null) query['folder_id'] = '$folderId';
    if (unfiled) query['unfiled'] = 'true';
    final uri =
        ApiConfig.u('/student/final-touches').replace(queryParameters: query);
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Final Touch 목록 로드 실패: ${res.statusCode} / ${res.body}');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final items = decoded is Map<String, dynamic>
        ? decoded['items'] as List? ?? const []
        : decoded is List
            ? decoded
            : const [];

    return items
        .map((item) => FinalTouchSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<FinalTouchFolder>> fetchFolders({int? parentId}) async {
    final query = <String, String>{};
    if (parentId != null) query['parent_id'] = '$parentId';
    final uri = ApiConfig.u('/student/final-touches/folders')
        .replace(queryParameters: query.isEmpty ? null : query);
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Final Touch 폴더 로드 실패: ${res.statusCode} / ${res.body}');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final items = decoded is Map<String, dynamic>
        ? decoded['items'] as List? ?? const []
        : decoded is List
            ? decoded
            : const [];

    return items
        .map((item) => FinalTouchFolder.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<FinalTouchDetail> fetchFinalTouch(int id) async {
    final uri = ApiConfig.u('/student/final-touches/$id');
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Final Touch 상세 로드 실패: ${res.statusCode} / ${res.body}');
    }

    return FinalTouchDetail.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<int> createFromImport(
    FinalTouchImportDraft draft, {
    int? folderId,
    String? textbookFolderName,
    String? unitFolderName,
    String? folderName,
  }) async {
    final uri = ApiConfig.u('/analysis-records');
    final payload = draft.toRequestJson(
      folderId: folderId,
      textbookFolderName: textbookFolderName,
      unitFolderName: unitFolderName,
      folderName: folderName,
    );
    if (kDebugMode) {
      final tracePayload = <String, dynamic>{
        ...payload,
        'passage': '(${(payload['passage'] ?? '').toString().length} chars)',
        'passage_bracketed':
            '(${(payload['passage_bracketed'] ?? '').toString().length} chars)',
        'translation_bracketed':
            '(${(payload['translation_bracketed'] ?? '').toString().length} chars)',
        'sentence_details':
            '${(payload['sentence_details'] as List?)?.length ?? 0} items',
      };
      debugPrint(
        '[FinalTouchImport] POST $uri payload=${jsonEncode(tracePayload)}',
        wrapWidth: 1024,
      );
    }
    final res = await http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Final Touch 저장 실패: ${res.statusCode} / ${res.body}');
    }
    final decoded =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final record = decoded['analysis_record'] as Map<String, dynamic>?;
    return int.tryParse('${record?['id'] ?? decoded['id']}') ?? 0;
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      if (AuthStore.accessToken != null)
        'Authorization': 'Bearer ${AuthStore.accessToken}',
    };
  }
}
