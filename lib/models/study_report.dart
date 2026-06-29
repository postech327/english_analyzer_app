class StudyReport {
  final String errorType;
  final int totalAttempts;
  final int totalIncorrect;
  final double accuracy;

  StudyReport({
    required this.errorType,
    required this.totalAttempts,
    required this.totalIncorrect,
    required this.accuracy,
  });

  factory StudyReport.fromJson(Map<String, dynamic> json) {
    return StudyReport(
      errorType: json['error_type'],
      totalAttempts: json['total_attempts'],
      totalIncorrect: json['total_incorrect'],
      accuracy: (json['accuracy'] as num).toDouble(),
    );
  }
}
