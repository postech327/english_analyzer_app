import 'package:english_analyzer_app/utils/workbook_section_label_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('splits Unit number and No detail', () {
    final result = parseWorkbookSectionLabel('Unit 3 No. 1');
    expect(result.sectionTitle, '3강');
    expect(result.sectionKey, 'unit_3');
    expect(result.detailLabel, '1번');
  });

  test('splits Unit number and Gateway detail', () {
    final result = parseWorkbookSectionLabel('Unit 3 Gateway 1');
    expect(result.sectionTitle, '3강');
    expect(result.sectionKey, 'unit_3');
    expect(result.detailLabel, 'Gateway 1');
  });

  test('splits Korean unit and detail', () {
    final result = parseWorkbookSectionLabel('3강 1번');
    expect(result.sectionTitle, '3강');
    expect(result.sectionKey, 'unit_3');
    expect(result.detailLabel, '1번');
  });

  test('uses one Test section and number detail', () {
    final result = parseWorkbookSectionLabel('Test 2');
    expect(result.sectionTitle, 'Test');
    expect(result.sectionKey, 'test');
    expect(result.detailLabel, '2번');
  });

  test('keeps a custom section without a detail', () {
    final result = parseWorkbookSectionLabel('실전 복습');
    expect(result.sectionTitle, '실전 복습');
    expect(result.sectionKey, 'custom_실전_복습');
    expect(result.detailLabel, isNull);
  });

  test('explicit detail overrides embedded detail', () {
    final result = parseWorkbookSectionLabel(
      'Unit 3 No. 1',
      explicitDetailLabel: 'Gateway 2',
    );
    expect(result.sectionTitle, '3강');
    expect(result.detailLabel, 'Gateway 2');
  });
}
