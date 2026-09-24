import 'dart:convert';
import 'dart:io';

import 'package:english_analyzer_app/screens/student/student_exam_result_screen.dart';
import 'package:english_analyzer_app/screens/student/student_exam_take_screen.dart';
import 'package:english_analyzer_app/screens/teacher/teacher_problem_set_preview_screen.dart';
import 'package:english_analyzer_app/utils/grammar_vocabulary_inline_spans.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _problemSetId = 2020;
const _questionId = 211;
const _explanation = '②와 ⑤가 본문의 내용과 일치한다.';
const _choices = <String>[
  'Solar panels reduced household energy costs during winter.',
  'Community batteries stored excess electricity after sunset.',
  'Engineers never inspected the equipment for safety.',
  'The city cancelled every technician training program.',
  'Residents received weekly energy production reports.',
  'The project stopped before its final inspection.',
];

Map<String, dynamic> _contentMatchQuestion({
  bool teacher = false,
  bool unsafe = false,
  int choiceCount = 6,
  bool legacy = false,
}) {
  final options = List<Map<String, dynamic>>.generate(
    choiceCount,
    (index) => <String, dynamic>{
      'id': index + 1,
      'label': studentChoiceLabel(index),
      'text': _choices[index],
      if (teacher) 'is_correct': false,
    },
  );
  return <String, dynamic>{
    'question_id': _questionId,
    'id': _questionId,
    'order': 1,
    'question_type': 'content_match',
    'question_text': legacy
        ? '윗글의 내용과 일치하는 것을 고르시오.'
        : '윗글의 내용과 일치하는 것을 모두 고르시오. (정답 최대 2개)',
    'passage': 'A six-choice semantic Content Match passage.',
    'options': options,
    'explanation': _explanation,
    if (teacher) 'answer_text': legacy ? '3' : '2,5',
    'special_data': <String, dynamic>{
      'kind': 'content_match',
      'interaction_type': legacy ? 'single_choice' : 'multi_select',
      'max_answers': legacy ? 1 : 2,
      'choice_ids': List<String>.generate(
        choiceCount,
        (index) => String.fromCharCode(65 + index),
      ),
      if (teacher && !legacy) ...<String, dynamic>{
        'answer_indices': <int>[1, 4],
        'answer_choice_ids': <String>['B', 'E'],
        'answer_text': '2,5',
      },
      if (unsafe) ...<String, dynamic>{
        'answer_indices': <int>[1, 4],
        'answer_choice_ids': <String>['B', 'E'],
        'answer_text': '2,5',
        'correct_choice_ids': <String>['B', 'E'],
        'truth': <String>['contradicted', 'entailed'],
        'scope': <String>['matched'],
        'verdict': 'correct',
        'is_correct': true,
        'judge_result': <String, dynamic>{
          'correct_choice_ids': <String>['B', 'E'],
          'overall_valid': true,
        },
        'validation': <String, dynamic>{'correct_choice_count': 2},
        'evidence': <String>['SECRET_EVIDENCE'],
        'generator_family': 'SECRET_GENERATOR',
      },
    },
    if (legacy) 'answer_index': 2,
  };
}

Map<String, dynamic> _studentPayload(Map<String, dynamic> question) =>
    <String, dynamic>{
      'id': _problemSetId,
      'title': 'Semantic Content Match',
      'passage_content': 'A six-choice semantic Content Match passage.',
      'questions': <Map<String, dynamic>>[question],
    };

Map<String, dynamic> _teacherPayload(Map<String, dynamic> question) =>
    <String, dynamic>{
      'id': _problemSetId,
      'name': 'Semantic Content Match Teacher Preview',
      'passage': <String, dynamic>{
        'title': 'Semantic passage',
        'content': 'A six-choice semantic Content Match passage.',
      },
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
  Size surfaceSize = const Size(1200, 1600),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await http.runWithClient(body, () => MockClient(handler));
}

Future<void> _pumpStudent(
  WidgetTester tester,
  Map<String, dynamic> question,
) async {
  await tester.pumpWidget(
    const MaterialApp(home: StudentExamTakeScreen(problemSetId: _problemSetId)),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapChoice(WidgetTester tester, int position) async {
  final finder = find.text(_choices[position - 1]);
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

bool _hasTeacherCorrectBackground(WidgetTester tester, String choiceText) {
  return tester
      .widgetList<Container>(
    find.ancestor(
      of: find.text(choiceText),
      matching: find.byType(Container),
    ),
  )
      .any((container) {
    final decoration = container.decoration;
    return decoration is BoxDecoration &&
        decoration.color == const Color(0xFFECFDF5);
  });
}

Future<Map<String, dynamic>> _submitPositions(
  WidgetTester tester,
  List<int> positions,
) async {
  final question = _contentMatchQuestion();
  Map<String, dynamic>? submitted;
  await _withMockClient(
    tester,
    (request) async {
      if (request.method == 'POST' && request.url.path == '/student/answers') {
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
      await _pumpStudent(tester, question);
      for (final position in positions) {
        await _tapChoice(tester, position);
      }
      await tester.tap(find.text('시험 제출'));
      await tester.pumpAndSettle();
    },
  );
  return submitted!;
}

void main() {
  for (final prompt in <String>[
    '윗글의 내용과 일치하는 것을 모두 고르시오. (정답 최대 2개)',
    '윗글의 내용과 일치하지 않는 것을 모두 고르시오. (정답 최대 2개)',
    '윗글의 내용과 일치하는 것은?',
    '윗글의 내용과 일치하지 않는 것은?',
    '',
  ]) {
    testWidgets('preserves Content Match instruction: "$prompt"', (tester) async {
      final question = _contentMatchQuestion()..['question_text'] = prompt;
      await _withMockClient(
        tester,
        (request) async => _jsonResponse(_studentPayload(question)),
        () async {
          await _pumpStudent(tester, question);
          expect(
            find.text(prompt.isEmpty
                ? '문제 지시문이 없습니다. 선생님에게 문의하세요.'
                : prompt),
            findsOneWidget,
          );
          expect(
            find.text('윗글의 내용과 일치하거나 일치하지 않는 것을 고르세요.'),
            findsNothing,
          );
        },
      );
    });
  }

  testWidgets('detects semantic content match through the product contract', (
    tester,
  ) async {
    final question = _contentMatchQuestion();
    await _withMockClient(
      tester,
      (_) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        expect(find.text('보기'), findsOneWidget);
        expect(
          find.text('윗글의 내용과 일치하는 것을 모두 고르시오. (정답 최대 2개)'),
          findsOneWidget,
        );
      },
    );
  });

  testWidgets('renders exactly six product choices including the sixth', (
    tester,
  ) async {
    final question = _contentMatchQuestion();
    await _withMockClient(
      tester,
      (_) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        for (var index = 0; index < 6; index++) {
          expect(find.text(studentChoiceLabel(index)), findsOneWidget);
          expect(find.text(_choices[index]), findsOneWidget);
        }
        expect(find.text('⑥'), findsOneWidget);
      },
    );
  });

  testWidgets('choice two can be selected without a pre-answer highlight', (
    tester,
  ) async {
    final question = _contentMatchQuestion();
    await _withMockClient(
      tester,
      (_) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        expect(_hasSelectedBackground(tester, _choices[1]), isFalse);
        await _tapChoice(tester, 2);
        expect(_hasSelectedBackground(tester, _choices[1]), isTrue);
      },
    );
  });

  testWidgets('choices two and five remain selected together', (tester) async {
    final question = _contentMatchQuestion();
    await _withMockClient(
      tester,
      (_) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        await _tapChoice(tester, 2);
        await _tapChoice(tester, 5);
        expect(_hasSelectedBackground(tester, _choices[1]), isTrue);
        expect(_hasSelectedBackground(tester, _choices[4]), isTrue);
      },
    );
  });

  testWidgets('third choice is blocked when max_answers is two', (
    tester,
  ) async {
    final question = _contentMatchQuestion();
    await _withMockClient(
      tester,
      (_) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        await _tapChoice(tester, 2);
        await _tapChoice(tester, 5);
        await _tapChoice(tester, 6);
        expect(_hasSelectedBackground(tester, _choices[1]), isTrue);
        expect(_hasSelectedBackground(tester, _choices[4]), isTrue);
        expect(_hasSelectedBackground(tester, _choices[5]), isFalse);
      },
    );
  });

  testWidgets('submission sends canonical answer_text 2,5 only', (
    tester,
  ) async {
    final submitted = await _submitPositions(tester, <int>[2, 5]);
    final answer =
        (submitted['answers'] as List<dynamic>).single as Map<String, dynamic>;
    expect(answer, <String, dynamic>{
      'question_id': _questionId,
      'answer_text': '2,5',
    });
  });

  testWidgets('reverse selection order submits the same canonical set', (
    tester,
  ) async {
    final submitted = await _submitPositions(tester, <int>[5, 2]);
    final answer =
        (submitted['answers'] as List<dynamic>).single as Map<String, dynamic>;
    expect(answer['answer_text'], '2,5');
    expect(answer.containsKey('selected_index'), isFalse);
  });

  test('selection serializer is order-independent and exact-set shaped', () {
    expect(serializeLanguagePositionSelection(<int>{2, 5}), '2,5');
    expect(serializeLanguagePositionSelection(<int>{5, 2}), '2,5');
  });

  testWidgets('unsafe metadata neither selects nor renders an answer', (
    tester,
  ) async {
    final question = _contentMatchQuestion(unsafe: true);
    await _withMockClient(
      tester,
      (_) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        expect(_hasSelectedBackground(tester, _choices[1]), isFalse);
        expect(_hasSelectedBackground(tester, _choices[4]), isFalse);
        for (final leak in const <String>[
          'B,E',
          'entailed',
          'contradicted',
          'overall_valid',
          'SECRET_EVIDENCE',
          'SECRET_GENERATOR',
        ]) {
          expect(find.textContaining(leak), findsNothing);
        }
      },
    );
  });

  test(
    'student renderer does not read semantic or answer authority fields',
    () {
      final source = File(
        'lib/screens/student/student_exam_take_screen.dart',
      ).readAsStringSync();
      for (final key in const <String>[
        'answer_indices',
        'answer_choice_ids',
        'correct_choice_ids',
        'truth',
        'scope',
        'verdict',
        'is_correct',
        'judge_result',
        'validation',
        'evidence',
        'generator_family',
      ]) {
        expect(source.contains("specialData['$key']"), isFalse, reason: key);
      }
    },
  );

  testWidgets('teacher preview highlights choices two and five only', (
    tester,
  ) async {
    final question = _contentMatchQuestion(teacher: true);
    await _withMockClient(
      tester,
      (_) async => _jsonResponse(_teacherPayload(question)),
      () async {
        await tester.pumpWidget(
          const MaterialApp(
            home: TeacherProblemSetPreviewScreen(problemSetId: _problemSetId),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ExpansionTile).last);
        await tester.pumpAndSettle();

        for (var index = 0; index < 6; index++) {
          expect(find.text(_choices[index]), findsOneWidget);
        }
        expect(_hasTeacherCorrectBackground(tester, _choices[1]), isTrue);
        expect(_hasTeacherCorrectBackground(tester, _choices[4]), isTrue);
        expect(_hasTeacherCorrectBackground(tester, _choices[0]), isFalse);
        expect(find.text('2,5'), findsWidgets);
        expect(find.text(_explanation), findsOneWidget);
      },
    );
  });

  testWidgets(
    'result review displays selected and correct sets with explanation',
    (tester) async {
      final summary = <String, dynamic>{
        'total_questions': 1,
        'correct_count': 0,
        'incorrect_count': 1,
        'my_score': 0,
        'wrong_questions': <Map<String, dynamic>>[
          <String, dynamic>{
            'order': 1,
            'label': '내용일치',
            'question_text': '윗글의 내용과 일치하는 것을 모두 고르시오.',
            'selected_text': '1,4',
            'correct_text': '2,5',
            'explanation': _explanation,
          },
        ],
      };
      await _withMockClient(
        tester,
        (_) async => _jsonResponse(summary),
        () async {
          await tester.pumpWidget(
            const MaterialApp(
              home: StudentExamResultScreen(
                problemSetId: _problemSetId,
                totalQuestions: 1,
                correctAnswers: 0,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('오답 다시보기'));
          await tester.tap(find.text('오답 다시보기'));
          await tester.pumpAndSettle();

          expect(find.text('1,4'), findsOneWidget);
          expect(find.text('2,5'), findsOneWidget);
          expect(find.text(_explanation), findsOneWidget);
        },
      );
    },
  );

  testWidgets('legacy five-choice single-select renderer remains unchanged', (
    tester,
  ) async {
    final question = _contentMatchQuestion(choiceCount: 5, legacy: true);
    Map<String, dynamic>? submitted;
    await _withMockClient(
      tester,
      (request) async {
        if (request.method == 'POST') {
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
        await _pumpStudent(tester, question);
        expect(find.text('⑤'), findsOneWidget);
        expect(find.text('⑥'), findsNothing);
        await _tapChoice(tester, 3);
        await tester.tap(find.text('시험 제출'));
        await tester.pumpAndSettle();
      },
    );
    final answer =
        (submitted!['answers'] as List<dynamic>).single as Map<String, dynamic>;
    expect(answer['selected_index'], 2);
    expect(answer.containsKey('answer_text'), isFalse);
  });
}
