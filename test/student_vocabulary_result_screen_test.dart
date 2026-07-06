import 'package:english_analyzer_app/models/vocabulary.dart';
import 'package:english_analyzer_app/screens/student_vocabulary_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const item = VocabularyItem(id: 1, word: 'goal', meaningKo: '목표');
  const vocabularySet = VocabularySet(
    id: 10,
    title: '결과 테스트',
    status: 'published',
    itemCount: 1,
    items: [item],
  );

  testWidgets('hides wrong-review actions when every answer is correct',
      (tester) async {
    const attempt = VocabularyAttempt(
      id: 20,
      setId: 10,
      score: 100,
      totalCount: 1,
      correctCount: 1,
      rangeLabel: 'Unit 1 Gateway',
      results: [
        VocabularyAttemptResult(
          itemId: 1,
          word: 'goal',
          studentAnswer: '목표',
          correctAnswer: '목표',
          isCorrect: true,
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: StudentVocabularyResultScreen(
          attempt: attempt,
          vocabularySet: vocabularySet,
        ),
      ),
    );

    expect(find.text('오답이 없습니다. 훌륭해요!'), findsOneWidget);
    final wrongQuiz = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '오답만 다시 풀기'),
    );
    expect(wrongQuiz.onPressed, isNull);
  });
}
