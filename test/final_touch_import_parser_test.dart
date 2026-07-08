import 'package:english_analyzer_app/models/final_touch_import_draft.dart';
import 'package:english_analyzer_app/screens/teacher_final_touch_import_screen.dart';
import 'package:english_analyzer_app/utils/final_touch_import_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses labeled Final Touch text and builds sentence fallback data', () {
    final draft = parseFinalTouchImportText('''
[출처]
수특라이트 영어 12강 6번

[제목]
Research Findings

[주제]
the role of research

[요지]
Research gives ideas life.

[글의 흐름]
서론: 연구 결과를 소개한다.
본론: 사례를 설명한다.
결론: 대안적 관점을 강조한다.

[영어 지문]
[Research findings can inject life (into an idea).]
Research can function {like photographs}.

[한글 해석]
연구 결과는 아이디어에 생명력을 줄 수 있다.
연구는 사진처럼 기능할 수 있다.
''');

    expect(draft.source, '수특라이트 영어 12강 6번');
    expect(draft.title, 'Research Findings');
    expect(draft.outline['intro'], '연구 결과를 소개한다.');
    expect(draft.outline['body'], '사례를 설명한다.');
    expect(draft.outline['conclusion'], '대안적 관점을 강조한다.');
    expect(draft.passage, isNot(contains('[')));
    expect(draft.passageBracketed, contains('(into an idea)'));
    expect(draft.sentenceDetails, hasLength(2));
    expect(draft.sentenceDetails.first['sentence_no'], 1);
    expect(
      draft.sentenceDetails.first['translation'],
      '연구 결과는 아이디어에 생명력을 줄 수 있다.',
    );
    expect(draft.canSave, isTrue);
  });

  test('supports colon headings and reports optional missing fields', () {
    final draft = parseFinalTouchImportText('''
출처: 자체 제작
영어 지문: One sentence.
해석: 한 문장이다.
''');

    expect(draft.source, '자체 제작');
    expect(draft.passage, 'One sentence.');
    expect(draft.sentenceDetails.single['translation'], '한 문장이다.');
    expect(draft.warnings, contains('제목이 없습니다.'));
    expect(draft.warnings, contains('괄호 구조가 없습니다.'));
    expect(draft.canSave, isTrue);
  });

  test('warns when English and translation counts differ', () {
    final draft = parseFinalTouchImportText('''
[영어 지문]
First sentence.
Second sentence.
Third sentence.
[한글 해석]
첫 문장이다.
두 번째 문장이다.
''');

    expect(draft.sentenceDetails, hasLength(3));
    expect(
      draft.warnings,
      contains('영어 문장과 한글 해석 개수가 다릅니다.'),
    );
    expect(draft.sentenceDetails.last['translation'], isEmpty);
  });

  test('disables save when English passage is missing', () {
    final draft = parseFinalTouchImportText('''
[출처]
자체 제작
[한글 해석]
영어 지문이 없는 해석입니다.
''');

    expect(draft.canSave, isFalse);
    expect(draft.warnings, contains('영어 지문이 없습니다.'));
  });

  test('removes nested bracket symbols from plain passage', () {
    expect(
      stripFinalTouchBrackets('[Research (in science) {helps people}.]'),
      'Research in science helps people.',
    );
  });

  test('splits Unit No blocks into independent drafts', () {
    final result = parseFinalTouchImportDrafts('''
Unit 1 No. 1
[출처]
교재 1번
[제목]
First title
[영어 지문]
[First passage has enough words (for a test).]
[한글 해석]
첫 번째 지문의 해석이다.

Unit 1 No. 2
[출처]
교재 2번
[제목]
Second title
[영어 지문]
[Second passage has different words {for another test}.]
[한글 해석]
두 번째 지문의 해석이다.

Unit 1 No. 3
[출처]
교재 3번
[제목]
Third title
[영어 지문]
[Third passage remains separate from the other passages.]
[한글 해석]
세 번째 지문의 해석이다.
''');

    expect(result.drafts, hasLength(3));
    expect(
      result.drafts.map((draft) => draft.unitLabel),
      ['Unit 1 No. 1', 'Unit 1 No. 2', 'Unit 1 No. 3'],
    );
    expect(result.drafts[0].title, 'First title');
    expect(result.drafts[1].title, 'Second title');
    expect(result.drafts[2].title, 'Third title');
    expect(result.drafts[0].passage, isNot(contains('Second passage')));
    expect(result.drafts[1].passage, isNot(contains('Third passage')));
    expect(result.drafts.every((draft) => draft.canSave), isTrue);
  });

  test('splits repeated source headings when unit labels are absent', () {
    final result = parseFinalTouchImportDrafts('''
[출처]
첫 번째 출처
[영어 지문]
First source passage contains a complete English sentence.
[한글 해석]
첫 번째 출처의 해석이다.
[출처]
두 번째 출처
[영어 지문]
Second source passage contains another complete English sentence.
[한글 해석]
두 번째 출처의 해석이다.
''');

    expect(result.drafts, hasLength(2));
    expect(result.drafts[0].source, '첫 번째 출처');
    expect(result.drafts[1].source, '두 번째 출처');
    expect(result.drafts[0].passage, isNot(contains('Second source')));
  });

  test('infers passage and translation inside an unlabeled unit block', () {
    final result = parseFinalTouchImportDrafts('''
Unit 2 No. 1
Digital platforms can reshape how people understand social relationships.
They encourage users to consider a completely different point of view.
디지털 플랫폼은 사람들이 사회적 관계를 이해하는 방식을 바꿀 수 있다.
그것들은 사용자들이 완전히 다른 관점을 고려하도록 장려한다.
[제목]
Digital Platforms

Unit 2 No. 2
Research findings can inject life into an important idea.
They make its significance easier for ordinary people to understand.
연구 결과는 중요한 아이디어에 생명력을 불어넣을 수 있다.
그것들은 일반 사람들이 그 중요성을 더 쉽게 이해하게 한다.
[제목]
Research Findings
''');

    expect(result.drafts, hasLength(2));
    expect(result.drafts[0].passage, contains('Digital platforms'));
    expect(
      result.drafts[0].sentenceDetails.first['translation'],
      contains('디지털 플랫폼'),
    );
    expect(result.drafts[1].passage, contains('Research findings'));
    expect(result.drafts[1].passage, isNot(contains('Digital platforms')));
  });

  test('merges right-side Gateway and numbered translation blocks into drafts',
      () {
    final result = parseFinalTouchImportDrafts('''
Unit 1 Gateway
Dear students, I am Amanda Clark, the school club director.
Over the last few semesters, many students have asked for more diverse clubs.

Unit 1 No. 1
Recently, designers have tried to make public spaces more useful for everyone.
Their work can improve how people share ideas in daily life.

Unit 1 No. 2
Careful maintenance can prevent small problems from becoming serious damage.
This approach helps communities save money and protect public facilities.

Gateway
[\uD574\uC11D]
\uD559\uC0DD \uC5EC\uB7EC\uBD84\uAED8
\uC800\uB294 \uD559\uAD50 \uB3D9\uC544\uB9AC \uB2F4\uB2F9 \uAD50\uC0AC Amanda Clark\uC785\uB2C8\uB2E4.
[\uD574\uC124]
\uB354 \uB2E4\uC591\uD55C \uB3D9\uC544\uB9AC\uC5D0 \uB300\uD55C \uC694\uCCAD\uC774 \uC788\uC5C8\uB2E4.
[\uC5B4\uD718]
semester \uD559\uAE30
diverse \uB2E4\uC591\uD55C

01
[\uD574\uC11D]
\uCD5C\uADFC\uC5D0 \uB514\uC790\uC774\uB108\uB4E4\uC740 \uACF5\uACF5 \uACF5\uAC04\uC744 \uB354 \uC720\uC6A9\uD558\uAC8C \uB9CC\uB4E4\uB824\uACE0 \uB178\uB825\uD574 \uC654\uB2E4.
\uADF8\uB4E4\uC758 \uC791\uC5C5\uC740 \uC0AC\uB78C\uB4E4\uC774 \uC77C\uC0C1\uC5D0\uC11C \uC0DD\uAC01\uC744 \uB098\uB204\uB294 \uBC29\uC2DD\uC744 \uAC1C\uC120\uD560 \uC218 \uC788\uB2E4.
[\uD574\uC124]
\uACF5\uACF5 \uACF5\uAC04 \uB514\uC790\uC778\uC5D0 \uAD00\uD55C \uC9C0\uBB38\uC774\uB2E4.

02
[\uD574\uC11D]
\uC138\uC2EC\uD55C \uBCF4\uC218 \uAD00\uB9AC\uB294 \uC791\uC740 \uBB38\uC81C\uAC00 \uC2EC\uAC01\uD55C \uC190\uC0C1\uC774 \uB418\uB294 \uAC83\uC744 \uB9C9\uC744 \uC218 \uC788\uB2E4.
\uC774\uB7EC\uD55C \uC811\uADFC\uC740 \uACF5\uB3D9\uCCB4\uAC00 \uB3C8\uC744 \uC544\uB07C\uACE0 \uACF5\uACF5 \uC2DC\uC124\uC744 \uBCF4\uD638\uD558\uB294 \uB370 \uB3C4\uC6C0\uC774 \uB41C\uB2E4.
[\uC5B4\uD718]
maintenance \uBCF4\uC218 \uAD00\uB9AC
''');

    expect(result.drafts, hasLength(3));
    expect(
      result.drafts.map((draft) => draft.unitLabel),
      ['Unit 1 Gateway', 'Unit 1 No. 1', 'Unit 1 No. 2'],
    );
    expect(
      result.drafts[0].sentenceDetails.first['translation'],
      contains('\uD559\uC0DD \uC5EC\uB7EC\uBD84'),
    );
    expect(
      result.drafts[1].sentenceDetails.first['translation'],
      contains('\uCD5C\uADFC\uC5D0'),
    );
    expect(
      result.drafts[2].sentenceDetails.first['translation'],
      contains('\uC138\uC2EC\uD55C'),
    );
    final gatewayTranslations = result.drafts[0].sentenceDetails
        .map((item) => '${item['translation']}')
        .join('\n');
    expect(gatewayTranslations, isNot(contains('\uD574\uC124')));
    expect(gatewayTranslations, isNot(contains('semester')));
  });

  test('matches repeated Gateway and numbered companion blocks by occurrence',
      () {
    final result = parseFinalTouchImportDrafts('''
Unit 1 Gateway
Dear students,
I am Amanda Clark, the school club director, and I am writing to you about school clubs.
Over the last few semesters, many students have asked for more diverse clubs.
Best regards,
Amanda Clark

Unit 1 No. 1
Recently, designers have tried to make public spaces more useful for everyone.
Their work can improve how people share ideas in daily life.

Unit 1 No. 2
Careful maintenance can prevent small problems from becoming serious damage.
This approach helps communities save money and protect public facilities.

Unit 2 Gateway
① “Where could it be?” Sophie asked herself.
② It had been more than ten years [since she had last visited the area [where she had grown up]].
③ The village had changed a lot {over time}.
④ {Uncertain}, she awkwardly looked around (at her surroundings).
⑤ She walked the narrow streets (of the village), {unsure about which way to go}.
⑥ Suddenly, Sophie saw a familiar sight.
⑦ “Yes, this must be it,” she thought.
⑧ (In front of her) was a wall {with flowers painted on it}.
⑨ [Although the colors were now faded], the familiar shapes (on the wall) were the same ones [she had painted (with her father) (as a child)].
⑩ Sophie nodded, smiled brightly, and walked (toward the gate).
⑪ (At last), she had finally found the house [she had grown up in].

Unit 2 No. 1
Artists often borrow ideas from nature to solve difficult design problems.
These ideas can lead to new tools that are both simple and effective.

Unit 2 No. 2
People remember information better when they connect it to a clear story.
That is why teachers often use examples before introducing abstract concepts.

Gateway
[\uD574\uC11D]
\uC720\uB2DB 1 \uAC8C\uC774\uD2B8\uC6E8\uC774 \uD574\uC11D \uCCAB \uC904
Amanda Clark \uB4DC\uB9BC
[\uD574\uC124]
\uC720\uB2DB 1 \uAC8C\uC774\uD2B8\uC6E8\uC774 \uD574\uC124
[\uC5B4\uD718]
semester \uD559\uAE30

01
[\uD574\uC11D]
\uC720\uB2DB 1 1\uBC88 \uD574\uC11D
[\uD574\uC124]
\uC720\uB2DB 1 1\uBC88 \uD574\uC124

02
[\uD574\uC11D]
\uC720\uB2DB 1 2\uBC88 \uD574\uC11D
[\uD574\uC124]
\uC720\uB2DB 1 2\uBC88 \uD574\uC124

Gateway
[\uD574\uC11D]
\uC720\uB2DB 2 \uAC8C\uC774\uD2B8\uC6E8\uC774 \uD574\uC11D \uCCAB \uC904
\uB9C8\uCE68\uB0B4, Sophie\uB294 \uC9D1\uC744 \uCC3E\uC558\uB2E4.
[\uD574\uC124]
\uC720\uB2DB 2 \uAC8C\uC774\uD2B8\uC6E8\uC774 \uD574\uC124
[\uC5B4\uD718]
faded \uBC14\uB79C

01
[\uD574\uC11D]
\uC720\uB2DB 2 1\uBC88 \uD574\uC11D
[\uD574\uC124]
\uC720\uB2DB 2 1\uBC88 \uD574\uC124

02
[\uD574\uC11D]
\uC720\uB2DB 2 2\uBC88 \uD574\uC11D
[\uD574\uC124]
\uC720\uB2DB 2 2\uBC88 \uD574\uC124
''');

    expect(result.drafts, hasLength(6));
    expect(
      result.drafts.map((draft) => draft.unitLabel),
      [
        'Unit 1 Gateway',
        'Unit 1 No. 1',
        'Unit 1 No. 2',
        'Unit 2 Gateway',
        'Unit 2 No. 1',
        'Unit 2 No. 2',
      ],
    );
    expect(result.drafts[0].source, 'Unit 1 Gateway');
    expect(result.drafts[3].source, 'Unit 2 Gateway');
    expect(result.drafts[3].sentenceDetails, hasLength(11));

    final translations = [
      for (final draft in result.drafts)
        draft.sentenceDetails
            .map((item) => '${item['translation']}')
            .join('\n'),
    ];
    expect(translations[0],
        contains('\uC720\uB2DB 1 \uAC8C\uC774\uD2B8\uC6E8\uC774'));
    expect(translations[0],
        isNot(contains('\uC720\uB2DB 2 \uAC8C\uC774\uD2B8\uC6E8\uC774')));
    expect(translations[1], contains('\uC720\uB2DB 1 1\uBC88'));
    expect(translations[2], contains('\uC720\uB2DB 1 2\uBC88'));
    expect(translations[3],
        contains('\uC720\uB2DB 2 \uAC8C\uC774\uD2B8\uC6E8\uC774'));
    expect(translations[3],
        isNot(contains('\uC720\uB2DB 1 \uAC8C\uC774\uD2B8\uC6E8\uC774')));
    expect(translations[4], contains('\uC720\uB2DB 2 1\uBC88'));
    expect(translations[5], contains('\uC720\uB2DB 2 2\uBC88'));
    for (final translation in translations) {
      expect(translation, isNot(contains('\uD574\uC124')));
      expect(translation, isNot(contains('semester')));
      expect(translation, isNot(contains('faded')));
    }
  });

  test('keeps full translation block and falls back source to unit label', () {
    final result = parseFinalTouchImportDrafts('''
Unit 1 Gateway
Dear students,
I am Amanda Clark, the school club director, and I am writing to you about school clubs.
Best regards,
Amanda Clark

Gateway
[\uD574\uC11D]
\uD559\uC0DD \uC5EC\uB7EC\uBD84\uAED8
\uC800\uB294 \uD559\uAD50 \uB3D9\uC544\uB9AC \uB2F4\uB2F9 \uAD50\uC0AC Amanda Clark\uC774\uBA70, \uD559\uAD50 \uB3D9\uC544\uB9AC\uC640 \uAD00\uB828\uD574 \uC5EC\uB7EC\uBD84\uAED8 \uAE00\uC744 \uC501\uB2C8\uB2E4.
\uC9C0\uB09C \uBA87 \uD559\uAE30 \uB3D9\uC548 \uB354 \uB2E4\uC591\uD55C \uD559\uAD50 \uB3D9\uC544\uB9AC\uC5D0 \uB300\uD55C \uC694\uCCAD\uC774 \uC788\uC5C8\uC2B5\uB2C8\uB2E4.
Amanda Clark \uB4DC\uB9BC
[\uD574\uC124]
\uB354 \uB2E4\uC591\uD55C \uB3D9\uC544\uB9AC\uC5D0 \uB300\uD55C \uC694\uCCAD\uC774 \uC788\uC5C8\uB2E4.
[\uC5B4\uD718]
semester \uD559\uAE30
''');

    expect(result.drafts, hasLength(1));
    final draft = result.drafts.single;
    expect(draft.source, 'Unit 1 Gateway');
    expect(draft.warnings,
        isNot(contains('\uCD9C\uCC98\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.')));
    expect(draft.passageBracketed, contains('Dear students,'));
    expect(draft.passageBracketed, contains('Best regards,'));
    expect(draft.passageBracketed, contains('Amanda Clark'));
    final translations = draft.sentenceDetails
        .map((item) => '${item['translation']}')
        .join('\n');
    expect(translations, contains('\uD559\uC0DD \uC5EC\uB7EC\uBD84\uAED8'));
    expect(translations, contains('Amanda Clark \uB4DC\uB9BC'));
    expect(translations, isNot(contains('\uD574\uC124')));
    expect(translations, isNot(contains('semester')));
  });

  test('keeps all numbered narrative sentences including quotes and brackets',
      () {
    final result = parseFinalTouchImportDrafts('''
Unit 2 Gateway
① “Where could it be?” Sophie asked herself.
② It had been more than ten years [since she had last visited the area [where she had grown up]].
③ The village had changed a lot {over time}.
④ {Uncertain}, she awkwardly looked around (at her surroundings).
⑤ She walked the narrow streets (of the village), {unsure about which way to go}.
⑥ Suddenly, Sophie saw a familiar sight.
⑦ “Yes, this must be it,” she thought.
⑧ (In front of her) was a wall {with flowers painted on it}.
⑨ [Although the colors were now faded], the familiar shapes (on the wall) were the same ones [she had painted (with her father) (as a child)].
⑩ Sophie nodded, smiled brightly, and walked (toward the gate).
⑪ (At last), she had finally found the house [she had grown up in].

Gateway
[\uD574\uC11D]
\u201C\uC5B4\uB514\uC5D0 \uC788\uC744\uAE4C?\u201D Sophie\uB294 \uD63C\uC790 \uC0DD\uAC01\uD588\uB2E4.
\uADF8\uB140\uAC00 \uC790\uC2E0\uC774 \uC790\uB790\uB358 \uADF8 \uC9C0\uC5ED\uC744 \uB9C8\uC9C0\uB9C9\uC73C\uB85C \uBC29\uBB38\uD55C \uC9C0 10\uB144\uC774 \uB118\uC5C8\uB2E4.
\uADF8 \uB9C8\uC744\uC740 \uC2DC\uAC04\uC774 \uD750\uB974\uBA70 \uB9CE\uC774 \uBCC0\uD574 \uC788\uC5C8\uB2E4.
\uD655\uC2E0\uC774 \uC5C6\uC5B4, \uADF8\uB140\uB294 \uC8FC\uBCC0\uC744 \uC5B4\uC0C9\uD558\uAC8C \uB458\uB7EC\uBCF4\uC558\uB2E4.
\uADF8\uB140\uB294 \uAC08 \uAE38\uC744 \uD655\uC2E0\uD558\uC9C0 \uBABB\uD55C \uCC44 \uB9C8\uC744\uC758 \uC881\uC740 \uAE38\uC744 \uAC78\uC5C8\uB2E4.
\uAC11\uC790\uAE30 Sophie\uB294 \uC775\uC219\uD55C \uAD11\uACBD\uC744 \uBCF4\uC558\uB2E4.
\u201C\uB9DE\uC544, \uC774\uAC8C \uADF8\uAC83\uC774 \uD2C0\uB9BC\uC5C6\uC5B4,\u201D\uB77C\uACE0 \uADF8\uB140\uB294 \uC0DD\uAC01\uD588\uB2E4.
\uADF8\uB140 \uC55E\uC5D0\uB294 \uAF43\uC774 \uADF8\uB824\uC9C4 \uBCBD\uC774 \uC788\uC5C8\uB2E4.
\uC0C9\uC740 \uC774\uC81C \uBC14\uB798\uC5C8\uC9C0\uB9CC, \uBCBD\uC758 \uC775\uC219\uD55C \uBAA8\uC591\uB4E4\uC740 \uADF8\uB140\uAC00 \uC5B4\uB9B4 \uC801 \uC544\uBC84\uC9C0\uC640 \uADF8\uB838\uB358 \uAC83\uB4E4\uACFC \uAC19\uC558\uB2E4.
Sophie\uB294 \uACE0\uAC1C\uB97C \uB04C\uB355\uC774\uACE0, \uBC1D\uAC8C \uC6C3\uC73C\uBA70, \uB300\uBB38 \uCABD\uC73C\uB85C \uAC78\uC5B4\uAC14\uB2E4.
\uB9C8\uCE68\uB0B4, \uADF8\uB140\uB294 \uC790\uC2E0\uC774 \uC790\uB790\uB358 \uADF8 \uC9D1\uC744 \uB4DC\uB514\uC5B4 \uCC3E\uC558\uB2E4.
[\uD574\uC124]
\uC5B4\uB9B0 \uC2DC\uC808 \uC9D1\uC744 \uCC3E\uB294 \uC774\uC57C\uAE30\uC774\uB2E4.
[\uC5B4\uD718]
faded \uBC14\uB79C
''');

    expect(result.drafts, hasLength(1));
    final draft = result.drafts.single;
    expect(draft.sentenceDetails, hasLength(11));
    expect(draft.passageBracketed, contains('“Where could it be?”'));
    expect(draft.passageBracketed,
        contains('[Although the colors were now faded]'));
    expect(draft.sentenceDetails[8]['bracketed'], contains('familiar shapes'));
    final translations = draft.sentenceDetails
        .map((item) => '${item['translation']}')
        .join('\n');
    expect(translations, contains('\uB9C8\uCE68\uB0B4'));
    expect(translations, isNot(contains('\uD574\uC124')));
    expect(translations, isNot(contains('faded')));
  });

  test(
      'recovers multiple English lines when one long bracketed sentence exists',
      () {
    final result = parseFinalTouchImportDrafts('''
Unit 2 No. 1
? The climbers gathered at the foot of the mountain before sunrise.
? “Are we ready?” Mina asked, looking at the dark trail.
? The guide checked the ropes {to make sure everyone was safe}.
? The group members were all experienced, so I couldn’t understand [why they were climbing so slowly] — [what I thought was a ridiculous pace].
? After an hour, I realized (in the situation) that the path was covered with thin ice.
? We moved carefully, listening to the sound of snow under our boots.

01
[\uD574\uC11D]
\uB4F1\uBC18\uAC00\uB4E4\uC740 \uD574\uB728\uAE30 \uC804 \uC0B0 \uC544\uB798\uC5D0 \uBAA8\uC600\uB2E4.
\u201C\uC900\uBE44\uB410\uB098\uC694?\u201D Mina\uAC00 \uC5B4\uB450\uC6B4 \uC0B0\uAE38\uC744 \uBCF4\uBA70 \uBB3C\uC5C8\uB2E4.
\uAC00\uC774\uB4DC\uB294 \uBAA8\uB450\uAC00 \uC548\uC804\uD55C\uC9C0 \uD655\uC778\uD558\uAE30 \uC704\uD574 \uC904\uC744 \uC810\uAC80\uD588\uB2E4.
\uADF8 \uB4F1\uBC18\uB300\uC6D0\uB4E4\uC740 \uBAA8\uB450 \uACBD\uD5D8\uC774 \uB9CE\uC558\uB2E4.
\uD55C \uC2DC\uAC04 \uD6C4\uC5D0 \uB098\uB294 \uADF8 \uAE38\uC774 \uC587\uC740 \uC5BC\uC74C\uC73C\uB85C \uB36E\uC5EC \uC788\uC74C\uC744 \uAE68\uB2EC\uC558\uB2E4.
\uC6B0\uB9AC\uB294 \uBD80\uCE20 \uC544\uB798 \uB208 \uC18C\uB9AC\uB97C \uB4E4\uC73C\uBA70 \uC870\uC2EC\uC2A4\uB7FD\uAC8C \uC6C0\uC9C1\uC600\uB2E4.
[\uD574\uC124]
\uC0B0\uAE38\uC758 \uC704\uD5D8\uC744 \uAE68\uB2EB\uB294 \uB0B4\uC6A9\uC774\uB2E4.
[\uC5B4\uD718]
pace \uC18D\uB3C4
''');

    expect(result.drafts, hasLength(1));
    final draft = result.drafts.single;
    expect(draft.sentenceDetails, hasLength(6));
    expect(draft.passageBracketed, contains('The climbers gathered'));
    expect(draft.passageBracketed, contains('“Are we ready?”'));
    expect(
        draft.passageBracketed, contains('{to make sure everyone was safe}'));
    expect(
      draft.passageBracketed,
      contains(
          '[why they were climbing so slowly] — [what I thought was a ridiculous pace]'),
    );
    expect(draft.passageBracketed, contains('(in the situation)'));
    final translations = draft.sentenceDetails
        .map((item) => '${item['translation']}')
        .join('\n');
    expect(translations, contains('\uB4F1\uBC18\uAC00\uB4E4'));
    expect(translations, isNot(contains('\uD574\uC124')));
    expect(translations, isNot(contains('pace')));
  });

  test('preview title omits index prefix', () {
    const draft = FinalTouchImportDraft(
      index: 2,
      unitLabel: 'Unit 1 No. 2',
      source: 'Unit 1 No. 2',
      title: '',
      topic: '',
      gist: '',
      outline: {'intro': '', 'body': '', 'conclusion': ''},
      passage: 'This is a short passage for preview title testing.',
      passageBracketed: 'This is a short passage for preview title testing.',
      sentenceDetails: [],
      rawText: '',
      warnings: [],
    );

    expect(finalTouchImportPreviewTitle(draft), 'Unit 1 No. 2');
    expect(finalTouchImportPreviewTitle(draft), isNot(startsWith('3.')));
  });
}
