import 'package:english_analyzer_app/utils/vocabulary_import_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses supported vocabulary paste formats', () {
    final result = parseVocabularyPaste('''
1. goal\t목표
recently    최근에
design, 설계하다
provide 제공하다
grassy (잔디의)
''');

    expect(result.validRows.length, 5);
    expect(result.validRows.map((row) => row.word), contains('goal'));
    expect(
      result.validRows.firstWhere((row) => row.word == 'grassy').meaningKo,
      '잔디의',
    );
  });

  test('warns for duplicate and invalid lines', () {
    final result = parseVocabularyPaste('''
goal 목표
Goal 목표
invalid only english
''');

    expect(result.validRows.length, 2);
    expect(result.warningCount, 2);
    expect(result.rows[1].warning, '중복 단어입니다.');
    expect(result.rows[2].isValid, isFalse);
  });
}
