class ProblemSetResultSummary {
  const ProblemSetResultSummary({
    required this.attemptId,
    required this.problemSetId,
    required this.problemSetName,
    required this.score,
    required this.correctCount,
    required this.totalCount,
    required this.weakTypes,
    this.source,
    this.submittedAt,
  });

  final int attemptId;
  final int problemSetId;
  final String problemSetName;
  final String? source;
  final String? submittedAt;
  final int score;
  final int correctCount;
  final int totalCount;
  final List<String> weakTypes;

  factory ProblemSetResultSummary.fromJson(Map<String, dynamic> json) {
    return ProblemSetResultSummary(
      attemptId: _asInt(json['attempt_id']),
      problemSetId: _asInt(json['problem_set_id']),
      problemSetName:
          (json['problem_set_name'] ?? json['name'] ?? 'Problem Set')
              .toString(),
      source: _emptyToNull(json['source']),
      submittedAt: _emptyToNull(json['submitted_at']),
      score: _asInt(json['score']),
      correctCount: _asInt(json['correct_count']),
      totalCount: _asInt(json['total_count'] ?? json['total_questions']),
      weakTypes: (json['weak_types'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
    );
  }

  double get accuracy {
    if (totalCount <= 0) return 0;
    return (correctCount / totalCount).clamp(0.0, 1.0);
  }

  String get weakTypeText {
    if (weakTypes.isEmpty) return '뚜렷한 약점 없음';
    return weakTypes.take(3).join(', ');
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _emptyToNull(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}
