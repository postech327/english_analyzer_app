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
□ ensure 보장하다
''');

    expect(result.validRows.length, 6);
    expect(result.validRows.map((row) => row.word), contains('goal'));
    expect(
      result.validRows.firstWhere((row) => row.word == 'grassy').meaningKo,
      '잔디의',
    );
    expect(result.validRows.any((row) => row.word == 'ensure'), isTrue);
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

  test('removes promotional preamble before a Unit header', () {
    final cleanup = trimVocabularyPreamble('''
cafe.naver.com/jugis
instagram.com/jugis_official
본 자료는 내신과 수능의 완벽한 대비를 위해 제작되었습니다.
선택형

Unit 1 Gateway
□ foundation 재단
□ exhibition 전시회
□ document 문서
''');
    final result = parseVocabularyPaste(cleanup.text);

    expect(cleanup.removedLineCount, 4);
    expect(cleanup.startHeader, 'Unit 1 Gateway');
    expect(result.savableRows.map((row) => row.word), [
      'foundation',
      'exhibition',
      'document',
    ]);
  });

  test('supports Unit No and Korean lesson start headers', () {
    final unitResult = parseVocabularyPaste('''
수능특강 Light 영어
교육 현장에서 활용하세요.
Unit 1 No. 1
□ recently 최근에
□ design 설계하다
''');
    final lessonResult = parseVocabularyPaste('''
교재 소개문
자료 설명문
1강
goal 목표
provide 제공하다
''');

    expect(unitResult.savableRows.map((row) => row.word), [
      'recently',
      'design',
    ]);
    expect(lessonResult.savableRows.map((row) => row.word), [
      'goal',
      'provide',
    ]);
  });

  test('keeps a headerless vocabulary list unchanged', () {
    final cleanup = trimVocabularyPreamble('goal 목표\nrecently 최근에');
    final result = parseVocabularyPaste(cleanup.text);

    expect(cleanup.removedLineCount, 0);
    expect(cleanup.startHeader, isNull);
    expect(result.savableRows.length, 2);
  });
}
