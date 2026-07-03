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
}
