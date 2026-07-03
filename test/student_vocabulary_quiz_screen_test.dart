import 'package:english_analyzer_app/models/vocabulary.dart';
import 'package:english_analyzer_app/screens/student_vocabulary_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('quiz keeps the word card clean and formats multiple meanings',
      (tester) async {
    const items = [
      VocabularyItem(
        id: 1,
        word: 'appreciate',
        meaningKo: '감사하다, 고마워하다',
      ),
      VocabularyItem(id: 2, word: 'refund', meaningKo: '환급, 환불'),
      VocabularyItem(id: 3, word: 'amazing', meaningKo: '놀라운'),
      VocabularyItem(id: 4, word: 'confused', meaningKo: '혼란스러운'),
    ];
    const vocabularySet = VocabularySet(
      id: 10,
      title: '복수 뜻 테스트',
      status: 'published',
      itemCount: 4,
      items: items,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: StudentVocabularyMeaningQuizScreen(
          vocabularySet: vocabularySet,
          items: items,
        ),
      ),
    );

    expect(find.text('appreciate 감사하다'), findsNothing);
    expect(find.text('감사하다 · 고마워하다'), findsOneWidget);
    expect(find.text('환급 · 환불'), findsOneWidget);
  });
}
