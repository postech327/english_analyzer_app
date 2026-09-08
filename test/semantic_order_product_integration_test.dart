import 'dart:convert';

import 'package:english_analyzer_app/screens/student/student_exam_result_screen.dart';
import 'package:english_analyzer_app/screens/student/student_exam_take_screen.dart';
import 'package:english_analyzer_app/screens/teacher/teacher_problem_set_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _problemSetId = 904;

Map<String, dynamic> _semanticQuestion({
  String questionType = 'order',
  String kind = 'order',
  bool includeAnswerMetadata = false,
}) {
  return <String, dynamic>{
    'question_id': 91,
    'id': 91,
    'order': 1,
    'question_type': questionType,
    'question_text': '주어진 글 다음에 이어질 글의 순서를 정하세요.',
    'explanation': 'C의 지시어가 도입을 잇고, B와 D가 그 뒤를 따른다.',
    'special_data': <String, dynamic>{
      'kind': kind,
      'order_mode': 'fixed_start',
      'fixed_start': 'A',
      'fixed_start_text': 'Intro fixed passage.',
      'blocks': <String, String>{
        'A': 'Intro fixed passage.',
        'B': 'Block one follows the reference.',
        'C': 'Block two opens the sequence.',
        'D': 'Block three closes the sequence.',
      },
      'selectable_blocks': <String>['B', 'C', 'D'],
      if (includeAnswerMetadata) ...<String, dynamic>{
        'answer_order': <String>['C', 'B', 'D'],
        'answer_text': 'C-B-D',
        'correct_order': <String>['C', 'B', 'D'],
        'correct_sequence': 'C-B-D',
        'judge_result': <String, dynamic>{'winner': 'C-B-D'},
        'validation': <String, dynamic>{'unique': true},
        'semantic_constraints': <String>['C before B'],
      },
    },
    if (includeAnswerMetadata) 'answer_text': 'C-B-D',
  };
}

Map<String, dynamic> _studentPayload(Map<String, dynamic> question) =>
    <String, dynamic>{
      'id': _problemSetId,
      'title': 'Semantic Order',
      'passage_content':
          'RAW PASSAGE MUST NOT RENDER. Answer: C-B-D. Duplicate block tail.',
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
  Future<void> Function() body,
) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1600));
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

Finder _orderBlock(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(InkWell));

Future<void> _tapOrderBlock(WidgetTester tester, String text) async {
  final block = _orderBlock(text).first;
  await tester.ensureVisible(block);
  final rect = tester.getRect(block);
  await tester.tapAt(rect.topLeft + const Offset(18, 18));
  await tester.pump();
}

void main() {
  testWidgets('detects semantic Order from question_type', (tester) async {
    final question = _semanticQuestion(kind: 'semantic_order');
    await _withMockClient(
      tester,
      (request) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        expect(find.text('순서 배열'), findsOneWidget);
        expect(find.textContaining('B, C, D 블록'), findsOneWidget);
      },
    );
  });

  testWidgets('detects semantic Order from special_data.kind', (tester) async {
    final question = _semanticQuestion(questionType: 'semantic');
    await _withMockClient(
      tester,
      (request) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        expect(find.text('순서 배열'), findsOneWidget);
        expect(find.text('Block two opens the sequence.'), findsOneWidget);
      },
    );
  });

  testWidgets('renders fixed A content and movable B C D blocks', (
    tester,
  ) async {
    final question = _semanticQuestion();
    await _withMockClient(
      tester,
      (request) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        expect(
          find.textContaining('주어진 글\nIntro fixed passage.'),
          findsOneWidget,
        );
        expect(find.text('(B)'), findsOneWidget);
        expect(find.text('(C)'), findsOneWidget);
        expect(find.text('(D)'), findsOneWidget);
      },
    );
  });

  testWidgets('preserves direct C then B then D selection order', (
    tester,
  ) async {
    final question = _semanticQuestion();
    await _withMockClient(
      tester,
      (request) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        await _tapOrderBlock(tester, 'Block two opens the sequence.');
        await _tapOrderBlock(tester, 'Block one follows the reference.');
        await _tapOrderBlock(tester, 'Block three closes the sequence.');

        expect(find.text('선택한 순서: C-B-D'), findsOneWidget);
        expect(
          find.descendant(
            of: _orderBlock('Block two opens the sequence.').first,
            matching: find.text('1'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: _orderBlock('Block one follows the reference.').first,
            matching: find.text('2'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: _orderBlock('Block three closes the sequence.').first,
            matching: find.text('3'),
          ),
          findsOneWidget,
        );
      },
    );
  });

  testWidgets('reselecting a block follows the existing toggle contract', (
    tester,
  ) async {
    final question = _semanticQuestion();
    await _withMockClient(
      tester,
      (request) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        await _tapOrderBlock(tester, 'Block two opens the sequence.');
        await _tapOrderBlock(tester, 'Block one follows the reference.');
        await _tapOrderBlock(tester, 'Block two opens the sequence.');

        expect(find.text('선택한 순서: B'), findsOneWidget);
        expect(find.text('(C)'), findsOneWidget);
      },
    );
  });

  testWidgets(
    'fixed A is not selectable and incomplete Order is not submitted',
    (tester) async {
      final question = _semanticQuestion();
      var submitted = false;
      await _withMockClient(
        tester,
        (request) async {
          if (request.method == 'POST') submitted = true;
          return _jsonResponse(_studentPayload(question));
        },
        () async {
          await _pumpStudent(tester, question);
          expect(find.text('(A)'), findsNothing);
          expect(_orderBlock('Intro fixed passage.'), findsNothing);
          await _tapOrderBlock(tester, 'Block two opens the sequence.');
          await tester.tap(find.text('시험 제출'));
          await tester.pump();
          expect(submitted, isFalse);
          expect(find.textContaining('아직 선택하지 않은 문제가 있습니다'), findsOneWidget);
        },
      );
    },
  );

  testWidgets(
    'serializes direct Order answer as C-B-D without selected_index',
    (tester) async {
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
          await _tapOrderBlock(tester, 'Block two opens the sequence.');
          await _tapOrderBlock(tester, 'Block one follows the reference.');
          await _tapOrderBlock(tester, 'Block three closes the sequence.');
          await tester.tap(find.text('시험 제출'));
          await tester.pumpAndSettle();

          final answers = submitted!['answers'] as List<dynamic>;
          final answer = answers.single as Map<String, dynamic>;
          expect(answer['answer_text'], 'C-B-D');
          expect(answer.containsKey('selected_index'), isFalse);
        },
      );
    },
  );

  testWidgets('ignores accidental answer metadata and raw passage pre-submit', (
    tester,
  ) async {
    final question = _semanticQuestion(includeAnswerMetadata: true);
    await _withMockClient(
      tester,
      (request) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        expect(find.text('선택한 순서: -'), findsOneWidget);
        expect(find.text('C-B-D'), findsNothing);
        expect(
          find.textContaining('RAW PASSAGE MUST NOT RENDER'),
          findsNothing,
        );
        expect(find.textContaining('winner'), findsNothing);
        expect(find.textContaining('C before B'), findsNothing);
      },
    );
  });

  testWidgets('teacher preview renders fixed blocks answer and explanation', (
    tester,
  ) async {
    final question = _semanticQuestion(includeAnswerMetadata: true);
    final payload = <String, dynamic>{
      'id': _problemSetId,
      'name': 'Semantic Order Teacher Preview',
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

        expect(find.text('Intro fixed passage.'), findsOneWidget);
        expect(find.text('Block one follows the reference.'), findsOneWidget);
        expect(find.text('Block two opens the sequence.'), findsOneWidget);
        expect(find.text('Block three closes the sequence.'), findsOneWidget);
        expect(find.text('C-B-D'), findsOneWidget);
        expect(find.text('C의 지시어가 도입을 잇고, B와 D가 그 뒤를 따른다.'), findsOneWidget);
      },
    );
  });

  testWidgets('result review reuses selected correct and explanation fields', (
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
          'label': '순서',
          'question_text': '글의 순서를 정하세요.',
          'selected_text': 'B-C-D',
          'correct_text': 'C-B-D',
          'explanation': 'C가 먼저 문맥을 연결한다.',
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

        expect(find.text('B-C-D'), findsOneWidget);
        expect(find.text('C-B-D'), findsOneWidget);
        expect(find.text('C가 먼저 문맥을 연결한다.'), findsOneWidget);
      },
    );
  });

  testWidgets('legacy Actual Q9 fixture uses the same Order renderer', (
    tester,
  ) async {
    final question = _semanticQuestion()
      ..['question_text'] = 'Actual Q9 legacy order question';
    await _withMockClient(
      tester,
      (request) async => _jsonResponse(_studentPayload(question)),
      () async {
        await _pumpStudent(tester, question);
        expect(find.text('순서 배열'), findsOneWidget);
        expect(
          find.textContaining('주어진 글\nIntro fixed passage.'),
          findsOneWidget,
        );
        expect(find.text('(B)'), findsOneWidget);
        expect(find.text('(C)'), findsOneWidget);
        expect(find.text('(D)'), findsOneWidget);
      },
    );
  });
}
