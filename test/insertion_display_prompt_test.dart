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
}
