import 'question_import_draft.dart';

class ProblemSetImportDraft {
  const ProblemSetImportDraft({
    required this.name,
    required this.source,
    required this.textbookFolderName,
    required this.unitFolderName,
    required this.passage,
    required this.questions,
    required this.warnings,
  });

  final String name;
  final String source;
  final String textbookFolderName;
  final String unitFolderName;
  final String passage;
  final List<QuestionImportDraft> questions;
  final List<String> warnings;

  bool get isSaveable => questions.any((question) => question.isSaveable);

  ProblemSetImportDraft copyWith({
    String? name,
    String? source,
    String? textbookFolderName,
    String? unitFolderName,
    String? passage,
    List<QuestionImportDraft>? questions,
    List<String>? warnings,
  }) {
    return ProblemSetImportDraft(
      name: name ?? this.name,
      source: source ?? this.source,
      textbookFolderName: textbookFolderName ?? this.textbookFolderName,
      unitFolderName: unitFolderName ?? this.unitFolderName,
      passage: passage ?? this.passage,
      questions: questions ?? this.questions,
      warnings: warnings ?? this.warnings,
    );
  }
}
