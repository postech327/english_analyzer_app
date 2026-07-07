import 'package:english_analyzer_app/core/subject/subject_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defines supported subject keys and Korean names', () {
    expect(
      SubjectType.values.map((subject) => subject.key),
      ['english', 'korean', 'math', 'science', 'admission'],
    );
    expect(SubjectType.english.koreanName, '영어');
    expect(SubjectType.korean.koreanName, '국어');
    expect(SubjectType.math.koreanName, '수학');
    expect(SubjectType.science.koreanName, '과학');
    expect(SubjectType.admission.koreanName, '한국대학입시컨설팅');
  });

  test('parses subject values safely', () {
    expect(SubjectType.tryParse('math'), SubjectType.math);
    expect(SubjectType.tryParse('SCIENCE'), SubjectType.science);
    expect(SubjectType.tryParse('unknown'), isNull);
    expect(SubjectType.tryParse(null), isNull);
  });
}
