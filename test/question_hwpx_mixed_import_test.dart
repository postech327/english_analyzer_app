import 'package:english_analyzer_app/utils/irrelevant_display_passage.dart';
import 'package:english_analyzer_app/utils/insertion_display_prompt.dart';
import 'package:english_analyzer_app/utils/question_hwpx_import_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses all ten question types in one mixed HWPX text', () {
    final draft = parseQuestionHwpxImportText(_mixedSource);

    expect(draft.questions, hasLength(10));
    expect(
      draft.questions.where((question) => question.isSaveable),
      hasLength(10),
      reason: draft.questions
          .map(
            (question) =>
                '${question.questionNo}:${question.saveabilityReason}',
          )
          .join(', '),
    );
    expect(
      draft.questions.where((question) => question.isSaveable).map(
            (question) => question.questionNo,
          ),
      <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    );

    final q6 = draft.questions[5];
    expect(q6.questionType, 'insertion');
    expect(q6.isSaveable, isTrue, reason: q6.saveabilityReason);
    expect(q6.specialData?['kind'], 'insertion');
    expect(q6.specialData?['mode'], 'single');
    expect(q6.specialData?['interaction_type'], 'single_choice');
    expect(
      q6.specialData?['insert_sentence'],
      contains('You can use your anxiety to be more outward-facing'),
    );
    expect(
      q6.specialData?['passage_with_positions'],
      contains('Suffering from social angst'),
    );
    final insertionPassage =
        q6.specialData?['passage_with_positions'] as String;
    expect(insertionPassage, contains('The good news is that'));
    expect(insertionPassage, contains('Pay attention'));
    expect(insertionPassage, contains('By shifting your focus'));
    expect(insertionPassage, contains('This capacity'));
    expect(insertionPassage, contains('Together, compassion and empathy'));
    expect(insertionPassage, contains('In doing so, you contribute'));
    expect(insertionPassage, contains('①'));
    expect(insertionPassage, contains('②'));
    expect(insertionPassage, contains('③'));
    expect(insertionPassage, contains('④'));
    expect(insertionPassage, contains('⑤'));
    expect(insertionPassage.trim().endsWith('('), isFalse);
    expect(insertionPassage, isNot(contains('*angst')));
    expect(insertionPassage, isNot(contains('**buffer')));
    expect(q6.specialData?['positions'], <int>[1, 2, 3, 4, 5]);
    expect(q6.specialData?['answer_position'], 5);
    expect(q6.answerIndex, isNull);
    expect(q6.answerText, '5');
    expect(q6.answerText, isNot('6'));
    expect(q6.warnings, isEmpty);
    expect(q6.warnings, isNot(contains('정답이 선택지 범위를 벗어났습니다')));
    expect(
      insertionPositionLabels(q6.specialData?['positions'] as List<int>),
      <String>['①', '②', '③', '④', '⑤'],
    );
    expect(
      insertionPositionLabels(q6.specialData?['positions'] as List<int>),
      isNot(<String>['1', '2', '3', '4', '5']),
    );
    final insertionDisplay = insertionPassageForDisplay(insertionPassage);
    expect(insertionDisplay, contains('(①) Pay attention'));
    expect(insertionDisplay, contains('(②) By shifting'));
    expect(insertionDisplay, contains('(③) This capacity'));
    expect(insertionDisplay, contains('(④) Together'));
    expect(insertionDisplay, contains('(⑤) In doing so'));
    expect(insertionDisplay, isNot(contains('\n\n①\n\n')));
    expect(insertionDisplay, isNot(contains('\n\n②\n\n')));
    expect(insertionDisplay, isNot(contains('*angst')));
    expect(insertionDisplay, isNot(contains('**buffer')));

    final q7 = draft.questions[6];
    expect(q7.questionType, 'irrelevant');
    expect(q7.questionText, isNotEmpty);
    expect(q7.specialData?['kind'], 'irrelevant');
    expect(q7.specialData?['mode'], 'single');
    expect(q7.specialData?['positions'], <int>[1, 2, 3, 4, 5, 6]);
    expect(q7.specialData?['answer_position'], 4);
    expect(q7.answerText, '4');
    expect(q7.isSaveable, isTrue, reason: q7.saveabilityReason);
    final irrelevantPassage = q7.specialData?['passage_with_numbers'] as String;
    for (final marker in '❶❷❸❹❺❻'.split('')) {
      expect(irrelevantPassage, contains(marker));
    }
    expect(irrelevantPassage, isNot(contains('*procedural')));
    expect(irrelevantPassage, isNot(contains('**restoration')));
    expect(irrelevantPassage, isNot(contains('***reservoir')));
    final irrelevantDisplay = cleanupIrrelevantDisplayPassage(
      irrelevantPassage,
    );
    expect(irrelevantDisplay, contains('❶ Recovery as'));
    expect(irrelevantDisplay, contains('❷ Physiological'));
    expect(irrelevantDisplay, isNot(contains('① Recovery as')));

    final q10 = draft.questions[9];
    expect(q10.questionType, 'insertion');
    expect(q10.specialData?['mode'], 'multiple');
    expect(q10.answerText, 'A:1,B:2');
    final q10Display = insertionPassageForDisplay(
      q10.specialData?['passage_with_positions'] as String,
    );
    expect(q10Display, contains('(①) When emissions rise'));
    expect(q10Display, isNot(contains('\n\n①\n\n')));
  });

  test('recovers a promptless irrelevant fragment with filled markers', () {
    final draft = parseQuestionHwpxImportText(_promptlessIrrelevantSource);

    expect(draft.questions, hasLength(1));
    final question = draft.questions.single;
    expect(question.questionType, 'irrelevant');
    expect(question.questionText, isNotEmpty);
    expect(question.specialData?['positions'], <int>[1, 2, 3, 4, 5, 6, 7]);
    expect(question.specialData?['answer_position'], 3);
    expect(question.answerText, '3');
    expect(question.isSaveable, isTrue, reason: question.saveabilityReason);
  });
}

const _mixedSource = '''
<기본형>
1) 다음 글의 주제로 가장 적절한 것은?
People learn more effectively when they connect new ideas to prior knowledge.
① memory ② learning ③ travel ④ weather ⑤ music
[정답] ②

2) 다음 글의 제목으로 가장 적절한 것은?
Small daily habits can produce meaningful change over time.
① A Long Journey ② The Power of Small Habits ③ Weather Today ④ Old Music ⑤ City Maps
[정답] ②

3) 다음 글의 요지로 가장 적절한 것은?
Clear goals help teams coordinate their work and measure progress.
① Goals support teamwork. ② Teams should rest. ③ Work is impossible. ④ Progress is random. ⑤ Goals cause conflict.
[정답] ①

4) 다음 글의 빈칸에 들어갈 말로 가장 적절한 것은?
Careful observation is the first step toward ______ a difficult problem.
① ignoring ② hiding ③ understanding ④ repeating ⑤ creating
[정답] ③

5) 주어진 글 다음에 이어질 글의 순서로 가장 적절한 것은?
The class began a project about local history.
(A) Finally, they presented their findings.
(B) Next, they interviewed longtime residents.
(C) First, they searched old records.
[정답] C-B-A

6)
⑥글의 흐름으로 보아, 주어진 문장이 들어가기에 가장 적절한 곳은?
You can use your anxiety to be more outward-facing.
Suffering from social angst, awkwardness, or dread is completely human.
Even if it doesn’t show on the surface, a lot of people are managing internal anxiety in social situations.
The good news is that it is actually possible to build your social muscle and use it to boost your connections — and your anxiety is giving you clues to what lifelines other people might be thankful for you to extend.
(
①)
Pay attention to what your anxiety is trying to tell you about where you feel insecure, and practice empathy by offering a hand to others who might share similar struggles.
(②
By shifting your focus from self-protection to consideration for others, you transform anxiety into compassion.
③)
This capacity is not something you have to learn from scratch; it is something inherent in you.
( 4 )
Together, compassion and empathy can buffer against bad anxiety.
5)
In doing so, you contribute to a wider circle of goodwill — benefiting people and the world around you.
*angst 불안
**buffer 완화하다
[정답] ⑥
[정답] ⑤

7)
[출처] Mixed fixture
다음 글에서 전체 흐름과 관계없는 문장은?
Recovery has both a procedural aspect and a resultant aspect.
❶ Recovery as an outcome refers to the condition reached after effort.
❷ Physiological recovery outcomes involve the restoration of bodily systems.
❸ Psychological recovery outcomes relate to renewed mental resources.
❹ Interestingly, many professional athletes collect colorful stamps.
❺ Physiological and psychological states influence one another.
❻ What we do during recovery affects the resources available afterward.
*procedural 절차상의
**restoration 회복
***reservoir 저장소
[정답] ④

8) 다음 글에서 어법상 적절하지 않은 것을 고르시오.
Consumer surveys ① indicate that many people ② believe food matters, but only half ③ uses reliable sources while others ④ read commercial claims and ⑤ compare evidence.
① indicate ② believe ③ uses ④ read ⑤ compare
[정답] ③

9) 다음 글의 밑줄 친 부분 중, 문맥상 틀린 것을 바르게 고치시오. (정답 최대 2개)
Good institutions ① break trust, ② support dialogue, ③ share evidence, ④ clarify goals, and offer ⑤ vague reasons.
[정답] ① break → maintain ⑤ vague → convincing
[해설] 문맥에 맞게 두 낱말을 고친다.

10) 글의 흐름으로 보아, 주어진 문장들이 들어가기에 가장 적절한 곳은?
(A) Likewise, reducing the tax burden requires reducing emissions.
(B) Nevertheless, monitoring technology has advanced quickly.
Environmental taxes can be precisely targeted. (①) When emissions rise, the tax base rises. (②) Polluters have an incentive to reduce emissions. (③) Continuous measurement can be costly. (④) New tools improve accuracy. (⑤) Future applications may be wider.
[정답] (A) ① (B) ②
''';

const _promptlessIrrelevantSource = '''
7)
[출처] Mixed fixture
[정답] ③
Recovery has both a procedural aspect and a resultant aspect.
❶ Recovery as an ongoing process requires steady effort.
❷ It also involves adapting to changing circumstances.
❸ Some people prefer to collect colorful stamps on weekends.
❹ Supportive relationships can strengthen the process.
❺ Progress may include setbacks as well as gains.
❻ The resulting condition is not always permanent.
❼ Continued attention helps preserve what has been achieved.
''';
