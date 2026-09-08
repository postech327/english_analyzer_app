typedef JsonMap = Map<String, dynamic>;

class OrderBlock {
  const OrderBlock({
    required this.blockId,
    required this.sentenceIds,
    required this.text,
    this.displayLabel = '',
  });

  final String blockId;
  final List<String> sentenceIds;
  final String text;
  final String displayLabel;

  factory OrderBlock.fromCandidateJson(JsonMap json) => OrderBlock(
    blockId: (json['block_id'] ?? '').toString(),
    sentenceIds: _asStringList(json['sentence_ids']),
    text: (json['text_preview'] ?? '').toString(),
  );

  factory OrderBlock.fromGeneratedJson(JsonMap json) => OrderBlock(
    blockId: (json['block_id'] ?? '').toString(),
    sentenceIds: _asStringList(json['sentence_ids']),
    text: (json['text'] ?? '').toString(),
    displayLabel: (json['display_label'] ?? '').toString(),
  );
}

class OrderCandidate {
  const OrderCandidate({
    required this.raw,
    required this.candidateId,
    required this.fixedIntroSentenceIds,
    required this.blocks,
    required this.correctOrder,
    required this.suitabilityScore,
    required this.suitabilityLevel,
    required this.suitabilityReasons,
    required this.evidenceSummaries,
  });

  final JsonMap raw;
  final String candidateId;
  final List<String> fixedIntroSentenceIds;
  final List<OrderBlock> blocks;
  final List<String> correctOrder;
  final double suitabilityScore;
  final String suitabilityLevel;
  final List<String> suitabilityReasons;
  final List<String> evidenceSummaries;

  factory OrderCandidate.fromJson(JsonMap json) {
    final suitability = _asMap(json['suitability']);
    return OrderCandidate(
      raw: JsonMap.from(json),
      candidateId: (json['candidate_id'] ?? '').toString(),
      fixedIntroSentenceIds: _asStringList(json['fixed_intro_sentence_ids']),
      blocks: _asMapList(
        json['blocks'],
      ).map(OrderBlock.fromCandidateJson).toList(growable: false),
      correctOrder: _asStringList(json['correct_order']),
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

class OrderGenerationTarget {
  const OrderGenerationTarget({required this.raw, required this.candidateId});

  final JsonMap raw;
  final String candidateId;

  factory OrderGenerationTarget.fromJson(JsonMap json) => OrderGenerationTarget(
    raw: JsonMap.from(json),
    candidateId: (json['candidate_id'] ?? '').toString(),
  );
}

class OrderCandidatesResult {
  const OrderCandidatesResult({
    required this.candidates,
    required this.selectedTarget,
    required this.reasonCode,
  });

  final List<OrderCandidate> candidates;
  final OrderGenerationTarget? selectedTarget;
  final String? reasonCode;

  factory OrderCandidatesResult.fromJson(JsonMap json) {
    final data = _asMap(json['data']);
    final target = _asMap(data['selected_target']);
    final reason = (_asMap(data['metadata'])['reason_code'] ?? '')
        .toString()
        .trim();
    return OrderCandidatesResult(
      candidates: _asMapList(
        data['candidates'],
      ).map(OrderCandidate.fromJson).toList(growable: false),
      selectedTarget: target.isEmpty
          ? null
          : OrderGenerationTarget.fromJson(target),
      reasonCode: reason.isEmpty ? null : reason,
    );
  }

  OrderGenerationTarget? targetFor(OrderCandidate candidate) {
    final target = selectedTarget;
    return target?.candidateId == candidate.candidateId ? target : null;
  }
}

class OrderPreviewBlock {
  const OrderPreviewBlock({
    required this.label,
    required this.blockId,
    required this.text,
  });

  final String label;
  final String blockId;
  final String text;
}

class OrderGeneratedQuestion {
  const OrderGeneratedQuestion({
    required this.raw,
    required this.questionId,
    required this.stem,
    required this.fixedIntro,
    required this.blocks,
    required this.canonicalCorrectOrder,
    required this.explanation,
  });

  final JsonMap raw;
  final String questionId;
  final String stem;
  final String fixedIntro;
  final List<OrderBlock> blocks;
  final List<String> canonicalCorrectOrder;
  final String explanation;

  factory OrderGeneratedQuestion.fromJson(JsonMap json) {
    final data = _asMap(json['data']);
    final validation = _asMap(data['validation']);
    final validOrders = validation['valid_orders'];
    final canonical = validOrders is List && validOrders.length == 1
        ? _asStringList(validOrders.first)
        : const <String>[];
    return OrderGeneratedQuestion(
      raw: JsonMap.from(data),
      questionId: (data['question_id'] ?? '').toString(),
      stem: (_asMap(data['stem'])['ko'] ?? '').toString(),
      fixedIntro: (_asMap(data['fixed_intro'])['text'] ?? '').toString(),
      blocks: _asMapList(
        data['blocks'],
      ).map(OrderBlock.fromGeneratedJson).toList(growable: false),
      canonicalCorrectOrder: canonical,
      explanation: (_asMap(data['explanation'])['ko'] ?? '').toString(),
    );
  }

  // Presentation only. Persistence receives [raw] unchanged and the Backend
  // adapter remains the sole authority that constructs special_data.
  static const _productLabelByCanonicalId = <String, String>{
    'B1': 'B',
    'B2': 'C',
    'B3': 'D',
  };

  List<OrderPreviewBlock> get productBlocks {
    final byId = {for (final block in blocks) block.blockId: block};
    return _productLabelByCanonicalId.entries
        .where((entry) => byId.containsKey(entry.key))
        .map(
          (entry) => OrderPreviewBlock(
            label: entry.value,
            blockId: entry.key,
            text: byId[entry.key]!.text,
          ),
        )
        .toList(growable: false);
  }

  String get productAnswer => canonicalCorrectOrder
      .map((blockId) => _productLabelByCanonicalId[blockId] ?? blockId)
      .join('-');

  String get productAnswerWithArrows => canonicalCorrectOrder
      .map((blockId) => _productLabelByCanonicalId[blockId] ?? blockId)
      .join(' → ');
}

class OrderSaveResult {
  const OrderSaveResult({
    required this.problemSetId,
    required this.savedQuestionCount,
  });

  final int problemSetId;
  final int savedQuestionCount;

  factory OrderSaveResult.fromJson(JsonMap json) => OrderSaveResult(
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

String _evidenceSummary(JsonMap evidence) {
  final type = (evidence['evidence_type'] ?? '').toString();
  final cue = (evidence['cue'] ?? '').toString();
  final relation = (evidence['relation_type'] ?? '').toString();
  final transition = [evidence['before'], evidence['after']]
      .map((value) => value?.toString() ?? '')
      .where((value) => value.isNotEmpty)
      .join(' → ');
  return [
    type,
    transition,
    if (cue.isNotEmpty) cue else relation,
  ].where((value) => value.isNotEmpty).join(' · ');
}
