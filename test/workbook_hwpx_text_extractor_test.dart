import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:english_analyzer_app/utils/workbook_hwpx_text_extractor.dart';

void main() {
  test('extracts HWPX section paragraphs in section order', () {
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          'Contents/section1.xml',
          _sectionXml(['Unit 2 No. 1', '1. Second statement.']),
        ),
      )
      ..addFile(
        ArchiveFile.string(
          'Contents/section0.xml',
          _sectionXml([
            'Unit 2 Gateway [정답] FTTTT',
            '1. First statement.',
          ]),
        ),
      );
    final bytes = ZipEncoder().encode(archive);

    final result = extractWorkbookTextFromHwpx(bytes);

    expect(result.sectionCount, 2);
    expect(result.paragraphCount, 4);
    expect(
      result.text.indexOf('Unit 2 Gateway'),
      lessThan(result.text.indexOf('Unit 2 No. 1')),
    );
    expect(result.text, contains('1. First statement.'));
    expect(result.text, contains('1. Second statement.'));
  });

  test('rejects bytes that are not an HWPX zip', () {
    expect(
      () => extractWorkbookTextFromHwpx([1, 2, 3, 4]),
      throwsFormatException,
    );
  });
}

String _sectionXml(List<String> paragraphs) {
  final body = paragraphs
      .map((text) => '<hp:p><hp:run><hp:t>$text</hp:t></hp:run></hp:p>')
      .join();
  return '<?xml version="1.0" encoding="UTF-8"?>'
      '<hp:sec xmlns:hp="http://www.hancom.co.kr/hwpml/2011/paragraph">'
      '$body</hp:sec>';
}
