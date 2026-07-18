class StudentAssignedProblemSet {
  const StudentAssignedProblemSet({
    required this.assignmentId,
    required this.problemSetId,
    required this.name,
    required this.folderName,
    required this.questionCount,
    required this.status,
    required this.assignedAt,
    required this.teacherName,
    required this.isCompleted,
  });

  final int assignmentId;
  final int problemSetId;
  final String name;
  final String folderName;
  final int questionCount;
  final String status;
  final String assignedAt;
  final String teacherName;
  final bool isCompleted;

  factory StudentAssignedProblemSet.fromJson(Map<String, dynamic> json) {
    return StudentAssignedProblemSet(
      assignmentId: _asInt(json['assignment_id'] ?? json['id']),
      problemSetId: _asInt(json['problem_set_id']),
      name: _asText(
        json['name'] ?? json['problem_set_name'] ?? json['title'],
        fallback: '문제세트',
      ),
      folderName: _asText(json['folder_name'], fallback: '미분류'),
      questionCount: _asInt(json['question_count']),
      status: _asText(json['status'], fallback: 'assigned'),
      assignedAt: _asText(json['assigned_at']),
      teacherName: _asText(json['teacher_name'], fallback: '선생님'),
      isCompleted:
          json['is_completed'] == true || json['status'] == 'completed',
    );
  }

  static List<StudentAssignedProblemSet> listFromJson(dynamic value) {
    final items = value is Map<String, dynamic>
        ? value['assignments'] ?? value['items']
        : value;
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => StudentAssignedProblemSet.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((item) => item.problemSetId > 0)
        .toList();
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _asText(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty || text == 'null') return fallback;
  return text;
}
