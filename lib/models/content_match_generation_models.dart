typedef JsonMap = Map<String, dynamic>;

class ContentMatchClaim {
  const ContentMatchClaim({
    required this.claimId,
    required this.claimType,
    required this.meaning,
    required this.suitabilityScore,
    required this.suitabilityLevel,
    required this.suitabilityReasons,
    required this.evidenceSummaries,
  });

  final String claimId;
  final String claimType;
  final String meaning;
  final double suitabilityScore;
  final String suitabilityLevel;
  final List<String> suitabilityReasons;
  final List<String> evidenceSummaries;

  factory ContentMatchClaim.fromJson(JsonMap json) {
    final suitability = _asMap(json['suitability']);
    final localized = _asMap(json['canonical_meaning']);
    final ko = (localized['ko'] ?? '').toString().trim();
    final en = (localized['en'] ?? '').toString().trim();
    return ContentMatchClaim(
      claimId: (json['claim_id'] ?? '').toString(),
      claimType: (json['claim_type'] ?? '').toString(),
      meaning: ko.isNotEmpty ? ko : en,
      suitabilityScore: _asDouble(suitability['score']),
      suitabilityLevel: (suitability['level'] ?? '').toString(),
      suitabilityReasons: _asStringList(suitability['reasons']),
      evidenceSummaries: _asMapList(json['evidence'])
          .map(_evidenceSummary)
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class ContentMatchGenerationTarget {
  const ContentMatchGenerationTarget({
    required this.raw,
    required this.targetId,
    required this.questionMode,
    required this.targetAnswerMode,
    required this.claims,
    required this.selectionScore,
  });

  final JsonMap raw;
  final String targetId;
  final String questionMode;
  final String targetAnswerMode;
  final List<ContentMatchClaim> claims;
  final double selectionScore;

  factory ContentMatchGenerationTarget.fromJson(JsonMap json) =>
      ContentMatchGenerationTarget(
        raw: JsonMap.from(json),
        targetId: (json['target_id'] ?? '').toString(),
        questionMode: (json['question_mode'] ?? '').toString(),
        targetAnswerMode: (json['target_answer_mode'] ?? '').toString(),
        claims: _asMapList(
          json['claims'],
        ).map(ContentMatchClaim.fromJson).toList(growable: false),
        selectionScore: _asDouble(json['selection_score']),
      );
}

class ContentMatchCandidatesResult {
  const ContentMatchCandidatesResult({
    required this.claims,
    required this.selectedTarget,
    required this.totalClaims,
    required this.eligibleClaims,
  });

  final List<ContentMatchClaim> claims;
  final ContentMatchGenerationTarget? selectedTarget;
  final int totalClaims;
  final int eligibleClaims;

  factory ContentMatchCandidatesResult.fromJson(JsonMap json) {
    final data = _asMap(json['data']);
    final target = _asMap(data['selected_target']);
    final metadata = _asMap(data['metadata']);
    return ContentMatchCandidatesResult(
      claims: _asMapList(
        data['claims'],
      ).map(ContentMatchClaim.fromJson).toList(growable: false),
      selectedTarget: target.isEmpty
          ? null
          : ContentMatchGenerationTarget.fromJson(target),
      totalClaims: _asInt(metadata['total_claims']),
      eligibleClaims: _asInt(metadata['eligible_claims']),
    );
  }
}

class ContentMatchGeneratedChoice {
  const ContentMatchGeneratedChoice({
    required this.choiceId,
    required this.choiceNo,
    required this.text,
  });

  final String choiceId;
  final int choiceNo;
  final String text;

  factory ContentMatchGeneratedChoice.fromJson(JsonMap json) =>
      ContentMatchGeneratedChoice(
        choiceId: (json['choice_id'] ?? '').toString(),
        choiceNo: _asInt(json['choice_no']),
        text: (json['text'] ?? '').toString(),
      );
}

class ContentMatchGeneratedQuestion {
  const ContentMatchGeneratedQuestion({
    required this.raw,
    required this.questionId,
    required this.questionMode,
    required this.stem,
    required this.choices,
    required this.answerPositions,
    required this.explanation,
  });

  final JsonMap raw;
  final String questionId;
  final String questionMode;
  final String stem;
  final List<ContentMatchGeneratedChoice> choices;
  final List<int> answerPositions;
  final String explanation;

  factory ContentMatchGeneratedQuestion.fromJson(JsonMap json) {
    final data = _asMap(json['data']);
    return ContentMatchGeneratedQuestion(
      raw: JsonMap.from(data),
      questionId: (data['question_id'] ?? '').toString(),
      questionMode: (data['question_mode'] ?? '').toString(),
      stem: (_asMap(data['stem'])['ko'] ?? '').toString(),
      choices: _asMapList(
        data['choices'],
      ).map(ContentMatchGeneratedChoice.fromJson).toList(growable: false),
      answerPositions: _asIntList(data['answer']),
      explanation: (_asMap(data['explanation'])['ko'] ?? '').toString(),
    );
  }

  String get displayAnswer =>
      answerPositions.map(contentMatchChoiceLabel).join(', ');
}

class ContentMatchSaveResult {
  const ContentMatchSaveResult({
    required this.problemSetId,
    required this.savedQuestionCount,
  });

  final int problemSetId;
  final int savedQuestionCount;

  factory ContentMatchSaveResult.fromJson(JsonMap json) =>
      ContentMatchSaveResult(
        problemSetId: _asInt(json['problem_set_id']),
        savedQuestionCount: _asInt(json['saved_question_count']),
      );
}

String contentMatchChoiceLabel(int position) {
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

List<int> _asIntList(dynamic value) {
  if (value is! List) return const [];
  return value.map(_asInt).where((item) => item > 0).toList(growable: false);
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

String _evidenceSummary(JsonMap evidence) {
  final type = (evidence['type'] ?? '').toString();
  final sentenceIds = _asStringList(evidence['sentence_ids']).join(' · ');
  final field = (evidence['semantic_field'] ?? '').toString();
  final relation = (evidence['relation_id'] ?? '').toString();
  return [
    type,
    sentenceIds,
    if (field.isNotEmpty) field else relation,
  ].where((item) => item.isNotEmpty).join(' · ');
}
