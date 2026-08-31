import 'package:english_analyzer_app/utils/grammar_vocabulary_inline_spans.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const semanticCorrection = <String, dynamic>{
    'kind': 'correction_multi',
    'interaction_type': 'correction_multi',
    'positions': [1, 2, 3, 4, 5],
    'position_labels': ['①', '②', '③', '④', '⑤'],
    'position_texts': {
      '1': 'can improve',
      '2': 'frequent service',
      '3': 'waiting time',
      '4': 'However',
      '5': 'reliable transit',
    },
    'max_answers': 1,
  };

  test('semantic correction reuses inline marker rendering without spans', () {
    const passage = '①can improve access. ②frequent service matters. '
        '③waiting time grows. ④However, ⑤reliable transit helps.';
    final span = buildGrammarVocabularyInlineSpans(
      passage: passage,
      specialData: semanticCorrection,
      baseStyle: const TextStyle(),
    );
    final flattened = span.toPlainText();

    expect(isGrammarVocabularyQuestionType('correction'), isTrue);
    for (final label in ['①', '②', '③', '④', '⑤']) {
      expect(flattened, contains(label));
    }
    expect(flattened, passage);
    expect(semanticCorrection.containsKey('start_char'), isFalse);
    expect(semanticCorrection.containsKey('end_char'), isFalse);
  });

  test('backend position labels and string or integer text keys are supported',
      () {
    final mixedKeys = <String, dynamic>{
      ...semanticCorrection,
      'position_texts': <dynamic, dynamic>{'1': 'first', 2: 'second'},
    };

    expect(grammarVocabularyPositionLabel(mixedKeys, 4), '④');
    expect(grammarVocabularyPositionText(mixedKeys, 1), 'first');
    expect(grammarVocabularyPositionText(mixedKeys, 2), 'second');
  });

  test('max answers one replaces the previous selection', () {
    var selected = updateLanguagePositionSelection(
      selected: const <int>{},
      position: 2,
      checked: true,
      maxAnswers: 1,
    );
    selected = updateLanguagePositionSelection(
      selected: selected,
      position: 4,
      checked: true,
      maxAnswers: 1,
    );

    expect(selected, {4});
    expect(serializeLanguagePositionSelection(selected), '4');
  });

  test('legacy max answers two keeps deterministic multi-selection', () {
    var selected = updateLanguagePositionSelection(
      selected: const <int>{},
      position: 3,
      checked: true,
      maxAnswers: 2,
    );
    selected = updateLanguagePositionSelection(
      selected: selected,
      position: 1,
      checked: true,
      maxAnswers: 2,
    );

    expect(selected, {1, 3});
    expect(serializeLanguagePositionSelection(selected), '1,3');
  });

  test('student helpers ignore answer-bearing extra fields', () {
    final unsafeFixture = <String, dynamic>{
      ...semanticCorrection,
      'expected_positions': [4],
      'corrections': {
        '4': {'from': 'However', 'to': 'Therefore'}
      },
      'answer': 4,
    };

    expect(grammarVocabularyPositionLabel(unsafeFixture, 4), '④');
    expect(grammarVocabularyPositionText(unsafeFixture, 4), 'However');
    expect(shouldShowPositionTextInSelection(unsafeFixture), isFalse);
  });
}
