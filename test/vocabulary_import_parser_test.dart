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

  test('keeps all Korean meanings after the first Korean character', () {
    final result = parseVocabularyPaste('''
appreciate 감사하다, 고마워하다
refund 환급, 환불
boarding gate 탑승구
mining industry 광업
''');

    expect(result.savableRows.map((row) => row.word), [
      'appreciate',
      'refund',
      'boarding gate',
      'mining industry',
    ]);
    expect(result.savableRows.map((row) => row.meaningKo), [
      '감사하다, 고마워하다',
      '환급, 환불',
      '탑승구',
      '광업',
    ]);
  });

  test('assigns Unit and Gateway headers to following vocabulary rows', () {
    final result = parseVocabularyPaste('''
Unit 1 Gateway
foundation 재단
exhibition 전시회

Unit 1 No. 1
recently 최근에
design 설계하다

Unit 1 Gateway 2
provide 제공하다
''');

    expect(result.savableRows.map((row) => row.groupLabel), [
      'Unit 1 Gateway',
      'Unit 1 Gateway',
      'Unit 1 No. 1',
      'Unit 1 No. 1',
      'Unit 1 Gateway 2',
    ]);
    expect(result.savableRows.last.groupKey, 'unit_1_gateway_2');
  });

  test('supports Korean lesson and chapter-style group headers', () {
    final result = parseVocabularyPaste('''
1강
goal 목표
제2강
recently 최근에
Chapter 3
design 설계하다
Lesson 4
provide 제공하다
Day 5
ensure 보장하다
Test 6
submit 제출하다
''');

    expect(result.savableRows.map((row) => row.groupLabel), [
      '1강',
      '제2강',
      'Chapter 3',
      'Lesson 4',
      'Day 5',
      'Test 6',
    ]);
    expect(result.savableRows[0].groupKey, 'unit_1');
    expect(result.savableRows[1].groupKey, 'unit_2');
  });

  test('normalizes zero-padded Korean lesson keys', () {
    final result = parseVocabularyPaste('''
01강
goal 목표
''');

    expect(result.savableRows.single.groupLabel, '01강');
    expect(result.savableRows.single.groupKey, 'unit_1');
  });
}
