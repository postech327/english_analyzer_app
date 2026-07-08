class IntegratedLearningReport {
  const IntegratedLearningReport({
    required this.generatedAt,
    required this.students,
    this.warnings = const [],
  });

  final DateTime generatedAt;
  final List<StudentIntegratedLearningReport> students;
  final List<String> warnings;

  int get totalStudents => students.length;

  int get activeStudentCount =>
      students.where((student) => student.hasAnyStudyRecord).length;

  int get needsReviewStudentCount =>
      students.where((student) => student.needsReview).length;
}

class StudentIntegratedLearningReport {
  const StudentIntegratedLearningReport({
    required this.studentId,
    required this.studentName,
    required this.email,
    required this.workbook,
    required this.vocabulary,
    required this.finalTouch,
    required this.recommendedActions,
  });

  final int studentId;
  final String studentName;
  final String email;
  final WorkbookReportSummary workbook;
  final VocabularyReportSummary vocabulary;
  final FinalTouchReportSummary finalTouch;
  final List<RecommendedLearningAction> recommendedActions;

  int get completedLearningCount =>
      workbook.completedCount + vocabulary.completedBookCount + finalTouch.viewedCount;

  int get totalLearningCount =>
      workbook.totalCount + vocabulary.assignedBookCount + finalTouch.totalCount;

  int get incompleteCount =>
      workbook.incompleteCount + vocabulary.incompleteBookCount + finalTouch.notViewedCount;

  int get reviewItemCount =>
      workbook.weakTypes.length + vocabulary.wrongWordCount + finalTouch.notViewedCount;

  bool get hasAnyStudyRecord =>
      completedLearningCount > 0 ||
      workbook.averageScore > 0 ||
      vocabulary.studiedWordCount > 0 ||
      vocabulary.wrongWordCount > 0 ||
      finalTouch.sentenceAssemblyCompletedCount > 0;

  bool get needsReview => recommendedActions.isNotEmpty;

  DateTime? get lastStudyAt => latestDate([
        workbook.lastStudyAt,
        vocabulary.lastStudyAt,
        finalTouch.lastViewedAt,
      ]);

  double get overallCompletionRate {
    if (totalLearningCount <= 0) return 0;
    return completedLearningCount / totalLearningCount;
  }
}

class WorkbookReportSummary {
  const WorkbookReportSummary({
    required this.totalCount,
    required this.completedCount,
    required this.incompleteCount,
    required this.averageScore,
    this.lastStudyAt,
    this.weakTypes = const [],
    this.incompleteTitles = const [],
  });

  final int totalCount;
  final int completedCount;
  final int incompleteCount;
  final double averageScore;
  final DateTime? lastStudyAt;
  final List<String> weakTypes;
  final List<String> incompleteTitles;

  static const empty = WorkbookReportSummary(
    totalCount: 0,
    completedCount: 0,
    incompleteCount: 0,
    averageScore: 0,
  );
}

class VocabularyReportSummary {
  const VocabularyReportSummary({
    required this.assignedBookCount,
    required this.completedBookCount,
    required this.studiedWordCount,
    required this.wrongWordCount,
    this.lastStudyAt,
  });

  final int assignedBookCount;
  final int completedBookCount;
  final int studiedWordCount;
  final int wrongWordCount;
  final DateTime? lastStudyAt;

  int get incompleteBookCount {
    final incomplete = assignedBookCount - completedBookCount;
    return incomplete < 0 ? 0 : incomplete;
  }

  static const empty = VocabularyReportSummary(
    assignedBookCount: 0,
    completedBookCount: 0,
    studiedWordCount: 0,
    wrongWordCount: 0,
  );
}

class FinalTouchReportSummary {
  const FinalTouchReportSummary({
    required this.totalCount,
    required this.viewedCount,
    required this.notViewedCount,
    required this.sentenceAssemblyCompletedCount,
    this.lastViewedAt,
    this.notViewedTitles = const [],
  });

  final int totalCount;
  final int viewedCount;
  final int notViewedCount;
  final int sentenceAssemblyCompletedCount;
  final DateTime? lastViewedAt;
  final List<String> notViewedTitles;

  static const empty = FinalTouchReportSummary(
    totalCount: 0,
    viewedCount: 0,
    notViewedCount: 0,
    sentenceAssemblyCompletedCount: 0,
  );
}

class RecommendedLearningAction {
  const RecommendedLearningAction({
    required this.area,
    required this.title,
    required this.message,
    this.priority = ReportActionPriority.medium,
  });

  final String area;
  final String title;
  final String message;
  final ReportActionPriority priority;
}

enum ReportActionPriority { high, medium, low }

DateTime? latestDate(Iterable<DateTime?> values) {
  DateTime? latest;
  for (final value in values) {
    if (value == null) continue;
    if (latest == null || value.isAfter(latest)) latest = value;
  }
  return latest;
}
