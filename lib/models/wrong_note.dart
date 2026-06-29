class WrongNote {
  final List<WrongNoteItem> wrongNotes;

  WrongNote({
    required this.wrongNotes,
  });

  factory WrongNote.fromJson(Map<String, dynamic> json) {
    return WrongNote(
      wrongNotes: (json['wrong_notes'] as List<dynamic>? ?? [])
          .map((e) => WrongNoteItem.fromJson(e))
          .toList(),
    );
  }
}

class WrongNoteItem {
  final int questionId;
  final String questionType;
  final String questionText;
  final List<String> options;
  final int selectedIndex;
  final int correctIndex;
  final String? gptExplanation;

  WrongNoteItem({
    required this.questionId,
    required this.questionType,
    required this.questionText,
    required this.options,
    required this.selectedIndex,
    required this.correctIndex,
    this.gptExplanation,
  });

  factory WrongNoteItem.fromJson(Map<String, dynamic> json) {
    return WrongNoteItem(
      questionId: json['question_id'],
      questionType: json['question_type'],
      questionText: json['question_text'],
      options: List<String>.from(json['options']),
      selectedIndex: json['selected_index'],
      correctIndex: json['correct_index'],
      gptExplanation: json['gpt_explanation'],
    );
  }
}
