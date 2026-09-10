typedef JsonMap = Map<String, dynamic>;

class InsertionSentence {
  const InsertionSentence({
    required this.sentenceId,
    required this.index,
    required this.text,
  });

  final String sentenceId;
  final int index;
  final String text;

  factory InsertionSentence.fromJson(JsonMap json) => InsertionSentence(
        sentenceId: (json['sentence_id'] ?? '').toString(),
        index: _asInt(json['index']),
        text: (json['text'] ?? '').toString(),
      );
}

class InsertionCandidate {
  const InsertionCandidate({
    required this.raw,
    required this.candidateId,
    required this.insertedSentence,
    required this.correctGapId,
    required this.suitabilityScore,
    required this.suitabilityLevel,
    required this.suitabilityReasons,
    required this.evidenceSummaries,
  });

  final JsonMap raw;
  final String candidateId;
  final InsertionSentence insertedSentence;
  final String correctGapId;
  final double suitabilityScore;
  final String suitabilityLevel;
  final List<String> suitabilityReasons;
  final List<String> evidenceSummaries;

  factory InsertionCandidate.fromJson(JsonMap json) {
    final suitability = _asMap(json['suitability']);
    return InsertionCandidate(
      raw: JsonMap.from(json),
      candidateId: (json['candidate_id'] ?? '').toString(),
      insertedSentence: InsertionSentence.fromJson(
        _asMap(json['inserted_sentence']),
      ),
      correctGapId: (json['correct_gap_id'] ?? '').toString(),
      suitabilityScore: _asDouble(suitability['score']),
      suitabilityLevel: (suitability['level'] ?? '').toString(),
      suitabilityReasons: _asStringList(suitability['reasons']),
      evidenceSummaries: _collectEvidence(json['gap_scores']),
    );
  }
}

class InsertionGenerationTarget {
  const InsertionGenerationTarget({
    required this.raw,
    required this.candidateId,
    required this.evidenceSummaries,
  });

  final JsonMap raw;
  final String candidateId;
  final List<String> evidenceSummaries;

  factory InsertionGenerationTarget.fromJson(JsonMap json) =>
      InsertionGenerationTarget(
        raw: JsonMap.from(json),
        candidateId: (json['candidate_id'] ?? '').toString(),
        evidenceSummaries: _asMapList(json['evidence_summary'])
            .map(_evidenceSummary)
            .where((value) => value.isNotEmpty)
            .toList(growable: false),
      );
}

class InsertionCandidatesResult {
  const InsertionCandidatesResult({
    required this.candidates,
    required this.selectedTarget,
    required this.reasonCode,
  });

  final List<InsertionCandidate> candidates;
  final InsertionGenerationTarget? selectedTarget;
  final String? reasonCode;

  factory InsertionCandidatesResult.fromJson(JsonMap json) {
    final data = _asMap(json['data']);
    final target = _asMap(data['selected_target']);
    final reason =
        (_asMap(data['metadata'])['reason_code'] ?? '').toString().trim();
    return InsertionCandidatesResult(
      candidates: _asMapList(
        data['candidates'],
      ).map(InsertionCandidate.fromJson).toList(growable: false),
      selectedTarget:
          target.isEmpty ? null : InsertionGenerationTarget.fromJson(target),
      reasonCode: reason.isEmpty ? null : reason,
    );
  }

  InsertionGenerationTarget? targetFor(InsertionCandidate candidate) {
    final target = selectedTarget;
    return target?.candidateId == candidate.candidateId ? target : null;
  }
}

class InsertionDisplaySegment {
  const InsertionDisplaySegment({
    required this.sentenceId,
    required this.text,
    required this.markerBefore,
  });

  final String sentenceId;
  final String text;
  final String markerBefore;

  factory InsertionDisplaySegment.fromJson(JsonMap json) =>
      InsertionDisplaySegment(
        sentenceId: (json['sentence_id'] ?? '').toString(),
        text: (json['text'] ?? '').toString(),
        markerBefore: _displayMarker(json['marker_before']),
      );
}

class InsertionGeneratedQuestion {
  const InsertionGeneratedQuestion({
    required this.raw,
    required this.questionId,
    required this.stem,
    required this.insertedSentence,
    required this.segments,
    required this.trailingMarker,
    required this.answer,
    required this.explanation,
  });

  final JsonMap raw;
  final String questionId;
  final String stem;
  final String insertedSentence;
  final List<InsertionDisplaySegment> segments;
  final String trailingMarker;
  final int answer;
  final String explanation;

  factory InsertionGeneratedQuestion.fromJson(JsonMap json) {
    final data = _asMap(json['data']);
    final displayPassage = _asMap(data['display_passage']);
    return InsertionGeneratedQuestion(
      raw: JsonMap.from(data),
      questionId: (data['question_id'] ?? '').toString(),
      stem: (_asMap(data['stem'])['ko'] ?? '').toString(),
      insertedSentence:
          (_asMap(data['inserted_sentence'])['text'] ?? '').toString(),
      segments: _asMapList(
        displayPassage['segments'],
      ).map(InsertionDisplaySegment.fromJson).toList(growable: false),
      trailingMarker: _displayMarker(displayPassage['trailing_marker']),
      answer: _asInt(data['answer']),
      explanation: (_asMap(data['explanation'])['ko'] ?? '').toString(),
    );
  }

  // Presentation only. The Backend-generated [raw] object is persisted
  // unchanged; Flutter does not reconstruct answer_position or special_data.
  String get productPassage {
    final parts = <String>[];
    for (final segment in segments) {
      if (segment.markerBefore.isNotEmpty) parts.add(segment.markerBefore);
      if (segment.text.isNotEmpty) parts.add(segment.text);
    }
    if (trailingMarker.isNotEmpty) parts.add(trailingMarker);
    return parts.join(' ');
  }
}

class InsertionSaveResult {
  const InsertionSaveResult({
    required this.problemSetId,
    required this.savedQuestionCount,
  });

  final int problemSetId;
  final int savedQuestionCount;

  factory InsertionSaveResult.fromJson(JsonMap json) => InsertionSaveResult(
        problemSetId: _asInt(json['problem_set_id']),
        savedQuestionCount: _asInt(json['saved_question_count']),
      );
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

String _displayMarker(dynamic value) {
  final position = value is num ? value.toInt() : int.tryParse('$value');
  if (position != null && position >= 1 && position <= 20) {
    return String.fromCharCode(0x2460 + position - 1);
  }
  final marker = value?.toString() ?? '';
  return RegExp(r'^[①-⑳]$').hasMatch(marker) ? marker : '';
}

List<String> _collectEvidence(dynamic gapScores) {
  final summaries = <String>[];
  for (final score in _asMapList(gapScores)) {
    final evidence = score['evidence'];
    if (evidence is List) {
      summaries.addAll(
        evidence
            .map(_asMap)
            .map(_evidenceSummary)
            .where((value) => value.isNotEmpty),
      );
    }
    final direct = _evidenceSummary(score);
    if (direct.isNotEmpty) summaries.add(direct);
  }
  return summaries.toSet().toList(growable: false);
}

String _evidenceSummary(JsonMap evidence) {
  final type = (evidence['evidence_type'] ?? '').toString();
  final cue = (evidence['cue'] ?? '').toString();
  final relation = (evidence['relation_type'] ?? '').toString();
  final sentenceIds = _asStringList(evidence['sentence_ids']).join(' → ');
  return [
    type,
    sentenceIds,
    if (cue.isNotEmpty) cue else relation,
  ].where((value) => value.isNotEmpty).join(' · ');
}
