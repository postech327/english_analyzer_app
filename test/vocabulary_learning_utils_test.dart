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
}
