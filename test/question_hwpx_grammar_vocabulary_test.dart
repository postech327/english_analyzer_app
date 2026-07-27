import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_analyzer_app/utils/grammar_vocabulary_inline_spans.dart';
import 'package:english_analyzer_app/utils/question_hwpx_import_parser.dart';

void main() {
  test('builds student fallback options for language questions', () {
    expect(
      grammarVocabularyFallbackStudentOptions(
        questionType: 'vocabulary_count',
        positions: const <int>[],
      ),
      ['① 없음', '② 1개', '③ 2개', '④ 3개', '⑤ 4개'],
    );
    expect(
      grammarVocabularyFallbackStudentOptions(
        questionType: 'grammar',
        positions: const [1, 2, 3, 4, 5],
      ),
      ['①', '②', '③', '④', '⑤'],
    );
    expect(
      grammarVocabularyFallbackStudentOptions(
        questionType: 'vocabulary_correction',
        positions: const [1, 2, 3, 4, 5, 6, 7],
      ),
      ['①', '②', '③', '④', '⑤', '⑥', '⑦'],
    );
  });

  test('force recovers 7 and 8 passages from the normalized document', () {
    final draft = parseQuestionHwpxImportText(_forceRecoverySource);
    final q7 =
        draft.questions.firstWhere((question) => question.questionNo == 7);
    final q8 =
        draft.questions.firstWhere((question) => question.questionNo == 8);

    expect(q7.isSaveable, isTrue);
    expect(q7.warnings, isEmpty);
    expect(q7.passage, contains('fairer and more environmentally responsible'));
    expect(q7.passage, contains('⑤ their'));
    expect(q7.passage, contains('market-driven practices'));

    expect(q8.isSaveable, isTrue);
    expect(q8.warnings, isEmpty);
    expect(q8.passage, contains('① markets can function in more fair'));
    expect(q8.passage, contains('③ and shipped'));
    expect(q8.passage, contains('market-driven practices'));
  });

  test('parses twelve grammar and vocabulary interaction variants', () {
    final draft = parseQuestionHwpxImportText(_grammarVocabularySource);

    expect(draft.questions, hasLength(12));
    expect(draft.questions.where((question) => question.isSaveable),
        hasLength(12));
    expect(
      draft.questions.any(
        (question) => question.saveabilityReason == 'missing_passage',
      ),
      isFalse,
    );

    final q1 = draft.questions[0];
    expect(q1.questionType, 'vocabulary_count');
    expect(q1.specialData?['interaction_type'], 'single_choice');
    expect(q1.answerIndex, 3);
    expect(q1.specialData?['wrong_count'], 3);
    expect(q1.choices, ['없음', '1개', '2개', '3개', '4개']);
    expect(q1.questionText, startsWith('다음 글의 밑줄 친 부분 중'));
    expect(q1.passage, startsWith('Suffering from social angst'));
    expect((q1.specialData?['corrections'] as Map).keys,
        containsAll(['ⓓ', 'ⓕ', 'ⓖ']));

    final q2 = draft.questions[1];
    expect(q2.questionType, 'grammar');
    expect(q2.answerIndex, 4);
    expect(q2.specialData?['positions'], hasLength(5));
    expect(q2.passage, startsWith('Consumer surveys indicate'));
    expect(q2.passage, contains('believe ① that food'));
    expect(q2.passage, contains('only half ② use'));
    expect(q2.passage, contains('not ③ reviewed'));
    expect(q2.passage, contains('sites ④ devoted'));
    expect(q2.passage, contains('facilities ⑤ provides'));
    expect(q2.passage, isNot(contains('\n①')));
    expect(q2.specialData?['position_texts'], {
      '1': 'that',
      '2': 'use',
      '3': 'reviewed',
      '4': 'devoted',
      '5': 'provides',
    });
    final q2InlineSpan = buildGrammarVocabularyInlineSpans(
      passage: q2.passage,
      specialData: q2.specialData ?? const <String, dynamic>{},
      baseStyle: const TextStyle(),
    );
    expect(q2InlineSpan.toPlainText(), q2.passage);
    final underlinedQ2Texts = q2InlineSpan.children!
        .whereType<TextSpan>()
        .where((span) => span.style?.decoration == TextDecoration.underline)
        .map((span) => span.text)
        .toList();
    expect(
      underlinedQ2Texts,
      containsAll(['that', 'use', 'reviewed', 'devoted', 'provides']),
    );

    final q3 = draft.questions[2];
    expect(q3.questionType, 'vocabulary');
    expect(q3.answerIndex, 2);
    expect(q3.specialData?['positions'], hasLength(5));

    expect(draft.questions[3].questionType, 'grammar');

    final q5 = draft.questions[4];
    expect(q5.questionType, 'vocabulary_correction');
    expect(q5.specialData?['interaction_type'], 'correction_multi');
    expect(q5.specialData?['student_response_mode'], 'number_select');
    expect(q5.specialData?['expected_positions'], [1, 5]);
    expect(q5.specialData?['positions'], hasLength(5));
    expect(q5.answerText, '1:maintain,5:convincing');
    expect(q5.questionText, contains('정답 최대 2개'));
    expect(
        (q5.specialData?['corrections'] as Map).keys, containsAll(['1', '5']));

    final q6 = draft.questions[5];
    expect(q6.questionType, 'grammar_correction');
    expect(q6.specialData?['student_response_mode'], 'number_select');
    expect(q6.specialData?['expected_positions'], [3, 4]);
    expect(q6.specialData?['positions'], hasLength(5));
    expect(q6.answerText, '3:to be,4:convincing');

    final q7 = draft.questions[6];
    expect(q7.questionType, 'grammar');
    expect(q7.isSaveable, isTrue);
    expect(q7.questionText, contains('어법상 틀린 것은'));
    expect(q7.passage, contains('Reformist perspectives believe'));
    expect(q7.passage, contains('fairer and more environmentally responsible'));
    expect(q7.passage, contains('and ① more environmentally responsible'));
    expect(q7.passage, contains('By ⑤ their very nature'));
    expect(q7.passage, contains('⑤ their'));
    expect(q7.warnings, isEmpty);
    expect(
      q7.specialData?['vocabulary_notes'],
      containsAll([
        'perspective 관점, 시각',
        'cultivate 재배하다',
        'underpaid 저임금의',
        'undocumented 불법 체류의',
        'ship 운송하다',
        'genuine 진정한',
        'market-driven 시장 주도의',
      ]),
    );

    final q8 = draft.questions[7];
    expect(q8.questionType, 'grammar_vocabulary');
    expect(q8.isSaveable, isTrue);
    expect(q8.answerIndex, 2);
    expect(q8.questionText, contains('어법과 문맥상 낱말의 쓰임이 적절한 것은'));
    expect(q8.passage, contains('Reformist perspectives believe'));
    expect(q8.passage, contains('that ① markets can function in more fair'));
    expect(q8.passage, contains('① markets can function in more fair'));
    expect(q8.passage, contains('③ and shipped'));
    expect(q8.warnings, isEmpty);
    expect(q8.specialData?['vocabulary_notes'], contains('perspective 관점, 시각'));

    expect(draft.questions[8].questionType, 'grammar');
    expect(draft.questions[9].questionType, 'grammar_vocabulary');

    final q11 = draft.questions[10];
    expect(q11.questionType, 'grammar');
    expect(q11.specialData?['interaction_type'], 'multi_select');
    expect(q11.specialData?['answer_indices'], [2, 3]);
    expect(q11.specialData?['explanation_inferred_indices'], [2, 4]);
    expect(q11.warnings, contains('answer_explanation_mismatch'));
    expect(q11.isSaveable, isTrue);
    expect(q11.passage, startsWith('In music, proximity may refer'));

    final q12 = draft.questions[11];
    expect(q12.questionType, 'vocabulary_correction');
    expect(q12.specialData?['student_response_mode'], 'number_select');
    expect(q12.specialData?['expected_positions'], [4, 6]);
    expect(q12.specialData?['positions'], hasLength(7));
    expect(q12.answerText, '4:not zero,6:no apparent');
    expect(
        (q12.specialData?['corrections'] as Map).keys, containsAll(['4', '6']));
    expect(q12.passage, startsWith('Public goods are undervalued'));

    for (final question in draft.questions) {
      expect(question.specialData?['interaction_type'], isNotEmpty);
      expect(question.passage, isNot(contains('[해설]')));
      expect(question.passage, isNot(contains('[어휘]')));
      expect(question.passage, isNot(contains('[단어]')));
      final vocabularyNotes =
          (question.specialData?['vocabulary_notes'] as List?)?.join(' ') ?? '';
      expect(vocabularyNotes, isNot(contains('Consumer surveys indicate')));
      expect(vocabularyNotes, isNot(contains('Reformist perspectives')));
      expect(vocabularyNotes, isNot(contains('The concept of')));
      expect(vocabularyNotes, isNot(contains('In music')));
      expect(vocabularyNotes, isNot(contains('Public goods')));
    }
    expect(q1.passage, contains('ⓐ'));
    expect(q1.passage, contains('ⓗ'));
    expect(q12.passage, contains('⑦'));
    expect(draft.questions.any((question) => question.questionText == '[어휘]'),
        isFalse);
    expect(draft.questions.any((question) => question.questionText == '[단어]'),
        isFalse);
    expect(
      draft.questions.any((question) => question.questionType.trim().isEmpty),
      isFalse,
    );
    expect(
      draft.questions.any(
        (question) =>
            question.saveabilityReason == 'missing_type' ||
            question.saveabilityReason == 'missing_passage',
      ),
      isFalse,
    );
  });
}

const _forceRecoverySource = '''
7
[정답] ⑤
다음 글의 밑줄 친 부분 중, 어법상 틀린 것은?

8
[정답] ③
다음 밑줄 친 부분 중, 어법과 문맥상 낱말의 쓰임이 적절한 것은?

9
[정답] ⑤
[해설] fallback paragraphs retained elsewhere in the normalized document
다음 글의 밑줄 친 부분 중, 어법상 틀린 것은?
Placeholder passage ① is ② kept ③ only ④ for ⑤ parsing.
[별도 복구 본문 7]
Reformist perspectives believe that markets can function in fairer and more environmentally responsible ways. Producers ① use responsible methods, ② generally rotates crops, work with buyers ③ which purchase their goods, ensure food is ④ cultivated responsibly, and publish ⑤ their results. Genuine social and environmental concerns related to protecting people and the planet reveal the unfairness and harm caused by market-driven practices.
[별도 복구 본문 8]
Reformist perspectives believe that ① markets can function in more fair and more environmentally responsible ways. They avoid ② effectively reasoning in a hall of mirrors and marginalise workers, support goods ③ and shipped over long distances, ④ make sure they pay their workers poor wages, while ⑤ Genuine social and environmentally concerns reveal harm caused by market-driven practices.
''';

const _grammarVocabularySource = '''
<기본형>
1
[정답] ④
[해설] ⓓ secure → insecure ⓕ acquired → inherent ⓖ inward-facing → outward-facing다음 글의 밑줄 친 부분 중, 어휘의 사용이 적절하지 않은 것의 개수는?
Suffering from social angst includes ⓐ stable, ⓑ useful, ⓒ broad, ⓓ secure, ⓔ learned, ⓕ acquired, ⓖ inward-facing, and ⓗ shared.
① 없음 ② 1개 ③ 2개 ④ 3개 ⑤ 4개
[어휘] perspective 관점, 시각

2
[정답] ⑤
[해설] ⑤ provide → provides
다음 글에서 어법상 적절하지 않은 것을 고르시오.
Consumer surveys indicate that the majority of Americans believe they have some control over their health, and 72% believe ① that food and nutrition play the greatest role. However, only half ② use medical sources. Many online writings are not ③ reviewed by nutrition experts. Reputable food companies provide helpful facts, but commercial sites ④ devoted to sales often post misleading claims. Internet sites maintained by universities and medical facilities ⑤ provides evidence-based information.

3
[정답] ③
[해설] ③ authoritative → unreliable
다음 글의 밑줄 친 부분 중, 문맥상 적절하지 않은 어휘를 고르시오.
The report was ① recent, ② detailed, ③ authoritative, ④ readable, and ⑤ concise.

4
[정답] ④
[해설] ④ remained → had remained
다음 글의 밑줄 친 부분 중 어법상 어색한 것은?
They ① arrived and ② found that it ③ was unchanged because it ④ remained closed before they ⑤ came.

5
[정답] ① break → maintain ⑤ vague → convincing다음 글의 밑줄 친 부분 중, 문맥상 틀린 것을 바르게 고치시오. (정답 최대 2개)
[해설] 문맥에 맞게 두 낱말을 고친다.
Good institutions ① break trust, ② support dialogue, ③ share evidence, ④ clarify goals, and offer ⑤ vague reasons.

6
[정답] ③ being → to be ④ convinced → convincing
[해설] 두 표현을 문법에 맞게 고친다.
다음 글의 밑줄 친 부분 중, 어법상 틀린 것을 바르게 고치시오. (정답 최대 2개)
People ① expect the plan ② to work, ③ being useful, and find the evidence ④ convinced while ⑤ reading it.

7
다음 글의 밑줄 친 부분 중, 어법상 틀린 것은?
[정답] ⑤
[해설] ⑤ their → its
[어휘]
perspective 관점, 시각
cultivate 재배하다
underpaid 저임금의
undocumented 불법 체류의
ship 운송하다
genuine 진정한
market-driven 시장 주도의
다음 글의 밑줄 친 부분 중, 어법상 틀린 것은?
Reformist perspectives believe that markets can function in fairer and more environmentally responsible ways, and ① more environmentally responsible production is possible. A producer ② generally rotates crops and works with buyers ③ which purchase responsibly grown food. Goods are ④ cultivated with care. By ⑤ their very nature, Genuine social and environmental concerns reveal the unfairness and harm caused by market-driven practices.

8
다음 밑줄 친 부분 중, 어법과 문맥상 낱말의 쓰임이 적절한 것은?
[정답] ③
[해설] ① more fair → fairer ② marginalise → marginalising ④ poor → fair ⑤ envionmentall → environmental
[어휘]
perspective 관점, 시각
cultivate 재배하다
underpaid 저임금의
undocumented 불법 체류의
ship 운송하다
genuine 진정한
market-driven 시장 주도의
다음 밑줄 친 부분 중, 어법과 문맥상 낱말의 쓰임이 적절한 것은?
Reformist perspectives believe that ① markets can function in more fair and more environmentally responsible ways. They avoid ② effectively reasoning about policies that marginalise workers, support goods ③ and shipped over long distances, make sure they pay their workers ④ poor wages, and address ⑤ Genuine social and environmentally concerns.

9
[정답] ⑤
[해설] ⑤ significantly → significant
다음 글의 밑줄 친 부분 중, 어법상 틀린 것은?
The results ① were ② carefully ③ reviewed and showed ④ a ⑤ significantly change.

10
[정답] ③
[해설] ① high → highly ② destruction → construction ④ was → were ⑤ less → more
다음 밑줄 친 부분 중, 어법과 문맥상 낱말의 쓰임이 적절한 것은?
Workers were ① high trained for ② destruction work, remained ③ ready, ④ was prepared, and needed ⑤ less support.

11
[정답] ③, ④
[해설] ③ imagining → imagine ⑤ to emerge → emerging(emerge)
다음 글에서 어법상 적절하지 않은 것을 모두 고르시오.
In music, proximity may refer to how readers ① can ② begin ③ imagining alternatives, ④ consider evidence, and watch ideas ⑤ to emerge before ⑥ deciding.

12
[정답] ④ void → not zero ⑥ manifest → no apparent
[해설] 두 낱말을 문맥에 맞게 고친다.
다음 글의 밑줄 친 부분 중, 문맥상 틀린 것을 바르게 고치시오. (정답 최대 2개)
Public goods are undervalued when values are ① small, ② stable, ③ measurable, ④ void, ⑤ comparable, ⑥ manifest, and ⑦ recorded.
[단어] cultivate 재배하다
''';
