class VocabularySet {
  const VocabularySet({
    required this.id,
    required this.title,
    required this.status,
    required this.itemCount,
    this.description,
    this.sourceType,
    this.sourceLabel,
    this.gradeLabel,
    this.unitLabel,
    this.items = const [],
  });

  final int id;
  final String title;
  final String status;
  final int itemCount;
  final String? description;
  final String? sourceType;
  final String? sourceLabel;
  final String? gradeLabel;
  final String? unitLabel;
  final List<VocabularyItem> items;

  factory VocabularySet.fromJson(Map<String, dynamic> json) {
    final items = VocabularyItem.listFromJson(json['items']);
    return VocabularySet(
      id: _asInt(json['set_id'] ?? json['id']),
      title: _asString(json['title']),
      status: _asString(json['status'], fallback: 'draft'),
      itemCount: _asInt(json['item_count'], fallback: items.length),
      description: _nullableString(json['description']),
      sourceType: _nullableString(json['source_type']),
      sourceLabel: _nullableString(json['source_label']),
      gradeLabel: _nullableString(json['grade_label']),
      unitLabel: _nullableString(json['unit_label']),
      items: items,
    );
  }

  static List<VocabularySet> listFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => VocabularySet.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class VocabularyItem {
  const VocabularyItem({
    required this.id,
    required this.word,
    required this.meaningKo,
    this.groupLabel,
    this.groupKey,
    this.exampleSentence,
    this.synonym,
    this.antonym,
    this.note,
    this.orderIndex = 0,
  });

  final int id;
  final String word;
  final String meaningKo;
  final String? groupLabel;
  final String? groupKey;
  final String? exampleSentence;
  final String? synonym;
  final String? antonym;
  final String? note;
  final int orderIndex;

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: _asInt(json['item_id'] ?? json['id']),
      word: _asString(json['word']),
      meaningKo: _asString(json['meaning_ko']),
      groupLabel: _nullableString(json['group_label']),
      groupKey: _nullableString(json['group_key']),
      exampleSentence: _nullableString(json['example_sentence']),
      synonym: _nullableString(json['synonym']),
      antonym: _nullableString(json['antonym']),
      note: _nullableString(json['note']),
      orderIndex: _asInt(json['order_index']),
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'word': word,
        'meaning_ko': meaningKo,
        if ((groupLabel ?? '').isNotEmpty) 'group_label': groupLabel,
        if ((groupKey ?? '').isNotEmpty) 'group_key': groupKey,
        if ((exampleSentence ?? '').isNotEmpty)
          'example_sentence': exampleSentence,
        if ((synonym ?? '').isNotEmpty) 'synonym': synonym,
        if ((antonym ?? '').isNotEmpty) 'antonym': antonym,
        if ((note ?? '').isNotEmpty) 'note': note,
      };

  static List<VocabularyItem> listFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => VocabularyItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class VocabularyAttempt {
  const VocabularyAttempt({
    required this.id,
    required this.setId,
    required this.score,
    required this.totalCount,
    required this.correctCount,
    required this.results,
    this.mode = 'meaning_quiz',
    this.rangeLabel,
    this.rangeType,
    this.createdAt,
  });

  final int id;
  final int setId;
  final double score;
  final int totalCount;
  final int correctCount;
  final List<VocabularyAttemptResult> results;
  final String mode;
  final String? rangeLabel;
  final String? rangeType;
  final String? createdAt;
  int get wrongCount => totalCount - correctCount;

  factory VocabularyAttempt.fromJson(Map<String, dynamic> json) {
    return VocabularyAttempt(
      id: _asInt(json['attempt_id'] ?? json['id']),
      setId: _asInt(json['set_id']),
      score: _asDouble(json['score']),
      totalCount: _asInt(json['total_count']),
      correctCount: _asInt(json['correct_count']),
      results: VocabularyAttemptResult.listFromJson(json['results']),
      mode: _asString(json['mode'], fallback: 'meaning_quiz'),
      rangeLabel: _nullableString(json['range_label']),
      rangeType: _nullableString(json['range_type']),
      createdAt: _nullableString(json['created_at']),
    );
  }

  static List<VocabularyAttempt> listFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => VocabularyAttempt.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}

class VocabularyAttemptResult {
  const VocabularyAttemptResult({
    required this.itemId,
    required this.word,
    required this.studentAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });

  final int itemId;
  final String word;
  final String studentAnswer;
  final String correctAnswer;
  final bool isCorrect;

  factory VocabularyAttemptResult.fromJson(Map<String, dynamic> json) {
    return VocabularyAttemptResult(
      itemId: _asInt(json['item_id']),
      word: _asString(json['word']),
      studentAnswer: _asString(json['student_answer']),
      correctAnswer: _asString(json['correct_answer']),
      isCorrect: json['is_correct'] == true,
    );
  }

  static List<VocabularyAttemptResult> listFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) =>
              VocabularyAttemptResult.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}

class VocabularyStudentResultSummary {
  const VocabularyStudentResultSummary({
    required this.studentId,
    required this.studentName,
    required this.attemptCount,
    required this.bestScore,
    required this.latestScore,
    required this.latestCorrectCount,
    required this.latestTotalCount,
    required this.wrongCount,
    this.latestAttemptAt,
  });

  final int studentId;
  final String studentName;
  final int attemptCount;
  final double bestScore;
  final double latestScore;
  final int latestCorrectCount;
  final int latestTotalCount;
  final int wrongCount;
  final String? latestAttemptAt;

  factory VocabularyStudentResultSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return VocabularyStudentResultSummary(
      studentId: _asInt(json['student_id']),
      studentName: _asString(
        json['student_username'],
        fallback: '학생 ${_asInt(json['student_id'])}',
      ),
      attemptCount: _asInt(json['attempt_count']),
      bestScore: _asDouble(json['best_score']),
      latestScore: _asDouble(json['latest_score']),
      latestCorrectCount: _asInt(json['latest_correct_count']),
      latestTotalCount: _asInt(json['latest_total_count']),
      wrongCount: _asInt(json['wrong_count']),
      latestAttemptAt: _nullableString(json['latest_attempt_at']),
    );
  }

  static List<VocabularyStudentResultSummary> listFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => VocabularyStudentResultSummary.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}

class VocabularyAssignment {
  const VocabularyAssignment({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.status,
    this.assignedAt,
  });

  final int id;
  final int studentId;
  final String studentName;
  final String status;
  final String? assignedAt;

  factory VocabularyAssignment.fromJson(Map<String, dynamic> json) {
    return VocabularyAssignment(
      id: _asInt(json['assignment_id'] ?? json['id']),
      studentId: _asInt(json['student_id']),
      studentName: _asString(
        json['student_username'],
        fallback: '학생 ${_asInt(json['student_id'])}',
      ),
      status: _asString(json['status'], fallback: 'assigned'),
      assignedAt: _nullableString(json['assigned_at']),
    );
  }

  static List<VocabularyAssignment> listFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) =>
              VocabularyAssignment.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}

class VocabularyAssignResult {
  const VocabularyAssignResult({
    required this.assignedCount,
    required this.skippedCount,
  });

  final int assignedCount;
  final int skippedCount;

  factory VocabularyAssignResult.fromJson(Map<String, dynamic> json) {
    return VocabularyAssignResult(
      assignedCount: _asInt(json['assigned_count']),
      skippedCount: _asInt(json['skipped_count']),
    );
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _asString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'null' ? fallback : text;
}

String? _nullableString(dynamic value) {
  final text = _asString(value);
  return text.isEmpty ? null : text;
}
