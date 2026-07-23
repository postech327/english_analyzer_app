import 'package:english_analyzer_app/utils/question_hwpx_import_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const answerVariants = <String>[
    '(A) ② (B) ⑤',
    'A ② B ⑤',
    'A 2 B 5',
    'A:2, B:5',
    'A-2 / B-5',
  ];

  for (final answer in answerVariants) {
    test('parses multiple insertion answer: $answer', () {
      final draft = parseQuestionHwpxImportText(_source(answer));

      expect(draft.questions, hasLength(1));
      final question = draft.questions.single;
      expect(question.questionType, 'insertion');
      expect(question.isSaveable, isTrue, reason: question.saveabilityReason);
      expect(question.answerIndex, isNull);
      expect(question.answerText, 'A:2,B:5');
      expect(question.specialData, <String, dynamic>{
        'kind': 'insertion',
        'mode': 'multiple',
        'insert_sentences': <String, String>{
          'A':
              'Likewise, any actions the polluter can take to reduce their tax liability also reduce emission.',
          'B':
              'Nevertheless, the technologies for monitoring the concentrations and flows of specific substances in waste discharges have been advancing quickly.',
        },
        'passage_with_positions':
            'Environmental taxes can be precisely targeted. (①) When emissions rise, the tax base rises. (②) The polluter has an incentive to reduce emissions. (③) Lowering the tax burden reduces emissions. (④) Continuous measurement can be costly. (⑤) Future applications may be wider. (⑥)',
        'positions': <int>[1, 2, 3, 4, 5, 6],
        'answer_positions': <String, int>{'A': 2, 'B': 5},
      });
      expect(question.warnings, isEmpty);
    });
  }

  test('keeps passage text when positions use bare circled markers', () {
    final draft = parseQuestionHwpxImportText(
      _source('A ② B ⑤').replaceAllMapped(
        RegExp(r'\(([①②③④⑤⑥])\)'),
        (match) => match.group(1) ?? '',
      ),
    );

    final question = draft.questions.single;
    expect(question.isSaveable, isTrue, reason: question.saveabilityReason);
    expect(
      question.specialData?['passage_with_positions'],
      startsWith('Environmental taxes can be precisely targeted.'),
    );
    expect(question.specialData?['positions'], <int>[1, 2, 3, 4, 5, 6]);
  });

  test('keeps the existing exact single insertion repair saveable', () {
    final draft = parseQuestionHwpxImportText('''
<기본>
5) 글의 흐름으로 보아, 주어진 문장이 들어가기에 가장 적절한 곳은?
The owners had to secure the locations where flint was discovered, and the first property rights developed.
After learning how to fasten a stone tip to a wooden handle. (①) People improved their tools. (②) Useful stone became valuable. (③) Communities protected resources. (④) Ownership rules emerged. (⑤) Those rules spread. (⑥)
[정답] ⑤
''');

    final question = draft.questions.single;
    expect(question.isSaveable, isTrue, reason: question.saveabilityReason);
    expect(question.answerText, '5');
    expect(question.specialData?['mode'], 'single');
    expect(question.specialData?['answer_position'], 5);
  });

  test('keeps the existing order parser saveable', () {
    final draft = parseQuestionHwpxImportText('''
<기본>
1) 주어진 글 다음에 이어질 글의 순서로 가장 적절한 것은?
This is the fixed opening paragraph.
(A) This is the first movable paragraph.
(B) This is the second movable paragraph.
(C) This is the third movable paragraph.
[정답] C-B-A
''');

    final question = draft.questions.single;
    expect(question.isSaveable, isTrue, reason: question.saveabilityReason);
    expect(question.questionType, 'order');
    expect(question.answerText, 'C-B-A');
    expect(question.specialData?['answer_order'], <String>['C', 'B', 'A']);
  });

  test('uses seven numbered prompts instead of ten answer-side boundaries', () {
    final draft = parseQuestionHwpxImportText(_sevenQuestionSource);

    expect(draft.questions, hasLength(7));
    expect(
      draft.questions.map((question) => question.questionNo),
      <int>[1, 2, 3, 4, 5, 6, 7],
    );
    expect(
      draft.questions.where((question) => question.isSaveable).length,
      7,
    );
    final multiple = draft.questions[5];
    expect(multiple.questionType, 'insertion');
    expect(multiple.specialData?['mode'], 'multiple');
    expect(multiple.answerText, 'A:2,B:5');
    expect(multiple.specialData?['positions'], <int>[1, 2, 3, 4, 5, 6]);
    expect(draft.questions[6].isSaveable, isTrue);
    expect(draft.questions[6].answerText, '3');
  });

  test('merges ten prompt-less fallback fragments into seven candidates', () {
    final draft = parseQuestionHwpxImportText(_actualFallbackFragmentSource);

    expect(draft.questions, hasLength(7));
    expect(
      draft.questions.map((question) => question.questionNo),
      <int>[1, 2, 3, 4, 5, 6, 7],
    );
    expect(
      draft.questions.where((question) => question.isSaveable).length,
      7,
    );
    final multiple = draft.questions[5];
    expect(multiple.questionType, 'insertion');
    expect(multiple.questionText, contains('주어진 문장들이'));
    expect(multiple.specialData?['mode'], 'multiple');
    expect(multiple.answerText, 'A:2,B:5');
    expect(multiple.specialData?['insert_sentences'], hasLength(2));
    expect(
      (multiple.specialData?['insert_sentences'] as Map)['B'],
      'Nevertheless, the technologies for monitoring the concentrations and flows of specific substances in waste discharges have been advancing quickly.',
    );
    expect(
      multiple.specialData?['passage_with_positions'],
      startsWith('Environmental taxes can be precisely targeted.'),
    );
    expect(multiple.specialData?['positions'], <int>[1, 2, 3, 4, 5, 6]);
    expect(draft.questions[6].isSaveable, isTrue);
    expect(draft.questions[6].answerText, '3');
    expect(draft.questions[6].questionType, 'irrelevant');
    expect(draft.questions[6].questionText, isNotEmpty);
  });
}

String _source(String answer) => '''
<기본>
6) 글의 흐름으로 보아, 주어진 문장들이 들어가기에 가장 적절한 곳은?
(A) Likewise, any actions the polluter can take to reduce their tax liability also reduce emission.
(B) Nevertheless, the technologies for monitoring the concentrations and flows of specific substances in waste discharges have been advancing quickly.
본문: Environmental taxes can be precisely targeted. (①) When emissions rise, the tax base rises. (②) The polluter has an incentive to reduce emissions. (③) Lowering the tax burden reduces emissions. (④) Continuous measurement can be costly. (⑤) Future applications may be wider. (⑥)
[정답] $answer
''';

const _sevenQuestionSource = '''
<기본>
1) 주어진 글 다음에 이어질 글의 순서로 가장 적절한 것은?
Opening one.
(A) First A.
(B) First B.
(C) First C.
[정답] C-B-A
2번 주어진 글 다음에 이어질 글의 순서로 가장 적절한 것은?
Opening two.
(A) Second A.
(B) Second B.
(C) Second C.
[정답] A-C-B
3) 주어진 글 사이에 이어질 글의 순서로 가장 적절한 것은?
Opening three.
(A) Third A.
(B) Third B.
(C) Third C.
[정답] B-A-C
4번 주어진 글 다음에 이어질 글의 순서로 가장 적절한 것은?
Opening four.
(A) Fourth A.
(B) Fourth B.
(C) Fourth C.
[정답] C-B-A
5) 글의 흐름으로 보아, 주어진 문장이 들어가기에 가장 적절한 곳은?
The owners had to secure the locations where flint was discovered, and the first property rights developed.
After learning how to fasten a stone tip to a wooden handle. (①) People improved their tools. (②) Useful stone became valuable. (③) Communities protected resources. (④) Ownership rules emerged. (⑤) Those rules spread. (⑥)
[정답] ⑤
6) 글의 흐름으로 보아, 주어진 문장들이 들어가기에 가장 적절한 곳은?
(A) Likewise, any actions the polluter can take to reduce their tax liability also reduce emission.
(B) Nevertheless, the technologies for monitoring the concentrations and flows of specific substances in waste discharges have been advancing quickly.
Environmental taxes can be precisely targeted. (①) When emissions rise, the tax base rises. (②) The polluter has an incentive to reduce emissions. (③) Lowering the tax burden reduces emissions. (④) Continuous measurement can be costly. (⑤) Future applications may be wider. (⑥)
[정답] (A) ② (B) ⑤
[정답] (A)
[정답] ⑥
[정답] ⑤
7) 다음 글에서 전체 흐름과 관계 없는 문장은?
① Sentence one.
② Sentence two.
③ Sentence three.
④ Sentence four.
⑤ Sentence five.
[정답] ③
''';

const _actualFallbackFragmentSource = '''
[수능특강(영어) 18강 1번 변형]
주어진 글 다음에 이어질 글의 순서로 가장 적절한 것은?
Opening one.
(A) First A.
(B) First B.
(C) First C.
[정답] C-B-A
[수능특강(영어) 19강 1번 변형]
주어진 글 다음에 이어질 글의 순서로 가장 적절한 것은?
Opening two.
(A) Second A.
(B) Second B.
(C) Second C.
[정답] A-C-B
[수능특강(영어) 20강 1번 변형]
주어진 글 사이에 이어질 글의 순서로 가장 적절한 것은?
Opening three.
(A) Third A.
(B) Third B.
(C) Third C.
[정답] B-A-C
[수능특강(영어) 20강 2번 변형]
주어진 글 다음에 이어질 글의 순서로 가장 적절한 것은?
Opening four.
(A) Fourth A.
(B) Fourth B.
(C) Fourth C.
[정답] C-B-A
[수능특강(영어) 21강 Gateway번 변형]
글의 흐름으로 보아, 주어진 문장이 들어가기에 가장 적절한 곳은?
The owners had to secure the locations where flint was discovered, and the first property rights developed.
After learning how to fasten a stone tip to a wooden handle. (①) People improved their tools. (②) Useful stone became valuable. (③) Communities protected resources. (④) Ownership rules emerged. (⑤) Those rules spread. (⑥)
[정답] ⑤
[정답] ⑤
[수능특강(영어) 22강 Gateway번 변형]
(A) Likewise, any actions the polluter can take to reduce their tax liability also reduce emission. (B) Nevertheless, the technologies for monitoring the concentrations and flows of specific substances in waste discharges have been advancing quickly. Environmental taxes can be precisely targeted. (①) When emissions rise, the tax base rises. (②) The polluter has an incentive to reduce emissions. (③) Lowering the tax burden reduces emissions. (④) Continuous measurement can be costly. (⑤) Future applications may be wider. (⑥)
[정답] (A) ② (B) ⑤
[정답] (A)
[수능특강(영어) 23강 1번 변형]
① Sentence one.
② Sentence two.
③ Sentence three.
④ Sentence four.
⑤ Sentence five.
[정답] ③
[정답] ⑤
''';
