import 'package:english_analyzer_app/utils/question_hwpx_import_parser.dart';
import 'package:english_analyzer_app/utils/blank_display_passage.dart';
import 'package:english_analyzer_app/utils/grammar_vocabulary_inline_spans.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses two questions that share one long passage', () {
    final draft = parseQuestionHwpxImportText(_twoQuestionSet);

    expect(draft.questions, hasLength(2));
    expect(
        draft.questions.where((question) => question.isSaveable), hasLength(2));

    final title = draft.questions[0];
    final blank = draft.questions[1];
    expect(title.questionType, 'title');
    expect(blank.questionType, 'blank');
    expect(title.passage, blank.passage);
    expect(title.passage, contains('When students have trouble spelling'));
    expect(title.passage, isNot(contains('*visual')));
    expect(title.choices, hasLength(5));
    expect(blank.choices, hasLength(5));
    expect(title.answerIndex, 4);
    expect(blank.answerIndex, 0);
    expect(title.specialData?['shared_passage'], isTrue);
    expect(blank.specialData?['shared_passage'], isTrue);
  });

  test('parses order, reference, and content questions sharing A-D blocks', () {
    final draft = parseQuestionHwpxImportText(_threeQuestionSet);

    expect(draft.questions, hasLength(3));
    expect(
        draft.questions.where((question) => question.isSaveable), hasLength(3));

    final order = draft.questions[0];
    final reference = draft.questions[1];
    final content = draft.questions[2];
    expect(order.questionType, 'order');
    expect(reference.questionType, 'reference');
    expect(content.questionType, 'content_match');
    expect(order.passage, reference.passage);
    expect(reference.passage, content.passage);
    expect(order.passage, contains('(A)'));
    expect(order.passage, contains('(D)'));

    expect(order.specialData?['kind'], 'order');
    expect(order.specialData?['order_mode'], 'full');
    expect(order.specialData?['blocks'], isA<Map>());
    expect((order.specialData?['blocks'] as Map), hasLength(4));
    expect(order.specialData?['answer_order'], <String>['C', 'B', 'D', 'A']);
    expect(order.answerText, 'C-B-D-A');

    expect(reference.choices, hasLength(5));
    expect(reference.answerIndex, 1);
    expect(reference.specialData?['interaction_type'], 'single_choice');
    expect(content.choices, hasLength(5));
    expect(content.answerIndex, 3);
    expect(content.specialData?['interaction_type'], 'single_choice');
  });

  test('does not create candidates from glued answers and choice fragments',
      () {
    final draft = parseQuestionHwpxImportText(_realExtractionPattern);

    expect(draft.questions, hasLength(8));
    expect(
      draft.questions.where((question) => question.isSaveable),
      hasLength(8),
      reason: draft.questions
          .map(
            (question) =>
                '${question.questionNo}:${question.questionType}:${question.saveabilityReason}',
          )
          .join(', '),
    );
    expect(
      draft.questions.map((question) => question.questionType),
      <String>[
        'title',
        'blank',
        'topic',
        'vocabulary',
        'order',
        'order',
        'reference',
        'content_match',
      ],
    );
    expect(
      draft.questions.any(
        (question) =>
            question.questionText.startsWith('[정답]') ||
            question.questionText.startsWith('[해설]') ||
            question.questionText.isEmpty,
      ),
      isFalse,
    );
    expect(
      draft.questions.every(
        (question) =>
            question.passage.isNotEmpty &&
            question.specialData?['shared_passage'] == true,
      ),
      isTrue,
    );
    for (final question in draft.questions
        .where((question) => question.questionType == 'order')) {
      expect((question.specialData?['blocks'] as Map), isNotEmpty);
    }
    final reference = draft.questions[6];
    final content = draft.questions[7];
    expect(reference.choices, hasLength(5));
    expect(content.choices, hasLength(5));
  });

  test('recovers fixed-start order, reference labels, and multi answers', () {
    final draft = parseQuestionHwpxImportText(_fiveQuestionRecoverySet);

    expect(draft.questions, hasLength(5));
    expect(
      draft.questions.where((question) => question.isSaveable),
      hasLength(5),
      reason: draft.questions
          .map(
            (question) =>
                '${question.questionNo}:${question.questionType}:${question.saveabilityReason}',
          )
          .join(', '),
    );

    final fixedOrder = draft.questions[2];
    expect(fixedOrder.questionType, 'order');
    expect(fixedOrder.specialData?['fixed_start'], 'A');
    expect(
        fixedOrder.specialData?['fixed_start_text'], contains('researchers'));
    expect(fixedOrder.specialData?['selectable_blocks'], ['B', 'C', 'D']);
    expect((fixedOrder.specialData?['blocks'] as Map).keys,
        containsAll(<String>['A', 'B', 'C', 'D']));
    expect(fixedOrder.specialData?['answer_order'], ['C', 'B', 'D']);
    expect(fixedOrder.answerText, 'C-B-D');
    expect(fixedOrder.warnings, isEmpty);

    final reference = draft.questions[3];
    expect(reference.questionType, 'reference');
    expect(reference.choices, ['(a)', '(b)', '(c)', '(d)', '(e)']);
    expect(reference.answerIndex, 2);
    expect(reference.isSaveable, isTrue);

    final content = draft.questions[4];
    expect(content.questionType, 'content_match');
    expect(content.specialData?['kind'], 'content_match');
    expect(content.specialData?['interaction_type'], 'multi_select');
    expect(content.specialData?['answer_indices'], [1, 3]);
    expect(content.specialData?['max_answers'], 2);
    expect(content.answerText, '2,4');
    expect(content.answerIndex, isNull);
    expect(content.isSaveable, isTrue);
    expect(content.saveabilityReason, 'ok');
    expect(content.warnings.join(' '), isNot(contains('정답을 찾지 못했습니다')));
    expect(
      content.warnings.join(' '),
      isNot(contains('정답을 선택지 번호로 해석하지 못했습니다')),
    );
  });

  test('recovers a separated numbered answer-area entry by child order', () {
    final draft = parseQuestionHwpxImportText(_separatedAnswerAreaSet);

    expect(draft.questions, hasLength(5));
    expect(
      draft.questions.where((question) => question.isSaveable),
      hasLength(5),
      reason: draft.questions
          .map(
            (question) =>
                '${question.questionNo}:${question.questionType}:${question.answerText}:${question.saveabilityReason}',
          )
          .join(', '),
    );
    final content = draft.questions[4];
    expect(content.questionType, 'content_match');
    expect(content.answerText, '2,4');
    expect(content.answerIndex, isNull);
    expect(content.specialData?['kind'], 'content_match');
    expect(content.specialData?['interaction_type'], 'multi_select');
    expect(content.specialData?['answer_indices'], [1, 3]);
    expect(content.specialData?['max_answers'], 2);
    expect(content.specialData?['source_no'], 11);
    final positions = content.specialData?['positions'];
    expect(
        positions == null || (positions is List && positions.isEmpty), isTrue);
    expect(content.warnings, isEmpty);
    expect(content.saveabilityReason, 'ok');
  });

  test('recovers circled letter answers from the real HWPX answer style', () {
    final raw = _separatedAnswerAreaSet.replaceFirst(
      '[정답] ②,④[해설]',
      '[정답] ⓑ ⓔ[해설]',
    );
    final draft = parseQuestionHwpxImportText(raw);

    expect(draft.questions, hasLength(5));
    final content = draft.questions[4];
    expect(content.questionType, 'content_match');
    expect(content.answerRaw, 'ⓑ ⓔ');
    expect(content.answerText, '2,5');
    expect(content.answerIndex, isNull);
    expect(content.specialData?['answer_indices'], [1, 4]);
    expect(content.specialData?['source_no'], 11);
    expect(content.warnings, isEmpty);
    expect(content.saveabilityReason, 'ok');
  });

  test('keeps five long-passage groups aligned across eleven questions', () {
    final draft = parseQuestionHwpxImportText(_fiveGroupSet);

    expect(draft.questions, hasLength(11));
    expect(
      draft.questions.where((question) => question.isSaveable),
      hasLength(11),
      reason: draft.questions
          .map(
            (question) =>
                '${question.questionNo}:${question.questionType}:${question.saveabilityReason}',
          )
          .join(', '),
    );
    expect(draft.questions[0].questionType, 'title');
    expect(
      draft.questions[0].passage,
      contains('When students have trouble spelling'),
    );
    expect(draft.questions[1].questionType, 'blank');
    expect(draft.questions[1].passage, draft.questions[0].passage);

    final q3 = draft.questions[2];
    expect(q3.questionType, 'blank');
    expect(q3.passage, contains('memory for printed words'));
    expect(q3.passage, contains('_________________'));
    expect(q3.passage, contains('describe\n① them'));
    expect(
      buildGrammarVocabularyInlineSpans(
        passage: q3.passage,
        specialData: q3.specialData!,
        baseStyle: const TextStyle(),
      ).toPlainText(),
      contains('describe ① them'),
    );
    for (final marker in const ['①', '②', '③', '④', '⑤']) {
      expect(q3.passage, contains(marker));
    }
    expect(q3.choices, hasLength(5));
    expect(q3.choices, isNot(contains('strive → striving')));
    expect(q3.specialData?['interaction_type'], 'single_choice');

    final q4 = draft.questions[3];
    expect(q4.questionType, 'grammar_correction');
    expect(q4.specialData?['interaction_type'], 'correction_multi');
    expect(q4.specialData?['positions'], <int>[1, 2, 3, 4, 5]);
    expect(q4.specialData?['max_answers'], 3);
    expect(shouldShowPositionTextInSelection(q4.specialData!), isFalse);
    expect(
      grammarVocabularyPositionTexts(q4.specialData!),
      hasLength(5),
    );
    for (final position in const [1, 2, 3, 4, 5]) {
      expect(
        grammarVocabularyPositionText(q4.specialData!, position),
        isNotEmpty,
      );
    }

    final q5 = draft.questions[4];
    expect(q5.questionType, 'order');
    expect(
      (q5.specialData?['blocks'] as Map).keys,
      containsAll(<String>['A', 'B', 'C']),
    );
    expect(
      q5.specialData?['lead_passage'],
      contains('When students struggle with spelling'),
    );
    expect(q5.answerText, 'C-B-A');

    final q6 = draft.questions[5];
    expect(q6.questionType, 'topic');
    expect(q6.choices, hasLength(5));
    expect(q6.passage, contains('When students struggle with spelling'));
    expect(q6.specialData?['kind'], isNot('order'));

    expect(draft.questions[8].questionType, 'order');
    expect(draft.questions[9].questionType, 'reference');
    expect(draft.questions[10].questionType, 'content_match');
    expect(
      draft.questions.take(8).any(
            (question) => question.passage.contains('little William'),
          ),
      isFalse,
    );
    expect(
      draft.questions.skip(8).every(
            (question) => question.passage.contains('little William'),
          ),
      isTrue,
    );
    expect(
      draft.questions.map(
        (question) => question.specialData?['long_passage_group'],
      ),
      <int>[1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5],
    );

    final reference = draft.questions[9];
    expect(reference.choices, hasLength(5));
    for (final marker in const ['(a)', '(b)', '(c)', '(d)', '(e)']) {
      expect(reference.passage, contains(marker));
      expect(draft.questions[8].passage, contains(marker));
      expect(draft.questions[10].passage, contains(marker));
    }

    final content = draft.questions[10];
    expect(content.choices, hasLength(5));
    expect(content.specialData?['interaction_type'], 'multi_select');
    expect(content.answerText, '2,5');
  });

  test('normalizes blank placeholders to one non-wrapping display token', () {
    final normalized = blankPassageForDisplay('A ________ B [     ] C [___]');
    expect(
      normalized,
      'A $visibleBlankPlaceholder B $visibleBlankPlaceholder '
      'C $visibleBlankPlaceholder',
    );
    expect(blankPassageForDisplay(normalized), normalized);
  });

  test('renders blank placeholders as clearly underlined blank spans', () {
    final span = buildBlankPassageInlineSpans(
      passage: 'Before [     ] after ______.',
      baseStyle: const TextStyle(),
    );
    final blankSpans = span.children!
        .whereType<TextSpan>()
        .where(
          (child) => child.style?.decoration == TextDecoration.underline,
        )
        .toList(growable: false);

    expect(blankSpans, hasLength(2));
    expect(blankSpans.every((child) => !child.text!.contains('_')), isTrue);
    expect(
      blankSpans.every((child) => child.style?.decorationThickness == 2.2),
      isTrue,
    );
  });

  test('underlines only grammar and vocabulary family choices', () {
    expect(shouldUnderlineChoiceForQuestionType('blank'), isFalse);
    expect(shouldUnderlineChoiceForQuestionType('title'), isFalse);
    expect(shouldUnderlineChoiceForQuestionType('topic'), isFalse);
    expect(shouldUnderlineChoiceForQuestionType('gist'), isFalse);
    expect(shouldUnderlineChoiceForQuestionType('grammar'), isTrue);
    expect(shouldUnderlineChoiceForQuestionType('vocabulary'), isTrue);
    expect(shouldUnderlineChoiceForQuestionType('grammar_correction'), isTrue);
    expect(
      shouldUnderlineChoiceForQuestionType('vocabulary_correction'),
      isTrue,
    );
  });

  test('underlines the expression after a numbered inline marker', () {
    final span = buildGrammarVocabularyInlineSpans(
      passage: 'Lead text\n① mental evidence, ② visual memory, ③ linguistic '
          'patterns, ④ useless copying, ⑤ little context, and ⑥ effective '
          'learning.',
      specialData: const <String, dynamic>{},
      baseStyle: const TextStyle(),
    );
    final textSpans = span.children!.whereType<TextSpan>().toList();

    expect(span.toPlainText(), contains('Lead text ① mental'));
    expect(
      textSpans.any(
        (child) =>
            child.text == 'mental' &&
            child.style?.decoration == TextDecoration.underline,
      ),
      isTrue,
    );
    expect(
      textSpans.any(
        (child) =>
            child.text == 'visual' &&
            child.style?.decoration == TextDecoration.underline,
      ),
      isTrue,
    );
    expect(
      textSpans.any(
        (child) =>
            child.text == 'effective' &&
            child.style?.decoration == TextDecoration.underline,
      ),
      isTrue,
    );
  });

  test('underlines the referent immediately after reference markers', () {
    final span = buildReferenceMarkerInlineSpans(
      passage: '(a) he walked home. (b) he stopped. (c) He listened. '
          '(d) He followed. (e) he smiled.',
      baseStyle: const TextStyle(),
    );
    final underlined = span.children!
        .whereType<TextSpan>()
        .where(
          (child) => child.style?.decoration == TextDecoration.underline,
        )
        .map((child) => child.text)
        .toList(growable: false);

    expect(underlined, ['he', 'he', 'He', 'He', 'he']);
  });

  test('does not underline words after uppercase order block markers', () {
    final span = buildReferenceMarkerInlineSpans(
      passage: '(A) This starts. (B) However it changes. '
          '(C) Good evidence follows. (D) The sequence ends.',
      baseStyle: const TextStyle(),
    );
    final underlined = span.children!
        .whereType<TextSpan>()
        .where(
          (child) => child.style?.decoration == TextDecoration.underline,
        )
        .map((child) => child.text)
        .toList(growable: false);

    expect(underlined, isEmpty);
    expect(span.toPlainText(), contains('(A) This'));
    expect(span.toPlainText(), contains('(D) The'));
  });

  test('distinguishes lowercase reference and uppercase order markers', () {
    final span = buildReferenceMarkerInlineSpans(
      passage: '(A) One block begins. (a) he responds. '
          '(B) Little William waits. (b) He continues.',
      baseStyle: const TextStyle(),
    );
    final underlined = span.children!
        .whereType<TextSpan>()
        .where(
          (child) => child.style?.decoration == TextDecoration.underline,
        )
        .map((child) => child.text)
        .toList(growable: false);

    expect(underlined, ['he', 'He']);
  });

  test('preserves text after the last order block as trailing passage', () {
    final draft = parseQuestionHwpxImportText(_trailingOrderSet);

    expect(draft.questions, hasLength(2));
    final order = draft.questions.first;
    expect(order.questionType, 'order');
    expect(order.specialData?['lead_passage'], contains('Opening paragraph'));
    expect(
      order.specialData?['trailing_passage'],
      contains('Closing paragraph'),
    );
    expect(
      (order.specialData?['blocks'] as Map)['C'],
      isNot(contains('Closing paragraph')),
    );
  });
}

const _trailingOrderSet = '''
※ 다음 글을 읽고, 물음에 답하시오.
Opening paragraph gives the fixed context for the sequence.
(A) The first movable paragraph presents one explanation.
(B) The second movable paragraph supplies supporting evidence.
(C) The third movable paragraph completes the comparison.
Closing paragraph states the conclusion after the movable sequence.
1) 주어진 글 사이에 들어갈 글의 순서를 바르게 배열하시오.
[정답] (B)-(A)-(C)
2) 윗글의 주제로 가장 적절한 것을 고르시오.
① sequencing evidence around fixed context
② memorizing isolated vocabulary
③ removing every conclusion
④ ignoring supporting details
⑤ replacing all paragraphs
[정답] ①
''';

const _fiveGroupSet = '''
<기본형>
※ 다음 글을 읽고, 물음에 답하시오.
When students have trouble spelling, they learn that language patterns and word origins matter more than photographic memory. Understanding those patterns helps them predict unfamiliar spellings and revise mistakes.
1) 윗글의 제목으로 가장 적절한 것을 고르시오.
① Visual Memory Alone
② Avoiding New Words
③ Pictures and Drawing
④ Mechanical Copying
⑤ Spelling Through Language Patterns
[정답] ⑤
2) 다음 빈칸에 들어갈 말로 가장 적절한 것은?
① linguistic knowledge
② random pictures
③ silent copying
④ visual guessing
⑤ repeated drawing
[정답] ①

※ 다음 글을 읽고, 물음에 답하시오.
When students have trouble spelling, we commonly describe ① them as having a poor visual memory. They may ② strive to remember a word by visualizing it. Linguists have shown that one's memory for printed words _________________ and that visual attention alone does not explain spelling skill. Good spelling ③ to be memory for linguistic information, while students ④ imagine letter strings and learn ⑤ what words are structured.
3) 다음 빈칸에 들어갈 말로 가장 적절한 것은?
① has much to do with linguistic knowledge
② is unrelated to the frequency of visual exposure
③ depends solely on repetitive writing
④ is influenced mainly by visualizing text
⑤ relies primarily on memorizing letter shapes
[정답] ①
[정답] ② strive → striving ③ to be → is ⑤ what → how다음 글의 밑줄 친 부분 중, 어법상 틀린 것을 바르게 고치시오. (정답 최대 3개)
[정답] ② strive → striving ③ to be → is ⑤ what → how

<패러형>
※ 다음 글을 읽고, 물음에 답하시오.
When students struggle with spelling, we often say they have a weak visual memory. Linguists have demonstrated that spelling depends on linguistic knowledge. If spelling relied solely on rote visual memory, students could not spell words they had never encountered before.
(A) This suggests that repeatedly writing words may be somewhat helpful.
(B) However, visual strategies work better with knowledge of word structure.
(C) Good spelling results from knowledge of language structure and meaning.
5) 주어진 글 다음에 이어질 글의 순서를 바르게 배열하시오.
[정답] (C)-(B)-(A)
6) 윗글의 주제로 가장 적절한 것을 고르시오.
① the role of linguistic knowledge in spelling proficiency
② the importance of visual memory alone
③ teaching spelling only through repetition
④ avoiding unfamiliar words in competitions
⑤ the history of printed dictionaries
[정답] ①

<변형>
※ 다음 글을 읽고, 물음에 답하시오.
Group four shows that responsible producers respond to clear standards by improving working conditions, reporting results honestly, and correcting practices that fail independent review.
7) 윗글의 제목으로 가장 적절한 것을 고르시오.
① Standards and Responsible Production
② Hiding Production Results
③ Rejecting Independent Review
④ Unclear Working Conditions
⑤ Standards Without Change
[정답] ①
8) 다음 빈칸에 들어갈 말로 가장 적절한 것은?
① correct failed practices
② conceal every result
③ remove all standards
④ avoid honest reporting
⑤ prevent improvement
[정답] ①

<기본형>
※ 다음 글을 읽고, 물음에 답하시오.
(A) One evening, little William was walking home when (a) he noticed an elderly vendor beside the market road.
(B) William offered the vendor water because (b) he was concerned, and (c) he listened carefully to her story.
(C) The vendor thanked him, and (d) he followed the safer path that she pointed out.
(D) Later, a shopkeeper heard what had happened and said that (e) he admired William's patience and kindness.
9) 주어진 글의 순서로 가장 적절한 것은?
① A-B-C-D
② B-C-A-D
③ C-B-D-A
④ D-B-A-C
⑤ B-A-D-C
[정답] ①
10) 밑줄 친 (a)~(e) 중에서 가리키는 대상이 나머지 넷과 다른 것은?
① (a)
② (b)
③ (c)
④ (d)
⑤ (e)
[정답] ③
11) 윗글에 관한 내용과 일치하지 않는 것을 모두 고르시오. (정답 최대 2개)
① William was walking home.
② William ignored the elderly vendor.
③ The vendor showed him a safer path.
④ A shopkeeper praised William.
⑤ William crossed the crowded square with the vendor.
[정답] ②,⑤
''';

const _twoQuestionSet = '''
※ 다음 글을 읽고, 물음에 답하시오.
When students have trouble spelling, we commonly describe them as having a poor visual memory. Yet spelling depends on linguistic knowledge rather than a photographic copy of printed words. Skilled spellers understand recurring sound and letter relationships. This evidence shows that spelling is more than ______.
*visual memory 시각 기억

1) 다음 글의 제목으로 가장 적절한 것은?
① The Role of Visual Memory in Spelling
② Easy Ways to Photograph Printed Words
③ Why Students Should Avoid Difficult Words
④ The History of English Writing Systems
⑤ Why Spelling Is More Than Just Memorization
[정답] ⑤
[해설] 철자는 단순한 시각적 암기 이상의 지식에 의존한다.

2) 다음 빈칸에 들어갈 말로 가장 적절한 것은?
① memory for visual forms alone
② practice without linguistic knowledge
③ talent for drawing printed letters
④ repetition of unrelated images
⑤ avoidance of recurring patterns
[정답] ①
[해설] 글의 핵심은 시각 형태만 기억하는 것이 아니라는 점이다.
''';

const _threeQuestionSet = '''
※ 다음 글을 읽고 물음에 답하시오.
(A)
One evening, little William was on his way home when he saw a tired vendor.
(B)
William offered the vendor water and listened carefully to his story.
(C)
The elderly vendor thanked him and pointed toward the village road.
(D)
Later, the shopkeeper learned why William had stopped and praised his kindness.

9) 주어진 글 다음에 이어질 글의 순서로 가장 적절한 것은?
① A-B-C-D
② B-A-D-C
③ C-B-D-A
④ D-C-B-A
⑤ C-D-A-B
[정답] ③

10) 밑줄 친 (A)가 가리키는 대상으로 가장 적절한 것은?
① the shopkeeper
② little William
③ the village road
④ the elderly vendor
⑤ a passerby
[정답] ②

11) 윗글의 내용과 일치하지 않는 것은?
① William was going home.
② William met a tired vendor.
③ The vendor pointed toward a road.
④ The shopkeeper blamed William for stopping.
⑤ William listened to the vendor.
[정답] ④
''';

const _realExtractionPattern = '''
<기본형>
※ 다음 글을 읽고, 물음에 답하시오.
Writers do not simply photograph words in memory. They learn recurring linguistic patterns, use those patterns to predict spellings, and revise their predictions when new evidence appears. This makes spelling a process of ______ rather than mechanical copying.
*mechanical 기계적인
1
다음 글의 제목으로 가장 적절한 것은?
① Pictures Stored in the Mind
② Why Words Never Change
③ The Decline of Written Language
④ Copying as the Only Learning Method
⑤ Spelling as Pattern-Based Learning
[정답] ⑤[해설] 글은 철자를 패턴 학습으로 설명한다.2) 다음 빈칸에 들어갈 말로 가장 적절한 것은?
① active reasoning
② visual copying
③ random guessing
④ passive viewing
⑤ silent repetition
[정답] ①[해설] 언어 패턴을 이용한 능동적인 추론이다.3) 다음 글의 주제로 가장 적절한 것은?
① spelling develops through linguistic pattern knowledge
② memory always works like a camera
③ students should stop revising predictions
④ written words contain no recurring relationships
⑤ mechanical copying guarantees expert spelling
[정답] ①

<변형>
※ 다음 글을 읽고 물음에 답하세요.
(A) Markets can support fair production when buyers demand reliable evidence.
(B) Producers respond by improving working conditions and reporting methods.
(C) Clear standards then help consumers compare competing claims.
(D) These changes gradually reward responsible practices.
4) 다음 글의 밑줄 친 부분 중 문맥상 적절하지 않은 어휘는?
① fair
② reliable
③ improving
④ clear
⑤ responsible
[정답] ③[해설] 문맥에 맞는 표현을 고른다.5) 주어진 글 다음에 이어질 글의 순서로 가장 적절한 것은?
① A-B-C-D
② B-C-D-A
③ C-B-D-A
④ D-A-C-B
⑤ C-D-B-A
[정답] (C)-(B)-(D)-(A)

※ 다음 글을 읽고, 물음에 답하시오.
A.
One evening, William noticed an elderly vendor beside the road.
B)
He offered the vendor water and listened to her story.
C.
The vendor thanked him and showed him the safest path home.
D)
Later, a shopkeeper praised William for his kindness.
6) 주어진 글 다음에 이어질 글의 순서를 바르게 배열하시오.
[정답] (C)-(B)-(D)-(A)[해설] 사건의 흐름을 따른다.7) 밑줄 친 (a)~(e) 중에서 가리키는 대상이 나머지 넷과 다른 것은?
① (a) William
② (b) the vendor
③ (c) the vendor
④ (d) the vendor
⑤ (e) the vendor
[정답] ①[해설] (a)만 William을 가리킨다.8) 윗글의 내용과 일치하지 않는 것은?
① William saw an elderly vendor.
② William offered the vendor water.
③ The vendor showed William a path.
④ The shopkeeper punished William.
⑤ William was praised for his kindness.
[정답] ④
''';

const _fiveQuestionRecoverySet = '''
※ 다음 글을 읽고 물음에 답하시오.
(A) First, researchers observed how a small community shared information.
(B) Next, they compared the reports with records from neighboring towns.
(C) Before that comparison, they checked whether every report used the same terms.
(D) Finally, they published a careful account of the findings.

1) 주어진 글의 순서로 가장 적절한 것은?
① A-B-C-D
② B-C-A-D
③ C-A-B-D
④ D-B-A-C
⑤ B-A-D-C
[정답] ④

2) 다음 글의 밑줄 친 부분 중 문맥상 낱말의 쓰임이 적절하지 않은 것을 바르게 고치시오. (정답 최대 2개)
[정답] ③ careless → careful

3) 주어진 글 (A)에 이어질 내용의 순서를 바르게 배열하시오.
[정답] C-B-D

4) 밑줄 친 (a)~(e) 중에서 가리키는 대상이 나머지 넷과 다른 것은?
[정답] ③

5) 윗글의 내용과 일치하는 것을 모두 고르시오. (정답 최대 2개)
① The researchers ignored all neighboring records.
② They observed information sharing in a community.
③ Every report originally used different languages.
④ They checked the terms before comparing reports.
⑤ They never published their findings.
[정답] ②,④
''';

const _separatedAnswerAreaSet = '''
※ 다음 글을 읽고 물음에 답하시오.
(A) First, researchers observed how a small community shared information.
(B) Next, they compared the reports with records from neighboring towns.
(C) Before that comparison, they checked whether every report used the same terms.
(D) Finally, they published a careful account of the findings.

다음 글의 순서로 가장 적절한 것은?
① A-B-C-D
② B-C-A-D
③ C-A-B-D
④ D-B-A-C
⑤ B-A-D-C
7)
[정답] ④

다음 글의 밑줄 친 부분 중 문맥상 낱말의 쓰임이 적절하지 않은 것을 바르게 고치시오. (정답 최대 2개)
8)
[정답] ③ careless → careful

주어진 글 (A)에 이어질 내용의 순서를 바르게 배열하시오.
9)
[정답] C-B-D

밑줄 친 (a)~(e) 중에서 가리키는 대상이 나머지 넷과 다른 것은?
10)
[정답] ③

윗글에 관한 내용과 일치하지 않는 것을 모두 고르시오. (정답 최대 2개)
① The researchers ignored all neighboring records.
② They observed information sharing in a community.
③ Every report originally used different languages.
④ They checked the terms before comparing reports.
⑤ They never published their findings.

<변형>
11
[정답] ②,④[해설] 두 진술이 본문의 내용과 일치한다.
''';
