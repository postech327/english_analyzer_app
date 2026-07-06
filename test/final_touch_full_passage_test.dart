import 'package:english_analyzer_app/models/final_touch.dart';
import 'package:english_analyzer_app/widgets/final_touch_sentence_analysis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows numbered bracketed sentences and toggles to plain text',
      (tester) async {
    const details = [
      FinalTouchSentenceDetail(
        sentenceNo: 1,
        original: 'First plain sentence.',
        translation: '',
        translationBracketed: '',
        bracketed: '[First bracketed sentence].',
        spans: [],
        sentenceRole: '',
        roleHighlightType: 'none',
        isBlankCandidate: false,
        highlights: [],
        grammarPoints: [],
        questionPoint: '',
      ),
      FinalTouchSentenceDetail(
        sentenceNo: 2,
        original: 'Second plain sentence.',
        translation: '',
        translationBracketed: '',
        bracketed: '{Second bracketed sentence}.',
        spans: [],
        sentenceRole: '',
        roleHighlightType: 'none',
        isBlankCandidate: false,
        highlights: [],
        grammarPoints: [],
        questionPoint: '',
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FinalTouchFullBracketedPassage(
              body: '[First bracketed sentence]. {Second bracketed sentence}.',
              plainBody: 'First plain sentence. Second plain sentence.',
              sentenceDetails: details,
            ),
          ),
        ),
      ),
    );

    expect(find.text('전체 지문 한눈에 보기'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('First bracketed sentence'), findsOneWidget);
    expect(find.text('[ ] 절'), findsOneWidget);

    await tester.tap(find.byKey(const Key('final-touch-bracket-toggle')));
    await tester.pumpAndSettle();

    expect(find.textContaining('First plain sentence'), findsOneWidget);
    expect(find.textContaining('First bracketed sentence'), findsNothing);
    expect(find.text('일반 지문 보기'), findsOneWidget);
  });

  testWidgets('falls back to an unnumbered plain passage without details',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FinalTouchFullBracketedPassage(
            body: '',
            plainBody: 'Passage without sentence metadata',
          ),
        ),
      ),
    );

    expect(
      find.textContaining('Passage without sentence metadata'),
      findsOneWidget,
    );
    expect(find.text('1'), findsNothing);
  });
}
