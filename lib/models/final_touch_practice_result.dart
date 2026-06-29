class FinalTouchPracticeResult {
  const FinalTouchPracticeResult({
    required this.id,
    required this.finalTouchId,
    required this.passageId,
    required this.sourceLabel,
    required this.totalQuestions,
    required this.correctCount,
    required this.accuracyRate,
    required this.practicedTypes,
    required this.wrongTypes,
    required this.createdAt,
  });

  final int id;
  final int finalTouchId;
  final int? passageId;
  final String sourceLabel;
  final int totalQuestions;
  final int correctCount;
  final double accuracyRate;
  final List<String> practicedTypes;
  final List<String> wrongTypes;
  final DateTime? createdAt;

  factory FinalTouchPracticeResult.fromJson(Map<String, dynamic> json) {
    return FinalTouchPracticeResult(
      id: _asInt(json['id']),
      finalTouchId: _asInt(json['final_touch_id']),
      passageId: _asNullableInt(json['passage_id']),
      sourceLabel: _asString(json['source_label']),
      totalQuestions: _asInt(json['total_questions']),
      correctCount: _asInt(json['correct_count']),
      accuracyRate: _asDouble(json['accuracy_rate']),
      practicedTypes: _asStringList(json['practiced_types']),
      wrongTypes: _asStringList(json['wrong_types']),
      createdAt: DateTime.tryParse(_asString(json['created_at'])),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse('$value');
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

String _asString(dynamic value) => value?.toString() ?? '';

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}
