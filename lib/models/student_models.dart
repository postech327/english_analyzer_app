// lib/models/student_models.dart

// =====================================================
// 학생용 문제 세트 요약 (목록 화면)
// =====================================================
class StudentProblemSetSummary {
  final int id;
  final String title;
  final String? questionType;
  final int numQuestions;

  StudentProblemSetSummary({
    required this.id,
    required this.title,
    required this.numQuestions,
    this.questionType,
  });

  factory StudentProblemSetSummary.fromJson(Map<String, dynamic> json) {
    return StudentProblemSetSummary(
      id: json['id'] as int,
      title: json['title'] as String,
      questionType: json['question_type'] as String?,
      numQuestions: json['numQuestions'] as int? ?? 0,
    );
  }
}

// =====================================================
// 학생용 전체 문제 세트 (퀴즈 화면)
// =====================================================
class StudentQuestionSet {
  final int problemSetId;
  final String title;
  final String? passageTitle;
  final String? passageContent;
  final List<StudentQuestion> questions;

  StudentQuestionSet({
    required this.problemSetId,
    required this.title,
    required this.questions,
    this.passageTitle,
    this.passageContent,
  });

  factory StudentQuestionSet.fromJson(Map<String, dynamic> json) {
    return StudentQuestionSet(
      problemSetId: json['problem_set_id'] ?? 0,
      title: (json['title'] ?? json['name'] ?? '') as String,
      passageTitle: json['passage_title'] as String?,
      passageContent: json['passage_content'] as String?,
      questions: (json['questions'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => StudentQuestion.fromJson(e))
          .toList(),
    );
  }
}

// =====================================================
// 학생용 문제
// =====================================================
class StudentQuestion {
  final int id;
  final int? order;
  final String? questionType;
  final String text;
  final List<StudentOption> options;

  StudentQuestion({
    required this.id,
    required this.text,
    required this.options,
    this.order,
    this.questionType,
  });

  factory StudentQuestion.fromJson(Map<String, dynamic> json) {
    return StudentQuestion(
      id: json['id'] ?? json['question_id'] ?? 0,
      order: json['order'] as int?,
      questionType: json['question_type'] as String?,
      text: json['text'] ?? '',
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => StudentOption.fromJson(e))
          .toList(),
    );
  }
}

// =====================================================
// 학생용 선택지
// =====================================================
class StudentOption {
  final int? id;
  final String? label;
  final String? text;

  StudentOption({
    this.id,
    this.label,
    this.text,
  });

  factory StudentOption.fromJson(Map<String, dynamic> json) {
    return StudentOption(
      id: json['id'] ?? json['option_id'],
      label: json['label'] as String?,
      text: json['text'] as String?,
    );
  }
}

// =====================================================
// 정답 체크 결과 (🔥 오답 해설 포함)
// =====================================================
class StudentAnswerCheckResult {
  final int questionId;
  final bool correct;
  final int correctOptionId;
  final String? explanation; // ✅ GPT 오답 해설

  StudentAnswerCheckResult({
    required this.questionId,
    required this.correct,
    required this.correctOptionId,
    this.explanation,
  });

  factory StudentAnswerCheckResult.fromJson(Map<String, dynamic> json) {
    return StudentAnswerCheckResult(
      questionId: json['question_id'] as int,
      correct: json['correct'] as bool,
      correctOptionId: json['correct_option_id'] as int,
      explanation: json['explanation'] as String?, // ✅ 핵심
    );
  }
}

// =====================================================
// 학생시험요약
// =====================================================

class StudentExamSummary {
  final int problemSetId;
  final int? folderId;
  final String folderName;
  final String name;
  final String description;
  final int questionCount;
  final String createdAt;
  final bool isCompleted;

  StudentExamSummary({
    required this.problemSetId,
    required this.folderId,
    required this.folderName,
    required this.name,
    required this.description,
    required this.questionCount,
    required this.createdAt,
    required this.isCompleted,
  });

  factory StudentExamSummary.fromJson(Map<String, dynamic> json) {
    return StudentExamSummary(
      problemSetId: _asInt(json['problem_set_id'] ?? json['id']),
      folderId: _asNullableInt(json['folder_id']),
      folderName: (json['folder_name'] ?? '미분류').toString(),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      questionCount: _asInt(json['question_count'] ?? json['numQuestions']),
      createdAt: (json['created_at'] ?? '').toString(),
      isCompleted: json['is_completed'] ?? false,
    );
  }
}

class StudentExamFolder {
  final int? id;
  final int? parentId;
  final String name;
  final int count;
  final bool hasChildren;
  final bool isUnfiled;
  final bool isDirectBucket;

  StudentExamFolder({
    required this.id,
    required this.parentId,
    required this.name,
    required this.count,
    required this.hasChildren,
    required this.isUnfiled,
    required this.isDirectBucket,
  });

  factory StudentExamFolder.fromJson(Map<String, dynamic> json) {
    final name = (json['folder_name'] ?? json['name'] ?? '미분류').toString();
    return StudentExamFolder(
      id: _asNullableInt(json['folder_id'] ?? json['id']),
      parentId: _asNullableInt(json['parent_id']),
      name: name.isEmpty ? '미분류' : name,
      count: _asInt(json['count']),
      hasChildren: json['has_children'] == true,
      isUnfiled: json['is_unfiled'] == true,
      isDirectBucket: json['is_direct_bucket'] == true,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}
