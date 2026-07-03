import 'package:english_analyzer_app/models/vocabulary.dart';
import 'package:english_analyzer_app/utils/vocabulary_learning_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats multiple meanings for display without changing raw data', () {
    expect(
      displayVocabularyMeaning('감사하다, 고마워하다'),
      '감사하다 · 고마워하다',
    );
    expect(displayVocabularyMeaning('환급, 환불'), '환급 · 환불');
    expect(displayVocabularyMeaning('분리된 / 별도의'), '분리된 · 별도의');
  });

  test('builds 20-word learning ranges for 84 items', () {
    final ranges = buildVocabularyLearningRanges(84);

    expect(ranges.map((range) => range.label), [
      '전체',
      '1세트',
      '2세트',
      '3세트',
      '4세트',
      '5세트',
    ]);
    expect(ranges.map((range) => range.rangeLabel), [
      '전체 84단어',
      '1~20',
      '21~40',
      '41~60',
      '61~80',
      '81~84',
    ]);
    expect(ranges.map((range) => range.count), [84, 20, 20, 20, 20, 4]);
  });

  test('groups vocabulary items by label and keeps unclassified items', () {
    const items = [
      VocabularyItem(
        id: 1,
        word: 'foundation',
        meaningKo: '재단',
        groupLabel: 'Unit 1 Gateway',
      ),
      VocabularyItem(
        id: 2,
        word: 'exhibition',
        meaningKo: '전시회',
        groupLabel: 'Unit 1 Gateway',
      ),
      VocabularyItem(
        id: 3,
        word: 'recently',
        meaningKo: '최근에',
        groupLabel: 'Unit 1 No. 1',
      ),
      VocabularyItem(id: 4, word: 'goal', meaningKo: '목표'),
    ];

    final groups = buildVocabularyLearningGroups(items);

    expect(groups.map((group) => group.label), [
      'Unit 1 Gateway',
      'Unit 1 No. 1',
      '미분류',
    ]);
    expect(groups.map((group) => group.count), [2, 1, 1]);
    expect(hasVocabularyGroups(items), isTrue);
  });
}
