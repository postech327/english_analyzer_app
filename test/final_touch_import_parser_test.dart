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
}
