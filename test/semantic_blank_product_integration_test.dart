import 'dart:convert';

import 'package:english_analyzer_app/screens/student/student_exam_take_screen.dart';
import 'package:english_analyzer_app/utils/blank_display_passage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _problemSetId = 2601;
const _questionId = 2602;
const _sourcePassage =
    'The same phrase appears first, and the same phrase appears second.';
const _blankedPassage =
    'The same phrase appears first, and ________________________________ appears second.';
const _choices = <String>[
  'a different phrase',
  'the opening phrase',
  'the same phrase',
  'an unrelated phrase',
  'the final phrase',
];

Map<String, dynamic> _semanticBlankQuestion({bool unsafe = false}) {
  return <String, dynamic>{
    'question_id': _questionId,
    'id': _questionId,
    'order': 1,
    'question_type': 'blank',
    'question_text': '다음 빈칸에 들어갈 말로 가장 적절한 것을 고르시오.',
    'passage': _blankedPassage,
    'options': List<Map<String, dynamic>>.generate(
      _choices.length,
      (index) => <String, dynamic>{
        'id': index + 1,
        'label': '${index + 1}',
        'text': _choices[index],
      },
    ),
    'special_data': <String, dynamic>{
      'kind': 'blank',
      'interaction_type': 'single_choice',
      if (unsafe) ...<String, dynamic>{
        'answer_index': 2,
        'answer_text': 'the same phrase',
        'source_span': <String, dynamic>{'start': 39, 'end': 54},
        'selected_target': <String, dynamic>{
          'span': <String, dynamic>{'start': 39, 'end': 54},
          'text': 'the same phrase',
        },
        'validation': <String, dynamic>{'overall_valid': true},
        'judge_result': <String, dynamic>{'verdict': 'valid'},
        'evidence': 'SECRET_BLANK_EVIDENCE',
      },
    },
  };
}

Map<String, dynamic> _studentPayload(Map<String, dynamic> question) =>
    <String, dynamic>{
      'id': _problemSetId,
      'title': 'Semantic Blank Student Product',
      'passage_content': _sourcePassage,
      'questions': <Map<String, dynamic>>[question],
    };

http.Response _jsonResponse(Object body, [int statusCode = 200]) =>
    http.Response(
      jsonEncode(body),
      statusCode,
      headers: const <String, String>{'content-type': 'application/json'},
    );

Future<void> _withMockClient(
  WidgetTester tester,
  Future<http.Response> Function(http.Request request) handler,
  Future<void> Function() body, {
  Size surfaceSize = const Size(1200, 1400),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await http.runWithClient(body, () => MockClient(handler));
}

Future<void> _pumpStudent(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: StudentExamTakeScreen(problemSetId: _problemSetId)),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapChoice(WidgetTester tester, int index) async {
  final finder = find.text(_choices[index]);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

bool _hasSelectedBackground(WidgetTester tester, String choiceText) {
  return tester
      .widgetList<AnimatedContainer>(
        find.ancestor(
          of: find.text(choiceText),
          matching: find.byType(AnimatedContainer),
        ),
      )
      .any((container) {
        final decoration = container.decoration;
        return decoration is BoxDecoration &&
            decoration.color == const Color(0xFFEFF6FF);
      });
}

String _renderedSelectableText(WidgetTester tester) {
  return tester
      .widgetList<SelectableText>(find.byType(SelectableText))
      .map((widget) => widget.textSpan?.toPlainText() ?? widget.data ?? '')
      .join('\n');
}

void main() {
  testWidgets('uses the persisted blank passage instead of reconstructing it', (
    tester,
  ) async {
    final question = _semanticBlankQuestion();
    await _withMockClient(
      tester,
      (_) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester);
        final rendered = _renderedSelectableText(tester);
        expect(rendered, contains('The same phrase appears first'));
        expect(rendered, contains('appears second.'));
        expect(rendered, isNot(contains(_sourcePassage)));
        expect(rendered, contains('\u00A0\u00A0\u00A0'));
      },
    );
  });

  testWidgets('renders exactly five Backend choices', (tester) async {
    final question = _semanticBlankQuestion();
    await _withMockClient(
      tester,
      (_) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester);
        for (final choice in _choices) {
          expect(find.text(choice), findsOneWidget);
        }
        expect(find.text('6'), findsNothing);
      },
    );
  });

  testWidgets('keeps Blank as a single-choice interaction', (tester) async {
    final question = _semanticBlankQuestion();
    await _withMockClient(
      tester,
      (_) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester);
        await _tapChoice(tester, 0);
        expect(_hasSelectedBackground(tester, _choices[0]), isTrue);
        await _tapChoice(tester, 4);
        expect(_hasSelectedBackground(tester, _choices[0]), isFalse);
        expect(_hasSelectedBackground(tester, _choices[4]), isTrue);
      },
    );
  });

  testWidgets('submits the selected Backend option as selected_index', (
    tester,
  ) async {
    final question = _semanticBlankQuestion();
    Map<String, dynamic>? submitted;
    await _withMockClient(
      tester,
      (request) async {
        if (request.method == 'POST' &&
            request.url.path == '/student/answers') {
          submitted = jsonDecode(request.body) as Map<String, dynamic>;
          return _jsonResponse(<String, dynamic>{'total': 1, 'correct': 1});
        }
        if (request.url.path.endsWith('/result-summary')) {
          return _jsonResponse(<String, dynamic>{
            'total_questions': 1,
            'correct_count': 1,
            'incorrect_count': 0,
            'my_score': 100,
          });
        }
        return _jsonResponse(_studentPayload(question));
      },
      () async {
        await _pumpStudent(tester);
        await _tapChoice(tester, 2);
        await tester.tap(find.text('시험 제출'));
        await tester.pumpAndSettle();
      },
    );

    final answer =
        (submitted!['answers'] as List<dynamic>).single as Map<String, dynamic>;
    expect(answer, <String, dynamic>{
      'question_id': _questionId,
      'selected_index': 2,
    });
  });

  testWidgets('does not render or preselect leaked answer metadata', (
    tester,
  ) async {
    final question = _semanticBlankQuestion(unsafe: true);
    await _withMockClient(
      tester,
      (_) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester);
        for (final choice in _choices) {
          expect(_hasSelectedBackground(tester, choice), isFalse);
        }
        for (final leak in const <String>[
          'SECRET_BLANK_EVIDENCE',
          'overall_valid',
          'judge_result',
          'start: 39',
          'end: 54',
        ]) {
          expect(find.textContaining(leak), findsNothing);
        }
      },
    );
  });

  testWidgets('five-choice Blank remains usable at 320 logical pixels', (
    tester,
  ) async {
    final question = _semanticBlankQuestion();
    await _withMockClient(
      tester,
      (_) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester);
        await tester.ensureVisible(find.text(_choices.last));
        expect(find.text(_choices.last), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      surfaceSize: const Size(320, 900),
    );
  });

  test('blank display utility preserves which repeated occurrence is blank', () {
    expect(
      blankPassageForDisplay(_blankedPassage),
      'The same phrase appears first, and $visibleBlankPlaceholder appears second.',
    );
  });
}
