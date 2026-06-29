class ExamSummary {
  final int problemSetId;
  final String title;
  final int totalQuestions;
  final int correctCount;
  final int incorrectCount;
  final double accuracyRate;
  final List<List<dynamic>> weakTypes;

  ExamSummary({
    required this.problemSetId,
    required this.title,
    required this.totalQuestions,
    required this.correctCount,
    required this.incorrectCount,
    required this.accuracyRate,
    required this.weakTypes,
  });

  factory ExamSummary.fromJson(Map<String, dynamic> json) {
    return ExamSummary(
      problemSetId: json['problem_set_id'],
      title: json['title'],
      totalQuestions: json['total_questions'],
      correctCount: json['correct_count'],
      incorrectCount: json['incorrect_count'],
      accuracyRate: (json['accuracy_rate'] as num).toDouble(),
      weakTypes: List<List<dynamic>>.from(json['weak_types'] ?? []),
    );
  }
}