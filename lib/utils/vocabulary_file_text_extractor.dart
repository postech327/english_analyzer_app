import 'dart:convert';

import 'workbook_hwpx_text_extractor.dart';

const int vocabularyImportMaxBytes = 30 * 1024 * 1024;

class VocabularyFileTextResult {
  const VocabularyFileTextResult({
    required this.text,
    required this.format,
    this.sectionCount,
  });

  final String text;
  final String format;
  final int? sectionCount;
}

VocabularyFileTextResult extractVocabularyFileText(
  String fileName,
  List<int> bytes,
) {
  if (bytes.length > vocabularyImportMaxBytes) {
    throw const FormatException('파일 크기는 30MB 이하여야 합니다.');
  }
  final lowerName = fileName.toLowerCase();
  if (lowerName.endsWith('.hwp')) {
    throw const FormatException(
      '구형 .hwp 파일은 한글에서 HWPX로 다시 저장한 뒤 가져와 주세요.',
    );
  }
  if (lowerName.endsWith('.hwpx')) {
    final extracted = extractWorkbookTextFromHwpx(bytes);
    return VocabularyFileTextResult(
      text: extracted.text,
      format: 'HWPX',
      sectionCount: extracted.sectionCount,
    );
  }
  if (lowerName.endsWith('.txt')) {
    final text = utf8.decode(bytes, allowMalformed: false).trim();
    if (text.isEmpty) {
      throw const FormatException('TXT 파일에 텍스트가 없습니다.');
    }
    return VocabularyFileTextResult(text: text, format: 'TXT');
  }
  throw const FormatException('HWPX 또는 TXT 파일만 가져올 수 있습니다.');
}
