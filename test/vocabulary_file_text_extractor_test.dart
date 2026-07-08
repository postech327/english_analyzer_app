import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:english_analyzer_app/utils/vocabulary_file_text_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts UTF-8 vocabulary TXT', () {
    final result = extractVocabularyFileText(
      'words.txt',
      utf8.encode('goal 목표\nrecently 최근에'),
    );

    expect(result.format, 'TXT');
    expect(result.text, contains('goal 목표'));
  });

  test('reuses workbook HWPX text extraction', () {
    final xml = utf8.encode(
      '<hs:sec xmlns:hs="urn:test"><hp:p xmlns:hp="urn:p">'
      '<hp:run><hp:t>goal 목표</hp:t></hp:run></hp:p></hs:sec>',
    );
    final archive = Archive()
      ..addFile(
        ArchiveFile(
          'Contents/section0.xml',
          xml.length,
          xml,
        ),
      );
    final bytes = ZipEncoder().encode(archive)!;
    final result = extractVocabularyFileText('words.hwpx', bytes);

    expect(result.format, 'HWPX');
    expect(result.text, contains('goal 목표'));
    expect(result.sectionCount, 1);
  });

  test('rejects legacy HWP with guidance', () {
    expect(
      () => extractVocabularyFileText('words.hwp', [1, 2, 3]),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('HWPX로 다시 저장'),
        ),
      ),
    );
  });
}
