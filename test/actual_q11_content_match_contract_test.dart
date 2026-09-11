import 'dart:io';

import 'package:english_analyzer_app/screens/student/student_exam_take_screen.dart';
import 'package:english_analyzer_app/screens/teacher/teacher_problem_set_preview_screen.dart';
import 'package:english_analyzer_app/utils/question_hwpx_import_parser.dart';
import 'package:english_analyzer_app/utils/grammar_vocabulary_inline_spans.dart';
import 'package:english_analyzer_app/utils/workbook_hwpx_text_extractor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _actualQ11Path = r'C:\Users\Administrator\Desktop\hwpx샘플\단문장문변형테스트.hwpx';
const _actualQ11Sha256 =
    '1096637D5AB8D16064EA3E9DDD1A5F1991746EB8B282AB250552619011A57067';

void main() {
  test('preserves all six choices and B/E answer identity', () {
    final draft = parseQuestionHwpxImportText(_sixChoiceLongPassageSet);
    final question = draft.questions.last;

    expect(question.questionType, 'content_match');
    expect(question.choices, hasLength(6));
    expect(question.choices.first, 'William은 시장에서 늙은 노점상을 보았다.');
    expect(question.choices.last, '노점상은 돈을 받은 적이 없다고 소리쳤다.');
    expect(question.answerRaw, 'ⓑ ⓔ');
    expect(question.answerText, '2,5');
    expect(question.answerIndex, isNull);
    expect(question.specialData?['choice_ids'], ['A', 'B', 'C', 'D', 'E', 'F']);
    expect(question.specialData?['answer_choice_ids'], ['B', 'E']);
    expect(question.specialData?['answer_indices'], [1, 4]);
    expect(question.specialData?['interaction_type'], 'multi_select');
    expect(question.specialData?['max_answers'], 2);
    expect(question.isSaveable, isTrue);
  });

  test('actual verified HWPX keeps the Q8-Q11 contract', () async {
    final file = File(_actualQ11Path);
    if (!file.existsSync()) {
      return;
    }

    final hash = await Process.run(
      'certutil',
      ['-hashfile', file.path, 'SHA256'],
    );
    final normalizedHash = hash.stdout
        .toString()
        .split(RegExp(r'\s+'))
        .firstWhere(
          (part) => RegExp(r'^[A-Fa-f0-9]{64}$').hasMatch(part),
        )
        .toUpperCase();
    expect(normalizedHash, _actualQ11Sha256);

    final extracted = extractWorkbookTextFromHwpx(file.readAsBytesSync());
    final q11Source = extracted.text
        .split(
          '윗글에 관한 내용과 일치하지 않는 것을 모두 고르시오. (정답 최대 2개)',
        )
        .last;
    final rawQ11Choices = RegExp(
      r'^\s*[ⓐⓑⓒⓓⓔⓕ]\s*.+$',
      multiLine: true,
    ).allMatches(q11Source).where((match) {
      final text = match.group(0) ?? '';
      return text.contains('William은') || text.contains('노점상은');
    }).toList(growable: false);
    expect(rawQ11Choices, hasLength(6));

    final draft = parseQuestionHwpxImportText(extracted.text);
    expect(draft.questions, hasLength(11));
    expect(draft.questions.where((question) => question.isSaveable),
        hasLength(11));
    expect(
      draft.questions.skip(7).map((question) => question.questionType),
      ['vocabulary_correction', 'order', 'reference', 'content_match'],
    );

    final q11 = draft.questions[10];
    expect(q11.choices, hasLength(6));
    expect(q11.choices.first, 'William은 시장을 지나다가 늙은 노점상을 보았다.');
    expect(q11.choices.last, '노점상은 돈을 받은 적이 없다고 소리쳤다.');
    expect(q11.answerRaw, 'ⓑ ⓔ');
    expect(q11.answerText, '2,5');
    expect(q11.answerIndex, isNull);
    expect(q11.specialData?['choice_ids'], ['A', 'B', 'C', 'D', 'E', 'F']);
    expect(q11.specialData?['answer_choice_ids'], ['B', 'E']);
    expect(q11.specialData?['answer_indices'], [1, 4]);
    expect(q11.specialData?['interaction_type'], 'multi_select');
    expect(q11.specialData?['max_answers'], 2);
  });

  test('student choice labels include the sixth product option', () {
    expect(
        List.generate(6, studentChoiceLabel), ['①', '②', '③', '④', '⑤', '⑥']);
  });

  test('student multi-select accepts option six while enforcing max two', () {
    var selected = updateLanguagePositionSelection(
      selected: const {},
      position: 2,
      checked: true,
      maxAnswers: 2,
    );
    selected = updateLanguagePositionSelection(
      selected: selected,
      position: 6,
      checked: true,
      maxAnswers: 2,
    );
    selected = updateLanguagePositionSelection(
      selected: selected,
      position: 5,
      checked: true,
      maxAnswers: 2,
    );

    expect(selected, {2, 6});
    expect(serializeLanguagePositionSelection(selected), '2,6');
  });

  testWidgets('teacher preview renders six choices and two answers',
      (tester) async {
    final options = List<Map<String, dynamic>>.generate(
      6,
      (index) => {
        'label': studentChoiceLabel(index),
        'text': 'choice-${index + 1}',
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TeacherPreviewOptions(
            options: options,
            correctIndices: const {1, 4},
            underline: false,
          ),
        ),
      ),
    );

    for (var index = 0; index < 6; index++) {
      expect(find.text(studentChoiceLabel(index)), findsOneWidget);
      expect(find.text('choice-${index + 1}'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}

const _sixChoiceLongPassageSet = '''
※ 다음 글을 읽고, 물음에 답하시오.
(A) William saw an elderly vendor while walking through the market.
(B) William jingled coins and said that the sound was his payment.
[정답] (a) William
밑줄 친 (a)~(e) 중에서 가리키는 대상이 나머지 넷과 다른 것은?
[정답] ⓑ ⓔ
[해설]
ⓑ와 ⓔ는 본문과 일치하지 않는다.
윗글에 관한 내용과 일치하지 않는 것을 모두 고르시오. (정답 최대 2개)
ⓐ William은 시장에서 늙은 노점상을 보았다.
ⓑ William은 미트볼의 가격을 확인하고 집에 갔다.
ⓒ William은 주머니에서 몇 개의 동전을 딸랑거렸다.
ⓓ William은 노점상에게 이미 돈을 냈다고 말했다.
ⓔ 노점상은 미트볼을 눈으로 봤으니 돈을 내라고 했다.
ⓕ 노점상은 돈을 받은 적이 없다고 소리쳤다.
''';
