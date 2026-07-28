import 'package:english_analyzer_app/utils/insertion_display_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('single insertion uses singular prompt', () {
    expect(
      insertionDisplayPromptForMode('single'),
      '글의 흐름으로 보아, 주어진 문장이 들어가기에 가장 적절한 곳은?',
    );
  });

  test('multiple insertion uses plural prompt', () {
    expect(
      insertionDisplayPromptForMode('multiple'),
      '글의 흐름으로 보아, 주어진 문장들이 들어가기에 가장 적절한 곳은?',
    );
  });

  test('missing mode keeps legacy single insertion prompt', () {
    expect(
      insertionDisplayPromptForMode(null),
      singleInsertionDisplayPrompt,
    );
  });

  test('formats insertion markers as inline gaps and strips notes', () {
    final display = insertionPassageForDisplay(
      'Opening. (①) First. ② Second.\n*angst 불안\n**buffer 완화하다',
    );

    expect(display, 'Opening. (①) First. (②) Second.');
    expect(display, contains('(①) First'));
    expect(display, contains('(②) Second'));
    expect(display, isNot(contains('\n\n①\n\n')));
    expect(display, isNot(contains('\n\n②\n\n')));
    expect(display, isNot(contains('*angst')));
    expect(display, isNot(contains('**buffer')));
  });

  test('uses circled display labels without changing numeric positions', () {
    final positions = <int>[1, 2, 3, 4, 5];

    expect(
      insertionPositionLabels(positions),
      <String>['①', '②', '③', '④', '⑤'],
    );
    expect(positions, <int>[1, 2, 3, 4, 5]);
  });
}
