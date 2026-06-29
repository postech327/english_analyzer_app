class WorkbookAttempt {
  const WorkbookAttempt({
    required this.id,
    required this.assignmentId,
    required this.workbookId,
    required this.attemptNo,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.scorePercent,
    this.submittedAt,
    this.startedAt,
    this.results = const [],
  });

  final int id;
  final int assignmentId;
  final int workbookId;
  final int attemptNo;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final double scorePercent;
  final String? submittedAt;
  final String? startedAt;
  final List<WorkbookAttemptAnswerResult> results;

  factory WorkbookAttempt.fromJson(Map<String, dynamic> json) {
    return WorkbookAttempt(
      id: _asInt(json['attempt_id'] ?? json['id']),
      assignmentId: _asInt(json['assignment_id']),
      workbookId: _asInt(json['workbook_id']),
      attemptNo: _asInt(json['attempt_no'], fallback: 1),
      totalQuestions: _asInt(json['total_questions']),
      correctCount: _asInt(json['correct_count']),
      wrongCount: _asInt(json['wrong_count']),
      scorePercent: _asDouble(json['score_percent']),
      submittedAt: _nullableString(json['submitted_at']),
      startedAt: _nullableString(json['started_at']),
      results: WorkbookAttemptAnswerResult.listFromJson(json['results']),
    );
  }

  static List<WorkbookAttempt> listFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
            (item) => WorkbookAttempt.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class WorkbookAttemptAnswerResult {
  const WorkbookAttemptAnswerResult({
    required this.questionId,
    required this.questionType,
    required this.isCorrect,
    this.itemNumber,
    this.studentAnswer,
    this.correctAnswer,
    this.explanation,
  });

  final int questionId;
  final String questionType;
  final int? itemNumber;
  final String? studentAnswer;
  final String? correctAnswer;
  final bool isCorrect;
  final String? explanation;

  factory WorkbookAttemptAnswerResult.fromJson(Map<String, dynamic> json) {
    return WorkbookAttemptAnswerResult(
      questionId: _asInt(json['question_id']),
      questionType: _asString(json['question_type']),
      itemNumber: _nullableInt(json['item_number']),
      studentAnswer: _nullableString(json['student_answer']),
      correctAnswer: _nullableString(json['correct_answer']),
      isCorrect: json['is_correct'] == true,
      explanation: _nullableString(json['explanation']),
    );
  }

  static List<WorkbookAttemptAnswerResult> listFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => WorkbookAttemptAnswerResult.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }
}

class TeacherWorkbookAttemptReport {
  const TeacherWorkbookAttemptReport({
    required this.studentName,
    required this.workbookTitle,
    required this.assignmentStatus,
    required this.attemptCount,
    this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.dueAt,
    this.latestAttempt,
    this.attempts = const [],
  });

  final String studentName;
  final String workbookTitle;
  final String assignmentStatus;
  final String? assignedAt;
  final String? startedAt;
  final String? completedAt;
  final String? dueAt;
  final int attemptCount;
  final WorkbookAttempt? latestAttempt;
  final List<WorkbookAttempt> attempts;

  factory TeacherWorkbookAttemptReport.fromJson(Map<String, dynamic> json) {
    final student = json['student'] is Map
        ? Map<String, dynamic>.from(json['student'] as Map)
        : const <String, dynamic>{};
    final workbook = json['workbook'] is Map
        ? Map<String, dynamic>.from(json['workbook'] as Map)
        : const <String, dynamic>{};
    final assignment = json['assignment'] is Map
        ? Map<String, dynamic>.from(json['assignment'] as Map)
        : const <String, dynamic>{};
    final latest = json['latest_attempt'];
    return TeacherWorkbookAttemptReport(
      studentName: _asString(student['nickname'], fallback: 'student'),
      workbookTitle: _asString(workbook['title'], fallback: '워크북'),
      assignmentStatus: _asString(assignment['status'], fallback: 'assigned'),
      assignedAt: _nullableString(assignment['assigned_at']),
      startedAt: _nullableString(assignment['started_at']),
      completedAt: _nullableString(assignment['completed_at']),
      dueAt: _nullableString(assignment['due_at']),
      attemptCount: _asInt(json['attempt_count']),
      latestAttempt: latest is Map
          ? WorkbookAttempt.fromJson(Map<String, dynamic>.from(latest))
          : null,
      attempts: WorkbookAttempt.listFromJson(json['attempts']),
    );
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  final parsed = _asInt(value, fallback: -1);
  return parsed < 0 ? null : parsed;
}

double _asDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  if (text.isEmpty || text == 'null') return fallback;
  return text;
}

String? _nullableString(dynamic value) {
  final text = _asString(value);
  return text.isEmpty ? null : text;
}
