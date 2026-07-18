class QuestionImportDraft {
  const QuestionImportDraft({
    required this.questionNo,
    required this.source,
    required this.questionType,
    required this.passage,
    required this.questionText,
    required this.choices,
    required this.answerIndex,
    required this.answerRaw,
    required this.explanation,
    this.specialData,
    this.answerText,
    required this.warnings,
    required this.isSpecialUnsupported,
  });

  final int questionNo;
  final String source;
  final String questionType;
  final String passage;
  final String questionText;
  final List<String> choices;
  final int? answerIndex;
  final String answerRaw;
  final String explanation;
  final Map<String, dynamic>? specialData;
  final String? answerText;
  final List<String> warnings;
  final bool isSpecialUnsupported;

  bool get isSaveable =>
      !isSpecialUnsupported &&
      questionType.trim().isNotEmpty &&
      questionText.trim().isNotEmpty &&
      ((specialData != null && specialData!.isNotEmpty) ||
          (choices.length >= 2 &&
              answerIndex != null &&
              answerIndex! >= 0 &&
              answerIndex! < choices.length));

  QuestionImportDraft copyWith({
    String? source,
    String? questionType,
    String? passage,
    String? questionText,
    List<String>? choices,
    int? answerIndex,
    bool clearAnswerIndex = false,
    String? answerRaw,
    String? explanation,
    Map<String, dynamic>? specialData,
    bool clearSpecialData = false,
    String? answerText,
    bool clearAnswerText = false,
    List<String>? warnings,
    bool? isSpecialUnsupported,
  }) {
    return QuestionImportDraft(
      questionNo: questionNo,
      source: source ?? this.source,
      questionType: questionType ?? this.questionType,
      passage: passage ?? this.passage,
      questionText: questionText ?? this.questionText,
      choices: choices ?? this.choices,
      answerIndex: clearAnswerIndex ? null : (answerIndex ?? this.answerIndex),
      answerRaw: answerRaw ?? this.answerRaw,
      explanation: explanation ?? this.explanation,
      specialData: clearSpecialData ? null : (specialData ?? this.specialData),
      answerText: clearAnswerText ? null : (answerText ?? this.answerText),
      warnings: warnings ?? this.warnings,
      isSpecialUnsupported: isSpecialUnsupported ?? this.isSpecialUnsupported,
    );
  }

  Map<String, dynamic> toRequestJson() => {
        'question_no': questionNo,
        'question_type': questionType,
        'passage': passage,
        'question_text': questionText,
        'choices': choices,
        'answer_index': answerIndex,
        'answer_raw': answerRaw,
        'explanation': explanation,
        if (specialData != null && specialData!.isNotEmpty)
          'special_data': specialData,
        if (answerText != null && answerText!.trim().isNotEmpty)
          'answer_text': answerText,
      };
}
