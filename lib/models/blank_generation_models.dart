typedef JsonMap = Map<String, dynamic>;

class BlankCandidate {
  const BlankCandidate({
    required this.candidateId,
    required this.sentenceId,
    required this.text,
    required this.blankType,
    required this.semanticRole,
    required this.suitabilityScore,
    required this.suitabilityLevel,
    required this.suitabilityReasons,
  });

  final String candidateId;
  final String sentenceId;
  final String text;
  final String blankType;
  final String semanticRole;
  final double suitabilityScore;
  final String suitabilityLevel;
  final List<String> suitabilityReasons;

  factory BlankCandidate.fromJson(JsonMap json) {
    final suitability = _asMap(json['suitability']);
    return BlankCandidate(
      candidateId: (json['candidate_id'] ?? '').toString(),
      sentenceId: (json['sentence_id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      blankType: (json['blank_type'] ?? '').toString(),
      semanticRole: (json['semantic_role'] ?? '').toString(),
      suitabilityScore: _asDouble(suitability['score']),
      suitabilityLevel: (suitability['level'] ?? '').toString(),
      suitabilityReasons: _asStringList(suitability['reasons']),
    );
  }
}

class BlankGenerationTarget {
  const BlankGenerationTarget({
    required this.raw,
    required this.targetId,
    required this.candidateId,
    required this.sentenceId,
    required this.text,
    required this.blankType,
    required this.semanticRole,
    required this.selectionScore,
  });

  final JsonMap raw;
  final String targetId;
  final String candidateId;
  final String sentenceId;
  final String text;
  final String blankType;
  final String semanticRole;
  final double selectionScore;

  factory BlankGenerationTarget.fromJson(JsonMap json) => BlankGenerationTarget(
    raw: JsonMap.from(json),
    targetId: (json['target_id'] ?? '').toString(),
    candidateId: (json['candidate_id'] ?? '').toString(),
    sentenceId: (json['sentence_id'] ?? '').toString(),
    text: (json['text'] ?? '').toString(),
    blankType: (json['blank_type'] ?? '').toString(),
    semanticRole: (json['semantic_role'] ?? '').toString(),
    selectionScore: _asDouble(json['selection_score']),
  );
}

class BlankCandidatesResult {
  const BlankCandidatesResult({
    required this.candidates,
    required this.selectedTarget,
    required this.totalExtracted,
    required this.eligibleCandidates,
  });

  final List<BlankCandidate> candidates;
  final BlankGenerationTarget? selectedTarget;
  final int totalExtracted;
  final int eligibleCandidates;

  factory BlankCandidatesResult.fromJson(JsonMap json) {
    final data = _asMap(json['data']);
    final target = _asMap(data['selected_target']);
    final metadata = _asMap(data['metadata']);
    return BlankCandidatesResult(
      candidates: _asMapList(
        data['candidates'],
      ).map(BlankCandidate.fromJson).toList(growable: false),
      selectedTarget: target.isEmpty
          ? null
          : BlankGenerationTarget.fromJson(target),
      totalExtracted: _asInt(metadata['total_extracted']),
      eligibleCandidates: _asInt(metadata['eligible_candidates']),
    );
  }
}

class BlankGeneratedChoice {
  const BlankGeneratedChoice({required this.choiceNo, required this.text});

  final int choiceNo;
  final String text;

  factory BlankGeneratedChoice.fromJson(JsonMap json) => BlankGeneratedChoice(
    choiceNo: _asInt(json['choice_no']),
    text: (json['text'] ?? '').toString(),
  );
}

class BlankGeneratedQuestion {
  const BlankGeneratedQuestion({
    required this.raw,
    required this.questionId,
    required this.stem,
    required this.blankedPassage,
    required this.choices,
    required this.answerPosition,
    required this.explanation,
  });

  final JsonMap raw;
  final String questionId;
  final String stem;
  final String blankedPassage;
  final List<BlankGeneratedChoice> choices;
  final int answerPosition;
  final String explanation;

  factory BlankGeneratedQuestion.fromJson(JsonMap json) {
    final data = _asMap(json['data']);
    return BlankGeneratedQuestion(
      raw: JsonMap.from(data),
      questionId: (data['question_id'] ?? '').toString(),
      stem: (_asMap(data['stem'])['ko'] ?? '').toString(),
      blankedPassage: (_asMap(data['passage'])['blanked_text'] ?? '')
          .toString(),
      choices: _asMapList(
        data['choices'],
      ).map(BlankGeneratedChoice.fromJson).toList(growable: false),
      answerPosition: _asInt(data['answer']),
      explanation: (_asMap(data['explanation'])['ko'] ?? '').toString(),
    );
  }

  String get displayAnswer => blankChoiceLabel(answerPosition);
}

class BlankSaveResult {
  const BlankSaveResult({
    required this.problemSetId,
    required this.savedQuestionCount,
  });

  final int problemSetId;
  final int savedQuestionCount;

  factory BlankSaveResult.fromJson(JsonMap json) => BlankSaveResult(
    problemSetId: _asInt(json['problem_set_id']),
    savedQuestionCount: _asInt(json['saved_question_count']),
  );
}

String blankChoiceLabel(int position) {
  if (position >= 1 && position <= 20) {
    return String.fromCharCode(0x2460 + position - 1);
  }
  return position.toString();
}

JsonMap _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

List<JsonMap> _asMapList(dynamic value) {
  if (value is! List) return const [];
  return value.map(_asMap).toList(growable: false);
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList(growable: false);
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
