import 'package:english_analyzer_app/screens/teacher_vocabulary_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('new vocabulary editor renders all form sections',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TeacherVocabularyEditorScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('새 단어장'), findsOneWidget);
    expect(find.text('기본 정보'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('단어 붙여넣기'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('분석 결과'), findsOneWidget);
    expect(find.text('단어장 저장'), findsOneWidget);
  });

  testWidgets('analysis preview groups words and formats multiple meanings',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TeacherVocabularyEditorScreen()),
    );
    await tester.pumpAndSettle();

    final list = find.byType(ListView);
    await tester.drag(list, const Offset(0, -1000));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'Unit 1 Gateway\n'
      'foundation 재단\n'
      'appreciate 감사하다, 고마워하다',
    );
    await tester.tap(find.text('붙여넣은 단어 분석하기'));
    await tester.pumpAndSettle();
    await tester.drag(list, const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Unit 1 Gateway · 2단어'), findsOneWidget);
    expect(find.text('감사하다 · 고마워하다'), findsOneWidget);
    expect(find.text('그룹 1개'), findsOneWidget);
  });
}
