import 'package:english_analyzer_app/screens/student_workbook_view_screen.dart';
import 'package:english_analyzer_app/models/learning_assignment.dart';
import 'package:english_analyzer_app/models/workbook.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const teacherOnlyTexts = <String>[
    'visited',
    'ignored',
    'exhibition',
    'office',
    'collection',
    'historical',
    'arriving',
    'Because of',
    'if',
    'available',
  ];

  test('student inline-choice passage hides trailing answer bank', () {
    const raw = '''
I recently [[1:visited|ignored]] the foundation and viewed its
[[2:exhibition|office]] about local history. The numbered blanks remain.

visited
exhibition
collection
historical
arriving
Because of
if
available
''';

    final rendered = renderInlineChoicePassageForStudent(
      raw,
      teacherOnlyTexts: teacherOnlyTexts,
    );

    expect(rendered, contains('(1) ______'));
    expect(rendered, contains('(2) ______'));
    expect(rendered, contains('The numbered blanks remain.'));
    expect(rendered, isNot(contains('\nvisited\n')));
    expect(rendered, isNot(contains('\nexhibition\n')));
    expect(rendered, isNot(contains('\nBecause of\n')));
    expect(rendered, isNot(contains('\navailable')));
  });

  test('collects teacher-only answers from stored inline-choice structure', () {
    const question = WorkbookQuestion(
      id: 7,
      questionType: 'inline_choice',
      orderIndex: 1,
      prompt: 'Choose one option for each blank.',
      answer: <String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'number': 1,
            'answer': 'visited',
            'choices': <String>['visited', 'ignored'],
          },
        ],
      },
      content: <String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'number': 2,
            'answer': 'exhibition',
            'choices': <String>['exhibition', 'office'],
          },
        ],
      },
    );

    expect(
      inlineChoiceTeacherOnlyTextsForStudent(question),
      <String>['exhibition', 'office', 'visited', 'ignored'],
    );
  });

  test('selection completeness and submit payload remain unchanged', () {
    const question = WorkbookQuestion(
      id: 7,
      questionType: 'inline_choice',
      orderIndex: 1,
      prompt: 'Choose one option for each blank.',
      answer: <String, dynamic>{},
      content: <String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'number': 1,
            'choices': <String>['visited', 'ignored'],
          },
          <String, dynamic>{
            'number': 2,
            'choices': <String>['exhibition', 'office'],
          },
        ],
      },
    );
    final selected = <int, int>{7001: 0, 7002: 1};

    expect(isInlineChoiceAnsweredForStudent(question, selected), isTrue);
    expect(
      buildInlineChoiceSubmitAnswersForStudent(question, selected),
      <Map<String, dynamic>>[
        <String, dynamic>{
          'question_id': 7,
          'question_type': 'inline_choice',
          'item_number': 1,
          'student_answer': 'visited',
        },
        <String, dynamic>{
          'question_id': 7,
          'question_type': 'inline_choice',
          'item_number': 2,
          'student_answer': 'office',
        },
      ],
    );
  });

  test('cleanup is opt-in so other workbook types keep their passage', () {
    const passage = 'A vocabulary note remains visible.\nvisited\navailable';
    expect(renderInlineChoicePassageForStudent(passage), passage);
  });

  test('removes a compact answer bank and following teacher-only hint', () {
    const raw = '''
This sufficiently long passage contains [[1:visited|ignored]] and continues
with enough student-facing context before the teacher-only material.

visited, exhibition, collection, historical, arriving, Because of, if, available
This teacher explanation is intentionally much longer than a short word-bank note and must not be shown before the student answers.
''';

    final rendered = renderInlineChoicePassageForStudent(
      raw,
      teacherOnlyTexts: teacherOnlyTexts,
    );

    expect(rendered, contains('(1) ______'));
    expect(rendered, isNot(contains('visited, exhibition')));
    expect(rendered, isNot(contains('teacher explanation')));
  });

  test('removes a mixed standalone and parenthetical trailing answer bank', () {
    const raw = '''
The traveler [[1:visited|ignored]] the museum and viewed its
[[2:exhibition|concealment]] before studying the [[3:collection|separation]].
The [[4:historical|spiritual]] account then described people
[[5:arriving|leaving]] early [[6:Because of|Despite]] the weather,
[[7:if|unless]] enough seats were [[8:available|hidden]].

visited
exhibition (concealment 숨김, 은폐)
collection (separation 분리)
historical (spiritual 정신적인)
arriving
Because of
if
available
''';
    const values = <String>[
      'visited',
      'ignored',
      'exhibition',
      'concealment',
      'collection',
      'separation',
      'historical',
      'spiritual',
      'arriving',
      'leaving',
      'Because of',
      'Despite',
      'if',
      'unless',
      'available',
      'hidden',
    ];

    final rendered = renderInlineChoicePassageForStudent(
      raw,
      teacherOnlyTexts: values,
    );

    for (var number = 1; number <= 8; number++) {
      expect(rendered, contains('($number) ______'));
    }
    expect(rendered, isNot(contains('\nvisited')));
    expect(rendered, isNot(contains('exhibition (concealment')));
    expect(rendered, isNot(contains('collection (separation')));
    expect(rendered, isNot(contains('historical (spiritual')));
    expect(rendered, isNot(contains('\narriving')));
    expect(rendered, isNot(contains('\nBecause of')));
    expect(rendered, isNot(contains('\navailable')));
  });

  test('keeps matching words used naturally in the middle of the passage', () {
    const raw = '''
The visitor found that the exhibition was available in the afternoon.
She had visited it before, but the collection remained interesting.
Later she [[1:returned|departed]] after reading the final description.

returned
departed
''';

    final rendered = renderInlineChoicePassageForStudent(
      raw,
      teacherOnlyTexts: const <String>[
        'exhibition',
        'available',
        'visited',
        'collection',
        'returned',
        'departed',
      ],
    );

    expect(rendered, contains('exhibition was available'));
    expect(rendered, contains('had visited it before'));
    expect(rendered, contains('collection remained interesting'));
    expect(rendered, isNot(contains('\nreturned')));
    expect(rendered, isNot(contains('\ndeparted')));
  });

  test('collects correct and wrong aliases from legacy stored items', () {
    const question = WorkbookQuestion(
      id: 8,
      questionType: 'inline_choice',
      orderIndex: 1,
      prompt: 'Choose one option for each blank.',
      answer: <String, dynamic>{},
      content: <String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'number': 1,
            'correct': ' exhibition ',
            'wrong': 'concealment',
            'choices': <String>['exhibition', 'concealment'],
          },
        ],
      },
    );

    expect(
      inlineChoiceTeacherOnlyTextsForStudent(question),
      <String>['exhibition', 'concealment'],
    );
  });

  testWidgets(
      'actual Student Workbook card uses cleaned passage and keeps answer choices',
      (tester) async {
    final items = <Map<String, dynamic>>[
      <String, dynamic>{
        'number': 1,
        'correct': 'visited',
        'wrong': 'ignored',
        'choices': <String>['visited', 'ignored'],
      },
      <String, dynamic>{
        'number': 2,
        'correct': 'exhibition',
        'wrong': 'concealment',
        'choices': <String>['exhibition', 'concealment'],
      },
      <String, dynamic>{
        'number': 3,
        'correct': 'collection',
        'wrong': 'separation',
        'choices': <String>['collection', 'separation'],
      },
      <String, dynamic>{
        'number': 4,
        'correct': 'historical',
        'wrong': 'spiritual',
        'choices': <String>['historical', 'spiritual'],
      },
      for (var number = 5; number <= 10; number++)
        <String, dynamic>{
          'number': number,
          'correct': 'correct$number',
          'wrong': 'wrong$number',
          'choices': <String>['correct$number', 'wrong$number'],
        },
    ];
    final markers = <String>[
      for (var number = 1; number <= 10; number++)
        '[[$number:correct$number|wrong$number]]',
    ]..[0] = '[[1:visited|ignored]]';
    const bank = '''
visited
exhibition (concealment 숨김, 은폐)
collection (separation 분리)
historical (spiritual 정신적인)
correct5
correct6
correct7
correct8
correct9
correct10
''';
    final rawPassage =
        'This sufficiently long student passage keeps ten numbered blanks '
        '${markers.join(' in a natural sentence ')}.\n\n$bank';
    final question = WorkbookQuestion(
      id: 77,
      questionType: 'inline_choice',
      orderIndex: 1,
      prompt: 'Choose the correct expression.',
      passageText: rawPassage,
      answer: <String, dynamic>{'items': items},
      content: <String, dynamic>{
        'type': 'inline_choice',
        'passage_text': rawPassage,
        'items': items,
      },
    );
    final workbook = Workbook(
      id: 3,
      title: 'Inline choice workbook',
      status: 'published',
      questionCount: 1,
      questions: <WorkbookQuestion>[question],
    );
    const assignment = LearningAssignment(
      id: 4,
      teacherId: 1,
      studentId: 2,
      contentType: 'workbook',
      contentId: 3,
      title: 'Assignment',
      status: 'in_progress',
      assignedAt: '2026-08-04T00:00:00',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StudentWorkbookViewScreen(
          assignment: assignment,
          initialWorkbook: workbook,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final passageFinder = find.byKey(
      const ValueKey<String>('student-workbook-passage-77'),
    );
    expect(passageFinder, findsOneWidget);
    final passageText = tester.widget<Text>(passageFinder).data ?? '';
    expect(passageText, contains('(1) ______'));
    expect(passageText, contains('(10) ______'));
    expect(passageText, isNot(contains('\nvisited')));
    expect(passageText, isNot(contains('concealment 숨김, 은폐')));
    expect(passageText, isNot(contains('separation 분리')));
    expect(passageText, isNot(contains('spiritual 정신적인')));

    final answerArea = find.byKey(
      const ValueKey<String>('student-workbook-answer-area-77'),
    );
    expect(answerArea, findsOneWidget);
    expect(
      find.descendant(of: answerArea, matching: find.text('visited')),
      findsOneWidget,
    );
  });

  testWidgets(
      'Lambsford Student card removes legacy bank and preserves letter closing',
      (tester) async {
    const items = <Map<String, dynamic>>[
      <String, dynamic>{
        'number': 1,
        'choices': <String>['visited', 'am visited'],
      },
      <String, dynamic>{
        'number': 2,
        'choices': <String>['concealment', 'exhibition'],
      },
      <String, dynamic>{
        'number': 3,
        'choices': <String>['collection', 'separation'],
      },
      <String, dynamic>{
        'number': 4,
        'choices': <String>['historical', 'spiritual'],
      },
      <String, dynamic>{
        'number': 5,
        'choices': <String>['arrive', 'arriving'],
      },
      <String, dynamic>{
        'number': 6,
        'choices': <String>['Because of', 'Since'],
      },
      <String, dynamic>{
        'number': 7,
        'choices': <String>['if', 'that'],
      },
      <String, dynamic>{
        'number': 8,
        'choices': <String>['available', 'availably'],
      },
      <String, dynamic>{
        'number': 9,
        'choices': <String>['working', 'worked'],
      },
      <String, dynamic>{
        'number': 10,
        'choices': <String>['sorrowful', 'thankful'],
      },
    ];
    const rawPassage = '''
To Whom It May Concern,

I recently [[1:visited|am visited]] the Lambsford History Foundation’s [[2:concealment|exhibition]] about the Qukkon Gold Rush. The [[3:collection|separation]] of pictures, tools, and [[4:historical|spiritual]] documents made the gold miners [[5:arrive|arriving]] to Qukkon come to life. This reminded me of when I lived in Qukkon and worked in the mining industry. [[6:Because of|Since]] this, I’m wondering [[7:if|that]] there are volunteer guide positions [[8:available|availably]] for this exhibition. I can share my experiences [[9:working|worked]] in the extreme cold of Qukkon. Again, I would be [[10:sorrowful|thankful]] if you could tell me about the availability of volunteer positions as a guide.

visited

exhibition (concealment 숨김, 은폐)

collection (separation 분리)

historical (spiritual 정신적인)

arriving

Because of

if

available

working

thankful (sorrowful 슬픈)

Sincerely,Jonathan Hamilton
''';
    const question = WorkbookQuestion(
      id: 1,
      questionType: 'inline_choice',
      orderIndex: 1,
      prompt: '본문에서 알맞은 표현을 고르세요.',
      passageText: rawPassage,
      answer: <String, dynamic>{},
      content: <String, dynamic>{
        'unit_title': 'Unit 1 Gateway',
        'passage_text': rawPassage,
        'items': items,
      },
    );
    const workbook = Workbook(
      id: 1,
      title: 'Lambsford workbook',
      status: 'published',
      questionCount: 1,
      questions: <WorkbookQuestion>[question],
    );
    const assignment = LearningAssignment(
      id: 1,
      teacherId: 1,
      studentId: 2,
      contentType: 'workbook',
      contentId: 1,
      title: 'Lambsford assignment',
      status: 'in_progress',
      assignedAt: '2026-08-04T00:00:00',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: StudentWorkbookViewScreen(
          assignment: assignment,
          initialWorkbook: workbook,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final passageFinder = find.byKey(
      const ValueKey<String>('student-workbook-passage-1'),
    );
    final passageText = tester.widget<Text>(passageFinder).data ?? '';
    expect(passageText, contains('To Whom It May Concern'));
    expect(passageText, contains('Lambsford History Foundation'));
    expect(passageText, contains('Qukkon Gold Rush'));
    for (var number = 1; number <= 10; number++) {
      expect(passageText, contains('($number) ______'));
    }
    expect(passageText, contains('Sincerely,Jonathan Hamilton'));
    expect(passageText, isNot(contains('\nvisited')));
    expect(passageText, isNot(contains('concealment 숨김, 은폐')));
    expect(passageText, isNot(contains('separation 분리')));
    expect(passageText, isNot(contains('spiritual 정신적인')));

    final answerArea = find.byKey(
      const ValueKey<String>('student-workbook-answer-area-1'),
    );
    expect(
      find.descendant(of: answerArea, matching: find.text('visited')),
      findsOneWidget,
    );
  });

  testWidgets('cleaned passage wraps without overflow at 260px',
      (tester) async {
    const raw = '''
This sufficiently long student passage contains [[1:visited|ignored]] and
continues naturally on a narrow screen without exposing its answer bank.

visited
ignored
available
''';
    final rendered = renderInlineChoicePassageForStudent(
      raw,
      teacherOnlyTexts: teacherOnlyTexts,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 260,
              child: Text(rendered),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('(1) ______'), findsOneWidget);
    expect(find.textContaining('\nvisited\n'), findsNothing);
  });
}
