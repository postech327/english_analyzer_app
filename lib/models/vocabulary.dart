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
    this.exampleSentence,
    this.synonym,
    this.antonym,
    this.note,
    this.orderIndex = 0,
  });

  final int id;
  final String word;
  final String meaningKo;
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
    required this.score,
    required this.totalCount,
    required this.correctCount,
    required this.results,
  });

  final int id;
  final double score;
  final int totalCount;
  final int correctCount;
  final List<VocabularyAttemptResult> results;

  factory VocabularyAttempt.fromJson(Map<String, dynamic> json) {
    return VocabularyAttempt(
      id: _asInt(json['attempt_id'] ?? json['id']),
      score: _asDouble(json['score']),
      totalCount: _asInt(json['total_count']),
      correctCount: _asInt(json['correct_count']),
      results: VocabularyAttemptResult.listFromJson(json['results']),
    );
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
