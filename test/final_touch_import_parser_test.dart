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
}
