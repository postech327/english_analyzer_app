import 'package:flutter_test/flutter_test.dart';

import 'package:english_analyzer_app/utils/workbook_import_parser.dart';

void main() {
  test('parses seven tagged workbook question candidates', () {
    final candidates =
        parseWorkbookImportText(_sample, workbookSource: '수특 · 5강');

    expect(candidates, hasLength(7));
    expect(
      candidates.map((item) => item.detectedType),
      [
        'inline_choice',
        'check_learning_set',
        'true_false_en',
        'true_false_ko',
        'initial_blank',
        'sentence_insertion',
        'paragraph_order',
      ],
    );
    expect(candidates.where((item) => item.hasBlockingErrors), isEmpty);
    expect(candidates.every((item) => item.isSelectedByDefault), isTrue);
  });

  test('splits untagged inline choices by unit and question number', () {
    final candidates = parseWorkbookImportText('''
Unit 1 Gateway
1번
A laboratory is a(n) [artificial/natural] artificial (natural 자연적인)
environment.

Unit 1 Gateway
2번
The method was [effective/ineffective] effective (ineffective 비효율적인).
''');

    expect(candidates, hasLength(2));
    expect(candidates.every((item) => item.questionType == 'inline_choice'),
        isTrue);
    expect(candidates[0].title, 'Unit 1 Gateway 1번');
    expect(candidates[1].title, 'Unit 1 Gateway 2번');
    expect(candidates[0].answer['items'][0]['answer'], 'artificial');
    expect(
        candidates[1].answer['items'][0]['explanation'], 'ineffective 비효율적인');
  });

  test('detects an untagged numbered inline choice', () {
    final candidates = parseWorkbookImportText('''
1)
A study is [crucial/insignificant], crucial, (insignificant 중요하지 않은).
''');

    expect(candidates, hasLength(1));
    expect(candidates.single.questionType, 'inline_choice');
    expect(candidates.single.answer['items'][0]['answer'], 'crucial');
    expect(
      candidates.single.answer['items'][0]['explanation'],
      'insignificant 중요하지 않은',
    );
  });

  test('keeps several inline markers in one unit candidate', () {
    final candidates = parseWorkbookImportText('''
Unit 2 Gateway
1번
A laboratory is a(n) [artificial/natural] artificial (natural 자연적인)
environment. The old system was [established/destroyed] established (destroyed 파괴된).
''');

    expect(candidates, hasLength(1));
    expect(candidates.single.answer['items'], hasLength(2));
    expect(candidates.single.summary, contains('선택 항목 2개'));
    expect(candidates.single.summary, contains('해설 2개'));
  });

  test('uses large numbered source explanations in item order', () {
    final candidate = parseWorkbookImportText('''
Unit 3 Gateway
1번
The setting is [artificial/natural] artificial.
The method is [effective/ineffective] effective.

200. artificial (natural 자연적인)
204. effective (ineffective 비효율적인)
''').single;

    expect(candidate.answer['items'][0]['explanation'], 'natural 자연적인');
    expect(candidate.answer['items'][1]['explanation'], 'ineffective 비효율적인');
  });

  test('detects real untagged initial blank format and extracts answers', () {
    final candidates = parseWorkbookImportText('''
Unit 1 Gateway
❶ To Whom It May C________ Concern,
❷ I recently visited the Lambsford History Foundation’s e________ exhibition.
❸ The collection of pictures, tools, and historical d________ documents made the gold m________ miners come to life.
''');

    expect(candidates, hasLength(1));
    final candidate = candidates.single;
    expect(candidate.questionType, 'initial_blank');
    expect(candidate.isUnknown, isFalse);
    expect(candidate.title, 'Unit 1 Gateway');
    expect(candidate.answer['items'], hasLength(4));
    expect(
      (candidate.answer['items'] as List)
          .map((item) => item['answer'])
          .toList(),
      ['Concern', 'exhibition', 'documents', 'miners'],
    );
    expect(candidate.passageText, isNot(contains('C________ Concern')));
    expect(candidate.summary, '빈칸 4개 · 정답 4개');
    expect(candidate.hasBlockingErrors, isFalse);
  });

  test('detects real English T/F format with compact answers and explanations',
      () {
    final candidates = parseWorkbookImportText('''
Dear Editor,
I am Carmen Washington. I am writing to express my concern about Seasons Kitchen’s new child policy.

1. She has been a frequent customer of Seasons Kitchen for several years.
2. She believes her children have always shown good manners at the restaurant.
3. She agrees with the decision to ban all children in order to ensure peace.
4. She asked the manager to completely remove the restaurant’s child policy.
5. She expressed disappointment about the new policy that excludes children.

[정답] TTFFT

[해설]
3) She does not agree with the decision.
4) She asked for a change, not complete removal.

[해석]
1. 그녀는 수년 동안 단골 손님이었다.
''');

    expect(candidates, hasLength(1));
    final candidate = candidates.single;
    expect(candidate.questionType, 'true_false');
    expect(candidate.subtype, 'true_false_en');
    expect(candidate.isUnknown, isFalse);
    expect(candidate.answer['items'], hasLength(5));
    expect(
      (candidate.answer['items'] as List)
          .map((item) => item['answer'])
          .toList(),
      [true, true, false, false, true],
    );
    expect(candidate.answer['items'][2]['explanation'],
        'She does not agree with the decision.');
    expect(candidate.answer['items'][3]['explanation'],
        'She asked for a change, not complete removal.');
    expect(candidate.passageText, contains('Dear Editor'));
    expect(candidate.passageText, isNot(contains('[정답]')));
    expect(candidate.summary, 'T/F 문항 5개 · 정답 5개');
  });

  test('parses spaced compact T/F answers', () {
    final candidate = parseWorkbookImportText('''
The passage explains a classroom study.
1) The study included two groups.
2) Every student used the same method.
3) Retrieval practice improved memory.
4) No test was given.
5) The result supported retrieval practice.
[정답] T F T F T
''').single;

    expect(candidate.questionType, 'true_false');
    expect(
      (candidate.answer['items'] as List)
          .map((item) => item['answer'])
          .toList(),
      [true, false, true, false, true],
    );
  });

  test('does not over-split numbered initial blank and T/F source blocks', () {
    final initial = parseWorkbookImportText('''
Unit 1 Gateway
❶ The c________ collection was open.
❷ The e________ exhibition was popular.
❸ The d________ documents were displayed.
''');
    final trueFalse = parseWorkbookImportText('''
This passage describes a school event.
1) The event was held Monday.
2) Students attended the event.
3) The event ended early.
[정답] T T F
''');

    expect(initial, hasLength(1));
    expect(initial.single.questionType, 'initial_blank');
    expect(trueFalse, hasLength(1));
    expect(trueFalse.single.questionType, 'true_false');
    expect(trueFalse.single.answer['items'], hasLength(3));
  });

  test('reads labeled initial blank answers from the Unit header', () {
    final candidate = parseWorkbookImportText('''
Unit 2 Gateway [정답] (a) chaotic (b) endless (c) Worried (d) delayed (e) relax

The whole morning had been (a)c________.
She was met with (b)e________ security lines.
(c)W________ that she could not get to the boarding gate in time, she rushed.
The flight had been “(d)d________.”
She would have time to (e)r________.
''').single;

    expect(candidate.questionType, 'initial_blank');
    expect(candidate.title, 'Unit 2 Gateway');
    expect(candidate.answer['items'], hasLength(5));
    expect(
      (candidate.answer['items'] as List)
          .map((item) => item['answer'])
          .toList(),
      ['chaotic', 'endless', 'Worried', 'delayed', 'relax'],
    );
    expect(candidate.hasBlockingErrors, isFalse);
    expect(candidate.passageText, isNot(contains('[정답]')));
    expect(candidate.passageText, contains('(a) c________'));
  });

  test('splits labeled initial blanks into separate Unit candidates', () {
    final candidates = parseWorkbookImportText('''
Unit 2 Gateway [정답] (a) chaotic (b) endless
The morning was (a)c________.
There were (b)e________ lines.

Unit 2 No. 1 [정답] (a) still (b) trembling
Ryanna stood (a)s________.
Her hands were (b)t________.
''');

    expect(candidates, hasLength(2));
    expect(candidates.every((item) => item.questionType == 'initial_blank'),
        isTrue);
    expect(candidates.map((item) => item.answer['items'].length), [2, 2]);
    expect(candidates.map((item) => item.title),
        ['Unit 2 Gateway', 'Unit 2 No. 1']);
    expect(
      (candidates[1].answer['items'] as List)
          .map((item) => item['answer'])
          .toList(),
      ['still', 'trembling'],
    );
  });

  test('splits multiple untagged English T/F Unit candidates', () {
    final candidates = parseWorkbookImportText('''
Unit 2 Gateway
Passage A

1. A statement one.
2. A statement two.
3. A statement three.
4. A statement four.
5. A statement five.
[정답] FTTTT

Unit 2 No. 1
Passage B

1. B statement one.
2. B statement two.
3. B statement three.
4. B statement four.
5. B statement five.
[정답] TTFTF
''');

    expect(candidates, hasLength(2));
    expect(candidates.every((item) => item.subtype == 'true_false_en'), isTrue);
    expect(candidates.map((item) => item.answer['items'].length), [5, 5]);
    expect(
      (candidates[0].answer['items'] as List)
          .map((item) => item['answer'])
          .toList(),
      [false, true, true, true, true],
    );
    expect(
      (candidates[1].answer['items'] as List)
          .map((item) => item['answer'])
          .toList(),
      [true, true, false, true, false],
    );
  });

  test('keeps T/F explanations and excludes translations from statements', () {
    final candidate = parseWorkbookImportText('''
Unit 3 Gateway
Passage text.
1. First statement.
2. Second statement.
[정답] T F
[해설]
2) The second statement conflicts with the passage.
[해석]
1. 첫 번째 진술문입니다.
2. 두 번째 진술문입니다.
''').single;

    final items = candidate.answer['items'] as List;
    expect(items, hasLength(2));
    expect(items[1]['explanation'],
        'The second statement conflicts with the passage.');
    expect(items.map((item) => item['statement']).join(' '),
        isNot(contains('진술문입니다')));
  });

  test('detects real untagged paragraph order format', () {
    final candidate = parseWorkbookImportText('''
Unit 1 Gateway [정답] (B)-(C)-(A)

I recently visited the Lambsford History Foundation’s exhibition about the Qukkon Gold Rush.

(A) I can share my experiences working in the extreme cold of Qukkon.
(B) The collection of pictures, tools, and historical documents made the gold miners come to life.
(C) This reminded me of when I lived in Qukkon and worked in the mining industry.
''').single;

    expect(candidate.questionType, 'paragraph_order');
    expect(candidate.isUnknown, isFalse);
    expect(candidate.title, 'Unit 1 Gateway');
    expect(candidate.answer['segments'], hasLength(3));
    expect(candidate.answer['answer_order'], ['B', 'C', 'A']);
    expect(candidate.passageText, contains('Lambsford History Foundation'));
    expect(candidate.passageText, isNot(contains('[정답]')));
    expect(candidate.hasBlockingErrors, isFalse);
  });

  test('splits multiple untagged paragraph order Unit candidates', () {
    final candidates = parseWorkbookImportText('''
Unit 1 Gateway [정답] (B)-(C)-(A)
Lead 1
(A) A1
(B) B1
(C) C1

Unit 1 No. 1 [정답] (C)-(A)-(B)
Lead 2
(A) A2
(B) B2
(C) C2
''');

    expect(candidates, hasLength(2));
    expect(candidates.every((item) => item.questionType == 'paragraph_order'),
        isTrue);
    expect(candidates[0].answer['answer_order'], ['B', 'C', 'A']);
    expect(candidates[1].answer['answer_order'], ['C', 'A', 'B']);
  });

  test('detects real untagged sentence insertion format', () {
    final candidate = parseWorkbookImportText('''
Unit 1 Gateway [정답] ②

This reminded me of when I lived in Qukkon and worked in the mining industry.

I recently visited the Lambsford History Foundation’s exhibition. (①) The collection came to life. (②) Because of this, I’m wondering about volunteer positions. (③)
''').single;

    expect(candidate.questionType, 'sentence_insertion');
    expect(candidate.isUnknown, isFalse);
    expect(candidate.title, 'Unit 1 Gateway');
    expect(candidate.answer['insert_sentence'],
        contains('This reminded me of when I lived in Qukkon'));
    expect(candidate.answer['positions'], hasLength(3));
    expect(candidate.answer['answer'], '②');
    expect(candidate.passageText, isNot(contains('[정답]')));
    expect(candidate.hasBlockingErrors, isFalse);
  });

  test('splits multiple untagged sentence insertion Unit candidates', () {
    final candidates = parseWorkbookImportText('''
Unit 1 Gateway [정답] ②
Insert sentence 1.

Passage 1. (①) A. (②) B. (③)

Unit 1 No. 1 [정답] ③
Insert sentence 2.

Passage 2. (①) A. (②) B. (③) C. (④)
''');

    expect(candidates, hasLength(2));
    expect(
        candidates.every((item) => item.questionType == 'sentence_insertion'),
        isTrue);
    expect(candidates[0].answer['answer'], '②');
    expect(candidates[1].answer['answer'], '③');
    expect(candidates[0].answer['positions'], hasLength(3));
    expect(candidates[1].answer['positions'], hasLength(4));
  });

  test('splits Test headers after a Unit inline choice candidate', () {
    final candidates = parseWorkbookImportText('''
Unit 22 No. 4
Work stress has increased [significant/significantly] significantly over the past two decades.

Test 1
Dear Mr. Johnson,
We [regular/regularly] regularly check the property.
We need to inform you [that/what] that we will enter your rental unit.

Test 2
I was [cleaning/cleaned] cleaning the house when the phone rang.
I am [calling/called] calling to thank you.
''');

    expect(candidates, hasLength(3));
    expect(candidates.map((item) => item.title),
        ['Unit 22 No. 4', 'Test 1', 'Test 2']);
    expect(candidates.every((item) => item.questionType == 'inline_choice'),
        isTrue);
    expect(candidates.map((item) => item.answer['items'].length), [1, 2, 2]);
    expect(candidates[1].passageText, isNot(contains('Test 1')));
  });

  test('splits consecutive case-insensitive Test inline choice headers', () {
    final candidates = parseWorkbookImportText('''
TEST 1
A [good/bad] good idea.

test 2 extra title
A [large/small] large room.

Test 3
A [true/false] true story.
''');

    expect(candidates, hasLength(3));
    expect(
        candidates.map((item) => item.title), ['Test 1', 'Test 2', 'Test 3']);
    expect(candidates.every((item) => item.questionType == 'inline_choice'),
        isTrue);
    expect(candidates.map((item) => item.answer['items'].length), [1, 1, 1]);
  });

  test('keeps Unit and Test 1 through Test 28 as separate candidates', () {
    final source = StringBuffer()
      ..writeln('Unit 22 No. 4')
      ..writeln('Work is [significant/significantly] significantly changed.');
    for (var number = 1; number <= 28; number++) {
      source
        ..writeln()
        ..writeln('Test $number')
        ..writeln('Test text is [correct/wrong] correct.');
    }

    final candidates = parseWorkbookImportText(source.toString());

    expect(candidates, hasLength(29));
    expect(candidates.first.title, 'Unit 22 No. 4');
    expect(candidates.last.title, 'Test 28');
    expect(candidates.every((item) => item.questionType == 'inline_choice'),
        isTrue);
    expect(
        candidates.every((item) => item.answer['items'].length == 1), isTrue);
  });

  test('removes textbook preamble before the first Unit header', () {
    final result = parseWorkbookImportTextDetailed('''
수라영어수능특강 Light 영어
쥬기스, 수능의 시작
본 자료는 내신과 수능의 완벽한 대비를 위해 제작되었습니다.

Unit 1 Gateway
A laboratory is a(n) [artificial/natural] artificial (natural 자연적인).
''');

    expect(result.removedPreamble, isTrue);
    expect(result.candidates, hasLength(1));
    expect(result.candidates.single.title, 'Unit 1 Gateway');
    expect(result.candidates.single.questionType, 'inline_choice');
    expect(result.candidates.single.rawText, isNot(contains('쥬기스')));
    expect(result.candidates.single.passageText, isNot(contains('수라영어')));
  });

  test('removes preamble before the first Test header', () {
    final result = parseWorkbookImportTextDetailed('''
교재 설명문입니다.
카페 주소입니다.

Test 1
A [good/bad] good idea.
''');

    expect(result.removedPreamble, isTrue);
    expect(result.candidates, hasLength(1));
    expect(result.candidates.single.title, 'Test 1');
    expect(result.candidates.single.rawText, isNot(contains('카페 주소')));
  });

  test('omits a chart omission block without an unknown candidate', () {
    final result = parseWorkbookImportTextDetailed('''
Unit 6 Gateway [정답] 도표 생략

[정답] 도표 생략

도표 생략
''');

    expect(result.candidates, isEmpty);
    expect(result.omittedCount, 1);
  });

  test('counts an omitted chart between normal Unit candidates', () {
    final result = parseWorkbookImportTextDetailed('''
Unit 1 Gateway
A [good/bad] good idea.

Unit 6 Gateway [정답] 도표 생략
도표 생략

Unit 7 Gateway
A [large/small] large room.
''');

    expect(result.candidates, hasLength(2));
    expect(result.omittedCount, 1);
    expect(result.candidates.where((item) => item.isUnknown), isEmpty);
    expect(result.candidates.map((item) => item.title),
        ['Unit 1 Gateway', 'Unit 7 Gateway']);
  });
}

const _sample = '''
[본문 선택형]
A laboratory is a(n) [artificial/natural] artificial (natural 자연적인).

---

[확인학습]
보기:
browse / security / intense / chaotic / shallow / announcement
본문:
The morning had been ____________. There were ____________ lines.
정답:
chaotic security

---

[영어 T/F]
본문:
Daniel was going to the train station.
문항:
1 Daniel was going to the train station. [T / F]
2 Daniel waited on the bus. [T / F]
정답:
1 T 2 F

---

[한글 T/F]
본문:
Daniel was going to the train station.
문항:
1 Daniel은 기차역으로 가고 있었다. [T / F]
2 Daniel은 버스에서 기다렸다. [T / F]
정답:
1 T 2 F

---

[첫 글자 빈칸]
본문:
The morning had been (a) c________. There were (b) e________ lines.
정답:
(a) chaotic (b) endless

---

[문장 삽입]
삽입할 문장:
This reminded me of when I lived in Qukkon.
본문:
The exhibition was memorable. (①) The collection came to life. (②) I asked about volunteering. (③)
정답:
②

---

[문단 배열]
제시문:
I recently visited the exhibition.
A:
I can share my experiences.
B:
The collection came to life.
C:
This reminded me of Qukkon.
정답:
B-C-A
''';
