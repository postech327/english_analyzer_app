import 'package:flutter_test/flutter_test.dart';

import 'package:english_analyzer_app/utils/workbook_question_parser.dart';

void main() {
  group('parseInlineChoiceRawText', () {
    test('uses the first explicit marker choice as the answer', () {
      final result = parseInlineChoiceRawText(
        'A laboratory is a(n) [[1:artificial|natural]] environment.\n'
        'Some people feel [[2:disturbance|concentration]].',
        explanationText: '1. natural 자연적인\n2. concentration 집중',
      );

      expect(result.errors, isEmpty);
      expect(result.items, hasLength(2));
      expect(result.items[0].answer, 'artificial');
      expect(result.items[0].answerIndex, 0);
      expect(result.items[0].explanation, 'natural 자연적인');
      expect(result.items[1].explanation, 'concentration 집중');
    });

    test('matches parenthetical explanations by number and sequence', () {
      final numbered = parseInlineChoiceRawText(
        'Text [[200:artificial|natural]] and '
        '[[204:disturbance|concentration]].',
        explanationText: '200) artificial (natural 자연적인)\n'
            '204) disturbance (concentration 집중)',
      );
      final sequential = parseInlineChoiceRawText(
        'Text [[1:artificial|natural]] and '
        '[[2:disturbance|concentration]].',
        explanationText: 'artificial (natural 자연적인)\n'
            'disturbance (concentration 집중)',
      );

      expect(numbered.items[0].explanation, 'natural 자연적인');
      expect(numbered.items[1].explanation, 'concentration 집중');
      expect(sequential.items[0].explanation, 'natural 자연적인');
      expect(sequential.items[1].explanation, 'concentration 집중');
    });

    test('keeps explanations optional and legacy input compatible', () {
      final withoutExplanation = parseInlineChoiceRawText(
        'Text [[1:artificial|natural]].',
      );
      final legacy = parseInlineChoiceRawText(
        'Text [artificial/natural] artificial.',
      );

      expect(withoutExplanation.items.single.explanation, isNull);
      expect(legacy.errors, isEmpty);
      expect(legacy.items.single.answer, 'artificial');
    });

    test('normalizes punctuation around a legacy answer', () {
      final result = parseInlineChoiceRawText(
        'A study of their natural environment is '
        '[crucial/insignificant], crucial, '
        '(insignificant 중요하지 않은).',
      );

      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
      expect(result.items.single.answer, 'crucial');
      expect(
        result.items.single.explanation,
        'insignificant 중요하지 않은',
      );
    });

    test('separates a trailing parenthetical explanation', () {
      final result = parseInlineChoiceRawText(
        'The model would be less [effective/ineffective] effective '
        '(ineffective 비효율적인).',
      );

      expect(result.errors, isEmpty);
      expect(result.items.single.answer, 'effective');
      expect(result.items.single.explanation, 'ineffective 비효율적인');
    });

    test('matches numbered explanations to explicit item numbers', () {
      final result = parseInlineChoiceRawText(
        'A laboratory is a(n) [[1:artificial|natural]] environment. '
        'The old system was [[2:established|destroyed]] after reform.',
        explanationText: '1. natural 자연적인\n2. destroyed 파괴된',
      );

      expect(result.items[0].explanation, 'natural 자연적인');
      expect(result.items[1].explanation, 'destroyed 파괴된');
    });

    test('matches unnumbered explanations in appearance order', () {
      final result = parseInlineChoiceRawText(
        'A laboratory is a(n) [[1:artificial|natural]] environment. '
        'The old system was [[2:established|destroyed]] after reform.',
        explanationText: 'artificial (natural 자연적인)\n'
            'established (destroyed 파괴된)',
      );

      expect(result.items[0].explanation, 'natural 자연적인');
      expect(result.items[1].explanation, 'destroyed 파괴된');
    });

    test('extracts several explanations from one long line', () {
      final result = parseInlineChoiceRawText(
        'A laboratory is a(n) [[1:artificial|natural]] environment. '
        'The old system was [[2:established|destroyed]] after reform. '
        'The method was [[3:effective|ineffective]].',
        explanationText: 'artificial (natural 자연적인) '
            'established (destroyed 파괴된) '
            'effective (ineffective 비효율적인)',
      );

      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
      expect(result.items[0].explanation, 'natural 자연적인');
      expect(result.items[1].explanation, 'destroyed 파괴된');
      expect(result.items[2].explanation, 'ineffective 비효율적인');
    });

    test('falls back to order for large source explanation numbers', () {
      final result = parseInlineChoiceRawText(
        'Text [[1:artificial|natural]] and '
        '[[2:disturbance|concentration]].',
        explanationText: '200) artificial (natural 자연적인)\n'
            '204) disturbance (concentration 집중)',
      );

      expect(result.items[0].explanation, 'natural 자연적인');
      expect(result.items[1].explanation, 'concentration 집중');
    });
  });
}
