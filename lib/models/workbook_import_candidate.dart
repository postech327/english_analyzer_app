class WorkbookImportCandidate {
  const WorkbookImportCandidate({
    required this.localId,
    required this.detectedType,
    required this.questionType,
    required this.typeLabel,
    required this.title,
    required this.prompt,
    required this.answer,
    required this.rawText,
    required this.summary,
    this.subtype,
    this.passageText,
    this.choices,
    this.explanation,
    this.errors = const [],
    this.warnings = const [],
    this.sourceFileName,
  });

  final String localId;
  final String detectedType;
  final String questionType;
  final String typeLabel;
  final String title;
  final String prompt;
  final String? subtype;
  final String? passageText;
  final List<String>? choices;
  final Map<String, dynamic> answer;
  final String? explanation;
  final String rawText;
  final String summary;
  final List<String> errors;
  final List<String> warnings;
  final String? sourceFileName;

  bool get isUnknown => questionType == 'unknown';
  bool get hasBlockingErrors => errors.isNotEmpty;
  bool get isSelectedByDefault => !isUnknown && !hasBlockingErrors;

  WorkbookImportCandidate copyWith({
    String? localId,
    String? sourceFileName,
  }) {
    return WorkbookImportCandidate(
      localId: localId ?? this.localId,
      detectedType: detectedType,
      questionType: questionType,
      typeLabel: typeLabel,
      title: title,
      prompt: prompt,
      answer: answer,
      rawText: rawText,
      summary: summary,
      subtype: subtype,
      passageText: passageText,
      choices: choices,
      explanation: explanation,
      errors: errors,
      warnings: warnings,
      sourceFileName: sourceFileName ?? this.sourceFileName,
    );
  }
}
