import 'package:english_analyzer_app/utils/vocabulary_multi_file_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('infers the three common file roles from names', () {
    expect(
      inferVocabularyFileRole('단어목록(철자의미).hwpx', ''),
      VocabularyFileRole.paired,
    );
    expect(
      inferVocabularyFileRole('단어시험(의미시험).hwpx', ''),
      VocabularyFileRole.englishOnly,
    );
    expect(
      inferVocabularyFileRole('단어시험(철자시험).hwpx', ''),
      VocabularyFileRole.koreanOnly,
    );
  });

  test('merges English and Korean files by cleaned line order', () {
    final result = analyzeVocabularyImportFiles(const [
      VocabularyImportFileCandidate(
        name: 'english.txt',
        text: '1. goal\n☐ recently\n3) design',
        inferredRole: VocabularyFileRole.englishOnly,
      ),
      VocabularyImportFileCandidate(
        name: 'korean.txt',
        text: '① 목표\n최근에\n설계하다',
        inferredRole: VocabularyFileRole.koreanOnly,
      ),
    ]);

    expect(result.savableRows.length, 3);
    expect(result.savableRows[1].word, 'recently');
    expect(result.savableRows[1].meaningKo, '최근에');
  });

  test('warns for count mismatch and duplicate words', () {
    final mismatch = analyzeVocabularyImportFiles(const [
      VocabularyImportFileCandidate(
        name: 'english.txt',
        text: 'goal\ngoal\nextra',
        inferredRole: VocabularyFileRole.englishOnly,
      ),
      VocabularyImportFileCandidate(
        name: 'korean.txt',
        text: '목표\n목표',
        inferredRole: VocabularyFileRole.koreanOnly,
      ),
    ]);

    expect(mismatch.savableRows.length, 1);
    expect(
      mismatch.rows.any((row) => row.warning == '중복 단어입니다.'),
      isTrue,
    );
    expect(
      mismatch.rows.any((row) => row.warning == '한글 뜻이 없습니다.'),
      isTrue,
    );
  });

  test('prefers a paired file when present', () {
    final result = analyzeVocabularyImportFiles(const [
      VocabularyImportFileCandidate(
        name: '단어목록.txt',
        text: 'goal 목표\nrecently 최근에',
        inferredRole: VocabularyFileRole.paired,
      ),
      VocabularyImportFileCandidate(
        name: 'english.txt',
        text: 'ignored',
        inferredRole: VocabularyFileRole.englishOnly,
      ),
    ]);

    expect(result.savableRows.length, 2);
    expect(result.rows.first.source, '단어목록.txt');
  });
}
