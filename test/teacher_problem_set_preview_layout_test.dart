import 'package:english_analyzer_app/screens/teacher/teacher_problem_set_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('long type summary wraps without horizontal overflow',
      (tester) async {
    const summary =
        'blank 3 · grammar_correction 4 · vocabulary_correction 2 · '
        'content_match 3 · multiple_insertion 2';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            child: TeacherPreviewInfoPill(
              icon: Icons.category_outlined,
              text: summary,
            ),
          ),
        ),
      ),
    );

    expect(find.text(summary), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.text(summary)).width, lessThanOrEqualTo(180));
    expect(tester.getSize(find.text(summary)).height, greaterThan(20));
  });
}
