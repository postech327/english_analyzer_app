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

  bool get isSaveable => saveabilityReason == 'ok';

  String get saveabilityReason {
    final normalizedType = questionType.trim().toLowerCase();
    if (isSpecialUnsupported || normalizedType.isEmpty) {
      return isSpecialUnsupported ? 'unsupported' : 'missing_type';
    }
    if (normalizedType == 'irrelevant' ||
        normalizedType == 'unrelated_sentence') {
      return 'unsupported';
    }
    if (questionText.trim().isEmpty) {
      return 'missing_question_text';
    }

    final special = specialData;
    if (normalizedType == 'insertion') {
      if (special == null || special.isEmpty) return 'missing_special_data';
      final kind = special['kind']?.toString().trim().toLowerCase();
      if (kind != 'insertion') return 'not_insertion_kind';
      final mode = (special['mode'] ?? '').toString().trim().toLowerCase();
      final insertSentence =
          (special['insert_sentence'] ?? '').toString().trim();
      final passageWithPositions =
          (special['passage_with_positions'] ?? '').toString().trim();
      final positions = special['positions'];
      final answerPosition = special['answer_position'];
      final positionCount = positions is List ? positions.length : 0;
      if (mode != 'single') return 'not_single_mode';
      if (insertSentence.isEmpty) return 'missing_insert_sentence';
      if (passageWithPositions.isEmpty) {
        return 'missing_passage_with_positions';
      }
      if (positionCount == 0) return 'positions_empty';
      if (positionCount < 2) return 'not_enough_positions';
      if (answerPosition == null) return 'missing_answer_position';
      if ((answerText ?? '').trim().isEmpty) return 'missing_answer_text';
      if (warnings.isNotEmpty) return 'has_warnings';
      return 'ok';
    }

    if (normalizedType == 'order' && (special == null || special.isEmpty)) {
      return 'missing_special_data';
    }

    if (special != null && special.isNotEmpty) {
      final kind = special['kind']?.toString().trim().toLowerCase();
      if (kind == 'order' || normalizedType == 'order') {
        final blocks = special['blocks'];
        final answerOrder = special['answer_order'];
        final blockCount = blocks is Map ? blocks.length : 0;
        final answerCount = answerOrder is List ? answerOrder.length : 0;
        if (normalizedType != 'order') return 'not_order_type';
        if ((special['fixed_start'] ?? '').toString().trim().isEmpty) {
          return 'missing_fixed_start';
        }
        if (blockCount < 3) return 'not_enough_order_blocks';
        if (answerCount != blockCount) return 'answer_block_count_mismatch';
        if ((answerText ?? '').trim().isEmpty) return 'missing_answer_text';
        return 'ok';
      }
      return 'ok';
    }

    if (choices.length < 2) return 'not_enough_choices';
    if (answerIndex == null) return 'missing_answer_index';
    if (answerIndex! < 0 || answerIndex! >= choices.length) {
      return 'answer_index_out_of_range';
    }
    return 'ok';
  }

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
