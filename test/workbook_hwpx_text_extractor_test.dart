import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:english_analyzer_app/utils/question_hwpx_import_parser.dart';
import 'package:english_analyzer_app/utils/workbook_hwpx_text_extractor.dart';
import 'package:english_analyzer_app/utils/workbook_import_parser.dart';

void main() {
  test('extracts HWPX section paragraphs in section order', () {
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          'Contents/section1.xml',
          _sectionXml(['Unit 2 No. 1', '1. Second statement.']),
        ),
      )
      ..addFile(
        ArchiveFile.string(
          'Contents/section0.xml',
          _sectionXml([
            'Unit 2 Gateway [정답] FTTTT',
            '1. First statement.',
          ]),
        ),
      );
    final bytes = ZipEncoder().encode(archive);

    final result = extractWorkbookTextFromHwpx(bytes);

    expect(result.sectionCount, 2);
    expect(result.paragraphCount, 4);
    expect(
      result.text.indexOf('Unit 2 Gateway'),
      lessThan(result.text.indexOf('Unit 2 No. 1')),
    );
    expect(result.text, contains('1. First statement.'));
    expect(result.text, contains('1. Second statement.'));
  });

  test('joins split Korean T/F runs and keeps the trailing statement set', () {
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          'Contents/section0.xml',
          _sectionXmlRuns([
            ['Unit 1 Gateway', ' ', '[정답] TFTTT', '[해설]', '2) 앞쪽 해설'],
            ['[정답] TFTTT'],
            ['[해설]'],
            ['2) 앞쪽 해설'],
            ['English source passage.'],
            ['1)', '첫 번째 진술은 본문과 일치한다.'],
            ['2)', '두 번째 진술은 본문과 일치하지 않는다.'],
            ['3)', '세 번째 진술은 본문과 일치한다.'],
            ['4)', '네 번째 진술은 본문과 일치한다.'],
            ['5)', '다섯 번째 진술은 본문과 일치한다.'],
            ['[정답] TFTTT'],
            ['[해설]'],
            ['2) 두 번째 진술은 본문과 일치하지 않는다.'],
          ]),
        ),
      );

    final extracted = extractWorkbookTextFromHwpx(
      ZipEncoder().encode(archive),
    );
    final candidate = parseWorkbookImportText(extracted.text).single;

    expect(extracted.paragraphRuns.first, hasLength(5));
    expect(candidate.questionType, 'true_false');
    expect(candidate.subtype, 'true_false_ko');
    expect(candidate.passageText, 'English source passage.');
    expect(candidate.answer['items'], hasLength(5));
    expect(candidate.hasBlockingErrors, isFalse);
    expect(candidate.warnings, isEmpty);
  });

  test('rejects bytes that are not an HWPX zip', () {
    expect(
      () => extractWorkbookTextFromHwpx([1, 2, 3, 4]),
      throwsFormatException,
    );
  });

  test('extracts and merges adjacent underlined HWPX runs with exact offsets',
      () {
    final archive = Archive()
      ..addFile(ArchiveFile.string('Contents/header.xml', _headerXml))
      ..addFile(
        ArchiveFile.string(
          'Contents/section0.xml',
          _sectionXmlWithProperties([
            [(0, '1) 밑줄 친 부분이 다음 글에서 의미하는 바로 가장 적절한 것은?')],
            [
              (0, 'Hunters remember that '),
              (1, 'their neighbors share with them '),
              (1, 'on days when luck runs the other way'),
              (0, '. This keeps the community resilient.'),
            ],
            [
              (
                0,
                '① Mutual aid returns earlier generosity. ② Competition matters most. ③ Luck never changes. ④ Hunters work alone. ⑤ Sharing weakens communities.'
              )
            ],
            [(0, '[정답] ①')],
          ]),
        ),
      );

    final extracted = extractWorkbookTextFromHwpx(ZipEncoder().encode(archive));
    final ranges = extracted.paragraphUnderlineRanges[1];

    expect(ranges, hasLength(1));
    expect(
      ranges.single.text,
      'their neighbors share with them on days when luck runs the other way',
    );
    expect(
      extracted.paragraphs[1].substring(
        ranges.single.start,
        ranges.single.end,
      ),
      ranges.single.text,
    );
    expect(ranges.single.runStartIndex, 1);
    expect(ranges.single.runEndIndex, 2);

    final parsed = parseQuestionHwpxImportText(
      extracted.text,
      paragraphUnderlineRanges: extracted.paragraphUnderlineRanges,
    );
    final question = parsed.questions.single;
    expect(question.questionType, 'implication');
    final stored = question.specialData?['underline_ranges'] as List;
    expect(stored, hasLength(1));
    final storedRange = Map<String, dynamic>.from(stored.single as Map);
    expect(
      question.passage.substring(
        storedRange['start'] as int,
        storedRange['end'] as int,
      ),
      storedRange['text'],
    );
    expect(question.warnings, isNot(contains('missing_underlined_target')));
    expect(
      (question.toRequestJson()['special_data'] as Map)['underline_ranges'],
      stored,
    );
  });

  test('warns but keeps implication saveable when source has no underline run',
      () {
    final parsed = parseQuestionHwpxImportText('''
1) 밑줄 친 부분이 다음 글에서 의미하는 바로 가장 적절한 것은?
People support one another when circumstances change.
① Mutual support ② Isolation ③ Competition ④ Silence ⑤ Delay
[정답] ①
''');
    final question = parsed.questions.single;
    expect(question.questionType, 'implication');
    expect(question.warnings, contains('missing_underlined_target'));
    expect(question.isSaveable, isTrue);
  });

  test('joins split runs and aligns numberless long-set prompts', () {
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          'Contents/section0.xml',
          _sectionXmlRuns([
            ['[정답] ①', '다음 글의 주제로 가장 적절한 것은?'],
            [
              'Readers use evidence to revise conclusions.\n'
                  '① evidence supports revision\n② weather changes quickly\n'
                  '③ memory is perfect\n④ revision is harmful\n⑤ claims need no support',
            ],
            ['[정답] ①'],
            ['[정답] ②', '다음 글의 제목으로 가장 적절한 것은?'],
            [
              'Small acts of kindness can solve conflicts.\n'
                  '① Ignoring Others\n② Kindness Resolves Conflict\n'
                  '③ A Silent Market\n④ Expensive Food\n⑤ Walking Alone',
            ],
            ['[정답] ②'],
            ['※ 다음', ' 지문을', ' 읽고, ', '물음에 답하시오.'],
            ['(A) William noticed an elderly vendor beside the road.'],
            ['(B) William listened carefully because (a) he wanted to help.'],
            ['(C) The vendor thanked him while (b) he smiled.'],
            ['(D) A shopkeeper later praised William for his kindness.'],
            ['[정답] (C)-(B)-(D)', '주어진 글 (A)에 이어질 내용을 순서에 맞게 배열하시오.'],
            ['[정답] (C)-(B)-(D)'],
            ['[정답] (c) the vendor', '밑줄 친 (a)~(e) 중에서 가리키는 대상이 나머지 넷과 다른 것은?'],
            ['[정답] (c) the vendor'],
            [
              '[정답] ⓑ ⓔ',
              '[해설]',
              '두 진술이 본문과 다르다.',
              '윗글에 관한 내용과 일치하지 않는 것을 모두 고르시오. (정답 최대 2개)',
            ],
            ['[정답] ⓑ ⓔ'],
            ['[해설]'],
            ['ⓐ William noticed a vendor.'],
            ['ⓑ William ignored the vendor.'],
            ['ⓒ William listened carefully.'],
            ['ⓓ A shopkeeper praised William.'],
            ['ⓔ The vendor punished William.'],
          ]),
        ),
      );
    final bytes = ZipEncoder().encode(archive);

    final extracted = extractWorkbookTextFromHwpx(bytes);
    final draft = parseQuestionHwpxImportText(extracted.text);

    expect(extracted.paragraphRuns[6], hasLength(4));
    expect(
      extracted.paragraphs[6],
      '※ 다음 지문을 읽고, 물음에 답하시오.',
    );
    expect(draft.questions, hasLength(5));
    expect(
      draft.questions.map((question) => question.questionNo),
      [1, 2, 3, 4, 5],
    );
    expect(
      draft.questions.map((question) => question.questionType),
      ['topic', 'title', 'order', 'reference', 'content_match'],
    );
    expect(draft.questions.every((question) => question.isSaveable), isTrue);
    expect(draft.questions[2].passage, isNotEmpty);
    expect((draft.questions[2].specialData?['blocks'] as Map), hasLength(4));
    expect(draft.questions[3].choices, hasLength(5));
    expect(draft.questions[4].specialData?['answer_indices'], [1, 4]);
  });
}

String _sectionXml(List<String> paragraphs) {
  final body = paragraphs
      .map((text) => '<hp:p><hp:run><hp:t>$text</hp:t></hp:run></hp:p>')
      .join();
  return '<?xml version="1.0" encoding="UTF-8"?>'
      '<hp:sec xmlns:hp="http://www.hancom.co.kr/hwpml/2011/paragraph">'
      '$body</hp:sec>';
}

String _sectionXmlRuns(List<List<String>> paragraphs) {
  final body = paragraphs
      .map(
        (runs) => '<hp:p>${runs.map(
              (text) => '<hp:run><hp:t>${_xmlEscape(text)}</hp:t></hp:run>',
            ).join()}</hp:p>',
      )
      .join();
  return '<?xml version="1.0" encoding="UTF-8"?>'
      '<hp:sec xmlns:hp="http://www.hancom.co.kr/hwpml/2011/paragraph">'
      '$body</hp:sec>';
}

String _xmlEscape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

const _headerXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<hh:head xmlns:hh="http://www.hancom.co.kr/hwpml/2011/head">
  <hh:refList><hh:charProperties>
    <hh:charPr id="0"><hh:underline type="NONE"/></hh:charPr>
    <hh:charPr id="1"><hh:underline type="BOTTOM" shape="SOLID" color="#000000"/></hh:charPr>
  </hh:charProperties></hh:refList>
</hh:head>
''';

String _sectionXmlWithProperties(List<List<(int, String)>> paragraphs) {
  final body = paragraphs.map((runs) {
    final bodyRuns = runs.map(
      (run) => '<hp:run charPrIDRef="${run.$1}">'
          '<hp:t>${_xmlEscape(run.$2)}</hp:t></hp:run>',
    );
    return '<hp:p>${bodyRuns.join()}</hp:p>';
  }).join();
  return '<?xml version="1.0" encoding="UTF-8"?>'
      '<hp:sec xmlns:hp="http://www.hancom.co.kr/hwpml/2011/paragraph">'
      '$body</hp:sec>';
}
