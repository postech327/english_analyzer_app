// lib/models/student_exam/exam_summary_models.dart

class TypeStatistics {
  final int total;
  final int wrong;

  TypeStatistics({
    required this.total,
    required this.wrong,
  });

  factory TypeStatistics.fromJson(Map<String, dynamic> json) {
    return TypeStatistics(
      total: json['total'],
      wrong: json['wrong'],
    );
  }
}

class ExamSummaryResponse {
  final int problemSetId;
  final int userId;
  final int totalQuestions;
  final int correct;
  final int wrong;
  final int accuracy;
  final Map<String, TypeStatistics> byType;

  ExamSummaryResponse({
    required this.problemSetId,
    required this.userId,
    required this.totalQuestions,
    required this.correct,
    required this.wrong,
    required this.accuracy,
    required this.byType,
  });

  factory ExamSummaryResponse.fromJson(Map<String, dynamic> json) {
    final byTypeMap = <String, TypeStatistics>{};
    (json['by_type'] as Map<String, dynamic>).forEach((key, value) {
      byTypeMap[key] = TypeStatistics.fromJson(value);
    });

    return ExamSummaryResponse(
      problemSetId: json['problem_set_id'],
      userId: json['user_id'],
      totalQuestions: json['total_questions'],
      correct: json['correct'],
      wrong: json['wrong'],
      accuracy: json['accuracy'],
      byType: byTypeMap,
    );
  }
}
