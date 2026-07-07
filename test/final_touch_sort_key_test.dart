import 'package:english_analyzer_app/models/final_touch.dart';
import 'package:english_analyzer_app/screens/final_touch_list_screen.dart';
import 'package:english_analyzer_app/screens/teacher_final_touch_import_screen.dart';
import 'package:english_analyzer_app/utils/final_touch_sort_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses Unit Gateway and No labels', () {
    final gateway = parseFinalTouchSortKey('Unit 1 Gateway');
    expect(gateway.unitNumber, 1);
    expect(gateway.itemOrder, 0);
    expect(gateway.itemNumber, 0);

    final no1 = parseFinalTouchSortKey('Unit 1 No. 1');
    expect(no1.unitNumber, 1);
    expect(no1.itemOrder, 1);
    expect(no1.itemNumber, 1);

    final no2 = parseFinalTouchSortKey('Unit 01 No. 02');
    expect(no2.unitNumber, 1);
    expect(no2.itemNumber, 2);
  });

  test('parses alternate Lesson and Korean gang labels', () {
    final lesson = parseFinalTouchSortKey('Lesson 1 No. 1');
    expect(lesson.unitNumber, 1);
    expect(lesson.itemNumber, 1);

    final gang = parseFinalTouchSortKey('1강 1번');
    expect(gang.unitNumber, 1);
    expect(gang.itemNumber, 1);

    final gateway = parseFinalTouchSortKey('2강 Gateway');
    expect(gateway.unitNumber, 2);
    expect(gateway.itemOrder, 0);
  });

  test('sorts Final Touch labels in natural Unit and No order', () {
    final input = [
      'Unit 2 No. 2',
      'Unit 1 No. 2',
      'Unit 2 Gateway',
      'Unit 1 Gateway',
      'Unit 1 No. 1',
      'Unit 2 No. 1',
    ];

    final sorted = sortByFinalTouchNaturalOrder<String>(
      input,
      labelOf: (item) => item,
    );

    expect(sorted, [
      'Unit 1 Gateway',
      'Unit 1 No. 1',
      'Unit 1 No. 2',
      'Unit 2 Gateway',
      'Unit 2 No. 1',
      'Unit 2 No. 2',
    ]);
  });

  test('destination label falls back to unfiled', () {
    expect(finalTouchImportDestinationLabel('수특라이트 영어'), '수특라이트 영어');
    expect(finalTouchImportDestinationLabel('  '), '미분류');
    expect(finalTouchImportDestinationLabel(null), '미분류');
  });

  test('import destination uses current book folder when unit is not selected',
      () {
    const bookFolder = FinalTouchFolder(
      id: 12,
      parentId: null,
      name: '수특라이트 영어',
      count: 0,
      hasChildren: true,
      isUnfiled: false,
      isDirectBucket: false,
    );

    final folder = finalTouchActiveImportFolder(
      bookFolder: bookFolder,
      unitFolder: null,
    );

    expect(folder?.id, 12);
    expect(
      finalTouchImportFolderDisplayName(
        bookFolder: bookFolder,
        unitFolder: null,
      ),
      '수특라이트 영어',
    );
  });

  test('direct bucket import displays parent book folder name', () {
    const bookFolder = FinalTouchFolder(
      id: 20,
      parentId: null,
      name: '수특라이트 영독',
      count: 0,
      hasChildren: true,
      isUnfiled: false,
      isDirectBucket: false,
    );
    const directBucket = FinalTouchFolder(
      id: 20,
      parentId: 20,
      name: '직접 저장',
      count: 6,
      hasChildren: false,
      isUnfiled: false,
      isDirectBucket: true,
    );

    expect(
      finalTouchImportFolderDisplayName(
        bookFolder: bookFolder,
        unitFolder: directBucket,
      ),
      '수특라이트 영독',
    );
  });
}
