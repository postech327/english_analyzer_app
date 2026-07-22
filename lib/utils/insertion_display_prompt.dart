const singleInsertionDisplayPrompt = '글의 흐름으로 보아, 주어진 문장이 들어가기에 가장 적절한 곳은?';
const multipleInsertionDisplayPrompt = '글의 흐름으로 보아, 주어진 문장들이 들어가기에 가장 적절한 곳은?';

String insertionDisplayPromptForMode(Object? mode) {
  final normalized = (mode ?? '').toString().trim().toLowerCase();
  return normalized == 'multiple'
      ? multipleInsertionDisplayPrompt
      : singleInsertionDisplayPrompt;
}
