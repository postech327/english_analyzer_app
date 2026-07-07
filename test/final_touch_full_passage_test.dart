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
        translation: '첫 번째 일반 해석.',
        translationBracketed: '[첫 번째 구조 해석].',
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
        translation: '두 번째 일반 해석.',
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
              topic: '테스트 주제',
              title: '테스트 제목',
              gist: '테스트 요지',
            ),
          ),
        ),
      ),
    );

    expect(find.text('전체 지문 한눈에 보기'), findsOneWidget);
    expect(find.text('테스트 주제'), findsOneWidget);
    expect(find.text('테스트 제목'), findsOneWidget);
    expect(find.text('테스트 요지'), findsOneWidget);
    expect(find.text('영어 전체 지문'), findsOneWidget);
    expect(find.text('한국어 해석'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2));
    expect(find.text('2'), findsNWidgets(2));
    expect(find.textContaining('First bracketed sentence'), findsOneWidget);
    expect(find.textContaining('첫 번째 구조 해석'), findsOneWidget);
    expect(find.textContaining('두 번째 일반 해석'), findsOneWidget);
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

  testWidgets('uses two columns on wide screens and stacks on narrow screens',
      (tester) async {
    const details = [
      FinalTouchSentenceDetail(
        sentenceNo: 1,
        original: 'Wide layout keeps English on the left.',
        translation: 'Wide layout translation.',
        translationBracketed: '',
        bracketed: '[Wide layout keeps English on the left].',
        spans: [],
        sentenceRole: '',
        roleHighlightType: 'none',
        isBlankCandidate: false,
        highlights: [],
        grammarPoints: [],
        questionPoint: '',
      ),
    ];

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 900);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FinalTouchFullBracketedPassage(
              body: '[Wide layout keeps English on the left].',
              plainBody: 'Wide layout keeps English on the left.',
              sentenceDetails: details,
            ),
          ),
        ),
      ),
    );

    final wideEnglishTopLeft = tester.getTopLeft(
      find.byKey(const Key('final-touch-english-passage-panel')),
    );
    final wideTranslationTopLeft = tester.getTopLeft(
      find.byKey(const Key('final-touch-translation-panel')),
    );

    expect(wideEnglishTopLeft.dx, lessThan(wideTranslationTopLeft.dx));
    expect(wideEnglishTopLeft.dy, wideTranslationTopLeft.dy);

    tester.view.physicalSize = const Size(520, 900);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FinalTouchFullBracketedPassage(
              body: '[Wide layout keeps English on the left].',
              plainBody: 'Wide layout keeps English on the left.',
              sentenceDetails: details,
            ),
          ),
        ),
      ),
    );

    final narrowEnglishTopLeft = tester.getTopLeft(
      find.byKey(const Key('final-touch-english-passage-panel')),
    );
    final narrowTranslationTopLeft = tester.getTopLeft(
      find.byKey(const Key('final-touch-translation-panel')),
    );

    expect(narrowEnglishTopLeft.dx, narrowTranslationTopLeft.dx);
    expect(narrowTranslationTopLeft.dy, greaterThan(narrowEnglishTopLeft.dy));
  });
}
