typedef JsonMap = Map<String, dynamic>;

class CorrectionCandidate {
  const CorrectionCandidate({
    required this.raw,
    required this.candidateId,
    required this.targetSentenceId,
    required this.targetSentenceIndex,
    required this.originalText,
    required this.replacementText,
    required this.corruptionFamily,
    required this.candidateScore,
    required this.reason,
    required this.difficultyLabel,
  });

  final JsonMap raw;
  final String candidateId;
  final String targetSentenceId;
  final int targetSentenceIndex;
  final String originalText;
  final String replacementText;
  final String corruptionFamily;
  final double candidateScore;
  final String reason;
  final String difficultyLabel;

  factory CorrectionCandidate.fromJson(JsonMap json) {
    return CorrectionCandidate(
      raw: JsonMap.from(json),
      candidateId: (json['candidate_id'] ?? '').toString(),
      targetSentenceId: (json['target_sentence_id'] ?? '').toString(),
      targetSentenceIndex: _asInt(json['target_sentence_index']),
      originalText: (json['original_text'] ?? '').toString(),
      replacementText: (json['replacement_text'] ?? '').toString(),
      corruptionFamily: (json['corruption_family'] ?? '').toString(),
      candidateScore: _asDouble(json['candidate_score']),
      reason: (json['semantic_invalidity_reason'] ?? '').toString(),
      difficultyLabel: (json['difficulty_label'] ?? '').toString(),
    );
  }
}

class CorrectionCandidatesResult {
  const CorrectionCandidatesResult({
    required this.candidates,
    required this.candidateCount,
  });

  final List<CorrectionCandidate> candidates;
  final int candidateCount;

  factory CorrectionCandidatesResult.fromJson(JsonMap json) {
    final data = _asMap(json['data']);
    final candidates = _asMapList(
      data['candidates'],
    ).map(CorrectionCandidate.fromJson).toList(growable: false);
    return CorrectionCandidatesResult(
      candidates: candidates,
      candidateCount: _asInt(data['candidate_count']),
    );
  }
}

class CorrectionMarker {
  const CorrectionMarker({
    required this.position,
    required this.marker,
    required this.displayText,
    required this.originalText,
    required this.isCorrupted,
  });

  final int position;
  final String marker;
  final String displayText;
  final String originalText;
  final bool isCorrupted;

  factory CorrectionMarker.fromJson(JsonMap json) {
    return CorrectionMarker(
      position: _asInt(json['marker_position']),
      marker: (json['marker'] ?? '').toString(),
      displayText: (json['display_text'] ?? '').toString(),
      originalText: (json['original_text'] ?? '').toString(),
      isCorrupted: json['is_corrupted'] == true,
    );
  }
}

class CorrectionGeneratedQuestion {
  const CorrectionGeneratedQuestion({
    required this.raw,
    required this.questionId,
    required this.stem,
    required this.corruptedPassage,
    required this.markers,
    required this.answer,
    required this.correctExpression,
    required this.explanation,
  });

  final JsonMap raw;
  final String questionId;
  final String stem;
  final String corruptedPassage;
  final List<CorrectionMarker> markers;
  final int answer;
  final String correctExpression;
  final String explanation;

  factory CorrectionGeneratedQuestion.fromJson(JsonMap json) {
    final data = _asMap(json['data']);
    final corruption = _asMap(data['corruption']);
    return CorrectionGeneratedQuestion(
      raw: JsonMap.from(data),
      questionId: (data['question_id'] ?? '').toString(),
      stem: (_asMap(data['stem'])['ko'] ?? '').toString(),
      corruptedPassage: (data['corrupted_passage'] ?? '').toString(),
      markers: _asMapList(
        data['markers'],
      ).map(CorrectionMarker.fromJson).toList(growable: false),
      answer: _asInt(data['answer']),
      correctExpression: (corruption['original_text'] ?? '').toString(),
      explanation: (_asMap(data['explanation'])['ko'] ??
              corruption['explanation_ko'] ??
              '')
          .toString(),
    );
  }

  JsonMap get previewSpecialData => {
        'kind': 'correction_multi',
        'interaction_type': 'correction_multi',
        'positions': markers.map((item) => item.position).toList(),
        'position_labels': markers.map((item) => item.marker).toList(),
        'position_texts': {
          for (final item in markers) '${item.position}': item.displayText,
        },
        'max_answers': 1,
      };
}

class CorrectionSaveResult {
  const CorrectionSaveResult({
    required this.problemSetId,
    required this.savedQuestionCount,
  });

  final int problemSetId;
  final int savedQuestionCount;

  factory CorrectionSaveResult.fromJson(JsonMap json) {
    return CorrectionSaveResult(
      problemSetId: _asInt(json['problem_set_id']),
      savedQuestionCount: _asInt(json['saved_question_count']),
    );
  }
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

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
