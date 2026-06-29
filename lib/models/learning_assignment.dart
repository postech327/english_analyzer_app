class LearningAssignment {
  const LearningAssignment({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.contentType,
    required this.contentId,
    required this.title,
    required this.status,
    required this.assignedAt,
    this.teacherMessage,
    this.dueAt,
    this.startedAt,
    this.completedAt,
    this.teacherName,
    this.studentName,
    this.sourceLabel,
    this.folderName,
    this.displayStatus,
  });

  final int id;
  final int teacherId;
  final int studentId;
  final String contentType;
  final int contentId;
  final String title;
  final String? teacherMessage;
  final String? dueAt;
  final String status;
  final String assignedAt;
  final String? startedAt;
  final String? completedAt;
  final String? teacherName;
  final String? studentName;
  final String? sourceLabel;
  final String? folderName;
  final String? displayStatus;

  bool get isFinalTouch => contentType == 'final_touch';
  bool get isWorkbook => contentType == 'workbook';
  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isAssigned => status == 'assigned';

  factory LearningAssignment.fromJson(Map<String, dynamic> json) {
    return LearningAssignment(
      id: _asInt(json['assignment_id'] ?? json['id']),
      teacherId: _asInt(json['teacher_id']),
      studentId: _asInt(json['student_id']),
      contentType: _asString(json['content_type']),
      contentId: _asInt(json['content_id']),
      title: _asString(json['title']),
      teacherMessage: _nullableString(json['teacher_message']),
      dueAt: _nullableString(json['due_at']),
      status: _asString(json['status'], fallback: 'assigned'),
      assignedAt: _asString(json['assigned_at']),
      startedAt: _nullableString(json['started_at']),
      completedAt: _nullableString(json['completed_at']),
      teacherName: _nullableString(json['teacher_name']),
      studentName: _nullableString(json['student_name']),
      sourceLabel: _nullableString(json['source_label']),
      folderName: _nullableString(json['folder_name']),
      displayStatus: _nullableString(json['display_status']),
    );
  }

  static List<LearningAssignment> listFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => LearningAssignment.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }
}

class AssignableStudent {
  const AssignableStudent({
    required this.id,
    required this.nickname,
    required this.email,
  });

  final int id;
  final String nickname;
  final String email;

  factory AssignableStudent.fromJson(Map<String, dynamic> json) {
    return AssignableStudent(
      id: _asInt(json['id']),
      nickname: _asString(json['nickname'], fallback: 'student'),
      email: _asString(json['email']),
    );
  }

  static List<AssignableStudent> listFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => AssignableStudent.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }
}

class AssignmentCreateResult {
  const AssignmentCreateResult({
    required this.createdCount,
    required this.skippedCount,
    required this.skippedStudents,
  });

  final int createdCount;
  final int skippedCount;
  final List<String> skippedStudents;

  factory AssignmentCreateResult.fromJson(Map<String, dynamic> json) {
    final skipped = json['skipped_students'];
    return AssignmentCreateResult(
      createdCount: _asInt(json['created_count']),
      skippedCount: _asInt(json['skipped_count']),
      skippedStudents: skipped is List
          ? skipped.map((item) => item.toString()).toList()
          : const [],
    );
  }
}

int _asInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
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
