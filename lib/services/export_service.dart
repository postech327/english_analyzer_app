// lib/services/export_service.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'package:file_saver/file_saver.dart'; // 웹 저장
import 'package:open_filex/open_filex.dart'; // 저장 후 열기 (모바일/데스크톱)
import 'package:path_provider/path_provider.dart'; // 저장 경로 (모바일/데스크톱)
import 'package:universal_io/io.dart' as io; // File/Directory(웹 호환 안전)

// -----------------------------------------------------------------------------
// ExportService: FastAPI의 /export/ppt 호출 → PPT 파일 저장(Web/모바일/데스크톱)
// -----------------------------------------------------------------------------
class ExportService {
  final String baseUrl;
  ExportService(this.baseUrl);

  /// PPT 내보내기
  ///
  /// 성공 시:
  ///  - Web: 저장된 파일명(확장자 제외)을 반환
  ///  - 모바일/데스크톱: 저장된 전체 경로를 반환
  Future<String?> downloadPpt({
    required String passage,
    String? passageBracketed,
    String? dateStr,
    int maxWords = 12,
    String? filename, // ✅ 여기! (fileName 말고 filename로)
  }) async {
    final String safeName = filename ??
        'analysis_${DateTime.now().toIso8601String().replaceAll(":", "-")}';
    const String ext = 'pptx';

    try {
      final uri = Uri.parse('$baseUrl/export/ppt');

      final body = jsonEncode({
        'passage': passage,
        if (passageBracketed != null && passageBracketed.trim().isNotEmpty)
          'passage_bracketed': passageBracketed,
        if (dateStr != null && dateStr.trim().isNotEmpty) 'date_str': dateStr,
        'max_words': maxWords,
      });

      final res = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              // 응답은 PPT 바이너리이므로 Accept는 생략해도 되지만 남겨놔도 무방
              'Accept':
                  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 60));

      if (res.statusCode != 200) {
        // 서버가 JSON 에러 바디를 돌려줄 수 있으니 메시지 추출 시도
        String msg = 'HTTP ${res.statusCode}';
        try {
          final m = jsonDecode(utf8.decode(res.bodyBytes));
          if (m is Map && m['detail'] != null) msg = m['detail'].toString();
        } catch (_) {
          // 무시: 바이너리/기타 포맷일 수 있음
        }
        throw Exception('Export PPT failed: $msg');
      }

      final Uint8List bytes = Uint8List.fromList(res.bodyBytes);

      if (kIsWeb) {
        // -------------------- Web: FileSaver 사용 --------------------
        await FileSaver.instance.saveFile(
          name: safeName, // 확장자는 ext 옵션으로 붙음
          bytes: bytes,
          ext: ext,
          // PowerPoint는 커스텀 MIME 지정 필요
          mimeType: MimeType.other,
          customMimeType:
              'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        );
        // 웹은 로컬 경로 개념이 없어 파일명만 반환
        return '$safeName.$ext';
      } else {
        // --------------- 모바일/데스크톱: 로컬 경로에 저장 후 열기 ---------------
        final dir = await getApplicationDocumentsDirectory();
        final savePath = '${dir.path}/$safeName'; // ✅

        final file = io.File(savePath);
        await file.writeAsBytes(bytes, flush: true);

        // 저장 후 바로 열기
        await OpenFilex.open(savePath);

        return savePath;
      }
    } catch (e) {
      // 필요 시 로깅
      rethrow;
    }
  }
}
