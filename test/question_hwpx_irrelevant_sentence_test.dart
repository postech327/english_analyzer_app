import 'package:english_analyzer_app/utils/question_hwpx_import_parser.dart';
import 'package:english_analyzer_app/utils/irrelevant_display_passage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final answer in const <String>['⑤', '5', '5번', '(⑤)']) {
    test('parses irrelevant sentence answer $answer', () {
      final draft = parseQuestionHwpxImportText(_source(answer));

      expect(draft.questions, hasLength(1));
      final question = draft.questions.single;
      expect(question.questionType, 'irrelevant');
      expect(question.isSaveable, isTrue, reason: question.saveabilityReason);
      expect(question.choices, isEmpty);
      expect(question.answerIndex, isNull);
      expect(question.answerText, '5');
      expect(question.specialData?['kind'], 'irrelevant');
      expect(question.specialData?['mode'], 'single');
      expect(question.specialData?['positions'], <int>[1, 2, 3, 4, 5, 6, 7]);
      expect(question.specialData?['answer_position'], 5);
      expect(question.specialData?['numbered_sentences'], hasLength(7));
      final numbered = question.specialData?['numbered_sentences'] as List;
      expect(
        numbered.every(
          (item) =>
              leadingIrrelevantPosition(
                (item as Map)['text'].toString(),
              ) ==
              null,
        ),
        isTrue,
      );
      expect(question.passage, contains('⑤ This sentence changes the topic.'));
      expect(question.passage, isNot(contains('해설')));
      expect(question.passage, isNot(contains('어휘')));
      expect(question.explanation, contains('다섯 번째'));
    });
  }

  test('repairs a promptless fragmented biology candidate', () {
    final draft = parseQuestionHwpxImportText(_promptlessFragmentSource);

    expect(draft.questions, hasLength(1));
    final question = draft.questions.single;
    expect(question.questionNo, 7);
    expect(question.questionType, 'irrelevant');
    expect(question.questionText, '다음 글에서 전체 흐름과 관계없는 문장은?');
    expect(question.isSaveable, isTrue, reason: question.saveabilityReason);
    expect(question.answerIndex, isNull);
    expect(question.answerText, '5');
    expect(question.specialData?['answer_position'], 5);
    expect(question.specialData?['positions'], <int>[1, 2, 3, 4, 5, 6, 7]);
    expect(question.specialData?['numbered_sentences'], hasLength(7));
    expect(question.passage, startsWith('There is a problem in biology'));
    expect(question.passage, isNot(contains('glance 힐끗 봄')));
    expect(question.passage, isNot(contains('counterintuitive 직관에 반하는')));
    expect(question.passage, contains('① An increase in food supply'));
    expect(question.passage, contains('⑦ This demonstrates'));
  });
  test('repairs the final missing-type draft when markers are unavailable', () {
    final draft = parseQuestionHwpxImportText(_actualMissingTypeFragmentSource);

    expect(draft.questions, hasLength(1));
    final question = draft.questions.single;
    expect(question.questionNo, 7);
    expect(question.questionType, 'irrelevant');
    expect(question.questionText,
        '\uB2E4\uC74C \uAE00\uC5D0\uC11C \uC804\uCCB4 \uD750\uB984\uACFC \uAD00\uACC4\uC5C6\uB294 \uBB38\uC7A5\uC740?');
    expect(question.answerIndex, isNull);
    expect(question.answerText, '5');
    expect(question.specialData?['answer_position'], 5);
    expect(question.specialData?['positions'], hasLength(7));
    expect(question.specialData?['numbered_sentences'], hasLength(7));
    expect(question.passage, startsWith('There is a problem'));
    expect(question.passage, isNot(contains('glance \uD790\uB057 \uBD04')));
    expect(question.warnings, isEmpty);
    expect(question.isSaveable, isTrue, reason: question.saveabilityReason);
    expect(question.saveabilityReason, 'ok');
  });

  test('uses passage with numbers without rebuilding marker prefixes', () {
    final display = irrelevantPassageForDisplay(<String, dynamic>{
      'passage_with_numbers': '''
There is a problem in biology.
① An increase in food supply changes prey populations.
② Yet the result can be counterintuitive.
③ Predators may also increase.
*paradox 역설에 대한 어휘 설명
''',
      'numbered_sentences': <Map<String, dynamic>>[
        <String, dynamic>{'position': 1, 'text': 'SHOULD NOT RENDER'},
      ],
    });

    expect(
      display,
      'There is a problem in biology.\n'
      '① An increase in food supply changes prey populations.\n'
      '② Yet the result can be counterintuitive.\n'
      '③ Predators may also increase.',
    );
    expect(display, isNot(contains('SHOULD NOT RENDER')));
    expect(display, isNot(contains('*paradox')));
  });

  test('does not add position prefixes when only numbered sentences remain',
      () {
    final display = irrelevantPassageForDisplay(<String, dynamic>{
      'numbered_sentences': <Map<String, dynamic>>[
        <String, dynamic>{'position': 1, 'text': 'An increase in food supply.'},
        <String, dynamic>{'position': 2, 'text': '② Yet, in reality.'},
      ],
    });

    expect(display, 'An increase in food supply.\n② Yet, in reality.');
    expect(display, isNot(startsWith('①')));
  });

  test('keeps only the rightmost duplicate marker at any text position', () {
    final display = irrelevantPassageForDisplay(<String, dynamic>{
      'passage_with_numbers': '''
There is a problem. ① ① An increase in food supply.
②② Yet, in reality.
(③) ③ For instance.
4) ④ However.
⑤ ⑤ ⑤ In some ecosystems.
At first glance, this remains surprising.
glance 힐끗 봄
counterintuitive 직관에 반하는
instability 불안정성
align with ~에 부합하다
''',
    });

    expect(
      display,
      '''
There is a problem.
① An increase in food supply.
② Yet, in reality.
③ For instance.
④ However.
⑤ In some ecosystems.
At first glance, this remains surprising.''',
    );
  });

  test('strips a shifted generated marker sequence from the actual raw text',
      () {
    final display = irrelevantPassageForDisplay(<String, dynamic>{
      'passage_with_numbers': '''
There is a problem in biology known as the “paradox of enrichment.” At first glance, it may seem logical to assume that predators would thrive if their prey had more food available. ❶ An increase in food supply for prey should result in a population boom. ❷ Yet, in reality, the outcome is sometimes counterintuitive.
❶ ❸ For instance, rabbit numbers may increase dramatically.
❷ ❹ However, food shortages may arise.
❸ ❺ In some ecosystems, competition can affect survival.
❹ ❻ Thus, a larger food supply can create problems.
❺ ❼ This demonstrates that the common assumption is flawed.
❻ The paradox of enrichment reveals that resource abundance does not always align with ecological realities.
❼ *paradox 역설
''',
    });

    expect(display, contains('❶ An increase'));
    expect(display, contains('❷ Yet'));
    expect(display, contains('❸ For instance'));
    expect(display, contains('❹ However'));
    expect(display, contains('❺ In some ecosystems'));
    expect(display, contains('❻ Thus'));
    expect(display, contains('❼ This demonstrates'));
    expect(display, contains('The paradox of enrichment reveals'));
    expect(display, isNot(contains('❶ ❸')));
    expect(display, isNot(contains('❷ ❹')));
    expect(display, isNot(contains('❸ ❺')));
    expect(display, isNot(contains('❹ ❻')));
    expect(display, isNot(contains('❺ ❼')));
    expect(display, isNot(contains('❻ The paradox')));
    expect(display, isNot(contains('❼ *paradox')));
    expect(
      display,
      contains(
        '❼ This demonstrates that the common assumption is flawed. '
        'The paradox of enrichment reveals',
      ),
    );
  });
}

String _source(String answer) => '''
12) 다음 글에서 전체 흐름과 관계없는 문장은?
The passage introduces a shared topic.
① The first sentence develops the topic.
② The second sentence adds evidence.
③ The third sentence gives an example.
④ The fourth sentence returns to the claim.
⑤ This sentence changes the topic.
⑥ The sixth sentence continues the original discussion.
⑦ The final sentence concludes the discussion.
[정답] $answer
[해설] 다섯 번째 문장은 전체 흐름과 관계없다.
[어휘] evidence: 근거
''';

const _promptlessFragmentSource = '''
7)
glance 힐끗 봄 counterintuitive 직관에 반하는 instability 불안정 align with ~에 부합하다 There is a problem in biology known as the paradox of enrichment. At first glance, it may seem logical that more food would stabilize a population.
① An increase in food supply for prey should result in population growth. ② Yet, in reality, the outcome is sometimes counterintuitive. ③ For instance, if rabbits multiply, wolves may also increase. ④ However, once the number of wolves exceeds a threshold, prey can decline sharply. ⑤ In some ecosystems, competition among predators changes their fur color. ⑥ Thus, a larger food supply for prey can produce ecosystem instability. ⑦ This demonstrates that the common assumption is not always correct.
[정답] ⑤
[해설] 다섯 번째 문장이 전체 흐름과 관계없다.
''';

const _actualMissingTypeFragmentSource = '''
7)
glance \uD790\uB057 \uBD04 counterintuitive \uC9C1\uAD00\uC5D0 \uBC18\uD558\uB294 instability \uBD88\uC548\uC815 align with ~\uC5D0 \uBD80\uD569\uD558\uB2E4 There is a problem in biology known as the paradox of enrichment. An increase in food supply for prey should result in population growth. Yet, in reality, the outcome is sometimes counterintuitive. For instance, if rabbits multiply, wolves may also increase. However, once the number of wolves exceeds a threshold, prey can decline sharply. In some ecosystems, competition among predators changes their fur color. Thus, a larger food supply for prey can produce ecosystem instability. This demonstrates that the common assumption is not always correct.
[\uC815\uB2F5] \u2464
''';
