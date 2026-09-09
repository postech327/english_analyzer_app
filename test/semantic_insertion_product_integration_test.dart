import 'dart:convert';

import 'package:english_analyzer_app/screens/student/student_exam_result_screen.dart';
import 'package:english_analyzer_app/screens/student/student_exam_take_screen.dart';
import 'package:english_analyzer_app/screens/teacher/teacher_problem_set_preview_screen.dart';
import 'package:english_analyzer_app/widgets/special_question_interaction_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _problemSetId = 1203;
const _questionId = 119;
const _insertSentence =
    'This recognition, however, changes how the evidence should be read.';
const _markedPassage =
    'Researchers first gathered the reports. ① They compared their terms. '
    '② The comparison revealed a hidden assumption. ③ Later evidence tested '
    'that assumption. ④ The team revised its account. ⑤';

Map<String, dynamic> _semanticQuestion({
  String questionType = 'insertion',
  String kind = 'insertion',
  bool includeUnsafeMetadata = false,
  bool includeTeacherAnswer = false,
}) {
  return <String, dynamic>{
    'question_id': _questionId,
    'id': _questionId,
    'order': 1,
    'question_type': questionType,
    'question_text': '글의 흐름으로 보아, 주어진 문장이 들어가기에 가장 적절한 곳은?',
    'passage': _markedPassage,
    'passage_content': _markedPassage,
    'explanation': '앞 문장의 가정을 however로 받아 뒤의 검증으로 연결한다.',
    'special_data': <String, dynamic>{
      'kind': kind,
      'mode': 'single',
      'interaction_type': 'single_choice',
      'insert_sentence': _insertSentence,
      'passage_with_positions': _markedPassage,
      'positions': <int>[1, 2, 3, 4, 5],
      if (includeTeacherAnswer) ...<String, dynamic>{
        'answer_position': 3,
        'answer_text': '3',
      },
      if (includeUnsafeMetadata) ...<String, dynamic>{
        'answer_position': 3,
        'answer_positions': <String, int>{'A': 3},
        'answer_text': '3',
        'correct_gap_id': 'G4',
        'original_position': 4,
        'target_sentence_id': 'S4',
        'gap_id': 'G4',
        'before_sentence_id': 'S3',
        'after_sentence_id': 'S5',
        'is_correct': true,
        'validation': <String, dynamic>{'single_answer': true},
        'judge_result': <String, dynamic>{'overall_valid': true},
        'evidence': <String>['secret evidence'],
        'score': 0.99,
        'margin': 0.5,
        'positions_meta': <Map<String, dynamic>>[
          <String, dynamic>{'position': 3, 'gap_id': 'G4', 'is_correct': true},
        ],
      },
    },
    if (includeTeacherAnswer) 'answer_text': '3',
  };
}

Map<String, dynamic> _multipleQuestion() => <String, dynamic>{
      'question_id': _questionId,
      'id': _questionId,
      'order': 1,
      'question_type': 'insertion',
      'question_text': '문장들이 들어가기에 가장 적절한 곳을 고르세요.',
      'passage': _markedPassage,
      'special_data': <String, dynamic>{
        'kind': 'insertion',
        'mode': 'multiple',
        'interaction_type': 'single_choice',
        'insert_sentences': <String, String>{
          'A': 'The first inserted sentence.',
          'B': 'The second inserted sentence.',
        },
        'passage_with_positions': _markedPassage,
        'positions': <int>[1, 2, 3, 4, 5],
      },
    };

Map<String, dynamic> _studentPayload(
  Map<String, dynamic> question,
) =>
    <String, dynamic>{
      'id': _problemSetId,
      'title': 'Semantic Insertion',
      'passage_content':
          'RAW PASSAGE MUST NOT RENDER. The target and markers would duplicate.',
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

Finder _positionChoice(String label, bool selected) =>
    find.byKey(ValueKey('strong-position-$label-$selected'));

Future<void> _tapPosition(WidgetTester tester, String label) async {
  final finder = _positionChoice(label, false).first;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

String _renderedInsertionPassage(WidgetTester tester) {
  final richText = tester.widget<RichText>(
    find.descendant(
      of: find.byType(InsertionPassageView),
      matching: find.byType(RichText),
    ),
  );
  return richText.text.toPlainText();
}

void main() {
  testWidgets('detects semantic insertion from question_type', (tester) async {
    final question = _semanticQuestion(kind: 'semantic_insertion');
    await _withMockClient(
      tester,
      (request) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        expect(find.text('위치 선택'), findsOneWidget);
        expect(find.textContaining(_insertSentence), findsOneWidget);
      },
    );
  });

  testWidgets('detects semantic insertion from special_data kind', (
    tester,
  ) async {
    final question = _semanticQuestion(questionType: 'semantic');
    await _withMockClient(
      tester,
      (request) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        expect(find.text('위치 선택'), findsOneWidget);
      },
    );
  });

  testWidgets('renders given sentence and each marked boundary exactly once', (
    tester,
  ) async {
    final question = _semanticQuestion();
    await _withMockClient(
      tester,
      (request) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        expect(find.textContaining(_insertSentence), findsOneWidget);
        final rendered = _renderedInsertionPassage(tester);
        for (final marker in const <String>['①', '②', '③', '④', '⑤']) {
          expect(RegExp(marker).allMatches(rendered), hasLength(1));
        }
        expect(rendered.indexOf('①'), lessThan(rendered.indexOf('②')));
        expect(rendered.indexOf('②'), lessThan(rendered.indexOf('③')));
        expect(rendered.indexOf('③'), lessThan(rendered.indexOf('④')));
        expect(rendered.indexOf('④'), lessThan(rendered.indexOf('⑤')));
        expect(rendered.trimRight().endsWith('( ⑤ )'), isTrue);
      },
    );
  });

  testWidgets('single selection replaces the previous position', (
    tester,
  ) async {
    final question = _semanticQuestion();
    await _withMockClient(
      tester,
      (request) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        await _tapPosition(tester, '②');
        expect(_positionChoice('②', true), findsOneWidget);
        await _tapPosition(tester, '③');
        expect(_positionChoice('②', false), findsOneWidget);
        expect(_positionChoice('③', true), findsOneWidget);
      },
    );
  });

  testWidgets('serializes position three as numeric answer_text only', (
    tester,
  ) async {
    final question = _semanticQuestion();
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
        await _pumpStudent(tester, question);
        await _tapPosition(tester, '③');
        await tester.tap(find.text('시험 제출'));
        await tester.pumpAndSettle();

        final answers = submitted!['answers'] as List<dynamic>;
        final answer = answers.single as Map<String, dynamic>;
        expect(answer['answer_text'], '3');
        expect(answer.containsKey('selected_index'), isFalse);
      },
    );
  });

  testWidgets('unsafe metadata is ignored before answer selection', (
    tester,
  ) async {
    final question = _semanticQuestion(includeUnsafeMetadata: true);
    await _withMockClient(
      tester,
      (request) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        expect(_positionChoice('③', false), findsOneWidget);
        expect(_positionChoice('③', true), findsNothing);
        for (final leak in const <String>[
          'G4',
          'S4',
          'S3',
          'S5',
          'secret evidence',
          'overall_valid',
          'single_answer',
        ]) {
          expect(find.textContaining(leak), findsNothing);
        }
      },
    );
  });

  testWidgets('does not render raw fallback passage or duplicate marked body', (
    tester,
  ) async {
    final question = _semanticQuestion();
    await _withMockClient(
      tester,
      (request) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        expect(
          find.textContaining('RAW PASSAGE MUST NOT RENDER'),
          findsNothing,
        );
        expect(
          find.textContaining('Researchers first gathered'),
          findsOneWidget,
        );
        expect(find.textContaining(_insertSentence), findsOneWidget);
      },
    );
  });

  testWidgets('teacher preview shows sentence passage answer and explanation', (
    tester,
  ) async {
    final question = _semanticQuestion(includeTeacherAnswer: true);
    final payload = <String, dynamic>{
      'id': _problemSetId,
      'name': 'Semantic Insertion Teacher Preview',
      'passage': <String, dynamic>{'title': 'Shared', 'content': 'Shared body'},
      'questions': <Map<String, dynamic>>[question],
    };
    await _withMockClient(
      tester,
      (request) async => _jsonResponse(payload),
      () async {
        await tester.pumpWidget(
          const MaterialApp(
            home: TeacherProblemSetPreviewScreen(problemSetId: _problemSetId),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ExpansionTile).last);
        await tester.pumpAndSettle();

        expect(find.text(_insertSentence), findsOneWidget);
        expect(find.byType(InsertionPassageView), findsOneWidget);
        expect(_positionChoice('③', true), findsOneWidget);
        expect(find.text('3'), findsWidgets);
        expect(
          find.text('앞 문장의 가정을 however로 받아 뒤의 검증으로 연결한다.'),
          findsOneWidget,
        );
      },
    );
  });

  testWidgets('result review displays selected correct and explanation', (
    tester,
  ) async {
    final summary = <String, dynamic>{
      'total_questions': 1,
      'correct_count': 0,
      'incorrect_count': 1,
      'my_score': 0,
      'wrong_questions': <Map<String, dynamic>>[
        <String, dynamic>{
          'order': 1,
          'label': '삽입',
          'question_text': '문장이 들어갈 위치를 고르세요.',
          'selected_text': '2',
          'correct_text': '3',
          'explanation': '③에서 앞뒤 문맥이 연결된다.',
        },
      ],
    };
    await _withMockClient(
      tester,
      (request) async => _jsonResponse(summary),
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

        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('③에서 앞뒤 문맥이 연결된다.'), findsOneWidget);
      },
    );
  });

  testWidgets(
    'legacy multiple insertion renderer and selection remain intact',
    (tester) async {
      final question = _multipleQuestion();
      await _withMockClient(
        tester,
        (request) async => _jsonResponse(_studentPayload(question)),
        () async {
          await _pumpStudent(tester, question);
          expect(find.textContaining('주어진 문장들'), findsWidgets);
          expect(
            find.textContaining('(A) The first inserted sentence.'),
            findsOneWidget,
          );
          expect(
            find.textContaining('(B) The second inserted sentence.'),
            findsOneWidget,
          );
          expect(find.text('문장별 위치 선택'), findsOneWidget);
          expect(find.byType(StrongPositionChoice), findsNWidgets(10));
        },
      );
    },
  );

  testWidgets('semantic insertion wraps on a narrow layout without overflow', (
    tester,
  ) async {
    final question = _semanticQuestion();
    await _withMockClient(
      tester,
      (request) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        expect(find.byType(InsertionPassageView), findsOneWidget);
        expect(find.byType(StrongPositionChoice), findsNWidgets(5));
        expect(tester.takeException(), isNull);
      },
      surfaceSize: const Size(320, 1800),
    );
  });
}
