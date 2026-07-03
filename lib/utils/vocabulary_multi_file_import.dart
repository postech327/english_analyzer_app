import 'vocabulary_import_parser.dart';

enum VocabularyFileRole {
  auto,
  paired,
  englishOnly,
  koreanOnly,
  ignored,
}

class VocabularyImportFileCandidate {
  const VocabularyImportFileCandidate({
    required this.name,
    required this.text,
    this.role = VocabularyFileRole.auto,
    this.inferredRole = VocabularyFileRole.auto,
    this.format = '',
  });

  final String name;
  final String text;
  final VocabularyFileRole role;
  final VocabularyFileRole inferredRole;
  final String format;

  VocabularyFileRole get effectiveRole =>
      role == VocabularyFileRole.auto ? inferredRole : role;

  VocabularyImportFileCandidate copyWith({VocabularyFileRole? role}) {
    return VocabularyImportFileCandidate(
      name: name,
      text: text,
      role: role ?? this.role,
      inferredRole: inferredRole,
      format: format,
    );
  }
}

VocabularyFileRole inferVocabularyFileRole(String fileName, String text) {
  final name = fileName.toLowerCase();
  if (_containsAny(name, ['단어목록', '철자의미', '영어뜻', '단어장', '목록'])) {
    return VocabularyFileRole.paired;
  }
  if (_containsAny(name, ['의미시험', '영어만', '뜻맞히기', '의미', 'word', 'english'])) {
    return VocabularyFileRole.englishOnly;
  }
  if (_containsAny(name, ['철자시험', '한글만', 'spelling', 'korean', '뜻만'])) {
    return VocabularyFileRole.koreanOnly;
  }

  final lines = _cleanLines(text).take(30).toList();
  final paired = lines
      .where((line) =>
          RegExp(r'[A-Za-z]').hasMatch(line) && RegExp(r'[가-힣]').hasMatch(line))
      .length;
  final english =
      lines.where((line) => RegExp(r'[A-Za-z]').hasMatch(line)).length;
  final korean = lines.where((line) => RegExp(r'[가-힣]').hasMatch(line)).length;
  if (paired >= 2) return VocabularyFileRole.paired;
  if (english > korean && english > 0) return VocabularyFileRole.englishOnly;
  if (korean > 0) return VocabularyFileRole.koreanOnly;
  return VocabularyFileRole.auto;
}

VocabularyImportResult analyzeVocabularyImportFiles(
  List<VocabularyImportFileCandidate> files,
) {
  final active =
      files.where((file) => file.effectiveRole != VocabularyFileRole.ignored);
  final paired =
      active.where((file) => file.effectiveRole == VocabularyFileRole.paired);
  final english = active
      .where((file) => file.effectiveRole == VocabularyFileRole.englishOnly);
  final korean = active
      .where((file) => file.effectiveRole == VocabularyFileRole.koreanOnly);

  if (paired.isNotEmpty) {
    final rows = <VocabularyImportRow>[];
    for (final file in paired) {
      final parsed = parseVocabularyPaste(file.text);
      rows.addAll([
        for (final row in parsed.rows)
          VocabularyImportRow(
            lineNumber: rows.length + 1,
            word: row.word,
            meaningKo: row.meaningKo,
            warning: row.warning,
            source: file.name,
          ),
      ]);
    }
    return _markDuplicates(rows);
  }

  final englishCandidates = <_LineCandidate>[];
  for (final file in english) {
    englishCandidates.addAll(_englishCandidates(file));
  }
  final koreanCandidates = <_LineCandidate>[];
  for (final file in korean) {
    koreanCandidates.addAll(_koreanCandidates(file));
  }
  if (englishCandidates.isEmpty && koreanCandidates.isEmpty) {
    return const VocabularyImportResult([]);
  }

  final rows = <VocabularyImportRow>[];
  final maxCount = englishCandidates.length > koreanCandidates.length
      ? englishCandidates.length
      : koreanCandidates.length;
  for (var index = 0; index < maxCount; index++) {
    final englishLine =
        index < englishCandidates.length ? englishCandidates[index] : null;
    final koreanLine =
        index < koreanCandidates.length ? koreanCandidates[index] : null;
    final warning = englishLine == null
        ? '영어 단어가 없습니다.'
        : koreanLine == null
            ? '한글 뜻이 없습니다.'
            : null;
    rows.add(
      VocabularyImportRow(
        lineNumber: index + 1,
        word: englishLine?.value ?? '',
        meaningKo: koreanLine?.value ?? '',
        warning: warning,
        source: warning == null
            ? '2파일 병합'
            : (englishLine?.fileName ?? koreanLine?.fileName),
      ),
    );
  }
  return _markDuplicates(rows);
}

List<_LineCandidate> _englishCandidates(VocabularyImportFileCandidate file) {
  final result = <_LineCandidate>[];
  for (final line in _cleanLines(file.text)) {
    if (!RegExp(r'[A-Za-z]').hasMatch(line)) continue;
    final match = RegExp(r"[A-Za-z][A-Za-z\s\-'/]*").firstMatch(line);
    final value = match?.group(0)?.trim() ?? '';
    if (value.isNotEmpty) result.add(_LineCandidate(value, file.name));
  }
  return result;
}

List<_LineCandidate> _koreanCandidates(VocabularyImportFileCandidate file) {
  final result = <_LineCandidate>[];
  for (final line in _cleanLines(file.text)) {
    final match = RegExp(r'[가-힣]').firstMatch(line);
    if (match == null) continue;
    final value = line.substring(match.start).trim();
    if (value.isNotEmpty) result.add(_LineCandidate(value, file.name));
  }
  return result;
}

Iterable<String> _cleanLines(String text) sync* {
  for (var line in text.split(RegExp(r'\r?\n'))) {
    line = line.trim().replaceFirst(
          RegExp(
            r'^\s*(?:(?:\d+\s*[.)]?)|[①②③④⑤⑥⑦⑧⑨⑩]|[-•·□☐✓✔])\s*',
          ),
          '',
        );
    if (line.isEmpty || RegExp(r'^\d+$').hasMatch(line)) continue;
    yield line;
  }
}

VocabularyImportResult _markDuplicates(List<VocabularyImportRow> rows) {
  final seen = <String>{};
  return VocabularyImportResult([
    for (final row in rows)
      if (row.word.isNotEmpty && !seen.add(row.word.toLowerCase()))
        VocabularyImportRow(
          lineNumber: row.lineNumber,
          word: row.word,
          meaningKo: row.meaningKo,
          warning: '중복 단어입니다.',
          source: row.source,
        )
      else
        row,
  ]);
}

bool _containsAny(String value, List<String> needles) =>
    needles.any(value.contains);

class _LineCandidate {
  const _LineCandidate(this.value, this.fileName);

  final String value;
  final String fileName;
}

String vocabularyFileRoleLabel(VocabularyFileRole role) => switch (role) {
      VocabularyFileRole.auto => '자동',
      VocabularyFileRole.paired => '영어+뜻',
      VocabularyFileRole.englishOnly => '영어만',
      VocabularyFileRole.koreanOnly => '한글만',
      VocabularyFileRole.ignored => '사용 안 함',
    };
