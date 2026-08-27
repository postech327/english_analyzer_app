import 'package:english_analyzer_app/models/final_touch.dart';
import 'package:english_analyzer_app/utils/final_touch_import_parser.dart';
import 'package:english_analyzer_app/widgets/final_touch_sentence_analysis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a Backend semantic sentence ID without changing sentenceNo', () {
    final detail = FinalTouchSentenceDetail.fromJson({
      'semantic_sentence_id': 'sentence-uuid-1',
      'sentence_no': 7,
      'original': 'Stable sentence identity is separate from display order.',
    });

    expect(detail.semanticSentenceId, 'sentence-uuid-1');
    expect(detail.sentenceNo, 7);
  });

  test('legacy and invalid IDs remain empty instead of being invented', () {
    final missing = FinalTouchSentenceDetail.fromJson({'sentence_no': 1});
    final invalid = FinalTouchSentenceDetail.fromJson({
      'semantic_sentence_id': 123,
      'sentence_no': 2,
    });
    final imported = parseFinalTouchImportText('''
[영어 지문]
Manual import sentence.
[한글 해석]
수동 입력 문장이다.
''');

    expect(missing.semanticSentenceId, isEmpty);
    expect(invalid.semanticSentenceId, isEmpty);
    expect(
      imported.sentenceDetails.single.containsKey('semantic_sentence_id'),
      isFalse,
    );
  });

  testWidgets(
      'uses semantic ID as an internal card key and preserves rendering',
      (tester) async {
    const semanticId = 'sentence-uuid-rendering';
    const detail = FinalTouchSentenceDetail(
      semanticSentenceId: semanticId,
      sentenceNo: 3,
      original: 'The sentence remains visible.',
      translation: '문장은 계속 표시된다.',
      translationBracketed: '',
      bracketed: '[The sentence remains visible].',
      spans: [],
      sentenceRole: 'support',
      roleHighlightType: 'none',
      isBlankCandidate: false,
      highlights: [],
      grammarPoints: [
        FinalTouchGrammarPoint(
          target: 'remains',
          label: '연결 동사',
          explanation: '주어의 상태가 이어짐을 나타낸다.',
          referenceNo: null,
        ),
      ],
      questionPoint: '문장의 역할과 핵심 표현을 확인한다.',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FinalTouchSentenceAnalysis(details: [detail]),
        ),
      ),
    );

    expect(find.byKey(const ValueKey<String>(semanticId)), findsOneWidget);
    expect(find.text(semanticId), findsNothing);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('support'), findsOneWidget);
    expect(find.textContaining('The sentence remains visible'), findsOneWidget);
    expect(find.textContaining('문장은 계속 표시된다'), findsOneWidget);
    expect(find.text('연결 동사'), findsOneWidget);
    expect(find.text('문장의 역할과 핵심 표현을 확인한다.'), findsOneWidget);
  });

  testWidgets('legacy detail renders without a fabricated semantic key',
      (tester) async {
    const detail = FinalTouchSentenceDetail(
      sentenceNo: 1,
      original: 'Legacy sentence.',
      translation: '과거 문장이다.',
      translationBracketed: '',
      bracketed: 'Legacy sentence.',
      spans: [],
      sentenceRole: '',
      roleHighlightType: 'none',
      isBlankCandidate: false,
      highlights: [],
      grammarPoints: [],
      questionPoint: '',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FinalTouchSentenceAnalysis(details: [detail]),
        ),
      ),
    );

    expect(find.byKey(const ValueKey<String>('')), findsNothing);
    expect(find.textContaining('Legacy sentence'), findsOneWidget);
  });
}
