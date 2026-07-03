class VocabularyImportRow {
  const VocabularyImportRow({
    required this.lineNumber,
    required this.word,
    required this.meaningKo,
    this.warning,
    this.source,
    this.groupLabel,
    this.groupKey,
  });

  final int lineNumber;
  final String word;
  final String meaningKo;
  final String? warning;
  final String? source;
  final String? groupLabel;
  final String? groupKey;

  bool get isValid => word.isNotEmpty && meaningKo.isNotEmpty;
  bool get isSavable => isValid && warning == null;
}

class VocabularyImportResult {
  const VocabularyImportResult(this.rows);

  final List<VocabularyImportRow> rows;

  List<VocabularyImportRow> get validRows =>
      rows.where((row) => row.isValid).toList();
  List<VocabularyImportRow> get savableRows =>
      rows.where((row) => row.isSavable).toList();
  int get warningCount =>
      rows.where((row) => (row.warning ?? '').isNotEmpty).length;
}

class VocabularyPreambleCleanupResult {
  const VocabularyPreambleCleanupResult({
    required this.text,
    required this.removedLineCount,
    this.startHeader,
  });

  final String text;
  final int removedLineCount;
  final String? startHeader;

  bool get removedPreamble => removedLineCount > 0;
}

VocabularyPreambleCleanupResult trimVocabularyPreamble(String source) {
  final lines = source.split(RegExp(r'\r?\n'));
  var headerIndex = -1;
  String? startHeader;
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (_isVocabularyStartHeader(line)) {
      headerIndex = index;
      startHeader = line;
      break;
    }
  }
  if (headerIndex < 0) {
    return VocabularyPreambleCleanupResult(
      text: source,
      removedLineCount: 0,
    );
  }
  return VocabularyPreambleCleanupResult(
    text: lines.skip(headerIndex).join('\n').trim(),
    removedLineCount:
        lines.take(headerIndex).where((line) => line.trim().isNotEmpty).length,
    startHeader: startHeader,
  );
}

VocabularyImportResult parseVocabularyPaste(String source) {
  final cleanedSource = trimVocabularyPreamble(source).text;
  final rows = <VocabularyImportRow>[];
  final seen = <String>{};
  final lines = cleanedSource.split(RegExp(r'\r?\n'));
  String? currentGroupLabel;
  String? currentGroupKey;
  for (var index = 0; index < lines.length; index++) {
    var line = lines[index].trim();
    if (line.isEmpty) continue;
    if (isVocabularyGroupHeader(line)) {
      currentGroupLabel = normalizeVocabularyGroupLabel(line);
      currentGroupKey = vocabularyGroupKey(currentGroupLabel);
      continue;
    }
    line = line.replaceFirst(
      RegExp(r'^\s*(?:\d+\s*[.)]|[-•·□☐✓✔])\s*'),
      '',
    );

    String word = '';
    String meaning = '';
    final parenthetical = RegExp(
      r"^([A-Za-z][A-Za-z\s\-'/]*?)\s*\(([^)]+)\)\s*$",
    ).firstMatch(line);
    if (parenthetical != null) {
      word = parenthetical.group(1)!.trim();
      meaning = parenthetical.group(2)!.trim();
    } else {
      final koreanMeaning = RegExp(
        r"^([A-Za-z][A-Za-z\s\-'/]*?)\s+([가-힣].*)$",
      ).firstMatch(line);
      if (koreanMeaning != null) {
        word = koreanMeaning.group(1)!.trim();
        meaning = koreanMeaning.group(2)!.trim();
      } else {
        final separated =
            RegExp(r'^(.+?)(?:\t+|\s{2,}|,\s*)(.+)$').firstMatch(line);
        if (separated != null) {
          word = separated.group(1)!.trim();
          meaning = separated.group(2)!.trim();
        } else {
          final simple = RegExp(
            r"^([A-Za-z][A-Za-z\-'/]*(?:\s+[A-Za-z][A-Za-z\-'/]*)*)\s+(.+)$",
          ).firstMatch(line);
          if (simple != null) {
            word = simple.group(1)!.trim();
            meaning = simple.group(2)!.trim();
          }
        }
      }
    }

    String? warning;
    if (word.isEmpty ||
        meaning.isEmpty ||
        !RegExp(r'[A-Za-z]').hasMatch(word) ||
        !RegExp(r'[가-힣]').hasMatch(meaning)) {
      warning = '단어와 한글 뜻을 확인해 주세요.';
      word = '';
      meaning = '';
    } else {
      final key = word.toLowerCase();
      if (!seen.add(key)) warning = '중복 단어입니다.';
    }
    rows.add(
      VocabularyImportRow(
        lineNumber: index + 1,
        word: word,
        meaningKo: meaning,
        warning: warning,
        groupLabel: currentGroupLabel,
        groupKey: currentGroupKey,
      ),
    );
  }
  return VocabularyImportResult(rows);
}

bool _isVocabularyStartHeader(String line) => isVocabularyGroupHeader(line);

bool isVocabularyGroupHeader(String line) {
  if (line.isEmpty) return false;
  return RegExp(
    r'^(?:'
    r'Unit\s+\d+\b.*|'
    r'(?:Chapter|Ch\.)\s*\d+\b.*|'
    r'(?:제\s*)?\d+\s*강.*|'
    r'Lesson\s+\d+\b.*|'
    r'Day\s+\d+\b.*|'
    r'Test\s+\d+\b.*|'
    r'단어\s*목록(?:\s*\([^)]*\))?.*|'
    r'Words?\b.*|'
    r'Vocabulary\b.*|'
    r'Voca\b.*'
    r')$',
    caseSensitive: false,
  ).hasMatch(line);
}

String normalizeVocabularyGroupLabel(String line) =>
    line.trim().replaceAll(RegExp(r'\s+'), ' ');

String vocabularyGroupKey(String? label) {
  if (label == null || label.trim().isEmpty) return '';
  final normalized = label
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'^제(?=\d+\s*강$)'), '')
      .replaceAll(RegExp(r'(\d+)\s*강$'), r'lesson_$1')
      .replaceAll(RegExp(r'[^a-z0-9가-힣]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return normalized;
}
