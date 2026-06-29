class IntegratedReport {
  const IntegratedReport({
    required this.problemSetAttemptCount,
    required this.mockExamAttemptCount,
    required this.problemSetAverageScore,
    required this.mockExamAverageScore,
    required this.overallAverageScore,
    required this.problemSetWeakTypes,
    required this.mockExamWeakTypes,
    required this.commonWeakTypes,
    required this.recentProblemSetResults,
    required this.recentMockExamResults,
    required this.recommendations,
    this.latestProblemSetScore,
    this.latestMockExamScore,
  });

  final int problemSetAttemptCount;
  final int mockExamAttemptCount;
  final double problemSetAverageScore;
  final double mockExamAverageScore;
  final double overallAverageScore;
  final int? latestProblemSetScore;
  final int? latestMockExamScore;
  final List<String> problemSetWeakTypes;
  final List<String> mockExamWeakTypes;
  final List<String> commonWeakTypes;
  final List<RecentResultItem> recentProblemSetResults;
  final List<RecentResultItem> recentMockExamResults;
  final List<String> recommendations;

  factory IntegratedReport.fromJson(Map<String, dynamic> json) {
    return IntegratedReport(
      problemSetAttemptCount: _asInt(json['problem_set_attempt_count']),
      mockExamAttemptCount: _asInt(json['mock_exam_attempt_count']),
      problemSetAverageScore: _asDouble(json['problem_set_average_score']),
      mockExamAverageScore: _asDouble(json['mock_exam_average_score']),
      overallAverageScore: _asDouble(json['overall_average_score']),
      latestProblemSetScore: _asNullableInt(json['latest_problem_set_score']),
      latestMockExamScore: _asNullableInt(json['latest_mock_exam_score']),
      problemSetWeakTypes: _stringList(json['problem_set_weak_types']),
      mockExamWeakTypes: _stringList(json['mock_exam_weak_types']),
      commonWeakTypes: _stringList(json['common_weak_types']),
      recentProblemSetResults: _resultList(json['recent_problem_set_results']),
      recentMockExamResults: _resultList(json['recent_mock_exam_results']),
      recommendations: _stringList(json['recommendations']),
    );
  }

  bool get hasAnyResult =>
      problemSetAttemptCount > 0 || mockExamAttemptCount > 0;
}

class RecentResultItem {
  const RecentResultItem({
    required this.id,
    required this.title,
    required this.score,
    required this.correctCount,
    required this.totalCount,
    this.source,
    this.submittedAt,
  });

  final int id;
  final String title;
  final String? source;
  final String? submittedAt;
  final int score;
  final int correctCount;
  final int totalCount;

  factory RecentResultItem.fromJson(Map<String, dynamic> json) {
    return RecentResultItem(
      id: _asInt(json['id'] ?? json['attempt_id'] ?? json['problem_set_id']),
      title: (json['title'] ?? json['problem_set_name'] ?? 'Result').toString(),
      source: _emptyToNull(json['source']),
      submittedAt: _emptyToNull(json['submitted_at']),
      score: _asInt(json['score']),
      correctCount: _asInt(json['correct_count']),
      totalCount: _asInt(json['total_count'] ?? json['total_questions']),
    );
  }
}

List<RecentResultItem> _resultList(dynamic value) {
  return (value as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(RecentResultItem.fromJson)
      .toList();
}

List<String> _stringList(dynamic value) {
  return (value as List<dynamic>? ?? const [])
      .map((item) => item.toString())
      .where((item) => item.trim().isNotEmpty)
      .toList();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString());
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String? _emptyToNull(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}
